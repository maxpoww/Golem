#!/usr/bin/env bash
# loop-guard.sh — PreToolUse hook for the autonomous loop.
#
# The loop runs with bypassPermissions so it can actually work: read any tree,
# run nix, run cargo, run gradlew, commit. The one thing it must NOT do is act
# outside this machine, because those actions run under Max's identity, are
# public, and are not reversible by the tags the run is protected with.
#
# Claude Code's Bash(...) allow/deny patterns are prefix matches and get
# confused by compound commands — `git add x && git commit` did not match
# `Bash(git *)` in the 2026-08-31 run, which is half of why that loop could
# barely commit. This hook reads the whole command string instead, so `a && b`
# and heredocs are seen for what they are.
#
# exit 0 = allow, exit 2 = block (stderr goes back to the model as the reason).

set -uo pipefail

CMD="$(jq -r '.tool_input.command // empty' 2>/dev/null)"
[ -z "$CMD" ] && exit 0

block() {
  echo "BLOCKED by loop-guard: $1" >&2
  echo "This run is local-only: edit, build, test and commit freely in any of" >&2
  echo "the six trees, but nothing leaves this machine. Do the local half of" >&2
  echo "the item, then mark the outward half '- [?]' and say so in NOTES.md." >&2
  exit 2
}

# --- outward-facing: publishes under Max's identity, not reversible by tag ---
grep -qE '(^|[;&|(]|\s)git\s+(.*\s)?push(\s|$)'         <<<"$CMD" && block "git push"
grep -qE '(^|[;&|(]|\s)gh\s+(pr|release|repo|api|gist)' <<<"$CMD" && block "gh (creates or mutates something on GitHub)"
grep -qE '(^|[;&|(]|\s)(fastlane|supply)(\s|$)'         <<<"$CMD" && block "fastlane / Play Store submission"
grep -qE '(^|[;&|(]|\s)(netlify|vercel|surge|wrangler)' <<<"$CMD" && block "site deploy"
grep -qE '(^|[;&|(]|\s)(scp|rsync)\s.*:'                <<<"$CMD" && block "remote file copy"
grep -qE 'cachix\s+push|nix\s+copy\s+.*--to|nix-copy-closure' <<<"$CMD" && block "pushing to a remote nix store"
grep -qE 'curl\s+.*(-X\s*(POST|PUT|DELETE|PATCH)|--upload-file|-T\s)' <<<"$CMD" && block "HTTP write request"
grep -qE '(indexnow|deploy|publish)[a-z-]*\.(sh|py|js)'  <<<"$CMD" && block "deploy/publish script"

# --- protect the rollback path this run depends on -------------------------
grep -qE 'git\s+(.*\s)?tag\s+(-d|--delete)'   <<<"$CMD" && block "deleting a git tag (the pre-loop tags are the rollback path)"
grep -qE 'git\s+(.*\s)?reflog\s+expire'       <<<"$CMD" && block "expiring the reflog"
grep -qE 'nix-collect-garbage|nix\s+store\s+gc' <<<"$CMD" && block "nix GC (would evict the warm ISO/VM build this run was prepared with)"

# --- blast radius ----------------------------------------------------------
grep -qE 'rm\s+(-[a-zA-Z]*\s+)*-?[a-zA-Z]*[rf][a-zA-Z]*\s+(/|~|\$HOME)\s*($|[;&|])' <<<"$CMD" \
  && block "recursive delete of a top-level directory"

exit 0
