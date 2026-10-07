#!/bin/sh
# yt.sh <variant> — run AS ROOT on the laptop: a copy of the installed Seam plays a video (YT_URL) and profiles a 20 s window; which codec, how much CPU.
# env: YT_URL, YT_THREADS, YT_INTERVAL, YT_WARM (ms from page load to the window, default 20000), YT_PIN (YouTube quality pinned once playing: hd720 default, 0 = YouTube's own choice), YT_LINGER (s alive after the window); files: $V.user.js, $V.policies.json, $V.chrome.js
D=/tmp/seam-sb; V=$1; O=$D/yt-$V; mkdir -p $D; URL=${YT_URL:-https://www.youtube.com/watch?v=aqz-KE-bpKQ}
PATH=/etc/profiles/per-user/max/bin:/run/current-system/sw/bin:$PATH
E="env XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 HYPRLAND_INSTANCE_SIGNATURE=$(ls -t /run/user/1000/hypr | head -1)"
U="runuser -u max -- $E"; hc(){ $U hyprctl "$@"; }
I=$(readlink -f /etc/profiles/per-user/max/bin/seam); W=$(grep -o '/nix/store/[^"]*bin/firefox' "$I" | head -1); L=$(ls -d $(dirname "$W")/../lib/firefox-bin-*)
F=$D/farm; chmod -R u+w $F 2>/dev/null; rm -rf $F $O; mkdir -p $F $O; P=$D/prof-yt-$V; mkdir -p $P/chrome
cp -rs "$L/." "$F/"; chmod -R u+w "$F"; rm -f "$F/firefox" "$F/firefox-bin" "$F/mozilla.cfg"; cp -L "$L/firefox" "$L/firefox-bin" "$F/"
[ -f $D/$V.policies.json ] && { rm -f "$F/distribution/policies.json"; cp "$D/$V.policies.json" "$F/distribution/policies.json"; }   # per-variant enterprise policies (managed storage for uBO etc.)
first=$(grep -n -m1 'GOLEM chrome script' "$L/mozilla.cfg" | cut -d: -f1); head -n $((first-2)) "$L/mozilla.cfg" > "$F/mozilla.cfg"
if [ -f $D/$V.chrome.js ]; then cat $D/$V.chrome.js >> "$F/mozilla.cfg"; else tail -n +$((first-1)) "$L/mozilla.cfg" >> "$F/mozilla.cfg"; fi; cat $D/ytprobe.js >> "$F/mozilla.cfg"
sed "s|^exec -a .*|exec \"$F/firefox\" \"\$@\"|" "$W" > "$F/launch"; chmod +x "$F/launch"
[ -d $P ] || { [ -d /home/max/.cache/seam-lab/prof-base ] && cp -a /home/max/.cache/seam-lab/prof-base $P; }   # start from the AGED lab profile (uBlock has its start-up cache; else its list compile lands in the measurement)
rm -rf $P/sessionstore* $P/sessionCheckpoints.json   # a restored session would open Seam on its tab overview (content hidden): one blank tab, every run
cat /home/max/.local/share/seam/user.js > $P/user.js; printf 'user_pref("media.autoplay.default", 0);\nuser_pref("media.autoplay.blocking_policy", 0);\n' >> $P/user.js; [ -f $D/$V.user.js ] && cat $D/$V.user.js >> $P/user.js
cp -L /home/max/.local/share/seam/chrome/*.css $P/chrome/ 2>/dev/null; chown -R max:users $D
printf '#!/bin/sh\nexport YT_THREADS=%s YT_INTERVAL=%s YT_DIR=%s YT_URL=%s YT_WARM=%s YT_PIN=%s MOZ_LEGACY_PROFILES=1 MOZ_CRASHREPORTER_DISABLE=1\nexec %s --name seam --no-remote -profile %s about:blank > %s 2>&1\n' "'${YT_THREADS:-}'" "'${YT_INTERVAL:-2}'" $O "$URL" "${YT_WARM:-20000}" "${YT_PIN:-hd720}" "$F/launch" $P $O/log.txt > $D/run.sh; chmod +x $D/run.sh
hc dispatch "hl.exec_cmd(\"$D/run.sh\")" >/dev/null 2>&1
n=0; while [ ! -f $O/result.json ] && [ $n -lt 120 ]; do sleep 1; n=$((n+1)); done
[ -f $O/result.json ] && cat $O/result.json || { echo "NO RESULT"; tail -3 $O/log.txt; }; echo
cp $P/golem-media.json $O/ 2>/dev/null; sleep ${YT_LINGER:-6}   # YT_LINGER: keep Seam alive after the window (lets uBO finish an update batch)
pkill -TERM -f "$F/firefox"; n=0; while pgrep -f "$F/firefox" >/dev/null && [ $n -lt 12 ]; do sleep 1; n=$((n+1)); done; pkill -KILL -f "$F/" 2>/dev/null; chmod -R u+w $F; rm -rf $F
