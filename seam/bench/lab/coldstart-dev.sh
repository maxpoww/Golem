#!/bin/sh
# coldstart.sh <seam|chrome> <cold|warm> — AS ROOT on the laptop: drop the page cache (cold) and launch the browser
# through the compositor; print ms until its window is mapped (hyprctl clients, 50 ms poll) and until its title
# changes from the startup placeholder (first real content); then close it. The same yardstick for both browsers.

B=$1; M=$2; H=$(for s in $(ls /run/user/1000/hypr); do HYPRLAND_INSTANCE_SIGNATURE=$s /run/host/run/current-system/sw/bin/hyprctl activewindow >/dev/null 2>&1 && { echo $s; break; }; done); hc(){ HYPRLAND_INSTANCE_SIGNATURE=$H /run/host/run/current-system/sw/bin/hyprctl "$@"; }
case $B in seam) CLS=seam; CMD="/etc/profiles/per-user/max/bin/seam about:blank";; chrome) CLS=google-chrome; CMD="/etc/profiles/per-user/max/bin/google-chrome --mute-audio --user-data-dir=/home/max/.cache/seam-sb/chrome-cold --no-first-run --no-default-browser-check about:blank"; [ -d /home/max/.cache/seam-sb/chrome-cold ] || { mkdir -p /home/max/.cache/seam-sb/chrome-cold; chown max:users /home/max/.cache/seam-sb/chrome-cold; };; esac
[ "$M" = cold ] && { echo "no root here: warm only"; exit 1; }
T0=$(date +%s%3N); hc dispatch "hl.exec_cmd(\"$CMD\")" >/dev/null
n=0; while [ -z "$(hc clients -j | python3 -c 'import sys,json; c=sys.argv[1]; print("".join(x["address"] for x in json.load(sys.stdin) if x["class"]==c))' "$CLS" 2>/dev/null)" ] && [ $n -lt 1200 ]; do sleep 0.05; n=$((n+1)); done; T1=$(date +%s%3N)
sleep 0.2; A=$(hc clients -j | python3 -c 'import sys,json; c=sys.argv[1]; print(next((x["address"] for x in json.load(sys.stdin) if x["class"]==c),""))' "$CLS")
echo "$B $M: window mapped after $((T1-T0)) ms (title: $(hc clients -j | python3 -c 'import sys,json; a=sys.argv[1]; print(next((x["title"][:30] for x in json.load(sys.stdin) if x["address"]==a),""))' "$A"))"
sleep 5; hc dispatch "hl.dsp.window.close({ window = \"address:$A\" })" >/dev/null; sleep 4; pgrep -f "$CLS|seam-157|google/chrome" >/dev/null && pkill -TERM -f "chrome-cold|seam-157.0.1/bin/firefox" ; sleep 2
