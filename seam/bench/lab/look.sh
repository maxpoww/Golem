#!/bin/sh
# look.sh — a COPY of the installed Seam with the files in /tmp/seam-look swapped in; reports the top bar's geometry and takes a screenshot.
D=/tmp/seam-look; export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1
export HYPRLAND_INSTANCE_SIGNATURE=$(ls -t /run/user/1000/hypr | head -1)
I=$(readlink -f "$(command -v seam)"); W=$(grep -o '/nix/store/[^"]*bin/firefox' "$I" | head -1); L=$(dirname "$W")/../lib/firefox-bin-157.0
chmod -R u+w $D/farm 2>/dev/null; rm -rf $D/farm $D/prof $D/out.json; mkdir -p $D/farm $D/prof/chrome; F=$D/farm
cp -rs "$L/." "$F/"; chmod -R u+w "$F"; rm -f "$F/firefox" "$F/firefox-bin" "$F/mozilla.cfg"; cp -L "$L/firefox" "$L/firefox-bin" "$F/"
first=$(grep -n -m1 'GOLEM chrome script' "$L/mozilla.cfg" | cut -d: -f1); head -n $((first-2)) "$L/mozilla.cfg" > "$F/mozilla.cfg"
if [ -f $D/golem-chrome.js ]; then cat $D/golem-chrome.js >> "$F/mozilla.cfg"; else tail -n +$((first-1)) "$L/mozilla.cfg" >> "$F/mozilla.cfg"; fi; cat $D/look-probe.js >> "$F/mozilla.cfg"
sed "s|^exec -a .*|exec \"$F/firefox\" \"\$@\"|" "$W" > "$F/launch"; chmod +x "$F/launch"
cat ~/.local/share/seam/user.js > $D/prof/user.js; cp -L ~/.local/share/seam/chrome/*.css $D/prof/chrome/; chmod u+w $D/prof/chrome/*.css; [ -f $D/userChrome.css ] && cp -f $D/userChrome.css $D/prof/chrome/userChrome.css
printf '#!/bin/sh\nexport TL_DIR=%s MOZ_LEGACY_PROFILES=1 MOZ_CRASHREPORTER_DISABLE=1\nexec %s --name seam --no-remote -profile %s %s > %s 2>&1\n' $D "$F/launch" $D/prof "${URL:-about:blank}" $D/log.txt > $D/run.sh; chmod +x $D/run.sh
hyprctl dispatch "hl.exec_cmd(\"$D/run.sh\")" >/dev/null 2>&1
n=0; while [ ! -f $D/out.json ] && [ $n -lt 50 ]; do sleep 1; n=$((n+1)); done; cat $D/out.json 2>/dev/null || echo "NO RESULT"; echo
P=$(pgrep -o -f "$F/firefox"); hyprctl clients -j | jq -c ".[]|select(.pid==$P)|{at,size,floating}"
sleep 1; grim $D/shot.png
pkill -TERM -f "$F/firefox"; n=0; while pgrep -f "$F/firefox" >/dev/null && [ $n -lt 12 ]; do sleep 1; n=$((n+1)); done; pkill -KILL -f "$F/" 2>/dev/null; chmod -R u+w $D/farm; rm -rf $D/farm $D/prof
