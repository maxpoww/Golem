#!/bin/sh
# gfx.sh — run AS ROOT on the laptop: a copy of the installed Seam on the aged profile with the gfx timing probe; prints the timings.
D=/tmp/seam-sb/gfx; PATH=/etc/profiles/per-user/max/bin:/run/current-system/sw/bin:$PATH
E="env XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 HYPRLAND_INSTANCE_SIGNATURE=$(ls -t /run/user/1000/hypr | head -1)"
U="runuser -u max -- $E"; hc(){ $U hyprctl "$@"; }
I=$(readlink -f /etc/profiles/per-user/max/bin/seam); W=$(grep -o '/nix/store/[^"]*bin/firefox' "$I" | head -1); L=$(ls -d $(dirname "$W")/../lib/firefox-bin-*)
F=$D/farm; chmod -R u+w $F 2>/dev/null; rm -rf $D; mkdir -p $F; P=$D/prof; cp -a /home/max/.cache/seam-lab/prof-base $P; rm -rf $P/sessionstore* $P/sessionCheckpoints.json
cp -rs "$L/." "$F/"; chmod -R u+w "$F"; rm -f "$F/firefox" "$F/firefox-bin" "$F/mozilla.cfg"; cp -L "$L/firefox" "$L/firefox-bin" "$F/"
first=$(grep -n -m1 'GOLEM chrome script' "$L/mozilla.cfg" | cut -d: -f1); head -n $((first-2)) "$L/mozilla.cfg" > "$F/mozilla.cfg"; tail -n +$((first-1)) "$L/mozilla.cfg" >> "$F/mozilla.cfg"; cat /tmp/seam-sb/gfx-probe.js >> "$F/mozilla.cfg"
sed "s|^exec -a .*|exec \"$F/firefox\" \"\$@\"|" "$W" > "$F/launch"; chmod +x "$F/launch"; chown -R max:users $D
printf '#!/bin/sh\nexport NT_OUT=%s/out.json MOZ_LEGACY_PROFILES=1 MOZ_CRASHREPORTER_DISABLE=1\nexec %s --name seam --no-remote -profile %s about:blank > %s 2>&1\n' $D "$F/launch" $P $D/log.txt > $D/run.sh; chmod +x $D/run.sh
cat $L/libxul.so $L/omni.ja $L/browser/omni.ja > /dev/null
hc dispatch "hl.exec_cmd(\"$D/run.sh\")" >/dev/null 2>&1
n=0; while [ ! -f $D/out.json ] && [ $n -lt 60 ]; do sleep 1; n=$((n+1)); done; cat $D/out.json 2>/dev/null; echo
sleep 4; pkill -TERM -f "$F/firefox"; sleep 3; pkill -KILL -f "$F/" 2>/dev/null; chmod -R u+w $F; rm -rf $F
