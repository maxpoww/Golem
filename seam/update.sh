# seam-update — body of the `seam-update` command (wrapped by seam.nix with
# `set -euo pipefail` and SEAM_DIR). Usage:
#   seam-update            update if Mozilla has a newer release (root)
#   seam-update --check    report pinned / running / latest, change nothing
#   seam-update --force    re-pin + rebuild even if already current (root)

mode="${1:-}"
SRC="$SEAM_DIR/sources.json"
PD="https://product-details.mozilla.org/1.0/firefox_versions.json"
# Seam's languages (Golem's shell languages): Mozilla's language pack for each is pinned in
# sources.json "langpacks" BESIDE the tarball and always moves with it — a pack of another
# Firefox version is refused, and Seam silently speaks English. Add one here, then
# `sudo seam-update --force`.
LANGPACKS="es-ES es-MX fr de it pt-BR pt-PT"

log(){ echo "seam-update: $*"; }

pinned=$(jq -r .version "$SRC")
# the packs pinned FOR the pinned version, against the ones wanted (a pin written before
# 2026-11-10, or kept back by a machine whose lane was ahead of upstream, has none)
packs_pinned=$(jq -r --arg v "$pinned" '[.langpacks // {} | to_entries[]
  | select(.value.url | contains("/releases/" + $v + "/")) | .key] | sort | join(" ")' "$SRC")
