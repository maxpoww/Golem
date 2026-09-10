#!/usr/bin/env bash
# aging-check.sh — assert the DockMenu aging invariants (INVARIANTS.md)
# on a live machine. Exit 0 = all hold; non-zero = findings (one line
# each on stdout, prefixed FAIL/WARN). Run locally or:
#   ssh user@host 'bash -s' < aging-check.sh
set -uo pipefail

D="${XDG_DATA_HOME:-$HOME/.local/share}/waverunner"
C="${XDG_CONFIG_HOME:-$HOME/.config}/waverunner"
rc=0
fail() { echo "FAIL $*"; rc=1; }
warn() { echo "WARN $*"; }

# S3: no tmp leftovers
n=$(find "$D" "$C" -maxdepth 1 -name "*.tmp" 2>/dev/null | wc -l)
[ "$n" -eq 0 ] || fail "S3: $n *.tmp leftovers in state dirs"

# S2: corrupt rescues are findings to collect, not errors — surface them
n=$(find "$D" "$C" -maxdepth 1 -name "*.corrupt-*" 2>/dev/null | wc -l)
[ "$n" -eq 0 ] || warn "S2: $n corrupt-store rescue(s) present — collect + investigate"

# S5: bounded stores (caps with headroom; numbers from AUDIT.md)
check_size() { # file, max bytes, tag
  [ -f "$D/$1" ] || return 0
  s=$(wc -c < "$D/$1")
  [ "$s" -le "$2" ] || fail "S5: $1 is $s bytes (revisit threshold $2) — $3"
}
check_size clipboard-history.json 25000000 "cap 200 entries x 100k"
check_size notif-history.json 2000000 "cap 500 cards (#50)"
check_size apps-order.json 100000 "dead-id watch"
check_size usage.json 100000 "dead-id watch"

# S6: pending state only while installing
if [ -f "$D/pending-installs.json" ]; then
  act=$(systemctl is-active waverunner-apply.service 2>/dev/null || echo unknown)
  [ "$act" = "activating" ] || warn "S6: pending-installs.json present with helper $act — stuck tile?"
fi

# S4: orphaned pending icons (sidecars without the pending file)
if [ ! -f "$D/pending-installs.json" ]; then
  n=$(find "$D" -maxdepth 1 -name "pending-icon-*.rgba" 2>/dev/null | wc -l)
  [ "$n" -eq 0 ] || fail "S4: $n orphaned pending-icon sidecars with no pending install"
fi

# S4: notif image orphan ratio (rough: files vs history size). After #50
# the sweep keeps these matched; a big divergence = the sweep regressed.
if [ -d "$D/notif-images" ] && [ -f "$D/notif-history.json" ]; then
  imgs=$(find "$D/notif-images" -type f | wc -l)
  hist=$(wc -c < "$D/notif-history.json")
  # >1 image per 150 bytes of history is impossible for referenced-only files
  if [ "$imgs" -gt $(( hist / 150 + 20 )) ]; then
    fail "S4: notif-images has $imgs files vs ${hist}B history — orphans accumulating"
  fi
fi

# P1-adjacent: daemon alive + socket responsive
if command -v waverunner-ctl >/dev/null 2>&1; then
  if ! timeout 5 waverunner-ctl show >/dev/null 2>&1; then
    fail "daemon control socket unresponsive"
  else
    timeout 5 waverunner-ctl hide >/dev/null 2>&1
  fi
fi

# S-perms (#55): state dirs must be owner-only once the #55 build is live.
for d in "$D" "$C"; do
  [ -d "$d" ] || continue
  mode=$(stat -c %a "$d")
  [ "$mode" = "700" ] || warn "#55: $d is $mode (0700 expected once the #55 daemon has run)"
done

[ "$rc" -eq 0 ] && echo "OK: all machine-checkable invariants hold"
exit "$rc"
