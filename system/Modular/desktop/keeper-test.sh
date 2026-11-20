#!/usr/bin/env bash
# desktop/keeper-test.sh <golem-session-keeper> — THE SESSION KEEPER's one
# question, "is the machine going down?", against a made-up systemctl
# (checks.session-keeper). The "desktop" is a script that writes a line and
# ends; what systemd "says" comes from a file the test writes.
set -u
keeper=$1
W=$(mktemp -d); export XDG_RUNTIME_DIR="$W/xdg"; mkdir -p "$XDG_RUNTIME_DIR" "$W/root/run/systemd/shutdown"
# (Both run under the shell that runs this test: a build has no /usr/bin/env.)
cat > "$W/systemctl" <<STUB
#!$BASH
s=\$(cat "$W/state" 2>/dev/null)
[ -n "\$s" ] || exit 1          # no answer at all: the asker was ended with the session
echo "\$s"
STUB
cat > "$W/desktop" <<STUB
#!$BASH
echo started >> "$W/starts"
exit 0
STUB
chmod +x "$W/systemctl" "$W/desktop"
export GOLEM_KEEPER_SYSTEMCTL="$W/systemctl" GOLEM_KEEPER_ROOT="$W/root"
pass=0; fail=0
is() { if [ "$2" = "$3" ]; then echo "ok   $1"; pass=$((pass + 1)); else echo "FAIL $1 — got [$2], wanted [$3]"; fail=$((fail + 1)); fi; }
starts() { if [ -f "$W/starts" ]; then wc -l < "$W/starts" | tr -d ' '; else echo 0; fi; }
reset() { rm -f "$W/starts" "$W/state" "$W/root/run/nologin" "$W/root/run/systemd/shutdown/scheduled"; }

# 1. systemd says it is stopping: the desktop is not started again
reset; echo stopping > "$W/state"
"$keeper" "$W/desktop" 2>/dev/null; is "systemd is stopping: the desktop is not started again" "$(starts)" 1

# 2. the question gets NO answer (the asker died with the session): going down, after three tries
reset
t0=$(date +%s); "$keeper" "$W/desktop" 2>/dev/null; t1=$(date +%s)
is "no answer, three times: taken as going down — not started again" "$(starts)" 1
is "…and it did ask more than once before giving up" "$([ $((t1 - t0)) -ge 2 ] && echo yes || echo no)" yes

# 3. logins are closed (/run/nologin): going down, without a question
reset; echo running > "$W/state"; : > "$W/root/run/nologin"
"$keeper" "$W/desktop" 2>/dev/null; is "logins are closed: not started again" "$(starts)" 1

# 4. a shutdown is scheduled
reset; echo running > "$W/state"; : > "$W/root/run/systemd/shutdown/scheduled"
"$keeper" "$W/desktop" 2>/dev/null; is "a shutdown is scheduled: not started again" "$(starts)" 1

# 5. the machine is simply running and the desktop ended: it comes back — that is the keeper's job
for state in running degraded; do
  reset; echo "$state" > "$W/state"
  "$keeper" "$W/desktop" 2>/dev/null &
  k=$!
  for _ in $(seq 1 80); do [ "$(starts)" -ge 2 ] && break; sleep 0.1; done
  is "systemd says $state: the desktop is started again" "$([ "$(starts)" -ge 2 ] && echo again || echo "once ($(starts))")" again
  echo stopping > "$W/state"; wait "$k"
  is "…and no more once the machine does go down" "$(kill -0 "$k" 2>/dev/null && echo alive || echo ended)" ended
done

# 6. an answer that comes on the second try counts (the first asker was ended)
reset
( sleep 0.6; echo running > "$W/state" ) &
"$keeper" "$W/desktop" 2>/dev/null &
k=$!
for _ in $(seq 1 80); do [ "$(starts)" -ge 2 ] && break; sleep 0.1; done
is "silence, then \"running\": it was not going down — started again" "$([ "$(starts)" -ge 2 ] && echo again || echo once)" again
echo stopping > "$W/state"; wait "$k"

rm -rf "$W"
echo "== $pass passed, $fail failed"
[ "$fail" = 0 ]
