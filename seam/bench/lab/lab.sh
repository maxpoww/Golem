#!/bin/sh
# lab.sh — measure a Seam VARIANT on a real machine, on its real screen (2026-10-04).
# Unlike bench.sh (headless, on the dev box) this runs ON the target laptop: a copy of the
# INSTALLED Seam with the variant's chrome script / policies / user.js swapped in, its own
# profile, launched through the compositor. probe.js (appended to mozilla.cfg, never
# shipped) reports startup times, requests by host, loaded modules, per-process memory and
# CPU, and the load time of each URL; this script adds PSS and CPU from /proc.
#
#   on the laptop:  ~/.cache/seam-lab/{lab.sh,probe.js,in/<variant>/...}
#   lab.sh <variant> [fresh|keep]     env: URLS="…" MS=40000 CLEAN_SESSION=1
#   in/<variant>/: golem-chrome.js (optional), policies.json (optional), user.js,
#                  userChrome.css, userContent.css
#
# TRAPS (each cost a round): a variant still showing the Terms-of-Use modal renders its
# pages BEHIND it and looks ~20% cheaper; uBlock builds its fast-start snapshot only by
# the third launch (before that its process is +100 MB, +10 s CPU); a profile that never
# visited the test sites has a cold HTTP cache (+25% CPU); "keep" restores the previous
# run's tabs unless CLEAN_SESSION=1. Compare like with like, three runs each.
# variant dir in/<v>/: golem-chrome.js (optional), policies.json (optional), user.js, userChrome.css, userContent.css
LAB=$HOME/.cache/seam-lab; V=$1; MODE=${2:-fresh}; MS=${MS:-40000}
export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1
export HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/1000/hypr | head -1)
I=$(readlink -f "$(command -v seam)"); W=$(grep -o '/nix/store/[^"]*bin/firefox' "$I" | head -1); L=$(dirname "$W")/../lib/firefox-bin-157.0
F=$LAB/farm-$V; IN=$LAB/in/$V; P=$LAB/prof-$V; O=$LAB/out-$V-$MODE.json
chmod -R u+w "$F" 2>/dev/null; rm -rf "$F"; mkdir -p "$F"; cp -rs "$L/." "$F/"; chmod -R u+w "$F"
rm -f "$F/firefox" "$F/firefox-bin" "$F/mozilla.cfg" "$F/distribution/policies.json"
cp -L "$L/firefox" "$L/firefox-bin" "$F/"
first=$(grep -n -m1 'GOLEM chrome script' "$L/mozilla.cfg" | cut -d: -f1)
head -n $((first-2)) "$L/mozilla.cfg" > "$F/mozilla.cfg"
[ -f "$IN/golem-chrome.js" ] && cat "$IN/golem-chrome.js" >> "$F/mozilla.cfg"
cat "$LAB/probe.js" >> "$F/mozilla.cfg"
[ -f "$IN/policies.json" ] && cp "$IN/policies.json" "$F/distribution/policies.json"
sed "s|^exec -a .*|exec \"$F/firefox\" \"\$@\"|" "$W" > "$F/launch"; chmod +x "$F/launch"
if [ "$MODE" = fresh ]; then rm -rf "$P"; mkdir -p "$P/chrome"; fi
cp "$IN/user.js" "$P/user.js" 2>/dev/null; cp "$IN"/userChrome.css "$IN"/userContent.css "$P/chrome/" 2>/dev/null
[ -n "$CLEAN_SESSION" ] && rm -rf "$P"/sessionstore* "$P"/sessionCheckpoints.json
rm -f "$O"
cat > "$F/run.sh" <<EOS
#!/bin/sh
export SEAM_PROBE="$O" SEAM_PROBE_MS=$MS SEAM_PROBE_URLS="$URLS" SEAM_PROBE_PREFS="$PREFS" MOZ_LEGACY_PROFILES=1
exec "$F/launch" --name seamlab --no-remote -profile "$P" > "$LAB/log-$V.txt" 2>&1
EOS
chmod +x "$F/run.sh"
sync; echo 3 2>/dev/null | sudo -n tee /proc/sys/vm/drop_caches >/dev/null 2>&1
hyprctl dispatch "hl.exec_cmd(\"$F/run.sh\")" >/dev/null 2>&1
n=0; while [ ! -f "$O" ] && [ $n -lt 400 ]; do sleep 1; n=$((n+1)); done
[ -f "$O" ] || { echo "NO RESULT"; tail -5 "$LAB/log-$V.txt"; }
# outside view: PSS + cpu ticks of the whole tree
tot=0; cpu=0; np=0
for p in $(pgrep -f "$F/"); do pss=$(awk '/^Pss:/{print $2}' /proc/$p/smaps_rollup 2>/dev/null); [ -n "$pss" ] || continue
  set -- $(cut -d')' -f2 /proc/$p/stat); cpu=$((cpu+${12}+${13})); tot=$((tot+pss)); np=$((np+1)); echo "  $(cat /proc/$p/comm): $((pss/1024))MB"; done > "$LAB/procs-$V-$MODE.txt"
c1=0; for p in $(pgrep -f "$F/"); do set -- $(cut -d')' -f2 /proc/$p/stat 2>/dev/null); c1=$((c1+${12:-0}+${13:-0})); done; sleep 10
c2=0; for p in $(pgrep -f "$F/"); do set -- $(cut -d')' -f2 /proc/$p/stat 2>/dev/null); c2=$((c2+${12:-0}+${13:-0})); done
echo "PSS_MB=$((tot/1024)) PROCS=$np CPU_S=$((cpu/100)) IDLE_CPU_PCT=$(( (c2-c1)/10 ))"
grim "$LAB/shot-$V-$MODE.png" 2>/dev/null
PP=$(pgrep -o -f "$F/firefox"); for t in /proc/$PP/task/*; do set -- $(cut -d')' -f2 $t/stat 2>/dev/null); echo "$(( ${12:-0}+${13:-0} )) $(cat $t/comm 2>/dev/null)"; done | awk '{n=$1; $1=""; gsub(/[0-9#]+$/,"",$0); a[$0]+=n} END{for(k in a) if(a[k]>20) printf "%6.1fs %s\n", a[k]/100, k}' | sort -rn | head -12 > "$LAB/threads-$V-$MODE.txt"
pkill -TERM -f "$F/firefox" ; n=0; while pgrep -f "$F/" >/dev/null && [ $n -lt 20 ]; do sleep 1; n=$((n+1)); done; pkill -KILL -f "$F/" 2>/dev/null
echo "PROFILE_MB=$(du -sm "$P" | cut -f1)"
[ -f "$O" ] && jq -c '{t,nreq,kb,esm,startup:(.startup|{main,firstPaint,sessionRestored}),nhosts:(.hosts|length),loads:[.loads[]|{u:(.url|.[8:28]),ms,why}],wins:[.wins[]|{type,tabs:(.tabs|length?),dialog,sidebarBtn}],notes}' "$O"
