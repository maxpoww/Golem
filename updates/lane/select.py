#!/usr/bin/env python3
"""Choose which store paths go into a version's cache (one GitHub release).

    select.py CLOSURE_JSON DRVS_JSON MISSING_HASHES NEVER_PUBLISH OUT_LIST [PLACEHOLDER_DIR]

CLOSURE_JSON    `nix path-info -r --json` of the gate's output (any shape nix
                prints: a list of objects or an object keyed by path).
DRVS_JSON       `nix derivation show` of the derivers of the paths
                cache.nixos.org lacks ({} when not known).
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

The rule. Upload every path cache.nixos.org lacks whose derivation nix
would SUBSTITUTE (allowSubstitutes, the default; the trivial builders —
writeText, runCommandLocal, unit files — set it false, and nix builds those
locally whatever a cache holds). A size threshold is NOT the rule: the
first real update (MacBook, 2026-10-27) started compiling Hyprland on the
laptop because its 20 KiB `man` output was under the old 64 KiB threshold,
and nix builds the WHOLE derivation when one output it needs is in no cache.
Paths with no derivation (eval-time sources: patches, flake files) come
from every machine's own evaluation and stay out.

Three kinds stay out even when substitutable (first gate, 2026-10-27: 591
paths cache.nixos.org lacks, 201 substitutable):
- PER-MACHINE pieces: a fixture's initrd, system-path, unit lists, hwdb,
  toplevel… Every real machine builds its own from its own hardware and
  answers, so the fixtures' copies would never be used.
- FIXED-OUTPUT downloads (a file fetched verbatim from a third-party URL,
  path-info "ca: fixed:…"): each machine fetches them from their source
  just as fast, and we do not re-host other people's files.
- NEVER_PUBLISH: what the licence does not let us redistribute.

GitHub allows 1000 files per release; each path costs two (narinfo + nar)
plus nix-cache-info. A set that does not fit fails loudly (exit 3): never
drop pieces silently, that is how a laptop ends up compiling.
"""
import json
import os
import re
import sys

LIMIT_FILES = 990  # GitHub: 1000 assets per release, keep a margin
PER_MACHINE = [re.compile(r) for r in (
    r"^initrd-linux-", r"^nixos-system-", r"^system-path$", r"^system-units",
    r"^user-units", r"^etc$", r"^hwdb\.bin$", r"^home-manager-path$",
    r"^home-manager-generation$", r"^user-environment$", r"^X-Restart-Triggers",
    r"^firmware$",
)]


def load_closure(path):
    data = json.load(open(path))
    items = data.items() if isinstance(data, dict) else ((d["path"], d) for d in data)
    info = {}
    for p, d in items:
        if d is None:
            continue
        info[p] = {
            "size": int(d.get("narSize", 0)),
            "fixed": str(d.get("ca") or "").startswith("fixed:"),
            "hash": d.get("narHash", ""),
            "refs": d.get("references", []),
            "deriver": d.get("deriver"),
        }
    return info


def name_of(path):
    base = path.rsplit("/", 1)[-1]
    return base.split("-", 1)[1] if "-" in base else base


def hash_of(path):
    return path.rsplit("/", 1)[-1].split("-", 1)[0]


def main():
    if len(sys.argv) not in (6, 7):
        sys.exit(__doc__.split("\n\n")[1])
    closure_json, drvs_json, missing_file, never_file, out_file = sys.argv[1:6]
    placeholder_dir = sys.argv[6] if len(sys.argv) > 6 else None
    # Never write over an input: called with the arguments in the wrong
    # order, an earlier version emptied never-publish (2026-10-27).
    if os.path.exists(out_file):
        sys.exit(f"select.py: refusing to write over {out_file} (the lane writes into a fresh directory)")
    info = load_closure(closure_json)
    drvs = json.load(open(drvs_json))
    drvs = drvs.get("derivations", drvs) if isinstance(drvs, dict) else {}
    missing = {l.strip() for l in open(missing_file) if l.strip()}
    never = [re.compile(l.strip()) for l in open(never_file)
             if l.strip() and not l.lstrip().startswith("#")]

    def substitutable(p):
        """True/False from the derivation; None when there is none."""
        dv = info[p]["deriver"]
        if not dv:
            return None
        drv = drvs.get(dv) or drvs.get(dv.rsplit("/", 1)[-1])
        if drv is None:
            return None
        env = drv.get("env", {})
        if env.get("__json"):  # structuredAttrs
            try:
                env = json.loads(env["__json"])
            except ValueError:
                env = {}
        return env.get("allowSubstitutes", True) not in ("", "0", False, 0)

    lacking = {p for p in info if hash_of(p) in missing}
    refused = sorted(p for p in lacking if any(r.search(name_of(p)) for r in never))
    per_machine = {p for p in lacking if any(r.search(name_of(p)) for r in PER_MACHINE)}
    downloads = {p for p in lacking if info[p]["fixed"]}
    eligible = lacking - set(refused) - per_machine - downloads
    local_only = {p for p in eligible if substitutable(p) is False}
    no_drv = {p for p in eligible if substitutable(p) is None}
    chosen = eligible - local_only - no_drv

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

    files = 2 * len(chosen) + 1
    print(json.dumps({
        "closure": len(info),
        "not_on_cache_nixos_org": len(lacking),
        "never_publish": [name_of(p) for p in refused],
        "per_machine_left_out": len(per_machine),
        "downloads_left_out": len(downloads),
        "local_only_left_out": len(local_only),
        "no_derivation_left_out": len(no_drv),
        "chosen": len(chosen),
        "chosen_nar_mib": sum(info[p]["size"] for p in chosen) >> 20,
        "files": files,
        "placeholders": len(placeholders),
    }))
    if files > LIMIT_FILES:
        print(f"select.py: {files} files do not fit one GitHub release ({LIMIT_FILES});"
              " split the cache (updates/README.md, The cache)", file=sys.stderr)
        sys.exit(3)


if __name__ == "__main__":
    main()
