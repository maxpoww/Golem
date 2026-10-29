# golem-lane — Golem's update lane (updates/README.md has the whole story).
#
#   golem-lane run [--now] [--bump] [--base REF] [--no-publish]
#       The daily job. Once a week (PUBLISH_DAYS): take main (or REF), jump
#       to the next NixOS release when it is due, else move nixpkgs +
#       home-manager to their release branch's newest tested commit, BUILD
#       and BOOT every Golem system (the gate), put that version's heavy
#       pieces into its cache (a signed GitHub release of golem-cache), and
#       only then move `stable` to it — the branch every install follows.
#       Anything that fails stops the run before stable moves: no install
#       ever gets it. The other days it only gates main when main moved, so
#       a break is known before the week's publish. --now publishes today.
#   golem-lane release YY.MM [--push]
#       Prepare the jump to the next NixOS release by hand, on branch
#       release-YY.MM: move both inputs, build the gate, write what broke.
#       Never publishes. (The weekly run makes the jump by itself.)
#   golem-lane prune      keep the newest $KEEP version caches, delete the rest
#   golem-lane status     the last run, as JSON
#
# Runs as the maintainer (it pushes with their GitHub login). Configuration
# comes from the environment (updates/builder.nix sets it on the build
# machine); every default below is the dev box's.

set -euo pipefail

