#!/usr/bin/env bash
# run-actions-agent.sh — overnight headless loop for the Golem ACTIONS research agent.
#
# Runs work units via `claude -p` until the deadline (default 3h). It does NOT
# exit early: when a batch finishes the agent starts the next one (agent.md P9),
# and if BOTH models hit token limits it sleeps 10 min and retries (limits reset
# in windows). Primary model is Fable; on token exhaustion it switches to Opus.
#
# Launch:            ~/Golem/docs/shell/actions/run-actions-agent.sh
# Custom duration:   ACTIONS_DURATION_SECS=7200 ~/Golem/docs/shell/actions/run-actions-agent.sh
# Everything is logged to work/driver.log; deliverables land in work/batch-*/.

set -u
cd "$(dirname "$0")"

DURATION="${ACTIONS_DURATION_SECS:-10800}"   # 3 hours
ITER_CAP=1800                                # max seconds for one claude call
PRIMARY="${ACTIONS_PRIMARY_MODEL:-claude-fable-5}"
FALLBACK="${ACTIONS_FALLBACK_MODEL:-claude-opus-5}"
TOOLS="Read,Write,Edit,Glob,Grep,WebSearch,WebFetch"
PROMPT='Read /home/max/Golem/docs/shell/actions/agent.md and follow it exactly: perform the single next unit of work derived from work/STATE.md, write the output files, update STATE.md, and finish with the short wrap-up agent.md specifies.'

mkdir -p work
LOG="work/driver.log"
OUT="work/.last-iteration.log"
START=$(date +%s)
DEADLINE=$((START + DURATION))
MODEL="$PRIMARY"
ITER=0
FAILS=0

say() { printf '%s %s\n' "$(date '+%H:%M:%S')" "$*" | tee -a "$LOG"; }

finish() {
  ELAPSED=$(( $(date +%s) - START ))
  say "=== run over · $ITER iterations · $((ELAPSED/60)) min elapsed ==="
  say "Read work/SUMMARY.md first, then work/batch-*/actions-40.md and implementation.md"
}
trap 'echo; say "INTERRUPTED by user."; finish; exit 130' INT

# Sleep, but never past the deadline.
nap() {
  local want=$1 left=$((DEADLINE - $(date +%s) - 30))
  [ "$left" -lt "$want" ] && want=$left
  [ "$want" -gt 0 ] && sleep "$want"
}

[ -f work/STATE.md ] || printf 'batch: 1\nphase: P0\nnext: initialize batch 1 (create work/batch-01/) and begin P1 chunk 1/4\ndone:\n' > work/STATE.md

say "=== ACTIONS agent · start $(date '+%F %H:%M') · deadline $(date -d "@$DEADLINE" '+%H:%M') · $PRIMARY -> $FALLBACK ==="

while :; do
  NOW=$(date +%s); LEFT=$((DEADLINE - NOW))
  if [ "$LEFT" -lt 90 ]; then say "Deadline reached."; break; fi
  CAP=$(( LEFT < ITER_CAP ? LEFT : ITER_CAP ))
  ITER=$((ITER + 1))
  STATE_LINE=$(grep -E '^(batch|phase):' work/STATE.md 2>/dev/null | tr '\n' ' ')
  say "--- iter $ITER · $MODEL · ${STATE_LINE:-no state}· $((LEFT/60)) min left ---"

  ARGS=(--model "$MODEL" --allowedTools "$TOOLS")
  [ "$MODEL" = "$PRIMARY" ] && [ "$PRIMARY" != "$FALLBACK" ] && ARGS+=(--fallback-model "$FALLBACK")

  timeout "$CAP" claude -p "$PROMPT" "${ARGS[@]}" > "$OUT" 2>&1
  RC=$?
  tee -a "$LOG" < "$OUT"

  if [ "$RC" -eq 0 ]; then
    FAILS=0
    sleep 5
    continue
  fi

  if [ "$RC" -eq 124 ]; then
    say "iter $ITER hit the ${CAP}s cap — fine, STATE.md resumes the unit next iter"
    FAILS=0
    continue
  fi

  if grep -qiE 'usage limit|session limit|hit your .*limit|rate.?limit|limit (reached|exceeded)|resets [0-9]|out of (tokens|credits)|quota|insufficient credit' "$OUT"; then
    if [ "$MODEL" = "$PRIMARY" ] && [ "$PRIMARY" != "$FALLBACK" ]; then
      MODEL="$FALLBACK"
      say "TOKENS: $PRIMARY exhausted -> switching to $FALLBACK"
    else
      say "TOKENS: both models limited -> napping 10 min, then retrying"
      nap 600
    fi
    continue
  fi

  FAILS=$((FAILS + 1))
  PAUSE=$(( FAILS * 60 )); [ "$PAUSE" -gt 300 ] && PAUSE=300
  say "iter $ITER failed (rc=$RC, streak $FAILS) -> retry in ${PAUSE}s"
  if [ "$FAILS" -ge 3 ] && [ "$MODEL" = "$PRIMARY" ] && [ "$PRIMARY" != "$FALLBACK" ]; then
    MODEL="$FALLBACK"
    say "3 straight failures on $PRIMARY -> trying $FALLBACK"
  fi
  nap "$PAUSE"
done

finish
