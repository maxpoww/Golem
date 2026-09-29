#!/usr/bin/env bash
# selftest.sh — run Seam's chrome-script self-test HEADLESS against a real Seam build.
# No display, no user profile touched (throwaway profile), nothing sent anywhere.
#
#   ./selftest.sh                  healthy path + every fault injection (the matrix)
#   ./selftest.sh --one [BREAK]    one run; BREAK = throw-open | nav-bar | agent-sheet | ...
#
# Env overrides:
#   SEAM_BUILD   Seam store path   (default: newest /nix/store/*-seam-<pinned version>)
#   SEAM_SCRIPT  golem-chrome.js   (default: /etc/nixos/golem-chrome.js; in the Fedora
#                                   toolbox that's /run/host/etc/nixos/golem-chrome.js)
#
# Exit 0 = every case passed. The test hook is SEAM_SELFTEST in golem-chrome.js
# (ovSelfTest): health check, then the real open -> close -> switch path, asserting
# the browser is left sane; faults must degrade to plain working Firefox.
set -euo pipefail
here=${SEAM_DIR:-$(cd "$(dirname "$0")" && pwd)}
ver=$(grep -oE '"version": *"[^"]+"' "$here/sources.json" | grep -oE '[0-9][0-9.]*[0-9]')

BUILD=${SEAM_BUILD:-}
if [ -z "$BUILD" ]; then
  # (a Beam-era *-firefox-<ver> build has the identical library dir; only mozilla.cfg differs and the farm replaces it)
  for d in $(ls -dt /nix/store/*-seam-"$ver" /nix/store/*-firefox-"$ver" 2>/dev/null); do
    [ -f "$d/lib/firefox-bin-$ver/mozilla.cfg" ] && { BUILD=$d; break; }
  done
fi
[ -n "$BUILD" ] || { echo "no Seam $ver build in /nix/store (rebuild first, or set SEAM_BUILD)"; exit 2; }
SCRIPT=${SEAM_SCRIPT:-$here/golem-chrome.js}

L="$BUILD/lib/firefox-bin-$ver"

# throwaway copy of the build with OUR mozilla.cfg (the binary must be a real file:
# Firefox resolves its libs/autoconfig relative to its true location)
T=$(mktemp -d); trap 'chmod -R u+w "$T" 2>/dev/null; rm -rf "$T"' EXIT   # cp -rs inherits the store's read-only dirs
cp -rs "$L/." "$T/"
rm -f "$T/firefox" "$T/firefox-bin" "$T/mozilla.cfg"
cp -L "$L/firefox" "$L/firefox-bin" "$T/"; chmod +x "$T/firefox" "$T/firefox-bin"
first=$(grep -n -m1 'GOLEM chrome script' "$L/mozilla.cfg" | cut -d: -f1)
head -n $((first-2)) "$L/mozilla.cfg" > "$T/mozilla.cfg"; cat "$SCRIPT" >> "$T/mozilla.cfg"
LDP=$(strings "$BUILD/bin/firefox" | grep -oE "^LD_LIBRARY_PATH='[^']+'" | sed -E "s/^LD_LIBRARY_PATH='(.*)'/\1/" | sort -u | tr '\n' ':')

run(){ # run <break> -> prints result json
  local out prof; out=$(mktemp); prof=$(mktemp -d); rm -f "$out"
  # fidelity: the real userChrome/userContent (if readable) — they change what the bar paints
  CH=${SEAM_SELFTEST_CHROME:-$HOME/.local/share/seam/chrome}
  if [ -r "$CH/userChrome.css" ]; then
    mkdir -p "$prof/chrome"; cp "$CH"/userChrome.css "$CH"/userContent.css "$prof/chrome/" 2>/dev/null || true
    echo 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' > "$prof/user.js"
  fi
  # uBO's first-run default flips network.prefetch-next off before its managed setting lands;
  # production (home.nix) pins it on — mirror that here so the hover-prefetch test sees it
  echo 'user_pref("network.prefetch-next", true);' >> "$prof/user.js"
  HOME="$prof" XDG_CACHE_HOME="$prof/.cache" XDG_CONFIG_HOME="$prof/.config" \
  LD_LIBRARY_PATH="$LDP" MOZ_HEADLESS=1 MOZ_CRASHREPORTER_DISABLE=1 MOZ_LEGACY_PROFILES=1 \
  SEAM_SELFTEST="$out" SEAM_SELFTEST_BREAK="$1" SEAM_SELFTEST_HTTP="${SEAM_SELFTEST_HTTP:-}" \
    timeout 90 "$T/firefox" --headless --no-remote -profile "$prof" about:blank >/dev/null 2>&1 || true
  if [ -f "$out" ]; then cat "$out"; else echo '{"ok":false,"steps":["NO-RESULT (crash/timeout)"]}'; fi
  rm -rf "$out" "$prof"
}

# local http pages for the capture-race test (the overview only snapshots http tabs)
if command -v python3 >/dev/null; then
  W=$(mktemp -d); port=$(( 38000 + $$ % 1000 )); for k in 0 1 2 3; do
    printf '<html><body style="margin:0;background:rgb(%d,90,140)"><h1>page %d</h1></body></html>' $((40*k+30)) "$k" > "$W/p$k.html"; done
  printf '<html><body style="margin:0"><a id=same href="/p1.html" style="display:block;width:200px;height:40px">same</a><a id=query href="/p2.html?x=1" style="display:block;width:200px;height:40px">query</a><a id=cross href="http://localhost:%s/p3.html" style="display:block;width:200px;height:40px">cross</a><a id=nostore href="/nostore-p1.html" style="display:block;width:200px;height:40px">nostore</a><a id=again href="/p0.html" style="display:block;width:200px;height:40px">again</a></body></html>' "$port" > "$W/pf.html"
  cp "$W/p1.html" "$W/nostore-p1.html"
  # a page whose name says nostore answers Cache-Control: no-store (the hover-prefetch learning test)
  python3 - "$port" "$W" >/dev/null 2>&1 <<'PYS' & HTTPD=$!
import sys,functools,http.server
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
    def end_headers(self):
        if "nostore" in self.path: self.send_header("Cache-Control","no-store")
        super().end_headers()
http.server.ThreadingHTTPServer(("127.0.0.1",int(sys.argv[1])),functools.partial(H,directory=sys.argv[2])).serve_forever()
PYS
  trap 'kill $HTTPD 2>/dev/null; rm -rf "$W"; chmod -R u+w "$T" 2>/dev/null; rm -rf "$T"' EXIT
  export SEAM_SELFTEST_HTTP="http://127.0.0.1:$port"
  sleep 0.5
fi

# the per-machine display-rate test wants the running compositor's hyprctl (from a toolbox the
# host's is under /run/host); Seam itself finds it on PATH on a Golem machine
for h in "${GOLEM_HYPRCTL:-}" "$(command -v hyprctl 2>/dev/null || true)" /run/current-system/sw/bin/hyprctl /run/host/run/current-system/sw/bin/hyprctl; do
  [ -n "$h" ] && [ -x "$h" ] && { export GOLEM_HYPRCTL="$h"; break; }; done
echo "Seam $ver  build=$BUILD  hyprctl=${GOLEM_HYPRCTL:-none}"
echo "script=$SCRIPT"
if [ "${1:-}" = "--one" ]; then run "${2:-}"; echo; exit 0; fi
if [ "${1:-}" = "--host" ]; then
  # The CPU-share test needs a cgroup of Seam's own: run the same farm on the HOST, through the
  # compositor, inside a systemd user scope (what the dock does), pinned to one core so the
  # foreground/background contention is real. Paths under $HOME: shared with a toolbox.
  HB="$HOME/.cache/seam-selftest"; rm -rf "$HB"; mkdir -p "$HB/farm" "$HB/prof"; cp -rs "$T/." "$HB/farm/"; chmod -R u+w "$HB/farm"
  rm -f "$HB/farm/firefox" "$HB/farm/firefox-bin" "$HB/farm/mozilla.cfg"; cp -L "$T/firefox" "$T/firefox-bin" "$HB/farm/"; cp "$T/mozilla.cfg" "$HB/farm/"
  CH=${SEAM_SELFTEST_CHROME:-$HOME/.local/share/seam/chrome}; [ -r "$CH/userChrome.css" ] && { mkdir -p "$HB/prof/chrome"; cp "$CH"/userChrome.css "$CH"/userContent.css "$HB/prof/chrome/" 2>/dev/null || true; echo 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' > "$HB/prof/user.js"; }
  cat > "$HB/run.sh" <<EOS
#!/bin/bash
exec systemd-run --user --scope --quiet --collect --slice=app-graphical.slice -p CPUWeight=100 -p Delegate=yes --unit=seam-selftest-\$\$ -- \
  taskset -c 0 env HOME="$HB/prof" XDG_CACHE_HOME="$HB/prof/.cache" XDG_CONFIG_HOME="$HB/prof/.config" LD_LIBRARY_PATH="$LDP" \
  MOZ_HEADLESS=1 MOZ_LEGACY_PROFILES=1 GOLEM_HYPRCTL=/run/current-system/sw/bin/hyprctl \
  SEAM_SELFTEST="$HB/out.json" SEAM_SELFTEST_HOST=1 SEAM_SELFTEST_BREAK="" SEAM_SELFTEST_HTTP="${SEAM_SELFTEST_HTTP:-}" \
  timeout 240 "$HB/farm/firefox" --headless --no-remote -profile "$HB/prof" about:blank > "$HB/run.log" 2>&1
EOS
  chmod +x "$HB/run.sh"
  HC=${GOLEM_HYPRCTL:-hyprctl}; "$HC" dispatch "hl.exec_cmd(\"$HB/run.sh\")" >/dev/null 2>&1 || true
  for i in $(seq 260); do [ -f "$HB/out.json" ] && break; sleep 1; done
  if [ -f "$HB/out.json" ]; then cat "$HB/out.json"; echo; else echo '{"ok":false,"steps":["NO-RESULT (host run: see ~/.cache/seam-selftest/run.log)"]}'; tail -5 "$HB/run.log" 2>/dev/null; fi
  exit 0
fi

fail=0
for c in "" throw-open nav-bar tabbrowser-tabpanels golem-overview-btn agent-sheet sidebar-main; do
  res=$(run "$c")
  ok=$(echo "$res" | grep -oE '"ok":(true|false)' | head -1)
  printf '  %-22s %s  %s\n' "${c:-HEALTHY}" "${ok#\"ok\":}" "$(echo "$res" | grep -oE '"steps":\[[^]]*\]')"
  [ "$ok" = '"ok":true' ] || fail=1
done
[ $fail = 0 ] && echo "ALL PASS" || echo "FAILURES"
exit $fail
