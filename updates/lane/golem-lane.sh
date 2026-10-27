# golem-lane — Golem's update lane (updates/README.md has the whole story).
#
#   golem-lane run [--bump] [--base REF] [--no-publish]
#       The daily job. Take main (or REF), move nixpkgs + home-manager to
#       their release branch's newest tested commit once a week, BUILD every
#       Golem system (the gate), put that version's heavy pieces into its
#       cache (a signed GitHub release of golem-cache), and only then move
#       `stable` to it — the branch every install follows. Anything that fails
#       stops the run before stable moves: no install ever gets it.
#   golem-lane release YY.MM [--push]
#       Prepare the jump to the next NixOS release on branch release-YY.MM:
#       move both inputs, build the gate, write what broke. Never publishes.
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
LIB=${GOLEM_LANE_LIB:-$(dirname "$(readlink -f "$0")")}
SYSTEM=x86_64-linux

TREE=$STATE/repo
STATUS=$STATE/status.json
NIXF=(--extra-experimental-features "nix-command flakes")
GIT_PUSH=(git -C "$TREE" -c credential.helper= -c "credential.helper=!gh auth git-credential")

mkdir -p "$STATE/logs" "$STATE/gcroots"

say() { printf '%s golem-lane: %s\n' "$(date '+%F %T')" "$*" >&2; }

# One status file, rewritten whole at each phase: what the last run did.
status() {  # status <phase> <ok:true|false> <message> [extra json object]
  local tmp=$STATUS.tmp extra=${4:-}
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
  git -C "$TREE" -c user.name="Golem update lane" commit -q -m "flake.lock: weekly upstream — nixpkgs ${before:0:12} → ${after:0:12}, home-manager

Moved by the update lane (updates/README.md): the newest tested commit of
both release branches. Built for every Golem system before publishing."
  BUMPED=1
  say "bumped nixpkgs ${before:0:12} → ${after:0:12}"
}

checks() {  # every flake check, as build targets
  nix "${NIXF[@]}" eval --json "$(flake)#checks.$SYSTEM" --apply builtins.attrNames \
    | jq -r --arg f "$(flake)" --arg s "$SYSTEM" '.[] | "\($f)#checks.\($s).\(.)"'
}

# THE GATE: the flake's checks + every Golem system, built. A failure here
# is the whole point of the lane: it stops before anything is published.
gate() {
  local targets
  say "gate: building every Golem system"
  if ! nix "${NIXF[@]}" build --keep-going -L --out-link "$STATE/gcroots/gate" \
        "$(flake)#packages.$SYSTEM.update-gate" >> "$LOG" 2>&1; then
    grep -E '^error:' "$LOG" | tail -5 >&2 || true
    fail gate "a Golem system does not build ($(grep -cE '^error: Cannot build' "$LOG" || true) failed builds)"
  fi
  GATE_OUT=$(readlink -f "$STATE/gcroots/gate")
  [ -e "$GATE_OUT/." ] || fail gate "the gate built but its output is missing"
  mapfile -t targets < <(checks)
  say "gate: running ${#targets[@]} checks"
  if ! nix "${NIXF[@]}" build --keep-going -L --no-link "${targets[@]}" >> "$LOG" 2>&1; then
    grep -E '^error:' "$LOG" | tail -5 >&2 || true
    fail gate "a check fails"
  fi
}

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
  local rev=$1 tag=g-${1:0:12} work sel n notes
  work=$STATE/export; rm -rf "$work"; mkdir -p "$work"
  if gh release view "$tag" --repo "$CACHE_REPO" --json isDraft --jq '.isDraft' 2>/dev/null | grep -qx false \
     && verify "$tag" quiet; then
    say "cache $tag already published and complete"
    return 0
  fi
  gh release delete "$tag" --repo "$CACHE_REPO" --yes --cleanup-tag >/dev/null 2>&1 || true

  nix "${NIXF[@]}" path-info -r --json "$GATE_OUT" > "$work/closure.json"
  jq -r 'if type == "array" then .[].path else keys[] end' "$work/closure.json" \
    | sed 's|^/nix/store/||; s|-.*||' > "$work/hashes"
  # cache.nixos.org already has most of the closure; ask it about each path.
  # shellcheck disable=SC2016  # $c and $(…) belong to the inner sh
  xargs -P 48 -I{} sh -c 'c=$(curl -s -o /dev/null -w "%{http_code}" --retry 2 -I "https://cache.nixos.org/{}.narinfo"); [ "$c" = 200 ] || echo {}' \
    < "$work/hashes" > "$work/missing"
  sel=$(python3 "$LIB/select.py" "$work/closure.json" "$work/missing" "$TREE/updates/lane/never-publish" "$work/chosen")
  say "cache: $sel"
  n=$(wc -l < "$work/chosen")
  [ "$n" -gt 0 ] || fail cache "nothing to upload — the selection is empty"

  mkdir -p "$work/out"
  xargs -a "$work/chosen" nix "${NIXF[@]}" copy --no-recursive \
    --to "file://$work/out?compression=zstd&parallel-compression=true&secret-key=$KEY" >> "$LOG" 2>&1 \
    || fail cache "exporting the pieces failed"
  # GitHub release files sit in one flat list: the NARs move up next to the
  # narinfos, whose URL line says so (the signature covers the content, not
  # where it is stored).
  mv "$work/out/nar/"* "$work/out/"
  rm -rf "$work/out/nar" "$work/out/log" "$work/out/realisations"
  sed -i 's|^URL: nar/|URL: |' "$work/out/"*.narinfo

  notes="Cache of Golem $rev ($n pieces, built and signed by the update lane).

