#!/usr/bin/env python3
"""What Standard's Hyprland configuration USES, against two Hyprland sources.

    hyprland.py <running source> <latest source> <calls.log> <hypr tree> [patches dir]

"Uses" is read from the configuration itself, not from a list kept by hand:
  - calls.log is everything the configuration does when it is run against the
    recording mock (system/home/hypr/test/mock.lua): every option it sets,
    every rule, bind, monitor, animation and curve with its keys;
  - the tree's Lua files give the hl.* functions, dispatchers and events named.

Each name is then looked for in the source of the Hyprland Standard runs and in
the latest one. A name the first has and the second has not is what breaks at
the next move of the pin; an option whose type changed is shown with both.
Exit status 1 when something Standard uses is gone from the latest.
"""
import json
import os
import re
import sys


def sources(root):
    out = {}
    for d, _, files in os.walk(os.path.join(root, "src")):
        for f in files:
            if f.endswith((".cpp", ".hpp", ".h", ".c")):
                p = os.path.join(d, f)
                try:
                    out[p] = open(p, errors="replace").read()
                except OSError:
                    pass
    return out


def quoted(files):
    """every "string" of the source -> the files it is in"""
    idx = {}
    for p, text in files.items():
        for m in re.finditer(r'"((?:[^"\\\n]|\\.)*)"', text):
            idx.setdefault(m.group(1), set()).add(p)
    return idx


def registered(text_by_file):
    """the options a source registers: name -> (type, the rest of its line)"""
    r = {}
    for p, text in text_by_file.items():
        for m in re.finditer(r'MS<(\w+)>\(\s*"([^"]+)"([^\n]*)', text):
            r[m.group(2)] = (m.group(1), m.group(3))
    return r


class Table:
    """the mock's way of writing a Lua value -> dicts, lists, scalars"""

    def __init__(self, text):
        self.s, self.i = text, 0

    def ws(self):
        while self.i < len(self.s) and self.s[self.i] in " \t":
            self.i += 1

    def value(self):
        self.ws()
        c = self.s[self.i]
        if c == "{":
            return self.table()
        if c == '"':
            m = re.compile(r'"((?:[^"\\]|\\.)*)"').match(self.s, self.i)
            self.i = m.end()
            return m.group(1)
        m = re.compile(r"<[^>]*>|[^,{}\s]+").match(self.s, self.i)
        self.i = m.end()
        return m.group(0)

    def table(self):
        self.i += 1
        d, seq = {}, []
        while True:
            self.ws()
            if self.s[self.i] == "}":
                self.i += 1
                break
            m = re.compile(r'(?:([A-Za-z_]\w*)|\["((?:[^"\\]|\\.)*)"\])\s*=\s*').match(self.s, self.i)
            if m:
                self.i = m.end()
                d[m.group(1) or m.group(2)] = self.value()
            else:
                seq.append(self.value())
            self.ws()
            if self.s[self.i] == ",":
                self.i += 1
        return d if d or not seq else seq


def norm(name):
    return name.replace(".", ":")


