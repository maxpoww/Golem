#!/usr/bin/env bash
# 2hs.sh — work the todo backlog autonomously for 2h, streaming output.
#
# Rewritten 2026-09-01 after the 2026-08-31 run. That run did 99 items and
# parked 75, and the parks were mostly not the model's judgement — they were
# the harness. It ran with:
#
#     TOOLS="Read,Edit,Bash(npm test *),Bash(git *)"
#
# on a session rooted at ~/Golem only. So it could not `ls`, could not `grep`,
# could not run `nix` (this repo is a NixOS flake), could not reach the four
# other trees the work actually lives in — and `Bash(git *)` did not even match
# `git add x && git commit -F - <<EOF`, so several of its own commits were
# denied. It wrote 546 lines of NOTES.md explaining, correctly and in detail,
# that it had been asked to build things it was forbidden to see.
#
# This version gives it the machine. Constraints are now about blast radius
# (loop-guard.sh: nothing leaves this box) and about the roadmap freeze
# (in the prompt), not about which tools exist.
#
# Recovery: every tree was tagged pre-loop-<stamp> before the run, and
# ~/Golem-web's uncommitted worktree was tarred into the scratchpad.
set -uo pipefail

# ---- config ---------------------------------------------------------------
GOLEM="/home/max/Golem"
TODO_DIR="$GOLEM/todo"
BUDGET=$(( 120 * 60 ))          # 2h total
SLICE_MAX=$(( 30 * 60 ))        # max per iteration (nix builds are slow)
SETTINGS="$GOLEM/loop-settings.json"

# Model. Override per run:  MODEL=opus ./2hs.sh
# The 2026-08-31 run was opus and cost $22.67 for 31 iterations.
MODEL="${MODEL:-fable}"

# The five other trees the backlog refers to. The last run could reach none of
# them and parked ~28 items saying so.
ADD_DIRS=(
  /home/max/launcher                    # waverunner: Rust engine + surfaces
  /home/max/waveview                    # overview plugin
  /home/max/Golem-web                   # golem-os.com (HAS UNCOMMITTED WORK)
  /home/max/AndroidStudioProjects/Golem # Kotlin phone app (branch: rename-package)
  /home/max/notification-fix            # 3-file Chrome extension
)
# ---------------------------------------------------------------------------

command -v jq  >/dev/null || { echo "jq is required"; exit 1; }
command -v nix >/dev/null || { echo "nix is required (the last run's biggest gap)"; exit 1; }
[ -f "$GOLEM/roadmap.md" ] || { echo "roadmap.md missing"; exit 1; }
[ -d "$TODO_DIR" ]         || { echo "$TODO_DIR missing"; exit 1; }
[ -x "$GOLEM/loop-guard.sh" ] || { echo "loop-guard.sh missing or not executable"; exit 1; }
[ -f "$SETTINGS" ]         || { echo "$SETTINGS missing"; exit 1; }

cd "$GOLEM" || exit 1

DIR_ARGS=()
for d in "${ADD_DIRS[@]}"; do
  [ -d "$d" ] && DIR_ARGS+=(--add-dir "$d") || echo "warning: $d not found, skipping"
done

END=$(( $(date +%s) + BUDGET ))
STUCK=0
LAST=""

next_todo() {
  local f
  for f in $(printf '%s\n' "$TODO_DIR"/todo*.md | sort -V); do
    grep -q '^- \[ \]' "$f" && { echo "$f"; return; }
  done
}

read -r -d '' PROMPT_TEMPLATE <<'EOF'
Read Golem.md and roadmap.md for overall context, then open %s.

Work ONLY on items in that file. Take the first unchecked item.

## The law you are most likely to break

Golem.md, "What Golem does not build itself": the Brain senses and decides,
it does NOT reimplement what a mature daemon already does. Power, thermals,
network, bluetooth, audio — run the proven backend (TLP, UPower, thermald,
NetworkManager, BlueZ, PipeWire) and connect it to the Brain. The
intelligence is in the offer, never in the plumbing.

This is easy to violate by accident, because writing a small sysfs poller is
usually the shortest path to a working demo and it looks like progress. If
you catch yourself parsing `/sys` or shelling out to a CLI to re-derive
something a daemon already publishes on D-Bus, stop and use the daemon.

