#!/bin/sh
# chrome.sh start|stop — run AS ROOT on the laptop: Google Chrome as the owner through the compositor, fresh
# profile, remote debugging on 127.0.0.1:9222 (tunnel it: ssh -L 9222:127.0.0.1:9222 root@laptop), autoplay allowed.
export PATH=/etc/profiles/per-user/max/bin:/run/current-system/sw/bin:$PATH
H=$(ls -t /run/user/1000/hypr | head -1); hc(){ runuser -u max -- env XDG_RUNTIME_DIR=/run/user/1000 HYPRLAND_INSTANCE_SIGNATURE=$H hyprctl "$@"; }
case "$1" in
  start) rm -rf /tmp/chrome-bench; mkdir -p /tmp/chrome-bench; chown max:users /tmp/chrome-bench
         hc dispatch "hl.exec_cmd(\"google-chrome --user-data-dir=/tmp/chrome-bench --no-first-run --no-default-browser-check --remote-debugging-port=9222 --remote-allow-origins=* --autoplay-policy=no-user-gesture-required about:blank\")" >/dev/null
         n=0; while ! curl -s --max-time 2 http://127.0.0.1:9222/json/version >/dev/null && [ $n -lt 60 ]; do sleep 1; n=$((n+1)); done; curl -s http://127.0.0.1:9222/json/version | grep -o '"Browser": "[^"]*"'
         n=0; while [ -z "$(hc clients -j | jq -r '.[] | select(.class=="google-chrome") | .address')" ] && [ $n -lt 30 ]; do sleep 1; n=$((n+1)); done
         A=$(hc clients -j | jq -r '.[] | select(.class=="google-chrome") | .address' | head -1)
         # same geometry as the Seam farm window (tiled, the whole workspace): a floating 1050x680 Chrome gets a smaller player and a lower stream
         [ "$(hc clients -j | jq -r ".[] | select(.address==\"$A\") | .floating")" = "true" ] && hc dispatch "hl.dsp.window.float({ window = \"address:$A\" })" >/dev/null; sleep 1
         hc clients -j | jq -r ".[] | select(.address==\"$A\") | \"chrome window: floating=\(.floating) size=\(.size)\"" ;;
  stop)  for a in $(hc clients -j | jq -r '.[] | select(.class=="google-chrome") | .address'); do hc dispatch "hl.dsp.window.close({ window = \"address:$a\" })" >/dev/null; done; sleep 4; pgrep -c -x chrome || echo "chrome gone" ;;
esac