REPO_URL=${GOLEM_LANE_REPO_URL:-https://github.com/maxpoww/Golem.git}
CACHE_REPO=${GOLEM_LANE_CACHE_REPO:-maxpoww/golem-cache}
KEY=${GOLEM_LANE_KEY:-$HOME/.local/share/golem-lane/cache-key.sec}
STATE=${GOLEM_LANE_STATE:-$HOME/.local/state/golem-lane}
KEEP=${GOLEM_LANE_KEEP:-6}
BUMP_DAYS=${GOLEM_LANE_BUMP_DAYS:-7}
PUBLISH_DAYS=${GOLEM_LANE_PUBLISH_DAYS:-7}
RELEASE_WAIT_DAYS=${GOLEM_LANE_RELEASE_WAIT_DAYS:-28}
LIB=${GOLEM_LANE_LIB:-$(dirname "$(readlink -f "$0")")}
SYSTEM=x86_64-linux

TREE=$STATE/repo
STATUS=$STATE/status.json
NIXF=(--extra-experimental-features "nix-command flakes")
GIT_PUSH=(git -C "$TREE" -c credential.helper= -c "credential.helper=!gh auth git-credential")

mkdir -p "$STATE/logs" "$STATE/gcroots"
PHASE=prepare OK=true LOG=

say() { printf '%s golem-lane: %s\n' "$(date '+%F %T')" "$*" >&2; }

# One status file, rewritten whole at each phase: what the last run did.
status() {  # status <phase> <ok:true|false> <message> [extra json object]
  local tmp=$STATUS.tmp extra=${4:-}
  PHASE=$1 OK=$2
  [ -n "$extra" ] || extra='{}'
  jq -n --arg phase "$1" --argjson ok "$2" --arg msg "$3" --arg at "$(date -Is)" \
        --argjson extra "$extra" \
        '{at: $at, phase: $phase, ok: $ok, message: $msg} + $extra' > "$tmp"
  mv -f "$tmp" "$STATUS"
}

notify() {  # the maintainer's desktop, if they are logged in
  local bus
  bus=/run/user/$(id -u)/bus
  [ -S "$bus" ] || return 0
  DBUS_SESSION_BUS_ADDRESS=unix:path=$bus notify-send -a "Golem update lane" "$1" "$2" 2>/dev/null || true
}

fail() {  # fail <phase> <message>
  say "FAILED ($1): $2"
  status "$1" false "$2"
  notify "Golem update lane: $1 failed" "$2 — nothing was published. Log: $LOG"
  exit 1
}

# A command that dies under set -e never reaches fail(): without this the
# status went on reading ok at the phase the run died in (2026-10-28).
stopped() {  # the EXIT trap of a run: stopped <exit code>
  [ "$1" = 0 ] || [ "$OK" = false ] || {
    status "$PHASE" false "stopped (exit $1); journalctl -u golem-lane, log: $LOG"
    notify "Golem update lane: $PHASE stopped" "Exit $1. journalctl -u golem-lane, log: $LOG"
  }
}

# After a wake the timer starts a missed run at once, before the network is
# back (2026-10-28: "Could not resolve host: github.com"). Wait for the
# repository, up to 15 minutes, as golem-wait-online does for the installs.
online() {
  local i
  for i in $(seq 1 90); do
    GIT_TERMINAL_PROMPT=0 git ls-remote "$REPO_URL" HEAD >/dev/null 2>&1 && return 0
    if [ "$i" = 1 ]; then say "no network yet; waiting for $REPO_URL"; status prepare true "waiting for the network"; fi
    sleep 10
  done
  return 1
}

prepare_tree() {  # a clean checkout of $1 (default origin/main), detached
  if [ ! -d "$TREE/.git" ]; then
    say "cloning $REPO_URL"
    git clone -q "$REPO_URL" "$TREE"
  fi
  git -C "$TREE" fetch -q --prune origin '+refs/heads/*:refs/remotes/origin/*'
  # A local repository's branches too, as local/<branch> (GOLEM_LANE_LOCAL):
  # how a version is gated and cached before it is on GitHub at all.
  if [ -n "${GOLEM_LANE_LOCAL:-}" ]; then
    git -C "$TREE" fetch -q "$GOLEM_LANE_LOCAL" '+refs/heads/*:refs/remotes/local/*'
  fi
  git -C "$TREE" checkout -q -f --detach "${1:-origin/main}"
  git -C "$TREE" clean -q -fdx
}

flake() { printf 'git+file://%s' "$TREE"; }

# Weekly: nixpkgs and home-manager to the newest commit of their release
# branch (nixos-YY.MM is the CHANNEL branch: Hydra built and tested it).
bump() {
  local before after
  if grep -qE 'nixpkgs\.url = "github:NixOS/nixpkgs/[0-9a-f]{40}"' "$TREE/flake.nix"; then
    say "nixpkgs is pinned to a commit in flake.nix, not a release branch — not bumping"
    return 0
  fi
  before=$(jq -r '.nodes.nixpkgs.locked.rev' "$TREE/flake.lock")
  nix "${NIXF[@]}" flake update nixpkgs home-manager --flake "$(flake)" 2>&1 | tail -3 >&2
  git -C "$TREE" diff --quiet -- flake.lock && { say "nixpkgs and home-manager already newest"; return 0; }
  after=$(jq -r '.nodes.nixpkgs.locked.rev' "$TREE/flake.lock")
  git -C "$TREE" add flake.lock
  # The dock's Install list is made for one nixpkgs (system/home/
  # package-index.rev); the desktop matrix refuses it for any other.
  if [ "$after" != "$before" ]; then
    say "nixpkgs moved: refreshing the dock's package index (tools/package-index)"
    (cd "$TREE" && tools/package-index/refresh.sh) >> "$LOG" 2>&1 \
      || fail bump "the package index could not be refreshed for nixpkgs ${after:0:12}"
    git -C "$TREE" add system/home/package-index.tsv system/home/package-index.rev tools/package-index/dropped.txt
  fi
  git -C "$TREE" -c user.name="Golem update lane" commit -q -m "flake.lock: weekly upstream — nixpkgs ${before:0:12} → ${after:0:12}, home-manager

Moved by the update lane (updates/README.md): the newest tested commit of
both release branches, with the dock's package index made for it. Built for
every Golem system before publishing."
  BUMPED=1
  say "bumped nixpkgs ${before:0:12} → ${after:0:12}"
}

last_error() {  # the last real error line of the run's log, colours stripped
  sed -E 's/\x1b\[[0-9;]*[mK]//g' "$LOG" | grep -a -E '^ *error: ' \
    | grep -a -v -E 'error: (build of|Cannot build|[0-9]+ dependenc)' | tail -1 \
    | sed -E 's/^ *error: //' | cut -c1-240
}

checks() {  # every flake check, as build targets
  nix "${NIXF[@]}" eval --json "$(flake)#checks.$SYSTEM" --apply builtins.attrNames \
    | jq -r --arg f "$(flake)" --arg s "$SYSTEM" '.[] | "\($f)#checks.\($s).\(.)"'
}

# THE GATE: the flake's checks (the boot test among them) + every Golem
# system, built. A failure here is the whole point of the lane: it stops
# before anything is published. gate_try reports in GATE_ERR instead of
# stopping the run; its gc root is gcroots/<name> (default gate: the
# published version's closure, which the next build reuses).
gate_try() {
  local targets root=$STATE/gcroots/${1:-gate}
  GATE_ERR=
  say "gate: building every Golem system"
  if ! nix "${NIXF[@]}" build --keep-going -L --out-link "$root" \
        "$(flake)#packages.$SYSTEM.update-gate" >> "$LOG" 2>&1; then
    GATE_ERR="a Golem system does not build ($(grep -acE '^error: Cannot build' "$LOG" || true) failed builds): $(last_error)"
    return 1
  fi
  GATE_OUT=$(readlink -f "$root")
  [ -e "$GATE_OUT/." ] || { GATE_ERR="the gate built but its output is missing"; return 1; }
  mapfile -t targets < <(checks)
  say "gate: running ${#targets[@]} checks"
  if ! nix "${NIXF[@]}" build --keep-going -L --no-link "${targets[@]}" >> "$LOG" 2>&1; then
    GATE_ERR="a check fails: $(last_error)"
    return 1
  fi
}
gate() { gate_try "$@" || fail gate "$GATE_ERR"; }

report() {  # one line per system: its kernel
  local d k
  for d in "$GATE_OUT"/*; do
    k=$(readlink "$d/kernel" 2>/dev/null || true)
    k=${k%/*}; k=${k##*-linux-}
    printf '%s\t%s\n' "${d##*/}" "${k:-?}"
  done
}

