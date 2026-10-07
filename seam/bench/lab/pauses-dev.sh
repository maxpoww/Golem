#!/bin/sh
# pauses.sh <marker-file> <proc-pattern> [out] [window-class] — run AS ROOT on the laptop next to a video measurement:
# waits for the window-start marker (ms since epoch, laptop clock), starts cpusample.sh on <proc-pattern>
# for 20 s, and presses 'k' (YouTube play/pause) at +4, +8, +12, +16 s through ydotool (a real uinput
# key through the compositor), logging each press time; the browser side records when video.paused flips.
M=$1; P=$2; O=${3:-$M.presses}; C=$4; : > $O
H=$(for s in $(ls /run/user/1000/hypr); do HYPRLAND_INSTANCE_SIGNATURE=$s /run/host/run/current-system/sw/bin/hyprctl activewindow >/dev/null 2>&1 && { echo $s; break; }; done)
hc(){ HYPRLAND_INSTANCE_SIGNATURE=$H /run/host/run/current-system/sw/bin/hyprctl "$@"; }; focus(){ [ -n "$C" ] && hc dispatch "hl.dsp.focus({ window = \"class:$C\" })" >/dev/null 2>&1; }

n=0; while [ ! -s "$M" ] && [ $n -lt 1500 ]; do sleep 0.2; n=$((n+1)); done
[ -s "$M" ] || { echo "no marker" >> $O; exit 1; }
T0=$(cat "$M"); echo "marker $T0" >> $O
sh /home/max/.cache/seam-sb/cpusample.sh "$P" 20 > $O.cpu 2>&1 &
for d in 4 8 12 16; do
  while [ $(( $(date +%s%3N) - T0 )) -lt $((d*1000)) ]; do sleep 0.05; done
  focus; sleep 0.15; echo "press $(date +%s%3N)" >> $O; hc dispatch "hl.dsp.send_shortcut({ mods = \"\", key = \"k\", window = \"class:$C\" })" >/dev/null 2>&1
done
wait; echo "done" >> $O
