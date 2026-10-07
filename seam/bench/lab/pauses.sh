#!/bin/sh
# pauses.sh <marker-file> <proc-pattern> [out] — run AS ROOT on the laptop next to a video measurement:
# waits for the window-start marker (ms since epoch, laptop clock), starts cpusample.sh on <proc-pattern>
# for 20 s, and presses 'k' (YouTube play/pause) at +4, +8, +12, +16 s through ydotool (a real uinput
# key through the compositor), logging each press time; the browser side records when video.paused flips.
M=$1; P=$2; O=${3:-$M.presses}; : > $O
export YDOTOOL_SOCKET=/tmp/.ydotool_socket; YD=/nix/store/xmdkfvizgrykg67i158xxidlzyza8n87-ydotool-1.0.4/bin/ydotool
n=0; while [ ! -s "$M" ] && [ $n -lt 1500 ]; do sleep 0.2; n=$((n+1)); done
[ -s "$M" ] || { echo "no marker" >> $O; exit 1; }
T0=$(cat "$M"); echo "marker $T0" >> $O
sh /tmp/seam-sb/cpusample.sh "$P" 20 > $O.cpu 2>&1 &
for d in 4 8 12 16; do
  while [ $(( $(date +%s%3N) - T0 )) -lt $((d*1000)) ]; do sleep 0.05; done
  echo "press $(date +%s%3N)" >> $O; $YD key 37:1 37:0
done
wait; echo "done" >> $O