# THE CACHE: the version's heavy pieces nobody else hosts, signed, as one
# release g-<rev12> of $CACHE_REPO, uploaded as a draft and made public only
# when complete, then read back until GitHub serves every file.
cache() {
  local rev=$1 tag=g-${1:0:12} work sel n notes f
  # A fresh directory per version: nix remembers what it saw in a binary
  # cache by its URL, and the placeholders below must never be remembered.
  rm -rf "$STATE/export"
  work=$STATE/export/${rev:0:12}; EXPORT_OUT=$work/out; mkdir -p "$EXPORT_OUT"
  if gh release view "$tag" --repo "$CACHE_REPO" --json isDraft --jq '.isDraft' 2>/dev/null | grep -qx false \
     && verify "$tag" quiet; then
    say "cache $tag already published and complete"
    return 0
  fi
  gh release delete "$tag" --repo "$CACHE_REPO" --yes --cleanup-tag >/dev/null 2>&1 || true

  nix "${NIXF[@]}" path-info -r --json --json-format 1 "$GATE_OUT" > "$work/closure.json"
  jq -r 'if type == "array" then .[].path else keys[] end' "$work/closure.json" \
    | sed 's|^/nix/store/||; s|-.*||' > "$work/hashes"
  # cache.nixos.org already has most of the closure; ask it about each path.
  # shellcheck disable=SC2016  # $c and $(…) belong to the inner sh
  xargs -P 48 -I{} sh -c 'c=$(curl -s -o /dev/null -w "%{http_code}" --retry 2 -I "https://cache.nixos.org/{}.narinfo"); [ "$c" = 200 ] || echo {}' \
    < "$work/hashes" > "$work/missing"
  # Whether nix would substitute each path at all is in its derivation
  # (allowSubstitutes): select.py uploads exactly the ones it would.
  jq -r --rawfile miss "$work/missing" '
      ($miss | split("\n") | map(select(length > 0) | {(.): true}) | add // {}) as $m
      | to_entries[] | select(.value != null)
      | select($m[.key | ltrimstr("/nix/store/") | split("-")[0]]) | .value.deriver // empty' \
      "$work/closure.json" | sort -u | while read -r f; do [ -e "$f" ] && echo "$f"; done > "$work/derivers"
  if [ -s "$work/derivers" ]; then
    xargs -a "$work/derivers" nix "${NIXF[@]}" derivation show > "$work/drvs.json" 2>> "$LOG" \
      || fail cache "reading the derivations failed: $(last_error)"
  else
    echo '{}' > "$work/drvs.json"
  fi
  sel=$(python3 "$LIB/select.py" "$work/closure.json" "$work/drvs.json" "$work/missing" \
          "$TREE/updates/lane/never-publish" "$work/chosen" "$EXPORT_OUT") \
    || fail cache "selecting the pieces failed (select.py exit $?)"
  say "cache: $sel"
  n=$(wc -l < "$work/chosen")
  [ "$n" -gt 0 ] || fail cache "nothing to upload — the selection is empty"
  # Second, independent check of the licence rule on the final list.
  if sed 's|^/nix/store/[a-z0-9]*-||' "$work/chosen" | grep -E -f <(grep -v -E '^\s*(#|$)' "$TREE/updates/lane/never-publish") >&2; then
    fail cache "a never-publish path is in the upload list"
  fi

  xargs -a "$work/chosen" nix "${NIXF[@]}" copy --no-recursive \
    --to "file://$EXPORT_OUT?compression=zstd&parallel-compression=true&secret-key=$KEY" >> "$LOG" 2>&1 \
    || fail cache "exporting the pieces failed: $(last_error)"
  # The placeholders only let nix accept the pieces; they never ship.
  while read -r f; do rm -f "$EXPORT_OUT/$f"; done < "$EXPORT_OUT/placeholders.txt"
  rm -f "$EXPORT_OUT/placeholders.txt"
  [ "$(find "$EXPORT_OUT" -maxdepth 1 -name '*.narinfo' | wc -l)" = "$n" ] \
    || fail cache "the export holds $(find "$EXPORT_OUT" -maxdepth 1 -name '*.narinfo' | wc -l) pieces, not the $n chosen"
  # GitHub release files sit in one flat list: the NARs move up next to the
  # narinfos, whose URL line says so (the signature covers the content, not
  # where it is stored).
  mv "$EXPORT_OUT/nar/"* "$EXPORT_OUT/"
  rm -rf "$EXPORT_OUT/nar" "$EXPORT_OUT/log" "$EXPORT_OUT/realisations"
  sed -i 's|^URL: nar/|URL: |' "$EXPORT_OUT/"*.narinfo

  notes="Cache of Golem $rev ($n pieces, built and signed by the update lane).

Kernel of every Golem system in this version:

$(report | sed 's/^/    /')"
  gh release create "$tag" --repo "$CACHE_REPO" --draft --target main \
     --title "Golem ${rev:0:12}" --notes "$notes" \
     >/dev/null || fail cache "creating release $tag failed"
  find "$EXPORT_OUT" -maxdepth 1 -type f -print0 \
    | xargs -0 -n 40 gh release upload "$tag" --repo "$CACHE_REPO" --clobber >> "$LOG" 2>&1 \
    || fail cache "uploading to release $tag failed"
  gh release edit "$tag" --repo "$CACHE_REPO" --draft=false >/dev/null || fail cache "publishing release $tag failed"
  verify "$tag" || fail cache "release $tag is not served completely after 10 minutes"
}

# Every file of a release, read back from the public URL (GitHub may answer
# 404 for a moment after an upload), and one piece proven to carry a valid
# signature by landing it in a throwaway store that checks signatures.
verify() {
  local tag=$1 quiet=${2:-} url names f code tries pub one tmp
  url=https://github.com/$CACHE_REPO/releases/download/$tag
  mapfile -t names < <(gh release view "$tag" --repo "$CACHE_REPO" --json assets --jq '.assets[].name')
  [ "${#names[@]}" -gt 1 ] || return 1
  for f in "${names[@]}"; do
    for tries in $(seq 1 60); do
      code=$(curl -s -o /dev/null -w '%{http_code}' -I -L "$url/$f")
      [ "$code" = 200 ] && break
      [ -n "$quiet" ] && return 1
      sleep 10
    done
    [ "$code" = 200 ] || { say "verify: $f still $code after $tries tries"; return 1; }
  done
  [ -n "$quiet" ] && return 0
  pub=$(nix "${NIXF[@]}" key convert-secret-to-public < "$KEY")
  one=$(for f in "$EXPORT_OUT/"*.narinfo; do
          grep -q '^References: *$' "$f" || continue
          printf '%s %s\n' "$(sed -n 's/^FileSize: //p' "$f")" "$(sed -n 's/^StorePath: //p' "$f")"
        done 2>/dev/null | sort -n | head -1 | cut -d' ' -f2)
  [ -n "$one" ] || { say "verify: every file of $tag is served (no reference-free piece to prove the key on)"; return 0; }
  tmp=$(mktemp -d)
  if ! NIX_REMOTE='' nix "${NIXF[@]}" copy --from "$url" --to "local?root=$tmp" \
        --option trusted-public-keys "$pub" "$one" >> "$LOG" 2>&1; then
    chmod -R u+w "$tmp" 2>/dev/null || true; rm -rf "$tmp"
    say "verify: $one did not land from $url with the lane's key"
    return 1
  fi
  chmod -R u+w "$tmp" 2>/dev/null || true; rm -rf "$tmp"
  say "verify: every file of $tag is served, and $one checks out against the key"
}

# PUBLISH: main gets the version first if it is not on main yet (the weekly
# bump, or a --base branch), then stable moves. Both are plain pushes: git
# refuses anything but a fast-forward, so the lane can never rewrite what is
# there, and stable never holds a commit main lacks. If main moved during
# the run, nothing is pushed: the next run starts again from the new main.
publish() {
  local rev=$1
  if ! git -C "$TREE" merge-base --is-ancestor "$rev" origin/main \
     && ! "${GIT_PUSH[@]}" push -q origin "$rev:refs/heads/main" >> "$LOG" 2>&1; then
    say "main moved during the run — not publishing; the next run builds the new main"
    status publish true "main moved during the run; retrying next run"
    exit 0
  fi
  "${GIT_PUSH[@]}" push -q origin "$rev:refs/heads/stable" >> "$LOG" 2>&1 \
    || fail publish "stable could not move to ${rev:0:12} (not a fast-forward?)"
  if [ "${BUMPED:-0}" = 1 ]; then date +%s > "$STATE/last-bump"; fi
  date +%s > "$STATE/last-publish"
}

prune() {
  local stable keep tags t name draft
  stable=$(git -C "$TREE" rev-parse -q --verify origin/stable 2>/dev/null || true)
  keep=$KEEP
  mapfile -t tags < <(gh release list --repo "$CACHE_REPO" --limit 200 --json tagName,isDraft,createdAt \
    --jq 'sort_by(.createdAt) | reverse | .[] | select(.tagName | startswith("g-")) | "\(.tagName) \(.isDraft)"')
  for t in "${tags[@]}"; do
    read -r name draft <<< "$t"
    if [ "$draft" = false ] && [ "$keep" -gt 0 ]; then keep=$((keep - 1)); continue; fi
    [ -n "$stable" ] && [ "$name" = "g-${stable:0:12}" ] && continue
    say "prune: deleting $name"
    gh release delete "$name" --repo "$CACHE_REPO" --yes --cleanup-tag >/dev/null || true
  done
}

# NixOS ships YY.05 (supported to Dec 31) and YY.11 (to Jun 30 of the next
# year).
current_release() {  # the release flake.nix follows, e.g. 26.05
  sed -n 's|.*home-manager/release-\([0-9][0-9]\.[0-9][0-9]\).*|\1|p' "$TREE/flake.nix" | head -1
}
next_release() {  # next_release YY.MM: "<next> <end of YY.MM>"
  case "$1" in
    *.05) echo "${1%.05}.11 20${1%.05}-12-31" ;;
    *.11) echo "$(( ${1%.11} + 1 )).05 20$(( ${1%.11} + 1 ))-06-30" ;;
    *) return 1 ;;
  esac
}