Its three qualifiers matter as much as the rule:
- adding a backend is a real dependency with a cost, decided per module and
  written into the flake — not a reflex;
- the backend is a backend, never a shipped UI. The surface is Golem's;
- bind to the D-Bus interface, not the vendor. Read Golem.md for the worked
  example (PowerProfiles, and why TLP and power-profiles-daemon collide).

## The trees

Golem's work is spread across repos. You can reach all of them this run:

  ~/Golem      this repo — the plan, the NixOS flake, system/ and hosts/
  ~/launcher   waverunner: the Rust engine, Mind providers, collectors, surfaces
  ~/waveview   the overview plugin (Rust)
  ~/Golem-web  golem-os.com — HAS 14 UNCOMMITTED FILES, do not discard them
  ~/AndroidStudioProjects/Golem   the Kotlin phone app, on branch rename-package
  ~/notification-fix              a 3-file Chrome extension

A previous loop was sandboxed to ~/Golem and parked ~28 items with the note
"this is waverunner code and I cannot reach it". Those walls are GONE. If an
item's NOTES.md entry blames reach, that reason has expired — check before you
believe it.

## How to verify (the last run could do none of this)

  ~/Golem      nix eval .#nixosConfigurations.golem.config.system.build.toplevel.drvPath
               nixos-rebuild build-vm --flake .#golem-vm
               nix build .#iso            (already built warm before this run)
  ~/launcher   cd /home/max/launcher && nix develop -c cargo test --workspace
               (245 tests, green at the start of this run — keep them green)
  ~/waveview   same pattern, nix develop -c cargo test
  phone app    cd ~/AndroidStudioProjects/Golem && ./gradlew test
               (java and ANDROID_HOME are set; gradle comes from ./gradlew)

`cargo` is NOT on PATH — it only exists inside `nix develop`. That is not a
blocker, it is the invocation.

## Two rules that are NOT about tooling

1. THE FREEZE. roadmap.md has Arc 1 at SH -> S7 -> S9 under "no new OPTIONS
   surfaces, no module growth". Do not build S3 modules, the S6 settings
   surface, or the S8 onboarding tour, even though you can now reach the code.
   Refactors, fixes and audits of existing surfaces are fine. If an item would
   add a surface, park it and say the freeze is why.

2. LOCAL ONLY. Commit freely in any tree. Do NOT push, deploy, submit to
   F-Droid, or touch golem-os.com's live site. A hook blocks these; if you hit
   it, that is expected — do the local half and park the outward half. Max
   reviews and pushes himself.

## Keep your context lean (this is cost, not style)

Last run averaged 44 turns per iteration and its spend was almost entirely
context re-reads. Same capability, fewer tokens:

- NEVER dump a build into the transcript. Run it as
  `nix build ... > /tmp/build.log 2>&1; echo $?` then `tail -30` or grep the
  log for errors. Same for cargo, gradlew and nixos-rebuild — their happy
  output is thousands of lines you will pay to re-read every turn after.
- Do not read NOTES.md top to bottom; it is 600 lines. `grep -A5 todoN` it
  for the entries about your file.
- Read the sections of files you need, not whole files, when the file is
  large and you know what you are looking for.
- Batch independent shell commands into one call instead of five.

## Per item

Before starting, decide if you can finish it end-to-end:
- If it needs a decision only Max can make (taste, values, design language),
  hardware you do not have, a human to watch, or his eyes on a running
  desktop — do NOT attempt it. Change "- [ ]" to "- [?]", add one line to
  NOTES.md naming the item and the real blocker, move to the next item.
- If you CAN do it: make the change, then actually run the build or the test
  above. Only if it passes, commit and change "- [ ]" to "- [x]".
- If it fails and you cannot fix it after a genuine attempt: revert, mark
  "- [?]", say why in NOTES.md, move on.

Never claim a green run you did not perform. The last loop was scrupulous
about this and it is the reason its output is trustworthy — hold that line.
If an item is documentation-only and no test applies, say so rather than
implying verification.

