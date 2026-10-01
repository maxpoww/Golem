#!/usr/bin/env bash
# refresh.sh — regenerate Golem's package index: every package the dock's
# Install section offers, and ONLY the ones that can actually install here.
#
# Why Golem carries its own (system/home/package-index.tsv):
#  - The dock's own index lists everything nixpkgs has (~23,700). On Golem's
#    pin, 617 of those can never install — macOS-only, end-of-life (old .NET,
#    Electron), insecure or broken — and the dock offered every one of them
#    (scan, 2026-10-01). Max: "it cant fail".
#  - Its build is a full nixpkgs evaluation, ~6.5 GB of memory, and every
#    laptop ran it on its own updates (the MacBook has 4 GB).
#
# Run on a machine with the memory (the dev box), whenever flake.lock's
# nixpkgs moves; commit the two files it writes. The desktop matrix refuses
# an index made for another nixpkgs revision.
#
#   tools/package-index/refresh.sh            # from the repo root
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
nixcmd=(nix --extra-experimental-features 'nix-command flakes')
flake="git+file://$PWD"
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT

rev=$(python3 -c 'import json; print(json.load(open("flake.lock"))["nodes"]["nixpkgs"]["locked"]["rev"])')
echo "nixpkgs $rev"

# 1. The dock's full index, built from the launcher pinned in flake.lock
#    (its nixpkgs follows Golem's).
idx=$("${nixcmd[@]}" build --no-link --print-out-paths --impure --expr \
  "(builtins.getFlake \"$flake\").inputs.waverunner.packages.x86_64-linux.package-index")
full="$idx/share/waverunner/nixpkgs-index.tsv"
head -1 "$full" > "$work/header"
tail -n +2 "$full" | cut -f1 > "$work/attrs"
echo "full index: $(wc -l < "$work/attrs") packages"

# 2. Evaluate every one, 3000 at a time (bounded memory). "name hash" for
#    each one that evaluates.
split -l 3000 -d "$work/attrs" "$work/chunk-"
: > "$work/okh"
for c in "$work"/chunk-*; do
  python3 -c 'import json,sys; print(json.dumps([l.strip() for l in open(sys.argv[1]) if l.strip()]))' "$c" > "$c.json"
  "${nixcmd[@]}" eval --json --impure --expr \
    "import $PWD/tools/package-index/check.nix { flake = \"$flake\"; names = builtins.fromJSON (builtins.readFile $c.json); }" 2>/dev/null \
    | python3 -c 'import json,sys; [print(k, v[3:].split("/")[3].split("-")[0]) for k,v in json.load(sys.stdin).items() if v.startswith("ok:")]' >> "$work/okh"
  echo "  $(basename "$c"): $(wc -l < "$work/okh") installable so far"
done
cut -d' ' -f1 "$work/okh" > "$work/ok"

# 3. Of those, the ones NOT in the binary cache install by building on the
#    machine. Fine for a repackaged download (unfree apps are never cached:
#    VS Code, Discord, Spotify, Steam, DaVinci…), not for:
#    - a manual download (nixpkgs' requireFile, whose builder is a script
#      named "restrict-message"): it can never install unattended;
#    - a big compile (more than MAX_BUILDS derivations to build): hours on a
#      laptop, and the 4 GB MacBook may never finish it.
MAX_BUILDS=${MAX_BUILDS:-20}
xargs -P 48 -n 2 sh -c 'c=$(curl -s -o /dev/null -w "%{http_code}" -I "https://cache.nixos.org/$1.narinfo"); [ "$c" = 200 ] || echo "$0"' < "$work/okh" > "$work/uncached"
echo "not in the binary cache: $(wc -l < "$work/uncached")"
dry() {
  o=$(nix --extra-experimental-features 'nix-command flakes' build --dry-run --impure \
        --expr "(builtins.getFlake \"$flake\").nixosConfigurations.golem-desktop-vm.pkgs.$1" 2>&1)
  n=$(printf '%s\n' "$o" | sed -n 's/.*these \([0-9]*\) derivations will be built.*/\1/p; s/.*this derivation will be built.*/1/p' | head -1)
  case "$o" in *restrict-message.drv*) echo "$1 manual-download" ;; esac
  if [ "${n:-0}" -gt "$MAX_BUILDS" ]; then echo "$1 builds-$n"; fi
}
export -f dry; export flake MAX_BUILDS
xargs -P 8 -n 1 bash -c 'dry "$0"' < "$work/uncached" | sort -u > tools/package-index/dropped.txt
echo "dropped (manual download / big compile): $(cut -d' ' -f1 tools/package-index/dropped.txt | sort -u | wc -l)"
awk 'NR==FNR { drop[$1]=1; next } !($1 in drop)' tools/package-index/dropped.txt "$work/ok" > "$work/ok2"
mv "$work/ok2" "$work/ok"

# 4. Keep the installable rows, in the index's own order and format.
out=system/home/package-index.tsv
{ cat "$work/header"; awk -F'\t' 'NR==FNR { ok[$1]=1; next } FNR>1 && ($1 in ok)' "$work/ok" "$full"; } > "$out.tmp"
mv "$out.tmp" "$out"
echo "$rev" > system/home/package-index.rev
echo "kept $(($(wc -l < "$out") - 1)) of $(wc -l < "$work/attrs"); wrote $out (+ .rev)"