# The calendar: the lane notes the day it first sees the next release
# branch (release_due counts from it) and says once a week where things are.
calendar() {
  local cur next eol left
  cur=$(current_release)
  [ -n "$cur" ] || return 0
  read -r next eol < <(next_release "$cur") || return 0
  left=$(( ( $(date -d "$eol" +%s) - $(date +%s) ) / 86400 ))
  if git ls-remote --exit-code -q https://github.com/NixOS/nixpkgs "refs/heads/nixos-$next" >/dev/null 2>&1; then
    [ -s "$STATE/release-seen-$next" ] || date +%s > "$STATE/release-seen-$next"
    CALENDAR="NixOS $next is out; Golem is on $cur, supported $left more days. The lane moves Golem to $next by itself on $(date -d "@$(( $(cat "$STATE/release-seen-$next") + RELEASE_WAIT_DAYS * 86400 ))" +%F) or later, if every system builds and boots on it."
  elif [ "$left" -lt 31 ]; then
    CALENDAR="NixOS $cur stops getting fixes in $left days ($eol) and $next is not out yet."
  fi
  if [ -n "${CALENDAR:-}" ] && [ ! -e "$STATE/calendar-$next-$(date +%G-%V)" ]; then
    : > "$STATE/calendar-$next-$(date +%G-%V)"   # once a week
    notify "Golem: NixOS $next" "$CALENDAR"
  fi
}

