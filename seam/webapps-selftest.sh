#!/usr/bin/env bash
# webapps-selftest.sh: the WEBAPPS module's own test, headless, against a real Seam build
# (the same farm as selftest.sh: a throwaway copy of the build with OUR mozilla.cfg).
#
#   ./webapps-selftest.sh        cold start through the flag, relaunch, a link into a
#                                webapp, a second webapp, a plain launch, the kill switch,
#                                a permission prompt, restart + restore, no tab ever lost
#
# Env: SEAM_BUILD (default: newest /nix/store/*-seam-<pinned version>), SEAM_DIR.
# Exit 0 = every check passed.
set -euo pipefail
here=${SEAM_DIR:-$(cd "$(dirname "$0")" && pwd)}
ver=$(grep -oE '"version": *"[^"]+"' "$here/sources.json" | grep -oE '[0-9][0-9.]*[0-9]')
BUILD=${SEAM_BUILD:-}
if [ -z "$BUILD" ]; then
  for d in $(ls -dt /nix/store/*-seam-"$ver" 2>/dev/null); do
    [ -f "$d/lib/firefox-bin-$ver/mozilla.cfg" ] && { BUILD=$d; break; }
  done
fi
[ -n "$BUILD" ] || { echo "no Seam $ver build in /nix/store (rebuild first, or set SEAM_BUILD)"; exit 2; }
L="$BUILD/lib/firefox-bin-$ver"
T=$(mktemp -d); trap 'chmod -R u+w "$T" 2>/dev/null; rm -rf "$T"' EXIT
cp -rs "$L/." "$T/"
rm -f "$T/firefox" "$T/firefox-bin" "$T/mozilla.cfg"
cp -L "$L/firefox" "$L/firefox-bin" "$T/"; chmod +x "$T/firefox" "$T/firefox-bin"
first=$(grep -n -m1 'GOLEM chrome script' "$L/mozilla.cfg" | cut -d: -f1)
head -n $((first-2)) "$L/mozilla.cfg" > "$T/mozilla.cfg"; cat "$here/golem-chrome.js" >> "$T/mozilla.cfg"
LDP=$(strings "$BUILD/bin/firefox" | grep -oE "^LD_LIBRARY_PATH='[^']+'" | sed -E "s/^LD_LIBRARY_PATH='(.*)'/\1/" | sort -u | tr '\n' ':')
echo "Seam $ver  build=$BUILD"
FARM="$T" LDP="$LDP" CHROMEDIR="$here" timeout 600 python3 "$here/webapps-selftest.py"
