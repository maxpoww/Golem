#!/usr/bin/env bash
# Overnight closure delivery to the comodore, over the USB wifi dongle.
#
# WHY THIS SHAPE (finding #67): a single `nix copy` of the whole ~2.95 GiB
# closure killed this machine's rtl8187 twice — the transfer stalls, the
# link throws "Broken pipe", and the box drops off the network entirely
# until someone power-cycles it. The measured pathology was ~25 KB/s
# SUSTAINED long before the drop, i.e. the link was collapsing under load,
# not merely slow. So this script does two things the plain copy didn't:
#
#   1. RATE-LIMITS the stream (pv -L) so the dongle is never saturated,
#      with automatic backoff on failure and slow recovery on success.
#      Saturation is the thing that kills it; a polite trickle may not.
#   2. Delivers ONE STORE PATH AT A TIME and recomputes what is missing
#      from the target every round, so a drop costs one path, never the
#      transfer. Every path that lands stays landed.
#
# It waits the machine out whenever it disappears, re-mounts the target
# root if a reboot happened, and grinds until the closure is complete.
# If the host stays gone it says so loudly — that is #67's death, and it
# needs Max's hands on the power button.
set -uo pipefail

IP=${IP:-192.168.1.129}
HOST=root@$IP
TOP=${TOP:?set TOP to the toplevel store path to deliver}
MNT=/mnt
# pv is the throttle — resolve it rather than pinning a store path, which
# a garbage collection would take out from under this script.
PV=${PV:-$(command -v pv 2>/dev/null)}
if [[ -z "${PV:-}" || ! -x "$PV" ]]; then
  PV=$(nix build --no-link --print-out-paths nixpkgs#pv 2>/dev/null)/bin/pv
fi
[[ -x "$PV" ]] || { echo "no pv available — it is the throttle, and the throttle is the point (#67)" >&2; exit 1; }

RATE_START=${RATE_START:-400}   # KB/s
RATE_MIN=48
RATE_MAX=900
PAUSE=${PAUSE:-2}               # seconds between paths — let the dongle breathe
UP_AFTER=20                     # consecutive wins before easing the rate back up

SSHOPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=10 -o ServerAliveInterval=15 -o ServerAliveCountMax=4"
HERE=$(dirname "$(readlink -f "$0")")
LOG=$HERE/deliver.log
STATE=$HERE/deliver.state

rate=$RATE_START
wins=0

say() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG"; }

wait_for_host() {
  local n=0 mins
  while ! ping -c1 -W2 "$IP" >/dev/null 2>&1; do
    n=$((n+1)); sleep 10
    mins=$(( n / 6 ))
    if (( n % 6 == 0 )); then
      if (( mins >= 15 )); then
        say "!! comodore GONE for ${mins} min — this is #67's death. It needs a PHYSICAL POWER-CYCLE; I keep waiting."
      else
        say "waiting for the comodore (${mins} min)..."
      fi
    fi
  done
  for _ in $(seq 1 24); do
    ssh $SSHOPTS "$HOST" 'echo ok' >/dev/null 2>&1 && return 0
    sleep 5
  done
  return 1
}

# The root the engine prepared, found by LABEL rather than by device name:
# a BIOS GPT install is ESP + BIOS-boot + swap + root, and which number
# "root" lands on is the engine's business, not this script's.
ensure_mounted() {
  ssh $SSHOPTS "$HOST" '
    mountpoint -q /mnt && { echo MOUNTED; exit 0; }
    mkdir -p /mnt
    if mount /dev/disk/by-label/golem /mnt 2>/dev/null; then echo MOUNTED; else echo NOMOUNT; fi
  ' 2>/dev/null | tail -1
}

deliver_one() {   # $1 = store path
  local p=$1 sz
  sz=$(nix path-info -S "$p" 2>/dev/null | awk '{print $2}')
  nix-store --export "$p" 2>/dev/null \
    | "$PV" -q -L "${rate}k" \
    | ssh $SSHOPTS "$HOST" "nix-store --store $MNT --import >/dev/null" 2>>"$LOG"
  return ${PIPESTATUS[2]}
}

say "=== delivery starting: $TOP"
say "    rate ${rate} KB/s, one path at a time, ${PAUSE}s between paths"
mapfile -t ALL < <(nix-store -qR "$TOP")   # topological: references before referrers
TOTAL_B=$(nix path-info -S "$TOP" | awk '{print $2}')
say "    closure: ${#ALL[@]} paths / $(( TOTAL_B / 1024 / 1024 )) MiB"

round=0
while :; do
  round=$((round+1))
  wait_for_host || { say "host up but no ssh — retrying"; sleep 30; continue; }
  [[ "$(ensure_mounted)" == MOUNTED ]] || { say "could not mount LABEL=golem at /mnt — retrying"; sleep 60; continue; }

  # ASK THE DB, NOT THE FILESYSTEM. The last death left a truncated
  # nix-manual sitting in /mnt/nix/store that the database had never
  # registered — an `[ -e ]` test calls that path "present", the install
  # then activates against a path Nix does not know, and the failure
  # lands at the very end. `path-info --all` lists only VALID paths, so
  # a half-written path is correctly seen as missing and re-sent.
  ssh $SSHOPTS "$HOST" \
    "nix --extra-experimental-features nix-command --store $MNT path-info --all" \
    2>/dev/null | sort > "$HERE/.present" || { say "could not read the target db — retrying"; sleep 30; continue; }

  # Walk ALL in its original order so `missing` stays TOPOLOGICAL —
  # nix-store --import refuses a path whose references aren't there yet,
  # so sorting this set would break the very first big path.
  declare -A present=()
  while IFS= read -r p; do [[ -n "$p" ]] && present["$p"]=1; done < "$HERE/.present"
  missing=()
  for p in "${ALL[@]}"; do [[ -n "${present[$p]:-}" ]] || missing+=("$p"); done

  if (( ${#missing[@]} == 0 )); then
    say "ALL ${#ALL[@]} PATHS PRESENT — closure delivered (round $round). Ready to write GRUB."
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
        wins=0; say "  link steady — easing rate up to ${rate} KB/s"
      fi
      (( n % 25 == 0 )) && say "  …$n/${#missing[@]} this round ($(basename "$p" | cut -c34-))"
      echo "$(( done_n + n ))/${#ALL[@]} rate=${rate}" > "$STATE"
      sleep "$PAUSE"
    else
      wins=0
      if (( rate > RATE_MIN )); then
        rate=$(( rate / 2 )); (( rate < RATE_MIN )) && rate=$RATE_MIN
        say "  drop at $n/${#missing[@]} — backing off to ${rate} KB/s"
      else
        say "  drop at $n/${#missing[@]} — already at the floor (${rate} KB/s)"
      fi
      break   # back to the outer loop: wait the machine out, recompute, resume
    fi
  done
done

say "=== done."