# THE RELEASE JUMP happens by itself (Max, 2026-10-29: Golem's users never
# think about NixOS versions, and neither should the maintainer). NixOS
# creates nixos-YY.MM about two weeks before it announces the release; the
# lane jumps RELEASE_WAIT_DAYS (28) after it first saw that branch, so the
# release has had its first fixes, or at once when the current release ends
# within 14 days. The same gate decides: every system builds and boots on
# it, or the week's update goes out on the current release and the
# maintainer is told what broke. Prints the release to jump to.
release_due() {
  local cur next eol seen
  cur=$(current_release)
  [ -n "$cur" ] || return 1
  read -r next eol < <(next_release "$cur") || return 1
  [ -s "$STATE/release-seen-$next" ] || return 1
  seen=$(cat "$STATE/release-seen-$next")
  if [ $(( $(date +%s) - seen )) -lt $(( RELEASE_WAIT_DAYS * 86400 )) ] \
     && [ $(( $(date -d "$eol" +%s) - $(date +%s) )) -ge $(( 14 * 86400 )) ]; then
    return 1
  fi
  git ls-remote --exit-code -q https://github.com/nix-community/home-manager "refs/heads/release-$next" >/dev/null 2>&1 || return 1
  echo "$next"
}

# Move the tree to NixOS <to> and its home-manager, with the dock's package
# index made for it, as one commit. Never touches system.stateVersion.
move_release() {  # move_release <to>
  local to=$1 from
  from=$(current_release)
  sed -i "s|NixOS/nixpkgs/nixos-$from|NixOS/nixpkgs/nixos-$to|; s|home-manager/release-$from|home-manager/release-$to|; s|NixOS's $from channel branch|NixOS's $to channel branch|" "$TREE/flake.nix"
  nix "${NIXF[@]}" flake update nixpkgs home-manager --flake "$(flake)" >> "$LOG" 2>&1 || return 1
  (cd "$TREE" && tools/package-index/refresh.sh) >> "$LOG" 2>&1 || return 1
  git -C "$TREE" add flake.nix flake.lock system/home/package-index.tsv system/home/package-index.rev tools/package-index/dropped.txt
  git -C "$TREE" -c user.name="Golem update lane" commit -q -m "flake: NixOS $from → $to

Moved by the update lane (updates/README.md, the release jump): NixOS $to
and home-manager release-$to, with the dock's package index made for it.
Built and booted for every Golem system before publishing."
}

