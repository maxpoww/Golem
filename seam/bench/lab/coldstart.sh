#!/bin/sh
# coldstart.sh <seam|chrome> <cold|warm> — AS ROOT on the laptop: drop the page cache (cold) and launch the browser
# through the compositor; print ms until its window is mapped (hyprctl clients, 50 ms poll) and until its title
# changes from the startup placeholder (first real content); then close it. The same yardstick for both browsers.
export PATH=/etc/profiles/per-user/max/bin:/run/current-system/sw/bin:$PATH
B=$1; M=$2; H=$(ls -t /run/user/1000/hypr | head -1); hc(){ runuser -u max -- env XDG_RUNTIME_DIR=/run/user/1000 HYPRLAND_INSTANCE_SIGNATURE=$H hyprctl "$@"; }
case $B in seam) CLS=seam; CMD="seam about:blank";; chrome) CLS=google-chrome; CMD="google-chrome --user-data-dir=/tmp/chrome-cold --no-first-run --no-default-browser-check about:blank"; [ -d /tmp/chrome-cold ] || { mkdir -p /tmp/chrome-cold; chown max:users /tmp/chrome-cold; };; esac
[ "$M" = cold ] && { sync; echo 3 > /proc/sys/vm/drop_caches; sleep 2; }
T0=$(date +%s%3N); hc dispatch "hl.exec_cmd(\"$CMD\")" >/dev/null
n=0; while [ -z "$(hc clients -j | jq -r ".[] | select(.class==\"$CLS\") | .address")" ] && [ $n -lt 1200 ]; do sleep 0.05; n=$((n+1)); done; T1=$(date +%s%3N)
sleep 0.2; A=$(hc clients -j | jq -r ".[] | select(.class==\"$CLS\") | .address" | head -1)
echo "$B $M: window mapped after $((T1-T0)) ms (title: $(hc clients -j | jq -r ".[] | select(.address==\"$A\") | .title" | cut -c1-30))"
sleep 5; hc dispatch "hl.dsp.window.close({ window = \"address:$A\" })" >/dev/null; sleep 4; pgrep -f "$CLS|seam-157|google/chrome" >/dev/null && pkill -TERM -u max -f "chrome-cold|seam-157.0.1/bin/firefox" ; sleep 2
