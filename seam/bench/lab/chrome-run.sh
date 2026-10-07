#!/bin/sh
# chrome-run.sh <url> — from the DEV BOX: Chrome on the MacBook through the compositor, the video page, 45 s warm,
# 20 s window with 4 real presses + CPU sample (pauses.sh on the laptop), results in $S/acer/mb-chrome-*.
S=/tmp/claude-1000/-home-max/01022959-a2fa-4209-b76f-5af45660221d/scratchpad; MB="ssh -o UserKnownHostsFile=$S/kh root@${LAB:-192.168.1.242}"; URL=$1
$MB 'sh /tmp/seam-sb/chrome.sh start' | cut -c1-160
ssh -o UserKnownHostsFile=$S/kh -N -L 9222:127.0.0.1:9222 root@${LAB:-192.168.1.242} & T=$!; sleep 2
$MB 'pkill -f "pause[s].sh /tmp/seam-sb/chrome-window-start"' >/dev/null 2>&1   # its own ssh: the arming command line below contains the pattern text
$MB 'rm -f /tmp/seam-sb/chrome-window-start /tmp/seam-sb/chrome-presses.txt*; (sh /tmp/seam-sb/pauses.sh /tmp/seam-sb/chrome-window-start "chrome-bench" /tmp/seam-sb/chrome-presses.txt google-chrome >/dev/null 2>&1 &); echo armed'
(sleep 62; $MB 'H=$(ls -t /run/user/1000/hypr | head -1); runuser -u max -- env XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 HYPRLAND_INSTANCE_SIGNATURE=$H PATH=/etc/profiles/per-user/max/bin:/run/current-system/sw/bin grim /tmp/seam-sb/yt-chrome.png') &
MARKER_SSH="ssh -o UserKnownHostsFile=$S/kh root@${LAB:-192.168.1.242}" WARM=${WARM:-45} python3 ~/.cache/golem-wt/seam-debloat/seam/bench/lab/chrome-video.py localhost:9222 "$URL" > $S/acer/mb-chrome.json; sleep 3
$MB 'cat /tmp/seam-sb/chrome-presses.txt; echo "== cpu"; cat /tmp/seam-sb/chrome-presses.txt.cpu' | tee $S/acer/mb-chrome-presses.txt
$MB 'sh /tmp/seam-sb/chrome.sh stop' | tail -1; kill $T 2>/dev/null; wait
python3 ~/.cache/golem-wt/seam-debloat/seam/bench/lab/ytsum.py chrome $S/acer/mb-chrome.json $S/acer/mb-chrome-presses.txt