cmd_run() {
  local base="" publish_it=1 force_bump=0 now_flag=0 rev stable due last pub_due next_pub to from
  while [ $# -gt 0 ]; do
    case "$1" in
      --now) now_flag=1 ;;
      --bump) force_bump=1 ;;
      --base) base=$2; shift ;;
      --no-publish) publish_it=0 ;;
      *) echo "golem-lane run: unknown argument $1" >&2; exit 2 ;;
    esac
    shift
  done
  LOG=$STATE/logs/$(date +%F-%H%M%S).log
  find "$STATE/logs" -name '*.log' -mtime +30 -delete 2>/dev/null || true
  exec 7>"$STATE/lock"
  flock -n 7 || { say "another run is going on"; exit 0; }
  trap 'stopped $?' EXIT
  trap 'exit 143' TERM INT   # a stop or a shutdown mid-run goes through stopped() too

  online || fail prepare "no network for 15 minutes ($REPO_URL unreachable)"
  status prepare true "fetching"
  prepare_tree "${base:-origin/main}"
  [ -n "$base" ] && say "base: $base ($(git -C "$TREE" rev-parse --short=12 HEAD))"
  calendar || true

  # Once a week, not every day main moves: one update a week per machine
  # (one download, one boot entry, one store version), and the week's NixOS
  # fixes in it. Urgent: --now.
  last=$(cat "$STATE/last-publish" 2>/dev/null || echo 0)
  pub_due=$(( $(date +%s) - last >= PUBLISH_DAYS * 86400 ))
  next_pub=$(date -d "@$(( last + PUBLISH_DAYS * 86400 ))" +%F)
  stable=$(git -C "$TREE" rev-parse -q --verify origin/stable 2>/dev/null || true)
  if [ "$pub_due" = 0 ] && [ "$now_flag" = 0 ] && [ "$force_bump" = 0 ] && [ -z "$base" ]; then
    rev=$(git -C "$TREE" rev-parse HEAD)
    if [ "$rev" = "$stable" ] || [ "$rev" = "$(cat "$STATE/last-gated" 2>/dev/null)" ]; then
      say "nothing new to test; the next update goes out on $next_pub"
      status "done" true "nothing new to test; next publish $next_pub"
      exit 0
    fi
    # main moved: build and boot it now, so a break is known days before
    # the publish needs it.
    status gate true "testing main ${rev:0:12} (publishes on $next_pub)"
    gate main
    echo "$rev" > "$STATE/last-gated"
    say "main ${rev:0:12} builds and boots; it goes out on $next_pub"
    status "done" true "main ${rev:0:12} builds and boots; it goes out with the update of $next_pub"
    exit 0
  fi

  BUMPED=0 JUMPED='' from=$(current_release)
  if [ -z "$base" ] && to=$(release_due); then
    status release true "moving Golem to NixOS $to"
    say "release: NixOS $to is due — trying it"
    if move_release "$to" && gate_try; then
      JUMPED=$to BUMPED=1
      say "release: every Golem system builds and boots on NixOS $to"
    else
      say "release: NixOS $to is not ready for Golem yet: ${GATE_ERR:-moving the inputs failed}"
      notify "Golem: NixOS $to not ready yet" "${GATE_ERR:-moving the inputs failed}. This week's update goes out on $from; the lane tries $to again next week. Log: $LOG"
      prepare_tree origin/main
    fi
  fi
  last=$(cat "$STATE/last-bump" 2>/dev/null || echo 0)
  due=$(( $(date +%s) - last >= BUMP_DAYS * 86400 ))
  if [ -z "$JUMPED" ] && { [ "$force_bump" = 1 ] || [ "$due" = 1 ]; }; then
    status bump true "moving nixpkgs and home-manager"
    bump
  fi

  rev=$(git -C "$TREE" rev-parse HEAD)
  if [ "$rev" = "$stable" ]; then
    say "stable is already ${rev:0:12} — nothing new"
    status "done" true "nothing new: stable is ${rev:0:12}"
    exit 0
  fi
  if [ -n "$stable" ] && ! git -C "$TREE" merge-base --is-ancestor "$stable" "$rev"; then
    fail prepare "${rev:0:12} does not contain stable ${stable:0:12} — stable only ever moves forward"
  fi

  if [ -z "$JUMPED" ]; then
    status gate true "building ${rev:0:12}"
    gate
  fi
  say "gate: green. Kernels:"; report | sed 's/^/  /' >&2

  status cache true "uploading the cache of ${rev:0:12}"
  cache "$rev"

  if [ "$publish_it" = 0 ]; then
    status cached true "${rev:0:12} built, tested and cached; NOT published (--no-publish)"
    say "--no-publish: stopping before main/stable move"
    return 0
  fi
  status publish true "moving stable to ${rev:0:12}"
  publish "$rev"
  prune || true
  status "done" true "published ${rev:0:12}: stable moved, installs take it in their wave" \
    "$(report | jq -R -s 'split("\n") | map(select(length > 0) | split("\t") | {(.[0]): .[1]}) | add | {kernels: .}')"
  if [ -n "$JUMPED" ]; then
    notify "Golem moved to NixOS $JUMPED" "${rev:0:12} built and booted for every Golem system; the lab takes it tonight, installs over the next ${GOLEM_LANE_WAVES:-7} days."
  else
    notify "Golem ${rev:0:12} published" "Built and booted for every Golem system; installs take it over the next ${GOLEM_LANE_WAVES:-7} days."
  fi
}