Kernel of every Golem system in this version:

$(report | sed 's/^/    /')"
  gh release create "$tag" --repo "$CACHE_REPO" --draft --target main \
     --title "Golem ${rev:0:12}" --notes "$notes" \
     >/dev/null || fail cache "creating release $tag failed"
  find "$work/out" -maxdepth 1 -type f -print0 \
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
  one=$(for f in "$STATE/export/out/"*.narinfo; do
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
# year). A month before the end, or as soon as the next release branch
# exists, the lane says so — the jump itself is `golem-lane release`.
calendar() {
  local cur next eol left
  cur=$(sed -n 's|.*home-manager/release-\([0-9][0-9]\.[0-9][0-9]\).*|\1|p' "$TREE/flake.nix" | head -1)
  [ -n "$cur" ] || return 0
  case "$cur" in
    *.05) next=${cur%.05}.11; eol="20${cur%.05}-12-31" ;;
    *.11) next=$(( ${cur%.11} + 1 )).05; eol="20$(( ${cur%.11} + 1 ))-06-30" ;;
    *) return 0 ;;
  esac
  left=$(( ( $(date -d "$eol" +%s) - $(date +%s) ) / 86400 ))
  if git ls-remote --exit-code -q https://github.com/NixOS/nixpkgs "refs/heads/nixos-$next" >/dev/null 2>&1; then
    CALENDAR="NixOS $next is out; Golem is on $cur, supported $left more days. Prepare the jump: golem-lane release $next"
  elif [ "$left" -lt 31 ]; then
    CALENDAR="NixOS $cur stops getting fixes in $left days ($eol) and $next is not out yet."
  fi
  if [ -n "${CALENDAR:-}" ] && [ ! -e "$STATE/calendar-$next-$(date +%G-%V)" ]; then
    : > "$STATE/calendar-$next-$(date +%G-%V)"   # once a week
    notify "Golem: NixOS $next" "$CALENDAR"
  fi
}

cmd_run() {
  local base="" publish_it=1 force_bump=0 rev stable due last
  while [ $# -gt 0 ]; do
    case "$1" in
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

  status prepare true "fetching"
  prepare_tree "${base:-origin/main}"
  [ -n "$base" ] && say "base: $base ($(git -C "$TREE" rev-parse --short=12 HEAD))"

  last=$(cat "$STATE/last-bump" 2>/dev/null || echo 0)
  due=$(( $(date +%s) - last >= BUMP_DAYS * 86400 ))
  BUMPED=0
  if [ "$force_bump" = 1 ] || [ "$due" = 1 ]; then
    status bump true "moving nixpkgs and home-manager"
    bump
  fi
  calendar || true

  rev=$(git -C "$TREE" rev-parse HEAD)
  stable=$(git -C "$TREE" rev-parse -q --verify origin/stable 2>/dev/null || true)
  if [ "$rev" = "$stable" ]; then
    say "stable is already ${rev:0:12} — nothing new"
    status "done" true "nothing new: stable is ${rev:0:12}"
    exit 0
  fi
  if [ -n "$stable" ] && ! git -C "$TREE" merge-base --is-ancestor "$stable" "$rev"; then
    fail prepare "${rev:0:12} does not contain stable ${stable:0:12} — stable only ever moves forward"
  fi

  status gate true "building ${rev:0:12}"
  gate
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
  notify "Golem ${rev:0:12} published" "Built and tested for every Golem system; installs take it over the next ${GOLEM_LANE_WAVES:-7} days."
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
  from=$(sed -n 's|.*home-manager/release-\([0-9][0-9]\.[0-9][0-9]\).*|\1|p' "$TREE/flake.nix" | head -1)
  branch=release-$to
  git -C "$TREE" checkout -q -B "$branch"
  sed -i "s|NixOS/nixpkgs/nixos-$from|NixOS/nixpkgs/nixos-$to|; s|home-manager/release-$from|home-manager/release-$to|" "$TREE/flake.nix"
  nix "${NIXF[@]}" flake update nixpkgs home-manager --flake "$(flake)" >> "$LOG" 2>&1
  git -C "$TREE" add flake.nix flake.lock
  git -C "$TREE" -c user.name="Golem update lane" commit -q -m "flake: NixOS $from → $to (prepared by golem-lane release)"
  say "release $to: building the gate on $branch — this is the slow one"
  if nix "${NIXF[@]}" build --keep-going -L --no-link "$(flake)#packages.$SYSTEM.update-gate" >> "$LOG" 2>&1; then
    say "release $to: every Golem system builds. Next: a lab round on $branch (RUNBOOK.md), then merge to main."
  else
    say "release $to: some systems do not build. The errors:"
    grep -E '^error:' "$LOG" | sort -u | head -20 >&2 || true
  fi
  [ "$push" = --push ] && "${GIT_PUSH[@]}" push -q -u origin "$branch" && say "pushed $branch"
  say "log: $LOG"
}

case "${1:-}" in
  run) shift; cmd_run "$@" ;;
  release) shift; cmd_release "$@" ;;
  prune) prepare_tree origin/main; prune ;;
  status) cat "$STATUS" 2>/dev/null || echo '{}' ;;
  *) echo "usage: golem-lane run [--bump] [--base REF] [--no-publish] | release YY.MM [--push] | prune | status" >&2; exit 2 ;;
esac
