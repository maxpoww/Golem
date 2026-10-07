#!/bin/sh
# chrome.sh start|stop — run AS ROOT on the laptop: Google Chrome as the owner through the compositor, fresh
# profile, remote debugging on 127.0.0.1:9222 (tunnel it: ssh -L 9222:127.0.0.1:9222 root@laptop), autoplay allowed.
H=$(for s in $(ls /run/user/1000/hypr); do HYPRLAND_INSTANCE_SIGNATURE=$s /run/host/run/current-system/sw/bin/hyprctl activewindow >/dev/null 2>&1 && { echo $s; break; }; done); hc(){ HYPRLAND_INSTANCE_SIGNATURE=$H /run/host/run/current-system/sw/bin/hyprctl "$@"; }; CHROME=/run/host/run/current-system/etc/profiles/per-user/max/bin/google-chrome; CHROME=$(readlink -f $CHROME)
case "$1" in
  start) rm -rf /home/max/.cache/seam-sb/chrome-bench; mkdir -p /home/max/.cache/seam-sb/chrome-bench
         hc dispatch "hl.exec_cmd(\"$CHROME --user-data-dir=/home/max/.cache/seam-sb/chrome-bench --no-first-run --no-default-browser-check --remote-debugging-port=9222 --remote-allow-origins=* --autoplay-policy=no-user-gesture-required --mute-audio about:blank\")" >/dev/null
         n=0; while ! curl -s --max-time 2 http://127.0.0.1:9222/json/version >/dev/null && [ $n -lt 60 ]; do sleep 1; n=$((n+1)); done; curl -s http://127.0.0.1:9222/json/version | grep -o '"Browser": "[^"]*"'
         n=0; while [ -z "$(hc clients -j | python3 -c 'import sys,json; print("\n".join(c["address"] for c in json.load(sys.stdin) if c["class"]=="google-chrome"))')" ] && [ $n -lt 30 ]; do sleep 1; n=$((n+1)); done
         A=$(hc clients -j | python3 -c 'import sys,json; print("\n".join(c["address"] for c in json.load(sys.stdin) if c["class"]=="google-chrome"))' | head -1)
         hc dispatch "hl.dsp.window.fullscreen({ window = \"address:$A\", mode = \"maximized\" })" >/dev/null; sleep 1   # same geometry for both browsers: maximized
         hc clients -j | python3 -c 'import sys,json; a=sys.argv[1]; c=next((c for c in json.load(sys.stdin) if c["address"]==a),None); print("chrome window: floating=%s size=%s" % ((c["floating"],c["size"]) if c else ("?","?")))' "$A" ;;
  stop)  for a in $(hc clients -j | python3 -c 'import sys,json; print("\n".join(c["address"] for c in json.load(sys.stdin) if c["class"]=="google-chrome"))'); do hc dispatch "hl.dsp.window.close({ window = \"address:$a\" })" >/dev/null; done; sleep 4; pgrep -c -f chrome-bench || echo "chrome gone" ;;
esac