cmd_release() {
  local to=${1:-} push=${2:-} from branch
  [[ "$to" =~ ^[0-9][0-9]\.(05|11)$ ]] || { echo "usage: golem-lane release YY.MM [--push]" >&2; exit 2; }
  LOG=$STATE/logs/release-$to-$(date +%F-%H%M%S).log
  exec 7>"$STATE/lock"
  flock -n 7 || { say "another run is going on"; exit 1; }
  git ls-remote --exit-code -q https://github.com/NixOS/nixpkgs "refs/heads/nixos-$to" >/dev/null \
    || { say "NixOS $to has no release branch yet"; exit 1; }
  prepare_tree origin/main
  branch=release-$to
  git -C "$TREE" checkout -q -B "$branch"
  move_release "$to" || { say "release $to: moving the inputs failed; log: $LOG"; exit 1; }
  say "release $to: building the gate on $branch — this is the slow one"
  if nix "${NIXF[@]}" build --keep-going -L --no-link "$(flake)#packages.$SYSTEM.update-gate" >> "$LOG" 2>&1; then
    say "release $to: every Golem system builds. Next: a lab round on $branch (RUNBOOK.md), then merge to main."
  else
    say "release $to: some systems do not build. The errors:"
    grep -a -E '^ *error:' "$LOG" | sort -u | head -20 >&2 || true
  fi
  [ "$push" = --push ] && "${GIT_PUSH[@]}" push -q -u origin "$branch" && say "pushed $branch"
  say "log: $LOG"
}

case "${1:-}" in
  run) shift; cmd_run "$@" ;;
  release) shift; cmd_release "$@" ;;
  prune) prepare_tree origin/main; prune ;;
  status) cat "$STATUS" 2>/dev/null || echo '{}' ;;
  *) echo "usage: golem-lane run [--now] [--bump] [--base REF] [--no-publish] | release YY.MM [--push] | prune | status" >&2; exit 2 ;;
esac
