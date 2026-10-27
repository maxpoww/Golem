#!/usr/bin/env python3
"""Choose which store paths go into a version's cache (one GitHub release).

    select.py CLOSURE_JSON MISSING_HASHES NEVER_PUBLISH OUT_LIST

CLOSURE_JSON    `nix path-info -r --json` of the gate's output (any shape nix
                prints: a list of objects or an object keyed by path).
MISSING_HASHES  one store hash per line: paths cache.nixos.org does NOT have.
NEVER_PUBLISH   regexes (one per line, # comments) matched against the path's
                name (after "<hash>-"): never uploaded, whatever else is true.
OUT_LIST        written: the chosen store paths, one per line.

The rule. A path is worth uploading when cache.nixos.org lacks it AND it is
heavy (NAR size >= the threshold): heavy = slow to build or fetch (the dock,
patched Hyprland, nvidia, Seam, kernel modules, firmware). The small rest
(config and unit files, wrappers, the per-fixture toplevels) stays out: each
machine builds those in seconds, its own are different from the fixtures'
anyway, and following the references of the big aggregates (system-path,
etc) would drag every one of them in (2026-10-27, measured on the dev box:
352 paths, 50 of them heavy).

GitHub allows 1000 files per release; each path costs two (narinfo + nar)
plus nix-cache-info. If the set is too big the threshold doubles until it
fits, and the summary says so.
"""
import json
import re
import sys

LIMIT_FILES = 990          # GitHub: 1000 assets per release, keep a margin
START_THRESHOLD = 64 << 10  # 64 KiB


def load_closure(path):
    data = json.load(open(path))
    items = data.items() if isinstance(data, dict) else ((d["path"], d) for d in data)
    info = {}
    for p, d in items:
        if d is None:
            continue
        info[p] = {"size": int(d.get("narSize", 0))}
    return info


def name_of(path):
    base = path.rsplit("/", 1)[-1]
    return base.split("-", 1)[1] if "-" in base else base


def main():
    closure_json, missing_file, never_file, out_file = sys.argv[1:5]
    info = load_closure(closure_json)
    missing = {l.strip() for l in open(missing_file) if l.strip()}
    never = [re.compile(l.strip()) for l in open(never_file)
             if l.strip() and not l.lstrip().startswith("#")]

    def hash_of(p):
        return p.rsplit("/", 1)[-1].split("-", 1)[0]

    refused = sorted(p for p in info if hash_of(p) in missing
                     and any(r.search(name_of(p)) for r in never))
    eligible = {p for p in info if hash_of(p) in missing and p not in refused}

    threshold = START_THRESHOLD
    while True:
        chosen = {p for p in eligible if info[p]["size"] >= threshold}
        if 2 * len(chosen) + 1 <= LIMIT_FILES:
            break
        threshold *= 2

    with open(out_file, "w") as f:
        for p in sorted(chosen):
            f.write(p + "\n")

    total = sum(info[p]["size"] for p in chosen)
    print(json.dumps({
        "closure": len(info),
        "not_on_cache_nixos_org": len(eligible) + len(refused),
        "never_publish": [name_of(p) for p in refused],
        "threshold_kib": threshold >> 10,
        "chosen": len(chosen),
        "chosen_nar_mib": total >> 20,
        "files": 2 * len(chosen) + 1,
    }))


if __name__ == "__main__":
    main()
