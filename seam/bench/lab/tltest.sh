#!/bin/sh
# tltest.sh — Seam's traffic lights on a real floating window: shown, placed, and each button does its job.
# On the laptop: copy this, tltest-probe.js and the golem-chrome.js under test to /tmp/seam-tl/ and run it.
# A COPY of the installed Seam (class seam, own profile); it only acts while that copy is the active window.
D=/tmp/seam-tl; export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1
export HYPRLAND_INSTANCE_SIGNATURE=$(ls -t /run/user/1000/hypr | head -1)
I=$(readlink -f "$(command -v seam)"); W=$(grep -o '/nix/store/[^"]*bin/firefox' "$I" | head -1); L=$(dirname "$W")/../lib/firefox-bin-157.0
chmod -R u+w $D/farm 2>/dev/null; rm -rf $D/farm $D/prof $D/out-* $D/go-*; mkdir -p $D/farm $D/prof/chrome; F=$D/farm
cp -rs "$L/." "$F/"; chmod -R u+w "$F"; rm -f "$F/firefox" "$F/firefox-bin" "$F/mozilla.cfg"; cp -L "$L/firefox" "$L/firefox-bin" "$F/"
first=$(grep -n -m1 'GOLEM chrome script' "$L/mozilla.cfg" | cut -d: -f1); head -n $((first-2)) "$L/mozilla.cfg" > "$F/mozilla.cfg"; cat $D/golem-chrome.js $D/tltest-probe.js >> "$F/mozilla.cfg"
sed "s|^exec -a .*|exec \"$F/firefox\" \"\$@\"|" "$W" > "$F/launch"; chmod +x "$F/launch"
cat ~/.local/share/seam/user.js > $D/prof/user.js; cp -L ~/.local/share/seam/chrome/*.css $D/prof/chrome/
printf '#!/bin/sh\nexport TL_DIR=%s MOZ_LEGACY_PROFILES=1 MOZ_CRASHREPORTER_DISABLE=1\nexec %s --name seam --no-remote -profile %s about:blank > %s 2>&1\n' $D "$F/launch" $D/prof $D/log.txt > $D/run.sh; chmod +x $D/run.sh
before=$(cat /tmp/golem-ff-float 2>/dev/null)
hyprctl dispatch "hl.exec_cmd(\"$D/run.sh\")" >/dev/null 2>&1
wait_for(){ n=0; while [ ! -f "$D/out-$1.json" ] && [ $n -lt ${2:-60} ]; do sleep 1; n=$((n+1)); done; [ -f "$D/out-$1.json" ] && { echo "$1: $(cat $D/out-$1.json)"; return 0; }; echo "$1: NO RESULT"; return 1; }
mine(){ P=$(pgrep -o -f "$F/firefox"); [ -n "$P" ] && [ "$(hyprctl activewindow -j | jq -r .pid)" = "$P" ]; }
quit(){ pkill -TERM -f "$F/firefox"; sleep 4; pkill -KILL -f "$F/" 2>/dev/null; chmod -R u+w $D; rm -rf $D/farm $D/prof; echo "float signal file: before=$before after=$(cat /tmp/golem-ff-float 2>/dev/null)"; exit ${1:-0}; }
wait_for A 60 || quit 1
P=$(pgrep -o -f "$F/firefox"); hyprctl clients -j | jq -c ".[]|select(.pid==$P)|{class,floating,workspace:.workspace.name,size}"
grim $D/shot-A.png; echo "-"
mine || { echo "ABORT: the test window is not the active one"; quit 1; }
touch $D/go-B; wait_for B 30 || quit 1
hyprctl clients -j | jq -c ".[]|select(.pid==$P)|{after_green:\"tile\",floating,size}"; echo "-"
mine || { echo "ABORT before re-float: not active"; quit 1; }
hyprctl dispatch 'hl.dsp.window.float({ action = "toggle" })' >/dev/null 2>&1; sleep 2.5
hyprctl clients -j | jq -c ".[]|select(.pid==$P)|{refloated:true,floating}"
mine || { echo "ABORT before minimize: not active"; quit 1; }
touch $D/go-C; wait_for C 30 || quit 1
A=$(hyprctl clients -j | jq -r ".[]|select(.pid==$P)|.address"); hyprctl clients -j | jq -c ".[]|select(.pid==$P)|{after_orange:\"min\",workspace:.workspace.name}"
hyprctl dispatch "hl.plugin.waveview.restore_min(\"$A\")" >/dev/null 2>&1; sleep 4
hyprctl clients -j | jq -c ".[]|select(.pid==$P)|{restored:true,workspace:.workspace.name,floating}"
touch $D/go-D; wait_for D 30
n=0; while pgrep -f "$F/firefox" >/dev/null && [ $n -lt 15 ]; do sleep 1; n=$((n+1)); done
pgrep -f "$F/firefox" >/dev/null && echo "after red: STILL RUNNING" || echo "after red: Seam exited (${n}s)"
quit 0
