#!/bin/sh
# sp.sh — a blank start of the installed Seam on an AGED profile, under the startup profiler (all threads) for 14 s; the profile lands in /tmp/seam-sb/sp/profile.json
D=/tmp/seam-sb/sp; PATH=/etc/profiles/per-user/max/bin:/run/current-system/sw/bin:$PATH
E="env XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 HYPRLAND_INSTANCE_SIGNATURE=$(ls -t /run/user/1000/hypr | head -1)"
U="runuser -u max -- $E"; hc(){ $U hyprctl "$@"; }
I=$(readlink -f /etc/profiles/per-user/max/bin/seam); W=$(grep -o '/nix/store/[^"]*bin/firefox' "$I" | head -1); L=$(ls -d $(dirname "$W")/../lib/firefox-bin-*)
F=$D/farm; chmod -R u+w $F 2>/dev/null; rm -rf $D; mkdir -p $F; P=$D/prof; cp -a /home/max/.cache/seam-lab/prof-base $P; rm -rf $P/sessionstore* $P/sessionCheckpoints.json
cp -rs "$L/." "$F/"; chmod -R u+w "$F"; rm -f "$F/firefox" "$F/firefox-bin" "$F/mozilla.cfg"; cp -L "$L/firefox" "$L/firefox-bin" "$F/"
first=$(grep -n -m1 'GOLEM chrome script' "$L/mozilla.cfg" | cut -d: -f1); head -n $((first-2)) "$L/mozilla.cfg" > "$F/mozilla.cfg"; tail -n +$((first-1)) "$L/mozilla.cfg" >> "$F/mozilla.cfg"; cat /tmp/seam-sb/startup-probe.js >> "$F/mozilla.cfg"
sed "s|^exec -a .*|exec \"$F/firefox\" \"\$@\"|" "$W" > "$F/launch"; chmod +x "$F/launch"; chown -R max:users $D
printf '#!/bin/sh\nexport SP_OUT=%s/profile.json SP_MS=14000 MOZ_LEGACY_PROFILES=1 MOZ_CRASHREPORTER_DISABLE=1 MOZ_PROFILER_STARTUP=1 MOZ_PROFILER_STARTUP_FEATURES=js,cpu,processcpu MOZ_PROFILER_STARTUP_FILTERS="*" MOZ_PROFILER_STARTUP_INTERVAL=2 MOZ_PROFILER_STARTUP_ENTRIES=12000000\nexec %s --name seam --no-remote -profile %s about:blank > %s 2>&1\n' $D "$F/launch" $P $D/log.txt > $D/run.sh; chmod +x $D/run.sh
sync; echo 1 > /proc/sys/vm/drop_caches 2>/dev/null; cat $L/libxul.so $L/omni.ja $L/browser/omni.ja > /dev/null   # warm the binaries: a WARM start is what we profile
hc dispatch "hl.exec_cmd(\"$D/run.sh\")" >/dev/null 2>&1
n=0; while [ ! -f $D/profile.json.info ] && [ $n -lt 90 ]; do sleep 1; n=$((n+1)); done; cat $D/profile.json.info 2>/dev/null | cut -c1-300; echo
pkill -TERM -f "$F/firefox"; sleep 3; pkill -KILL -f "$F/" 2>/dev/null; chmod -R u+w $F; rm -rf $F
