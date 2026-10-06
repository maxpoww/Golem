#!/bin/sh
# closetest.sh — does an empty tab survive closing Seam by the WINDOW's close request? (2026-10-04)
# On the laptop: copy this and closetest-probe.js to /tmp/seam-ct/ and run it. It starts a COPY of the
# installed Seam (own profile, class seamct), leaves a new tab waiting, closes that window through the
# compositor only if it is the active one, reopens and lists the tabs. Passed on the MacBook Air: two
# sites back, no empty tab.
D=/tmp/seam-ct; export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1
export HYPRLAND_INSTANCE_SIGNATURE=$(ls -t /run/user/1000/hypr | head -1)
I=$(readlink -f "$(command -v seam)"); W=$(grep -o '/nix/store/[^"]*bin/firefox' "$I" | head -1); L=$(ls -d "$(dirname "$W")"/../lib/firefox-bin-* | head -1)
chmod -R u+w $D/farm 2>/dev/null; rm -rf $D/farm $D/prof; mkdir -p $D/farm $D/prof/chrome; F=$D/farm
cp -rs "$L/." "$F/"; chmod -R u+w "$F"; rm -f "$F/firefox" "$F/firefox-bin" "$F/mozilla.cfg"; cp -L "$L/firefox" "$L/firefox-bin" "$F/"
cat "$L/mozilla.cfg" $D/closetest-probe.js > "$F/mozilla.cfg"
sed "s|^exec -a .*|exec \"$F/firefox\" \"\$@\"|" "$W" > "$F/launch"; chmod +x "$F/launch"
cat ~/.local/share/seam/user.js > $D/prof/user.js; cp -L ~/.local/share/seam/chrome/*.css $D/prof/chrome/
run(){ rm -f $D/out.json; printf '#!/bin/sh\nexport NT_OUT=%s NB_PHASE=%s MOZ_LEGACY_PROFILES=1 MOZ_CRASHREPORTER_DISABLE=1\nexec %s --name seamct --no-remote -profile %s > %s 2>&1\n' $D/out.json "$1" "$F/launch" $D/prof $D/log.txt > $D/run.sh; chmod +x $D/run.sh
  hyprctl dispatch "hl.exec_cmd(\"$D/run.sh\")" >/dev/null 2>&1; n=0; while [ ! -f $D/out.json ] && [ $n -lt 70 ]; do sleep 1; n=$((n+1)); done; cat $D/out.json 2>/dev/null || echo "NO RESULT"; echo; }
echo "--- phase 1: a site, a link tab, a new tab left waiting"; run 1
aw=$(hyprctl activewindow -j | jq -r .class); echo "active window class: $aw"
if [ "$aw" != seamct ]; then echo "ABORT: the test window is not the active one; not closing anything"; pkill -TERM -f "$F/firefox"; exit 1; fi
hyprctl dispatch 'hl.dsp.window.close()' ; n=0; while pgrep -f "$F/firefox" >/dev/null && [ $n -lt 25 ]; do sleep 1; n=$((n+1)); done
if pgrep -f "$F/firefox" >/dev/null; then echo "still running after the close request (${n}s)"; pkill -TERM -f "$F/firefox"; sleep 5; else echo "Seam exited ${n}s after the window close request"; fi
echo "--- phase 2: reopened"; run 2
sleep 2; pkill -KILL -f "$F/" 2>/dev/null; chmod -R u+w $D; rm -rf $D