def main():
    old_root, new_root, calls_path, tree = sys.argv[1:5]
    patches = sys.argv[5] if len(sys.argv) > 5 else None

    old_src, new_src = sources(old_root), sources(new_root)
    old_q, new_q = quoted(old_src), quoted(new_src)
    reg_old, reg_new = registered(old_src), registered(new_src)
    reg_patch = {}
    if patches and os.path.isdir(patches):
        added = {}
        for f in sorted(os.listdir(patches)):
            if f.endswith(".patch"):
                text = open(os.path.join(patches, f), errors="replace").read()
                added[f] = "\n".join(l[1:] for l in text.split("\n") if l.startswith("+") and not l.startswith("+++"))
        reg_patch = registered(added)

    calls = [l.rstrip("\n") for l in open(calls_path) if l.strip() and not l.startswith("--")]

    # ── the options set ────────────────────────────────────────────────────
    known = {norm(n): n for n in list(reg_old) + list(reg_new) + list(reg_patch)}
    used, unknown = set(), set()

    def walk(path, v):
        key = ":".join(path)
        if key in known:
            used.add(known[key])
        elif isinstance(v, dict):
            for k, x in v.items():
                walk(path + norm(k).split(":"), x)
        else:
            unknown.add(key)

    for l in calls:
        if l.startswith("config("):
            walk([], Table(l[len("config("):]).value())

    gone = sorted(o for o in used if (o in reg_old or o in reg_patch) and o not in reg_new and o not in reg_patch)
    typed = sorted((o, reg_old[o][0], reg_new[o][0]) for o in used if o in reg_old and o in reg_new and reg_old[o][0] != reg_new[o][0])

    # ── the names used: functions, keys, events, dispatchers ───────────────
    lua = {}
    for d, _, files in os.walk(tree):
        if os.sep + "test" in d:
            continue
        for f in files:
            if f.endswith(".lua"):
                text = open(os.path.join(d, f)).read()
                lua[f] = "\n".join(re.sub(r"--.*$", "", line) for line in text.split("\n"))

    groups = {}

    def add(kind, name):
        groups.setdefault(kind, set()).add(name)

    def keys_of(kind, text):
        for m in re.finditer(r'(?<![\w"])([A-Za-z_]\w*) = ', text):
            add(kind, m.group(1))

    for text in lua.values():
        for m in re.finditer(r"\bhl((?:\.[A-Za-z_]\w*)+)", text):
            fn = "hl" + m.group(1)
            if not fn.startswith("hl.plugin."):
                add("hl.* functions (last word)", fn.split(".")[-1])
        for m in re.finditer(r'hl\.on\(\s*"([^"]+)"', text):
            add("events", m.group(1))

    for l in calls:
        m0 = re.match(r"[\w.]+", l)
        if not m0:
            continue
        name, body = m0.group(0), l[m0.end():]
        if name == "bind":
            parts = l.split("\t")
            if len(parts) >= 5:
                keys_of("bind: options", parts[4])
            continue
        if name == "on":
            m = re.search(r'on\("([^"]+)"', l)
            if m:
                add("events", m.group(1))
            continue
        if name in ("window_rule", "layer_rule"):
            mm = re.search(r"match = \{([^{}]*)\}", body)
            if mm:
                keys_of(name + ": match", mm.group(1))
                body = body.replace(mm.group(0), "")
            keys_of(name + ": effects", body)
            continue
        if name == "config" or name.startswith("plugin."):
            continue
        if name == "animation":
            for m in re.finditer(r'leaf = "([^"]+)"', l):
                add("animation: leaves", m.group(1))
            for m in re.finditer(r'style = "([a-zA-Z]+)', l):
                add("animation: styles", m.group(1))
        if name == "curve":
            for m in re.finditer(r'type = "([^"]+)"', l):
                add("curve: types", m.group(1))
        keys_of(name + ": keys", body)

    def count(idx, name):
        return len(idx.get(name, ()))

    names = {}
    names_gone = []
    for kind in sorted(groups):
        rows = [(n, count(old_q, n), count(new_q, n)) for n in sorted(groups[kind])]
        g = [n for n, o, nw in rows if o > 0 and nw == 0]
        blind = [n for n, o, nw in rows if o == 0]
        names[kind] = {"used": len(rows), "gone in the latest": g, "not found in the running source either (look by hand)": blind}
        names_gone += [f"{kind}: {n}" for n in g]

    def version(root):
        try:
            return open(os.path.join(root, "VERSION")).read().strip()
        except OSError:
            return "?"

    report = {
        "running": version(old_root),
        "latest": version(new_root),
        "options registered": {"running": len(reg_old), "latest": len(reg_new), "by Standard's patches": sorted(reg_patch)},
        "options Standard sets": len(used),
        "options gone in the latest": gone,
        "options whose type changed": [{"option": o, "running": a, "latest": b} for o, a, b in typed],
        "set but registered nowhere (look by hand)": sorted(unknown),
        "names": names,
    }
    print(json.dumps(report, indent=1, ensure_ascii=False))
    return 1 if gone or names_gone else 0


if __name__ == "__main__":
    sys.exit(main())
