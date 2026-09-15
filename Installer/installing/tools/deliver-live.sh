#!/usr/bin/env bash
# deliver-live — the #67 throttle pointed at a RUNNING machine.
#
# Same mechanics as deliver.sh (rate-limit under saturation, one store
# path at a time, ask the target DATABASE what is missing — #85), minus
# the medium-era /mnt mounting: the store is the live root's own. Born
# 2026-09-15 delivering gen 3 (quiet grub #89 + lid quirk #90) to the
# comodore over the rtl8187 — the dongle #67 first convicted.
set -uo pipefail

IP=${IP:-192.168.1.129}
HOST=root@$IP
TOP=${TOP:?set TOP to the toplevel store path to deliver}
PV=${PV:-$(command -v pv 2>/dev/null)}
if [[ -z "${PV:-}" || ! -x "$PV" ]]; then
  PV=$(nix build --no-link --print-out-paths nixpkgs#pv 2>/dev/null)/bin/pv
fi
[[ -x "$PV" ]] || { echo "no pv — the throttle is the point (#67)" >&2; exit 1; }

RATE_START=${RATE_START:-400}   # KB/s
RATE_MIN=48
RATE_MAX=900
PAUSE=${PAUSE:-2}
UP_AFTER=20

SSHOPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=10 -o ServerAliveInterval=15 -o ServerAliveCountMax=4"
HERE=$(dirname "$(readlink -f "$0")")
LOG=$HERE/deliver-live.log
STATE=$HERE/deliver-live.state

rate=$RATE_START
wins=0

say() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG"; }

wait_for_host() {
  local n=0
  while ! ping -c1 -W2 "$IP" >/dev/null 2>&1; do
    n=$((n+1)); sleep 10
    (( n % 6 == 0 )) && say "waiting for the comodore ($(( n / 6 )) min)..."
  done
  for _ in $(seq 1 24); do
    ssh $SSHOPTS "$HOST" 'echo ok' >/dev/null 2>&1 && return 0
    sleep 5
  done
  return 1
}

deliver_one() {   # $1 = store path
  nix-store --export "$1" 2>/dev/null \
    | "$PV" -q -L "${rate}k" \
    | ssh $SSHOPTS "$HOST" "nix-store --import >/dev/null" 2>>"$LOG"
  return ${PIPESTATUS[2]}
}

say "=== live delivery starting: $TOP -> $HOST"
mapfile -t ALL < <(nix-store -qR "$TOP")   # topological
TOTAL_B=$(nix path-info -S "$TOP" | awk '{print $2}')
say "    closure: ${#ALL[@]} paths / $(( TOTAL_B / 1024 / 1024 )) MiB, rate ${rate} KB/s"

round=0
while :; do
  round=$((round+1))
  wait_for_host || { say "host up but no ssh — retrying"; sleep 30; continue; }

  # the DB, not the filesystem (#85)
  ssh $SSHOPTS "$HOST" \
    "nix --extra-experimental-features nix-command path-info --all" \
    2>/dev/null | sort > "$HERE/.present-live" || { say "could not read target db — retrying"; sleep 30; continue; }

  declare -A present=()
  while IFS= read -r p; do [[ -n "$p" ]] && present["$p"]=1; done < "$HERE/.present-live"
  missing=()
  for p in "${ALL[@]}"; do [[ -n "${present[$p]:-}" ]] || missing+=("$p"); done

  if (( ${#missing[@]} == 0 )); then
    say "ALL ${#ALL[@]} PATHS PRESENT — closure delivered (round $round)."
    echo "DONE" > "$STATE"
    break
  fi

  done_n=$(( ${#ALL[@]} - ${#missing[@]} ))
  say "round $round: $done_n/${#ALL[@]} present, ${#missing[@]} to go (rate ${rate} KB/s)"

  n=0
  for p in "${missing[@]}"; do
    n=$((n+1))
    if deliver_one "$p"; then
      wins=$((wins+1))
      if (( wins >= UP_AFTER && rate < RATE_MAX )); then
        rate=$(( rate * 5 / 4 )); (( rate > RATE_MAX )) && rate=$RATE_MAX
        wins=0; say "  link steady — easing up to ${rate} KB/s"
      fi
      (( n % 25 == 0 )) && say "  …$n/${#missing[@]} this round"
      echo "$(( done_n + n ))/${#ALL[@]} rate=${rate}" > "$STATE"
      sleep "$PAUSE"
    else
      wins=0
      if (( rate > RATE_MIN )); then
        rate=$(( rate / 2 )); (( rate < RATE_MIN )) && rate=$RATE_MIN
        say "  drop at $n/${#missing[@]} — backing off to ${rate} KB/s"
      else
        say "  drop at $n/${#missing[@]} — at the floor (${rate} KB/s)"
      fi
      break
    fi
  done
done
say "=== done."