packs_wanted=$(printf '%s\n' $LANGPACKS | sort | paste -sd' ')
running=""
for b in /run/current-system/sw/bin/seam /etc/profiles/per-user/*/bin/seam; do
  [ -e "$b" ] || continue
  running=$(readlink -f "$b" 2>/dev/null | xargs -r grep -aoE 'firefox-bin-[0-9][0-9.]*[0-9]' 2>/dev/null | head -1 | sed 's/firefox-bin-//' || true)
  [ -n "$running" ] && break
done

if [ "$mode" != "--check" ] && command -v golem-wait-online >/dev/null; then
  golem-wait-online
fi
latest=$(curl -fsS --retry 3 "$PD" | jq -r .LATEST_FIREFOX_VERSION)
[[ "$latest" =~ ^[0-9]+(\.[0-9]+)+$ ]] || { log "bad version from Mozilla: '$latest'"; exit 1; }

if [ "$mode" = "--check" ]; then
  echo "pinned  (sources.json): $pinned"
  echo "system  (built):        ${running:-unknown}"
  echo "latest  (Mozilla):      $latest"
  echo "languages (pinned):     ${packs_pinned:-none}"
  if [ "$pinned" = "$latest" ]; then echo "status: up to date"; else echo "status: UPDATE AVAILABLE"; fi
  [ "$packs_pinned" = "$packs_wanted" ] || echo "status: LANGUAGE PACKS MISSING (wanted: $packs_wanted) — sudo seam-update pins them"
  exit 0
fi

[ "$(id -u)" = 0 ] || { log "must run as root (sudo seam-update, or: systemctl start seam-update)"; exit 1; }

# want = the version to pin: Mozilla's latest, or — when the browser is current but its
# language packs are not pinned — the same version again, with its packs
want="$latest"; packsonly=no
newest=$(printf '%s\n%s\n' "$pinned" "$latest" | sort -V | tail -1)
if [ "$mode" != "--force" ] && { [ "$pinned" = "$latest" ] || [ "$newest" = "$pinned" ]; }; then
  if [ "$packs_pinned" = "$packs_wanted" ]; then log "up to date ($pinned)"; exit 0; fi
  want="$pinned"; packsonly=yes
  log "language packs missing for $pinned (have: ${packs_pinned:-none}) — pinning them"
fi

# Everything from Mozilla's SHA256SUMS of that version: the tarball AND each language pack.
# Read before anything is written: a missing hash changes nothing.
rel="https://archive.mozilla.org/pub/firefox/releases/$want"
sums=$(curl -fsS --retry 3 "$rel/SHA256SUMS") || { log "could not read Mozilla's SHA256SUMS for $want"; exit 1; }
sumof(){ printf '%s\n' "$sums" | { grep -E " $1\$" || true; } | cut -d' ' -f1; }   # 2 matches fail the check below
url="$rel/linux-x86_64/en-US/firefox-$want.tar.xz"
sha=$(sumof "linux-x86_64/en-US/firefox-$want\.tar\.xz")
[[ "$sha" =~ ^[0-9a-f]{64}$ ]] || { log "no SHA256 for $want in Mozilla's SHA256SUMS"; exit 1; }
packs='{}'
for l in $LANGPACKS; do
  lsha=$(sumof "linux-x86_64/xpi/$l\.xpi")
  [[ "$lsha" =~ ^[0-9a-f]{64}$ ]] || { log "no SHA256 for the $l language pack of $want in Mozilla's SHA256SUMS"; exit 1; }
  packs=$(jq -c --arg l "$l" --arg u "$rel/linux-x86_64/xpi/$l.xpi" --arg s "$lsha" '. + {($l): {url: $u, sha256: $s}}' <<<"$packs")
done

log "updating $pinned -> $want"
# Golem's one rebuild lock (golem-rebuild uses it too): never two system rebuilds at once.
# We hold it ourselves, so the rebuild below is a plain nixos-rebuild.
exec 9>>/run/golem-rebuild.lock
flock 9

# The checkout is the OWNER's: git writes run as them (root-written index/object files
# are ones the owner can no longer touch). And the seal: when the checkout was blessed
# before this update, the pin written below is ours (root, from Mozilla's SHA256SUMS)
# and is re-blessed after — otherwise the dock's next app install is refused ("the
# system configuration changed since the last blessing"). Checked BEFORE writing.
asowner(){ runuser -u "$(stat -c %U "$SEAM_FLAKE")" -- "$@"; }
sealed_before=no
if [ -n "${SEAM_SEAL_CHECK:-}" ] && "$SEAM_SEAL_CHECK" >/dev/null 2>&1; then sealed_before=yes; fi
reseal(){ if [ "$sealed_before" = yes ] && [ -n "${SEAM_SEAL_BLESS:-}" ]; then "$SEAM_SEAL_BLESS" >/dev/null && log "re-sealed the checkout"; fi; }

cp -p "$SRC" "$SRC.prev"
tmp=$(mktemp "$SRC.XXXX")
jq -n --arg v "$want" --arg u "$url" --arg s "$sha" --argjson p "$packs" \
  '{version:$v,url:$u,sha256:$s,langpacks:$p}' > "$tmp"
chown --reference="$SRC.prev" "$tmp"; chmod --reference="$SRC.prev" "$tmp"
mv "$tmp" "$SRC"

if [ -n "${SEAM_FLAKE:-}" ]; then
  # flake system: the build only sees git-TRACKED files — stage the new pin, then
  # rebuild this machine's own composition from its checkout (safe.directory is set)
  asowner git -C "$SEAM_FLAKE" add seam/sources.json
  rebuild(){ nixos-rebuild switch --flake "$SEAM_FLAKE#$SEAM_FLAKE_ATTR"; }
else
  rebuild(){ nixos-rebuild switch; }
fi
if ! rebuild; then
  log "rebuild FAILED — restoring pin $pinned"
  mv "$SRC.prev" "$SRC"
  [ -n "${SEAM_FLAKE:-}" ] && asowner git -C "$SEAM_FLAKE" add seam/sources.json
  reseal
  exit 1
fi
reseal
log "Seam is now $want"

# Test the NEW build headless (as nobody: Firefox must not run as root). Never blocks
# the update — the safety net keeps the browser working either way; this only reports.
mkdir -p /var/lib/seam
extra=""
# nobody can't read the owner's home, so hand the test a world-readable copy of the two
# files it needs (the pin → which build; the chrome script → what to test)
stdir=$(mktemp -d /tmp/seam-selftest.XXXX)
cp "$SEAM_DIR/sources.json" "$SEAM_DIR/golem-chrome.js" "$stdir/"; chmod 755 "$stdir"; chmod 644 "$stdir"/*
if st=$(runuser -u nobody -- env SEAM_DIR="$stdir" SEAM_SCRIPT="$stdir/golem-chrome.js" TMPDIR=/tmp seam-selftest 2>&1); then
  log "selftest: ALL PASS"
elif printf '%s' "$st" | grep -q '"steps"'; then
  log "selftest: FAILURES — overview will run in safe mode until patched"
  extra=paused
else
  # no test results at all: the test could not start (permissions, missing build ...).
  # Nothing is known about this version, and nothing is paused — the overview checks
  # itself at every start (golem-chrome.js health check) and degrades on its own.
  log "selftest: COULD NOT RUN — $(printf '%s' "$st" | tail -1)"
  extra=untested
fi
rm -rf "$stdir"
printf '%s\n' "$st" > /var/lib/seam/selftest-"$want".txt
printf '%s\n' "$st" | sed 's/^/  /'

# tell every logged-in user to restart Seam (the running process keeps the old binary),
# each in their own language: root names their settings for golem-say.
# Not for the packs alone: the next start picks them up, nothing to be secured.
[ "$packsonly" = yes ] && exit 0
for bus in /run/user/*/bus; do
  [ -S "$bus" ] || continue
  u=$(stat -c %U "$bus")
  home=$(getent passwd "$u" | cut -d: -f6) || home=   # (none: the system's language)
  say() { GOLEM_SETTINGS="$home/.config/golem/settings.json" golem-say "$@"; }
  body=$(say "Security update installed. Restart Seam to apply it — your tabs come back.")
  case "$extra" in
    paused) body="$body $(say "The Golem tab overview is paused on this version (browsing unaffected).")" ;;
    untested) body="$body $(say "(The post-update self-test could not run; the browser checks itself at startup.)")" ;;
  esac
  runuser -u "$u" -- env DBUS_SESSION_BUS_ADDRESS="unix:path=$bus" \
    notify-send -a Seam -u critical "$(say "Seam updated to {0}" "$want")" "$body" || true
done
