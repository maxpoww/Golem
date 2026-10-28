#!/usr/bin/env bash
# webapps-selftest.sh: the WEBAPPS module's own test, headless, against a real Seam build
# (the same farm as selftest.sh: a throwaway copy of the build with OUR mozilla.cfg).
#
#   ./webapps-selftest.sh        cold start through the flag, relaunch, a link into a
#                                webapp, a second webapp, a plain launch, the kill switch,
#                                a permission prompt, restart + restore, no tab ever lost
#   ./webapps-selftest.sh rows   one site in a Seam tab and as a webapp: each window its own
#                                colour row (the web's switch + the drop / the apps')
#   ./webapps-selftest.sh recents the recents' kitchen: covers from before (YouTube Music
#                                songs of the history get their picture; goes on the network)
#
# Env: SEAM_BUILD (default: newest /nix/store/*-seam-<pinned version>), SEAM_DIR.
# Exit 0 = every check passed.
set -euo pipefail
here=${SEAM_DIR:-$(cd "$(dirname "$0")" && pwd)}
ver=$(grep -oE '"version": *"[^"]+"' "$here/sources.json" | grep -oE '[0-9][0-9.]*[0-9]')
BUILD=${SEAM_BUILD:-}
if [ -z "$BUILD" ]; then
  for d in $(ls -dt /nix/store/*-seam-"$ver" 2>/dev/null); do
    # the WRAPPED build (it has bin/firefox, whose wrapper names the libraries): the final
    # Seam package is a join that carries only bin/seam, and picking it left this test
    # unable to run after every update since the rename (2026-09-27 .. 2026-10-06)
    [ -f "$d/lib/firefox-bin-$ver/mozilla.cfg" ] && [ -x "$d/bin/firefox" ] && { BUILD=$d; break; }
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
# (Seam 158: the DisableDeveloperTools policy keeps Marionette off too; the throwaway farm
# drops that one policy so the test can drive it. The installed Seam keeps it.)
chmod u+w "$T/distribution"; rm -f "$T/distribution/policies.json"
python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); p["policies"].pop("DisableDeveloperTools",None); json.dump(p,open(sys.argv[2],"w"))' "$L/distribution/policies.json" "$T/distribution/policies.json"
LDP=$(strings "$BUILD/bin/firefox" | grep -oE "^LD_LIBRARY_PATH='[^']+'" | sed -E "s/^LD_LIBRARY_PATH='(.*)'/\1/" | sort -u | tr '\n' ':')
echo "Seam $ver  build=$BUILD"
# ./webapps-selftest.sh rows: the same farm for rows-selftest.py (each window its own colour row)
# (Seam 159: Marionette reaches the chrome only with this variable; the flag no longer does it)
FARM="$T" LDP="$LDP" CHROMEDIR="$here" MOZ_REMOTE_ALLOW_SYSTEM_ACCESS=1 timeout 600 python3 "$here/${1:-webapps}-selftest.py"
