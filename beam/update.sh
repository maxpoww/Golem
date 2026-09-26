# beam-update — body of the `beam-update` command (wrapped by beam.nix with
# `set -euo pipefail` and BEAM_DIR). Usage:
#   beam-update            update if Mozilla has a newer release (root)
#   beam-update --check    report pinned / running / latest, change nothing
#   beam-update --force    re-pin + rebuild even if already current (root)

mode="${1:-}"
SRC="$BEAM_DIR/sources.json"
PD="https://product-details.mozilla.org/1.0/firefox_versions.json"

log(){ echo "beam-update: $*"; }

pinned=$(jq -r .version "$SRC")
running=$(readlink -f /run/current-system/sw/bin/firefox 2>/dev/null \
  | xargs -r grep -aoE 'firefox-bin-[0-9][0-9.]*[0-9]' 2>/dev/null | head -1 | sed 's/firefox-bin-//' || true)

if [ "$mode" != "--check" ] && command -v golem-wait-online >/dev/null; then
  golem-wait-online
fi
latest=$(curl -fsS --retry 3 "$PD" | jq -r .LATEST_FIREFOX_VERSION)
[[ "$latest" =~ ^[0-9]+(\.[0-9]+)+$ ]] || { log "bad version from Mozilla: '$latest'"; exit 1; }

if [ "$mode" = "--check" ]; then
  echo "pinned  (sources.json): $pinned"
  echo "system  (built):        ${running:-unknown}"
  echo "latest  (Mozilla):      $latest"
  if [ "$pinned" = "$latest" ]; then echo "status: up to date"; else echo "status: UPDATE AVAILABLE"; fi
  exit 0
fi

[ "$(id -u)" = 0 ] || { log "must run as root (sudo beam-update, or: systemctl start beam-update)"; exit 1; }

newest=$(printf '%s\n%s\n' "$pinned" "$latest" | sort -V | tail -1)
if [ "$mode" != "--force" ] && { [ "$pinned" = "$latest" ] || [ "$newest" = "$pinned" ]; }; then
  log "up to date ($pinned)"; exit 0
fi

url="https://archive.mozilla.org/pub/firefox/releases/$latest/linux-x86_64/en-US/firefox-$latest.tar.xz"
sha=$(curl -fsS --retry 3 "https://archive.mozilla.org/pub/firefox/releases/$latest/SHA256SUMS" \
  | grep -E " linux-x86_64/en-US/firefox-$latest\.tar\.xz$" | cut -d' ' -f1)
[[ "$sha" =~ ^[0-9a-f]{64}$ ]] || { log "no SHA256 for $latest in Mozilla's SHA256SUMS"; exit 1; }

log "updating $pinned -> $latest"
exec 9>/run/golem-rebuild.lock
flock 9

cp -p "$SRC" "$SRC.prev"
tmp=$(mktemp "$SRC.XXXX")
jq -n --arg v "$latest" --arg u "$url" --arg s "$sha" '{version:$v,url:$u,sha256:$s}' > "$tmp"
chown --reference="$SRC.prev" "$tmp"; chmod --reference="$SRC.prev" "$tmp"
mv "$tmp" "$SRC"

if [ -n "${BEAM_FLAKE:-}" ]; then
  # flake system: the build only sees git-TRACKED files — stage the new pin, then
  # rebuild this machine's own composition from its checkout (safe.directory is set)
  git -C "$BEAM_FLAKE" add beam/sources.json
  rebuild(){ nixos-rebuild switch --flake "$BEAM_FLAKE#$BEAM_FLAKE_ATTR"; }
else
  rebuild(){ nixos-rebuild switch; }
fi
if ! rebuild; then
  log "rebuild FAILED — restoring pin $pinned"
  mv "$SRC.prev" "$SRC"
  [ -n "${BEAM_FLAKE:-}" ] && git -C "$BEAM_FLAKE" add beam/sources.json
  exit 1
fi
log "Beam is now $latest"

# Test the NEW build headless (as nobody: Firefox must not run as root). Never blocks
# the update — the safety net keeps the browser working either way; this only reports.
mkdir -p /var/lib/beam
extra=""
# nobody can't read the owner's home, so hand the test a world-readable copy of the two
# files it needs (the pin → which build; the chrome script → what to test)
stdir=$(mktemp -d /tmp/beam-selftest.XXXX)
cp "$BEAM_DIR/sources.json" "$BEAM_DIR/golem-chrome.js" "$stdir/"; chmod 755 "$stdir"; chmod 644 "$stdir"/*
if st=$(runuser -u nobody -- env BEAM_DIR="$stdir" BEAM_SCRIPT="$stdir/golem-chrome.js" TMPDIR=/tmp beam-selftest 2>&1); then
  log "selftest: ALL PASS"
else
  log "selftest: FAILURES — overview will run in safe mode until patched"
  extra=" The Golem tab overview is paused on this version (browsing unaffected)."
fi
rm -rf "$stdir"
printf '%s\n' "$st" > /var/lib/beam/selftest-"$latest".txt
printf '%s\n' "$st" | sed 's/^/  /'

# tell every logged-in user to restart Beam (the running process keeps the old binary)
for bus in /run/user/*/bus; do
  [ -S "$bus" ] || continue
  u=$(stat -c %U "$bus")
  runuser -u "$u" -- env DBUS_SESSION_BUS_ADDRESS="unix:path=$bus" \
    notify-send -a Beam -u critical "Beam updated to $latest" \
    "Security update installed. Restart Beam to apply it — your tabs come back.$extra" || true
done
