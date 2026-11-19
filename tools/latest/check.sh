#!/usr/bin/env bash
# check.sh — what Golem USES of NixOS and of Hyprland, against the LATEST of
# each. (Max, 2026-11-19: "checkealos todos con la última documentación de
# nixos e hyprland".) The documentation of both is generated from their
# source, so the source is what is read: nothing is kept by hand, and the
# answer is exact for the day it is asked.
#
#   NixOS     every option Golem's app modules, the loopback camera and the
#             /etc/nixos layout define, in nixos-unstable: there, visible,
#             the same type; the packages they name; the catalog's programs.
#   Hyprland  every option Golem's configuration sets, every hl.* function,
#             rule key, bind option, event and animation it names, in the
#             Hyprland Golem runs and in the latest: what the first has and
#             the second has not.
#
# Run it before moving either pin (flake.lock's nixpkgs, Hyprland's version):
# it says what would break. It downloads the two sources (≈50 MB) and builds
# nothing. Exit status 1 when something Golem uses is gone or renamed.
#
#   tools/latest/check.sh            # from the repo root; needs nix, python3
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
nixcmd=(nix --extra-experimental-features 'nix-command flakes')
flake="git+file://$PWD"
here=tools/latest
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
rc=0

fetch() { "${nixcmd[@]}" flake prefetch --json "$1" | python3 -c 'import json, sys; print(json.load(sys.stdin)["storePath"])'; }
build() { "${nixcmd[@]}" build --no-link --print-out-paths --impure --expr "(builtins.getFlake \"$flake\").$1"; }

# ── NixOS ───────────────────────────────────────────────────────────────────
unstable=$(fetch github:NixOS/nixpkgs/nixos-unstable)
"${nixcmd[@]}" eval --impure --json --expr \
  "import $PWD/$here/nixos-options.nix { flake = \"$flake\"; unstable = $unstable; }" > "$work/nixos.json"
python3 - "$work/nixos.json" <<'PY' || rc=1
import json, sys
d = json.load(open(sys.argv[1]))
print(f"NixOS: pinned {d['pinned']}, latest {d['latest']}")
print(f"  options Golem's files define: {d['definedTotal']} ({len(d['golemOrHomeManager'])} are Golem's own or home-manager's)")
print(f"  NixOS's own, looked up in the latest: {d['checked']} — the same there: {d['same']}")
for r in d["different"]:
    print("  ✗", json.dumps(r, ensure_ascii=False))
for n in d["notAnOption"]:
    print("  ? defined, and no option of the pinned NixOS:", n)
lost = [p["name"] for p in d["packagesNamed"] if p["pinned"] and not p["latest"]]
print(f"  packages named outright: {len(d['packagesNamed'])}, gone in the latest: {lost or 'none'}")
if d["zoomPortalArg"]["pinned"] and not d["zoomPortalArg"]["latest"]:
    print("  ✗ zoom-us no longer takes hyprlandXdgDesktopPortalSupport"); lost.append("zoom-us arg")
print(f"  the catalog's programs: {d['catalogAttrs']}; not an attribute of the pinned nixpkgs: {d['catalogMissingPinned'] or 'none'}; of the latest: {d['catalogMissingLatest'] or 'none'}")
sys.exit(1 if d["different"] or lost else 0)
PY

# ── Hyprland ────────────────────────────────────────────────────────────────
running=$(build 'nixosConfigurations.golem-desktop-vm.pkgs.hyprland.src')
latest=$(fetch github:hyprwm/Hyprland)
lua=$(build 'nixosConfigurations.golem-desktop-vm.pkgs.lua5_4')/bin/lua
# The configuration as a machine loads it, with every app module's own Lua
# on, run against the recording mock: everything it does, written down.
tree="$work/tree"; mkdir -p "$tree" "$work/state" "$work/config" "$work/home"
cp -r system/home/hypr/hyprland.lua system/home/hypr/golem "$tree/"; chmod -R u+w "$tree"
mods=$(cd system/home/hypr/golem/modules && ls -- *.lua 2>/dev/null | sed 's/\.lua$//; s/.*/"&"/' | paste -sd, -)
printf 'local M = dofile("%s")\nM.modules = { %s }\nreturn M\n' \
  "$PWD/system/home/hypr/test/machine.sample.lua" "$mods" > "$tree/golem/machine.lua"
HOME="$work/home" XDG_STATE_HOME="$work/state" XDG_CONFIG_HOME="$work/config" \
  "$lua" system/home/hypr/test/mock.lua "$tree" handlers > "$work/calls.log"
python3 "$here/hyprland.py" "$running" "$latest" "$work/calls.log" system/home/hypr \
  system/Modular/desktop/hyprland-patches > "$work/hypr.json" || rc=1
python3 - "$work/hypr.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
print(f"Hyprland: running {d['running']}, latest {d['latest']}")
r = d["options registered"]
added = r["by Golem's patches"]
print(f"  options: {r['running']} registered in the running one, {r['latest']} in the latest; Golem's patches add {len(added)}")
print(f"  options Golem sets: {d['options Golem sets']} — gone in the latest: {d['options gone in the latest'] or 'none'}")
for t in d["options whose type changed"]:
    print(f"  ~ {t['option']}: {t['running']} → {t['latest']} (read how the latest parses the value Golem gives)")
for n in d["set but registered nowhere (look by hand)"]:
    print("  ? set, and registered nowhere:", n)
for kind, v in d["names"].items():
    extra = ""
    if v["gone in the latest"]: extra += f" — GONE: {v['gone in the latest']}"
    blind = v["not found in the running source either (look by hand)"]
    if blind: extra += f" — not found in either: {blind}"
    print(f"  {kind}: {v['used']}{extra or ' — all in the latest'}")
PY
exit $rc
