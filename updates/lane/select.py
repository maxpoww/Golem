#!/usr/bin/env python3
"""Choose which store paths go into a version's cache (one GitHub release).

    select.py CLOSURE_JSON MISSING_HASHES NEVER_PUBLISH OUT_LIST [PLACEHOLDER_DIR]

CLOSURE_JSON    `nix path-info -r --json` of the gate's output (any shape nix
                prints: a list of objects or an object keyed by path).
MISSING_HASHES  one store hash per line: paths cache.nixos.org does NOT have.
NEVER_PUBLISH   regexes (one per line, # comments) matched against the path's
                name (after "<hash>-"): never uploaded, whatever else is true.
OUT_LIST        written: the chosen store paths, one per line.
PLACEHOLDER_DIR if given: a placeholder .narinfo there for every path the
                chosen ones refer to but that is not chosen, and their file
                names in PLACEHOLDER_DIR/placeholders.txt. Nix adds a path to
                a binary cache only when every reference is already listed
                in it ("the reference … is not valid"); the lane exports
                into that directory, then deletes the placeholders before
                uploading. A machine gets those references where it gets
                them today: cache.nixos.org, its own build, the download.

The rule. A path is worth uploading when cache.nixos.org lacks it AND it is
heavy (NAR size >= the threshold): heavy = slow to build or fetch (the dock,
patched Hyprland, nvidia, Seam, kernel modules, firmware). The small rest
(config and unit files, wrappers, the per-fixture toplevels) stays out: each
machine builds those in seconds, its own are different from the fixtures'
anyway, and following the references of the big aggregates (system-path,
etc) would drag every one of them in (2026-10-27, measured on the dev box:
352 paths, 50 of them heavy).

Two kinds stay out even when heavy (measured on the first gate, 2026-10-27:
172 heavy paths, 4.5 GiB):
- PER-MACHINE pieces: a fixture's initrd, system-path, unit lists, hwdb,
  the toplevel… Every real machine builds its own from its own hardware
  and answers, so the fixtures' copies would never be used (the eight
  initrds alone were 629 MiB).
- FIXED-OUTPUT downloads (a file fetched verbatim from a third-party URL,
  path-info "ca: fixed:…"): each machine fetches them from their source
  just as fast, and we do not re-host other people's files.

GitHub allows 1000 files per release; each path costs two (narinfo + nar)
plus nix-cache-info. If the set is too big the threshold doubles until it
fits, and the summary says so.
"""
import json
import re
import sys

LIMIT_FILES = 990          # GitHub: 1000 assets per release, keep a margin
PER_MACHINE = [re.compile(r) for r in (
    r"^initrd-linux-", r"^nixos-system-", r"^system-path$", r"^system-units",
    r"^user-units", r"^etc$", r"^hwdb\.bin$", r"^home-manager-path$",
    r"^home-manager-generation$", r"^user-environment$", r"^X-Restart-Triggers",
    r"^firmware$",
)]
START_THRESHOLD = 64 << 10  # 64 KiB


def load_closure(path):
    data = json.load(open(path))
    items = data.items() if isinstance(data, dict) else ((d["path"], d) for d in data)
    info = {}
    for p, d in items:
        if d is None:
            continue
        info[p] = {"size": int(d.get("narSize", 0)),
                   "fixed": str(d.get("ca") or "").startswith("fixed:"),
                   "hash": d.get("narHash", ""), "refs": d.get("references", [])}
    return info


def name_of(path):
    base = path.rsplit("/", 1)[-1]
    return base.split("-", 1)[1] if "-" in base else base


def main():
    closure_json, missing_file, never_file, out_file = sys.argv[1:5]
    placeholder_dir = sys.argv[5] if len(sys.argv) > 5 else None
    info = load_closure(closure_json)
    missing = {l.strip() for l in open(missing_file) if l.strip()}
    never = [re.compile(l.strip()) for l in open(never_file)
             if l.strip() and not l.lstrip().startswith("#")]

    def hash_of(p):
        return p.rsplit("/", 1)[-1].split("-", 1)[0]

    refused = sorted(p for p in info if hash_of(p) in missing
                     and any(r.search(name_of(p)) for r in never))
    per_machine = {p for p in info if hash_of(p) in missing
                   and any(r.search(name_of(p)) for r in PER_MACHINE)}
    downloads = {p for p in info if hash_of(p) in missing and info[p]["fixed"]}
    eligible = {p for p in info if hash_of(p) in missing
                and p not in refused and p not in per_machine and p not in downloads}

    threshold = START_THRESHOLD
    while True:
        chosen = {p for p in eligible if info[p]["size"] >= threshold}
        if 2 * len(chosen) + 1 <= LIMIT_FILES:
            break
        threshold *= 2

    with open(out_file, "w") as f:
        for p in sorted(chosen):
            f.write(p + "\n")

    placeholders = sorted({r for p in chosen for r in info[p]["refs"]
                           if r != p and r not in chosen and r in info})
    if placeholder_dir:
        names = []
        for r in placeholders:
            fn = hash_of(r) + ".narinfo"
            refs = " ".join(x.rsplit("/", 1)[-1] for x in info[r]["refs"])
            with open(f"{placeholder_dir}/{fn}", "w") as f:
                f.write(f"StorePath: {r}\nURL: placeholder.nar\nCompression: none\n"
                        f"NarHash: {info[r]['hash']}\nNarSize: {info[r]['size']}\n"
                        f"References: {refs}\n")
            names.append(fn)
        with open(f"{placeholder_dir}/placeholders.txt", "w") as f:
            f.write("".join(n + "\n" for n in names))

    total = sum(info[p]["size"] for p in chosen)
    print(json.dumps({
        "closure": len(info),
        "not_on_cache_nixos_org": sum(1 for p in info if hash_of(p) in missing),
        "never_publish": [name_of(p) for p in refused],
        "per_machine_left_out": len(per_machine),
        "downloads_left_out": len(downloads),
        "threshold_kib": threshold >> 10,
        "chosen": len(chosen),
        "chosen_nar_mib": total >> 20,
        "files": 2 * len(chosen) + 1,
        "placeholders": len(placeholders),
    }))


if __name__ == "__main__":
    main()
