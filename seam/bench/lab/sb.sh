#!/bin/sh
# sb.sh <variant> [wheel clicks/s] [seconds]   — run AS ROOT on the laptop.
# A COPY of the installed Seam with /tmp/seam-sb/<variant>.user.js appended to the installed user.js
# (and /tmp/seam-sb/<variant>.chrome.js in place of the installed chrome script if present) opens the
# bench page; a REAL wheel (uinput) scrolls it; the probe writes ready/result + a profile (Renderer,
# Compositor, GeckoMain) for /tmp/seam-sb/out-<variant>/.
D=/tmp/seam-sb; V=$1; RATE=${2:-25}; SECS=${3:-8}; O=$D/out-$V; URL=${SB_URL:-http://192.168.1.152:38555/scroll/index.html}
PATH=/etc/profiles/per-user/max/bin:/run/current-system/sw/bin:$PATH
Y=/nix/store/xmdkfvizgrykg67i158xxidlzyza8n87-ydotool-1.0.4/bin
E="env XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 HYPRLAND_INSTANCE_SIGNATURE=$(ls -t /run/user/1000/hypr | head -1)"
U="runuser -u max -- $E"; hc(){ $U hyprctl "$@"; }
I=$(readlink -f /etc/profiles/per-user/max/bin/seam); W=$(grep -o '/nix/store/[^"]*bin/firefox' "$I" | head -1); L=$(ls -d $(dirname "$W")/../lib/firefox-bin-*)
F=$D/farm; chmod -R u+w $F 2>/dev/null; rm -rf $F $O; mkdir -p $F $O; P=$D/prof-$V; mkdir -p $P/chrome
cp -rs "$L/." "$F/"; chmod -R u+w "$F"; rm -f "$F/firefox" "$F/firefox-bin" "$F/mozilla.cfg"; cp -L "$L/firefox" "$L/firefox-bin" "$F/"
first=$(grep -n -m1 'GOLEM chrome script' "$L/mozilla.cfg" | cut -d: -f1); head -n $((first-2)) "$L/mozilla.cfg" > "$F/mozilla.cfg"
if [ -f $D/$V.chrome.js ]; then cat $D/$V.chrome.js >> "$F/mozilla.cfg"; else tail -n +$((first-1)) "$L/mozilla.cfg" >> "$F/mozilla.cfg"; fi; cat $D/sbprobe.js >> "$F/mozilla.cfg"
[ -f $D/$V.policies.json ] && { rm -f "$F/distribution/policies.json"; cp $D/$V.policies.json "$F/distribution/policies.json"; }
sed "s|^exec -a .*|exec \"$F/firefox\" \"\$@\"|" "$W" > "$F/launch"; chmod +x "$F/launch"
[ -d $P ] || { [ -d /home/max/.cache/seam-lab/prof-base ] && cp -a /home/max/.cache/seam-lab/prof-base $P; }   # start from the AGED lab profile (uBlock has its start-up cache; else its list compile lands in the measurement)
rm -rf $P/sessionstore* $P/sessionCheckpoints.json   # a restored session would open Seam on its tab overview (content hidden): one blank tab, every run
cat /home/max/.local/share/seam/user.js > $P/user.js; [ -f $D/$V.user.js ] && cat $D/$V.user.js >> $P/user.js
cp -L /home/max/.local/share/seam/chrome/*.css $P/chrome/ 2>/dev/null; chown -R max:users $D
printf '#!/bin/sh\nexport SB_DIR=%s SB_URL=%s MOZ_LEGACY_PROFILES=1 MOZ_CRASHREPORTER_DISABLE=1\nexec %s --name seam --no-remote -profile %s about:blank > %s 2>&1\n' $O "$URL" "$F/launch" $P $O/log.txt > $D/run.sh; chmod +x $D/run.sh
export YDOTOOL_SOCKET=/tmp/.ydotool_socket; pgrep -x ydotoold >/dev/null || { $Y/ydotoold --socket-path=$YDOTOOL_SOCKET >/dev/null 2>&1 & sleep 2; }
HP=$(pgrep -x Hyprland | head -1); hcpu(){ set -- $(cut -d')' -f2 /proc/$HP/stat); echo $(( ${12} + ${13} )); }
hc dispatch "hl.exec_cmd(\"$D/run.sh\")" >/dev/null 2>&1
n=0; while [ ! -f $O/ready.json ] && [ $n -lt 90 ]; do sleep 1; n=$((n+1)); done; [ -f $O/ready.json ] || { echo "NO READY"; cat $O/log.txt | tail -3; pkill -f "$F/firefox"; exit 1; }
PID=$(pgrep -o -f "$F/firefox"); set -- $(hc clients -j | jq -r ".[]|select(.pid==$PID)|\"\(.at[0]) \(.at[1]) \(.size[0]) \(.size[1]) \(.floating)\""); X=$1; Yy=$2; Wd=$3; Ht=$4; echo "window at $X,$Yy size ${Wd}x$Ht floating=$5"; jq -c .state $O/ready.json
hc dispatch "hl.dsp.cursor.move({ x = $((X + Wd/2)), y = $((Yy + Ht/2)) })" >/dev/null 2>&1; sleep 0.5; $Y/ydotool mousemove -x 1 -y 0; $Y/ydotool mousemove -x -1 -y 0; sleep 0.5
H0=$(hcpu); T0=$(date +%s%N)
i=0; N=$((RATE*SECS)); us=$((1000000/RATE)); while [ $i -lt $N ]; do $Y/ydotool mousemove -w -x 0 -y -1 >/dev/null 2>&1; i=$((i+1)); [ $i -eq $((N/2)) ] && { $U grim $O/mid.png 2>/dev/null; }; usleep $us 2>/dev/null || sleep 0.0$((us/10000)); done
T1=$(date +%s%N); H1=$(hcpu); echo "wheel: $N clicks in $(( (T1-T0)/1000000 )) ms; Hyprland CPU during scroll: $(( (H1-H0)*10 )) ms"
n=0; while [ ! -f $O/result.json ] && [ $n -lt 120 ]; do sleep 1; n=$((n+1)); done
[ -f $O/result.json ] && jq -c '{title,ms,profile,log}' $O/result.json || echo "NO RESULT"
echo "$(( (H1-H0)*10 ))" > $O/hypr-ms.txt
pkill -TERM -f "$F/firefox"; n=0; while pgrep -f "$F/firefox" >/dev/null && [ $n -lt 12 ]; do sleep 1; n=$((n+1)); done; pkill -KILL -f "$F/" 2>/dev/null; chmod -R u+w $F; rm -rf $F
