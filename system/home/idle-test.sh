#!/usr/bin/env bash
# home/idle-test.sh <golem-idle-suspend> — THE IDLE SUSPEND, against a made-up
# systemctl (checks.idle-suspend). What a unit "is" comes from a file the
# test writes; a suspend that is asked for is written down, not done.
#   bash system/home/idle-test.sh "$(nix build --print-out-paths …idleSuspend)"
set -u
script=$1
W=$(mktemp -d); export XDG_RUNTIME_DIR="$W/run"; mkdir -p "$XDG_RUNTIME_DIR" "$W/bin" "$W/state"
# (The stub runs under the shell that runs this test: a build's sandbox has
# no /usr/bin/env to find one with.)
cat > "$W/bin/systemctl" <<STUB
#!$BASH
case "\$1" in
  is-active) u=\${2%.service}; s=\$(cat "$W/state/\$u" 2>/dev/null || echo inactive); echo "\$s"; [ "\$s" = active ] ;;   # systemd's own: only "active" is success
  suspend) echo suspend >> "$W/suspends" ;;
esac
STUB
chmod +x "$W/bin/systemctl"
export PATH="$W/bin:$PATH" GOLEM_IDLE_STEP=1
pass=0; fail=0
is() { if [ "$2" = "$3" ]; then echo "ok   $1"; pass=$((pass + 1)); else echo "FAIL $1 — got [$2], wanted [$3]"; fail=$((fail + 1)); fi; }
suspends() { if [ -f "$W/suspends" ]; then wc -l < "$W/suspends" | tr -d ' '; else echo 0; fi; }
reset() { rm -f "$W/suspends" "$W/state"/*; }

# 1. nothing of Standard's is running: it suspends at once
reset; out=$("$script" 2>&1)
is "nothing running: the suspend is asked for at once" "$(suspends)" 1

# 2. a one-shot that is running says "activating" (and is-active fails): the suspend waits, then happens
reset; echo activating > "$W/state/golem-first-boot"
"$script" > "$W/out2" 2>&1 &
p=$!; sleep 2
is "a first-boot build is running: no suspend while it is" "$(suspends)" 0
is "…and it says what it waits for" "$(grep -c 'golem-first-boot is running' "$W/out2")" 1
is "…with its pid written for the owner's return" "$(cat "$XDG_RUNTIME_DIR/golem/idle-suspend.pid" 2>/dev/null)" "$p"
echo inactive > "$W/state/golem-first-boot"
wait "$p"
is "the build ended: the suspend is asked for then" "$(suspends)" 1
is "…and the pid file is gone" "$([ -e "$XDG_RUNTIME_DIR/golem/idle-suspend.pid" ] && echo there || echo gone)" gone

# 3. the owner comes back while it waits: called off, never suspended
reset; echo activating > "$W/state/waverunner-apply"
"$script" > "$W/out3" 2>&1 &
p=$!; sleep 2
out=$("$script" --cancel 2>&1)
wait "$p" 2>/dev/null
echo inactive > "$W/state/waverunner-apply"; sleep 2
is "the owner came back: the waiting suspend is called off" "$(suspends)" 0
is "…and says so" "$(grep -c 'called off' <<< "$out")" 1
is "…and a second return finds nothing to call off" "$("$script" --cancel 2>&1; echo "rc=$?")" "rc=0"

# 4. a pid file that names some other program is never killed
reset; mkdir -p "$XDG_RUNTIME_DIR/golem"; sleep 30 & other=$!
echo "$other" > "$XDG_RUNTIME_DIR/golem/idle-suspend.pid"
"$script" --cancel > /dev/null 2>&1
is "a pid that is not the waiting suspend is left alone" "$(kill -0 "$other" 2>/dev/null && echo alive || echo dead)" alive
kill "$other" 2>/dev/null

# 5. a job that never ends does not keep the machine awake for ever
reset; echo activating > "$W/state/seam-update"
out=$(GOLEM_IDLE_MOST=3 "$script" 2>&1)
is "a job that never ends: suspended at the limit all the same" "$(suspends)" 1

# 6. every unit it names is waited for
for u in waverunner-apply golem-postinstall-apply golem-autoupdate seam-update golem-first-boot; do
  reset; echo activating > "$W/state/$u"
  "$script" > /dev/null 2>&1 & p=$!; sleep 1.5
  n=$(suspends); echo inactive > "$W/state/$u"; wait "$p"
  is "$u is waited for" "$n $(suspends)" "0 1"
done

rm -rf "$W"
echo "== $pass passed, $fail failed"
[ "$fail" = 0 ]
