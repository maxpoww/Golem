#!/bin/sh
# chrome-run-dev.sh <url> — DEV BOX (from the toolbox, no root): Chrome through the compositor, the video page, 45 s warm,
# 20 s window with 4 compositor-injected 'k' presses + CPU sample (pauses-dev.sh), results in $D/dev-chrome-*.
D=/home/max/.cache/seam-sb; URL=$1
sh $D/chrome-dev.sh start | cut -c1-160
pkill -f "pause[s]-dev.sh $D/chrome-window-start" 2>/dev/null; rm -f $D/chrome-window-start $D/chrome-presses.txt*
(sh $D/pauses-dev.sh $D/chrome-window-start "chrome-bench" $D/chrome-presses.txt google-chrome >/dev/null 2>&1 &)
MARKER="$D/chrome-window-start" MARKER_SSH="" WARM=${WARM:-45} PIN=${PIN:-0} python3 $D/chrome-video.py localhost:9222 "$URL" > $D/dev-chrome.json; sleep 3
cat $D/chrome-presses.txt | tr '\n' ' '; echo; cat $D/chrome-presses.txt.cpu
sh $D/chrome-dev.sh stop | tail -1
python3 $D/ytsum.py chrome $D/dev-chrome.json $D/chrome-presses.txt