Work through as many items in this file as you can. Stop when it has no
unchecked items left. Never edit another todo file.
EOF

STREAM_FILTER='
  if .type == "stream_event" and .event.delta.type? == "text_delta"
    then .event.delta.text
  elif .type == "assistant" then
    (.message.content[]? | select(.type == "tool_use")
     | "\n[36m▸ \(.name)[0m \(.input.command // .input.file_path // "")\n")
  elif .type == "result" then
    "\n[33m— iteration done (\(.num_turns // 0) turns, $\(.total_cost_usd // 0))[0m\n"
  else empty end'

printf '\033[1mstarting: %s budget, model %s, %d trees in scope, guard active\033[0m\n' \
  "$(( BUDGET / 60 ))m" "$MODEL" "$(( ${#DIR_ARGS[@]} / 2 + 1 ))"

while :; do
  REMAIN=$(( END - $(date +%s) ))
  [ "$REMAIN" -le 60 ] && { echo "time budget exhausted"; break; }

  TODO=$(next_todo)
  [ -n "$TODO" ] && [ -f "$TODO" ] || { echo "all todos resolved"; break; }

  # Same file back again = the last session ran out of slice mid-file. Resume
  # that session instead of paying to re-derive its context from zero — the
  # continued session also remembers what it already tried, which a cold one
  # re-discovers at full price.
  CONT=()
  if [ "$TODO" = "$LAST" ]; then STUCK=$(( STUCK + 1 )); CONT=(--continue); else STUCK=0; fi
  LAST="$TODO"
  if [ "$STUCK" -ge 3 ]; then
    echo "no progress on $TODO after 3 passes — parking it"
    sed -i 's/^- \[ \]/- [?]/' "$TODO"
    echo "- parked $(basename "$TODO"): loop made no progress in 3 iterations" >> NOTES.md
    STUCK=0; LAST=""
    continue
  fi

  SLICE=$(( REMAIN < SLICE_MAX ? REMAIN : SLICE_MAX ))
  printf '\n\033[1m=== %s | %s | %dm left ===\033[0m\n' \
    "$(date +%H:%M)" "$(basename "$TODO")" "$(( REMAIN / 60 ))"

  if [ ${#CONT[@]} -gt 0 ]; then
    PROMPT="Continue working through the unchecked items in $TODO under the same rules. Your previous slice was cut by a timeout, not by an error — pick up where you stopped."
  else
    PROMPT="$(printf "$PROMPT_TEMPLATE" "$TODO")"
  fi

  timeout "$SLICE" claude -p "$PROMPT" \
    "${CONT[@]}" \
    --model "$MODEL" \
    --permission-mode bypassPermissions \
    --settings "$SETTINGS" \
    "${DIR_ARGS[@]}" \
    --output-format stream-json --verbose --include-partial-messages \
    2>>run.err \
    | tee -a raw.jsonl \
    | jq -rj --unbuffered "$STREAM_FILTER" \
    || echo "iteration ended early on $TODO (timeout or error), continuing"
done

echo
echo "--- summary ---"
for f in $(printf '%s\n' "$TODO_DIR"/todo*.md | sort -V); do
  printf '%-24s done:%-4s parked:%-4s open:%s\n' "$(basename "$f")" \
    "$(grep -c '^- \[x\]' "$f")" "$(grep -c '^- \[?\]' "$f")" "$(grep -c '^- \[ \]' "$f")"
done
echo
echo "commits this run (vs the pre-loop tag):"
for d in "$GOLEM" "${ADD_DIRS[@]}"; do
  [ -d "$d/.git" ] || continue
  tag=$(git -C "$d" tag -l 'pre-loop-*' | sort | tail -1)
  [ -n "$tag" ] || { printf '  %-40s (untagged)\n' "$(basename "$d")"; continue; }
  n=$(git -C "$d" rev-list --count "$tag..HEAD" 2>/dev/null || echo '?')
  printf '  %-40s %-4s (roll back: git -C %s reset --hard %s)\n' \
    "$(basename "$d")" "$n" "$d" "$tag"
done
echo
echo "total cost:"
jq -s '[.[] | select(.type=="result") | .total_cost_usd] | add' raw.jsonl 2>/dev/null
