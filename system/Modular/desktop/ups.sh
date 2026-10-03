#!/usr/bin/env bash
#
# ups — the Golem upstream lane.
#
# The OPTION to run bleeding-edge upstream apps on Golem, for users who want
# them — installed the way a package manager would, but backed by per-app
# rootless containers so the reproducible NixOS base is never touched.
#
#   ups add    <name>   install the upstream build. It takes its REAL name
#                       (no prefix): `ups add opencode` gives you `opencode`.
#                       If a GUI app, its icon lands on the app-box automatically.
#                       If the name collides with a stock Golem command, ups asks
#                       whether the upstream build should take that command over.
#   ups erase  <name>   remove it. The container, the command, the icon, the
#                       cached image — gone; the stock app (if any) returns.
#                       Add --purge to also delete the app's own settings.
#   ups update <name|all>   pull the latest upstream build (snapshots first).
#   ups rollback <name>     undo the last update.
#   ups autoupdate <daily|weekly|monthly|off>   scheduled `ups update all`.
#   ups doctor [name]   check/repair containers. This is the reliability spine:
#                       an app whose container was orphaned by a base/podman
#                       upgrade is rebuilt from its saved image (offline) or its
#                       recipe. The exported commands call this automatically, so
#                       an upgrade can never brick an installed app.
#   ups list            what is installed.
#   ups catalog         recipes available to add.
#   ups enter  <name>   drop into the container's shell (debugging).
#
# DESIGN
#   * Overlay, never uninstall. An app is a PATH shim in ~/.local/bin (which
#     shadows the Nix command) plus, for GUI apps, a .desktop in
#     ~/.local/share/applications (which overrides the Nix one). erase deletes
#     the overlay and the stock app transparently reappears. The declarative
#     base is never modified — the whole feature is reversible by construction.
#   * Real home. The container shares your real $HOME, so an upstream app is
#     YOUR app — same login, same settings, same projects. (A recipe can set
#     UPS_ISOLATE_HOME=1 for the rare app where sharing the real profile would
#     be dangerous, e.g. a browser.)
#   * Disposable containers, durable state. The container is pure install-output,
#     rebuildable at any time; your data lives in your real home, so a rebuild
#     loses nothing. That is what makes `ups doctor` safe and automatic.
#
# A RECIPE maps a friendly name -> base image + install steps + what to export.
# Built-ins live in /etc/ups/recipes.d (shipped by ups.nix); a file at
# ~/.config/ups/recipes.d/<name>.sh overrides the same-named built-in. Format:
#
#   UPS_IMAGE="registry.fedoraproject.org/fedora-toolbox:latest"
#   UPS_DESC="one-line description shown by 'ups catalog'"
#   UPS_SETUP='shell run INSIDE the container (passwordless sudo available)'
#   UPS_BINS="opencode"            # CLI bins -> exported under their real name
#   UPS_APPS="com.example.App"     # GUI desktop-ids -> app-box launchers
#   UPS_DATA="~/.config/opencode ~/.local/share/opencode"   # for `erase --purge`
#   UPS_ISOLATE_HOME=1             # optional: give this app a private home

set -euo pipefail

PREFIX="ups-"
BIN_DIR="$HOME/.local/bin"
APPS_DIR="$HOME/.local/share/applications"
ICONS_ROOT="$HOME/.local/share/icons/hicolor"
CACHE_DIR="$HOME/.cache/ups"
STATE_DIR="$HOME/.local/share/ups/state"
HOMES_DIR="$HOME/.local/share/ups/homes"   # only used for UPS_ISOLATE_HOME apps
USER_RECIPES="${XDG_CONFIG_HOME:-$HOME/.config}/ups/recipes.d"
SYS_RECIPES="/etc/ups/recipes.d"

die()  { printf 'ups: %s\n' "$*" >&2; exit 1; }
info() { printf 'ups: %s\n' "$*" >&2; }

ensure_tools() {
  command -v distrobox >/dev/null 2>&1 || die "'distrobox' not found — build ups.nix into the system and start a new shell."
  command -v podman    >/dev/null 2>&1 || die "'podman' not found — build ups.nix into the system and start a new shell."
}

valid_name() { [[ "$1" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || die "invalid app name: '$1'"; }

recipe_path() {
  local name="$1"
  if [[ -f "$USER_RECIPES/$name.sh" ]]; then printf '%s\n' "$USER_RECIPES/$name.sh"; return 0; fi
  if [[ -f "$SYS_RECIPES/$name.sh"  ]]; then printf '%s\n' "$SYS_RECIPES/$name.sh";  return 0; fi
  return 1
}

load_recipe() {
  local name="$1" path
  path="$(recipe_path "$name")" || die "no recipe for '$name' — run 'ups catalog', or write ~/.config/ups/recipes.d/$name.sh"
  UPS_IMAGE=""; UPS_DESC=""; UPS_SETUP=""; UPS_BINS=""; UPS_APPS=""; UPS_DATA=""; UPS_ISOLATE_HOME=""
  # shellcheck disable=SC1090
  source "$path"
  [[ -n "$UPS_IMAGE" ]] || die "recipe '$name' is missing UPS_IMAGE."
}

container_exists() { podman container exists "$PREFIX$1" 2>/dev/null; }

# A container is HEALTHY when podman can inspect it. `podman container inspect`
# touches the graph driver, so it fails exactly when the RW layer was orphaned
# by an id-mapping/podman change (the "getting graph driver info … permission
# denied" breakage) AND when the container is simply missing. One cheap,
# non-interactive probe that covers every unhealthy case.
container_healthy() { podman container inspect "$PREFIX$1" >/dev/null 2>&1; }

list_names() {
  podman ps -a --format '{{.Names}}' 2>/dev/null | grep "^$PREFIX" | sed "s/^$PREFIX//" || true
}

# An app is "installed" if we have any durable trace of it — a state stamp, a
# golden restore image, or a live container. Crucially this stays true even when
# the container was DESTROYED/orphaned, which is exactly when doctor must act.
is_known() {
  local name="$1"
  [[ -f "$STATE_DIR/$name" ]] && return 0
  podman image exists "$(golden_img "$name")" 2>/dev/null && return 0
  container_exists "$name" && return 0
  return 1
}

# Every installed app: live containers UNION state stamps (so a missing container
# still shows up as something to repair).
known_names() {
  # NB: trailing `|| true` — under `set -o pipefail`, the grep filters return
  # non-zero when the list is empty, which would otherwise abort a caller that
  # does `x="$(known_names)"`.
  {
    list_names
    if [[ -d "$STATE_DIR" ]]; then ls "$STATE_DIR" 2>/dev/null | grep -v '\.isolate$' || true; fi
  } | grep -vE '^[[:space:]]*$' | sort -u || true
}

# Stamp the last install/update time (a container's create-time never changes on
# update, so we track "updated" ourselves).
mark_updated() { mkdir -p "$STATE_DIR"; : > "$STATE_DIR/$1"; }

updated_str() {
  local name="$1" f="$STATE_DIR/$1" c
  if [[ -f "$f" ]]; then
    date -r "$f" '+%Y-%m-%d %H:%M'
  else
    c="$(podman inspect -f '{{.Created}}' "$PREFIX$name" 2>/dev/null || true)"
    if [[ -n "$c" ]]; then printf '%s %s' "${c:0:10}" "${c:11:5}"; else printf '%s' "-"; fi
  fi
}

# podman refs must be lowercase.
snap_img()   { printf 'localhost/ups-prev/%s:snapshot' "${1,,}"; }   # one-deep rollback point
golden_img() { printf 'localhost/ups-good/%s:latest'   "${1,,}"; }   # last-known-good, for offline heal

isolate_marker() { printf '%s' "$STATE_DIR/$1.isolate"; }
is_isolated()    { [[ -f "$(isolate_marker "$1")" || "${UPS_ISOLATE_HOME:-}" == "1" ]]; }

# The distrobox --home flag for an app: empty (real home) unless isolated.
home_args() {
  local name="$1"
  if is_isolated "$name"; then mkdir -p "$HOMES_DIR/$name"; printf -- '--home\n%s\n' "$HOMES_DIR/$name"; fi
}

# --- CLI binaries: exported under their REAL name; the shim self-heals ---

# Where a command really lives INSIDE the container, ignoring the shared
# ~/.local/bin (which holds our shim of the same name). Without this, a shim that
# invoked the bare name would find ITSELF on the container's PATH — the container
# shares your home — and recurse instead of running the real upstream binary.
resolve_in_container() {
  local cname="$1" bin="$2"
  # trailing `|| true`: under pipefail a non-zero from distrobox/grep must not
  # abort the caller's `target="$(resolve_in_container …)"`.
  { distrobox enter --name "$cname" -- sh -c \
    'clean=$(printf "%s" "$PATH" | tr ":" "\n" | grep -vx "$HOME/.local/bin" | grep -vx "$HOME/bin" | paste -sd:); PATH="$clean" command -v "$1"' \
    _ "$bin" </dev/null 2>/dev/null | tr -d '\r' | tail -1 ; } || true
}

# Write the self-healing shim for one command. It invokes the real binary by
# ABSOLUTE PATH (no PATH lookup -> can't shadow itself). If the container was
# orphaned by an upgrade, it repairs via `ups doctor` and re-execs the freshly
# rewritten shim (so a changed binary path is picked up); a guard var prevents
# any repair loop.
write_shim() {
  local name="$1" bin="$2" target="$3" wrapper="$BIN_DIR/$2"
  if [[ "$target" == /* ]]; then
    cat > "$wrapper" <<EOF
#!/bin/sh
# ups-managed:$name
c="$PREFIX$name"
if ! podman container inspect "\$c" >/dev/null 2>&1; then
  if [ -n "\${UPS_REPAIRED:-}" ]; then
    echo "ups: '$name' still unavailable after repair — run: ups doctor $name" >&2; exit 1
  fi
  echo "ups: '$name' needs a rebuild (its upstream base changed) — repairing…" >&2
  ups doctor "$name" >&2 || { echo "ups: automatic repair failed — run: ups doctor $name" >&2; exit 1; }
  UPS_REPAIRED=1 exec "\$0" "\$@"
fi
exec distrobox enter --name "\$c" -- $target "\$@"
EOF
  else
    cat > "$wrapper" <<EOF
#!/bin/sh
# ups-managed:$name
echo "ups: '$bin' isn't available in the '$name' container — run: ups doctor $name" >&2
exit 127
EOF
  fi
  chmod +x "$wrapper"
}

export_bins() {
  local name="$1" bin wrapper target; local cname="$PREFIX$name"
  [[ -n "${UPS_BINS:-}" ]] || return 0
  mkdir -p "$BIN_DIR"
  for bin in $UPS_BINS; do
    wrapper="$BIN_DIR/$bin"
    if [[ -e "$wrapper" ]] && ! grep -q "ups-managed:$name\$" "$wrapper" 2>/dev/null; then
      info "skip '$bin': $wrapper already exists and is not ups-managed."
      continue
    fi
    target="$(resolve_in_container "$cname" "$bin")"
    if [[ "$target" == /* ]]; then
      write_shim "$name" "$bin" "$target"; info "  $bin -> $target"
    else
      info "warning: couldn't locate '$bin' inside the container — its command will ask for a repair."
      write_shim "$name" "$bin" ""
    fi
  done
  return 0
}

exported_bins() {
  local name="$1" f out=""
  [[ -d "$BIN_DIR" ]] || { printf '%s' "-"; return; }
  for f in "$BIN_DIR"/*; do
    [[ -f "$f" ]] || continue
    if grep -q "ups-managed:$name\$" "$f" 2>/dev/null; then out="$out ${f##*/}"; fi
  done
  printf '%s' "${out:- -}"
}

remove_bins() {
  local name="$1" f
  [[ -d "$BIN_DIR" ]] || return 0
  # Matches both the new real-name shims and the old design's u-prefixed ones —
  # both carry the "# ups-managed:<name>" marker line.
  for f in "$BIN_DIR"/*; do
    [[ -f "$f" ]] || continue
    if grep -q "ups-managed:$name\$" "$f" 2>/dev/null; then rm -f "$f"; info "removed $f"; fi
  done
  return 0
}

# --- app-box launchers (GUI): real name + copied icon, override the stock id ---

# Runs INSIDE the container. Copies the app's icon onto the host icon theme and
# prints the fields the host needs to synthesise a .desktop. Args: <app> <marker> <icons_root>
container_export_helper() {
  cat <<'REMOTE'
set -u
app="$1"; marker="$2"; icons_root="$3"
df=""
for c in "/usr/share/applications/$app.desktop" "$HOME/.local/share/applications/$app.desktop"; do
  [ -f "$c" ] && { df="$c"; break; }
done
[ -n "$df" ] || df="$(ls /usr/share/applications/*"$app"*.desktop 2>/dev/null | head -1 || true)"
if [ -z "$df" ]; then echo "UPS_ERR=no .desktop for '$app' inside the container"; exit 3; fi
getkey() { grep -m1 "^$1=" "$df" | cut -d= -f2-; }
name="$(getkey Name)"; exec_="$(getkey Exec)"; icon="$(getkey Icon)"
exec_="$(printf '%s' "$exec_" | sed -E 's/%[a-zA-Z]//g; s/[[:space:]]+$//')"
iconname=""
if [ -n "$icon" ]; then
  src=""
  case "$icon" in /*) [ -f "$icon" ] && src="$icon" ;; esac
  if [ -z "$src" ]; then
    for d in /usr/share/icons/hicolor/512x512/apps /usr/share/icons/hicolor/256x256/apps \
             /usr/share/icons/hicolor/128x128/apps /usr/share/icons/hicolor/scalable/apps \
             /usr/share/pixmaps; do
      for e in png svg svgz xpm; do [ -f "$d/$icon.$e" ] && { src="$d/$icon.$e"; break 2; }; done
    done
  fi
  if [ -n "$src" ] && [ -f "$src" ]; then
    ext="${src##*.}"; case "$ext" in svg|svgz) sub="scalable" ;; *) sub="256x256" ;; esac
    dest="$icons_root/$sub/apps"; mkdir -p "$dest"
    cp -f "$src" "$dest/$marker.$ext" && iconname="$marker"
  fi
fi
printf 'UPS_NAME=%s\n' "$name"
printf 'UPS_EXEC=%s\n' "$exec_"
printf 'UPS_ICON=%s\n' "$iconname"
REMOTE
}

write_launcher() {
  local name="$1" app="$2" marker="$3" disp="$4" execbin="$5" icon="$6"
  # Use the app's own desktop-id as the filename so this launcher OVERRIDES the
  # stock one in ~/.local/share/applications (XDG: user dir wins). The X-ups tag
  # marks it ours for clean removal even though the filename is the native id.
  local file="$APPS_DIR/$app.desktop"
  if [[ -f "$file" ]] && ! grep -q "^X-ups=" "$file" 2>/dev/null; then
    file="$APPS_DIR/$marker.desktop"   # a real user launcher exists here — don't clobber it
  fi
  {
    echo "[Desktop Entry]"
    echo "Type=Application"
    echo "Name=$disp"
    echo "Comment=Upstream build (via ups) — $name"
    echo "Exec=distrobox enter --name $PREFIX$name -- $execbin %U"
    [[ -n "$icon" ]] && echo "Icon=$icon"
    echo "Terminal=false"
    echo "StartupNotify=true"
    echo "X-ups=$name"
  } > "$file"
  chmod 644 "$file"
}

export_apps() {
  local name="$1"; local cname="$PREFIX$name"
  [[ -n "${UPS_APPS:-}" ]] || return 0
  mkdir -p "$APPS_DIR" "$CACHE_DIR" "$ICONS_ROOT"
  local helper="$CACHE_DIR/appexport.sh"
  container_export_helper > "$helper"
  local app marker out nm ex ic
  for app in $UPS_APPS; do
    marker="$PREFIX$name-$app"
    out="$(distrobox enter --name "$cname" -- bash "$helper" "$app" "$marker" "$ICONS_ROOT" 2>/dev/null || true)"
    if grep -q '^UPS_ERR=' <<< "$out"; then   # a here-string: under pipefail a pipe into grep -q can read FALSE on a match
      info "$(printf '%s\n' "$out" | sed -n 's/^UPS_ERR=//p' | head -1)"; continue
    fi
    nm="$(printf '%s\n' "$out" | sed -n 's/^UPS_NAME=//p' | head -1)"
    ex="$(printf '%s\n' "$out" | sed -n 's/^UPS_EXEC=//p' | head -1)"
    ic="$(printf '%s\n' "$out" | sed -n 's/^UPS_ICON=//p' | head -1)"
    [[ -n "$ex" ]] || ex="$app"
    # Resolve the launch command to an ABSOLUTE in-container path so it can't hit
    # a same-named ups shim on the shared-home PATH (the shim calls podman/ups,
    # absent inside the container). Mirrors the CLI-shim absolute-path trick.
    local exbin exrest exabs
    exbin="${ex%% *}"; exrest="${ex#"$exbin"}"
    if [[ "$exbin" != /* ]]; then
      exabs="$(resolve_in_container "$cname" "$exbin")"
      if [[ "$exabs" == /* ]]; then ex="$exabs$exrest"; fi
    fi
    write_launcher "$name" "$app" "$marker" "${nm:-$app}" "$ex" "$ic"
    info "placed '${nm:-$app}' on the app-box${ic:+ (icon ok)}"
  done
  return 0
}

remove_apps() {
  local name="$1" f d
  if [[ -d "$APPS_DIR" ]]; then
    for f in "$APPS_DIR"/*.desktop; do
      [[ -f "$f" ]] || continue
      grep -q "^X-ups=$name\$" "$f" 2>/dev/null && { rm -f "$f"; info "removed $f"; }
    done
    # legacy launchers from the old design
    rm -f "$APPS_DIR/$PREFIX$name.desktop"
    for f in "$APPS_DIR/$PREFIX$name-"*.desktop; do [[ -f "$f" ]] && rm -f "$f"; done
  fi
  for d in "$ICONS_ROOT"/*/apps; do
    [[ -d "$d" ]] || continue
    for f in "$d/$PREFIX$name-"*; do [[ -f "$f" ]] && rm -f "$f"; done
  done
  return 0   # never let a trailing false test abort the caller under set -e
}

# --- container lifecycle ---

# Remove a container as forcefully as needed — including when its layer is
# orphaned and normal removal balks. Used by erase and by doctor before rebuild.
nuke_container() {
  local name="$1"; local cname="$PREFIX$name"
  distrobox rm --force "$cname" >/dev/null 2>&1 || true
  podman rm -f "$cname"          >/dev/null 2>&1 || true
  # Always clear the STORAGE-library record too. When an upgrade orphans a
  # container, `podman rm -f` drops the libpod entry but leaves a storage entity
  # still holding the name (an "external entity") whose layer can't be deleted.
  # `podman rm --storage --force` frees the name once that layer record is gone —
  # this is the step that turns an un-removable, name-squatting container back
  # into a reusable name without ever needing root.
  podman rm --storage --force "$cname" >/dev/null 2>&1 || true
  if name_squatted "$name"; then
    info "warning: the name '$cname' is still held by broken storage. Reclaim disk + clear it with:"
    info "  podman system reset --force   # ups is the only user of podman here"
  fi
  return 0
}

# True if the name is still taken by a libpod or storage-library record.
name_squatted() {
  local cname="$PREFIX$1"
  podman container exists "$cname" 2>/dev/null && return 0
  podman ps -a --storage --external --format '{{.Names}}' 2>/dev/null | grep -qx "$cname"
}

# Create the container from UPS_IMAGE and run UPS_SETUP. On failure, roll the
# half-made container back so a failed add leaves nothing behind. Saves a golden
# image afterwards so doctor can rebuild fast and offline.
create_and_setup() {
  local name="$1"; local cname="$PREFIX$name"
  local hargs=(); mapfile -t hargs < <(home_args "$name")
  is_isolated "$name" && : > "$(isolate_marker "$name")"
  # Clear any stale storage-library record squatting on this name (left by a prior
  # orphaned container). Safe here: we only reach create when no live container of
  # this name exists.
  podman rm --storage --force "$cname" >/dev/null 2>&1 || true
  info "creating container '$cname' from $UPS_IMAGE ..."
  distrobox create --name "$cname" --image "$UPS_IMAGE" "${hargs[@]}" --no-entry --yes >/dev/null
  if [[ -n "${UPS_SETUP:-}" ]]; then
    info "installing upstream '$name' (first run pulls the image — can take a minute) ..."
    if ! distrobox enter --name "$cname" -- bash -euo pipefail -c "$UPS_SETUP" </dev/null; then
      info "install failed — rolling back container '$cname'"
      nuke_container "$name"
      die "could not install '$name'."
    fi
  fi
  save_golden "$name"
}

# Snapshot the working install so doctor can restore it without the network.
save_golden() {
  local name="$1"
  podman commit "$PREFIX$name" "$(golden_img "$name")" >/dev/null 2>&1 \
    && info "  saved a restore image (offline repair enabled)" || true
}

# u_names/exported_summary: show what the user got.
exported_summary() {
  local name="$1" b out=""
  for b in ${UPS_BINS:-}; do out="$out $b"; done
  [[ -n "${UPS_APPS:-}" ]] && out="$out (+ app-box icon)"
  printf '%s' "${out:- (nothing exported)}"
}

cmd_add() {
  local yes=0 name=""
  for a in "$@"; do
    case "$a" in
      -y|--yes|--force) yes=1 ;;
      --*) die "unknown flag '$a'" ;;
      *) if [[ -z "$name" ]]; then name="$a"; fi ;;
    esac
  done
  [[ -n "$name" ]] || die "usage: ups add <name> [--yes]"
  ensure_tools; valid_name "$name"; load_recipe "$name"
  container_exists "$name" && die "'$name' is already installed  (ups update $name to refresh, ups erase $name to remove)."

  # If an upstream bin would take over a stock Golem command, ask first.
  if [[ $yes -eq 0 && -n "${UPS_BINS:-}" ]]; then
    local bin p conflicts=""
    for bin in $UPS_BINS; do
      p="$(command -v "$bin" 2>/dev/null || true)"
      [[ -n "$p" && "$p" != "$BIN_DIR/"* ]] && conflicts="$conflicts $bin"
    done
    if [[ -n "$conflicts" ]]; then
      printf 'ups: you already have the stock Golem build of:%s\n' "$conflicts" >&2
      printf 'ups: install the bleeding-edge upstream build and let it take over that command? [Y/n] ' >&2
      local ans=""; read -r ans </dev/tty 2>/dev/null || ans=""
      case "$ans" in [Nn]*) die "aborted — nothing changed." ;; esac
    fi
  fi

  create_and_setup "$name"
  export_bins "$name"
  export_apps "$name"
  mark_updated "$name"
  info "done — '$name' is ready:$(exported_summary "$name")"
  path_hint
}

cmd_erase() {
  local purge=0 keep=0 name=""
  for a in "$@"; do
    case "$a" in
      --purge)      purge=1 ;;
      --keep-image) keep=1 ;;
      --*) die "unknown flag '$a'" ;;
      *) if [[ -z "$name" ]]; then name="$a"; fi ;;
    esac
  done
  [[ -n "$name" ]] || die "usage: ups erase <name> [--purge] [--keep-image]"
  ensure_tools; valid_name "$name"
  local cname="$PREFIX$name" img=""
  img="$(podman inspect -f '{{.Image}}' "$cname" 2>/dev/null || true)"

  remove_bins "$name"
  remove_apps "$name"
  rm -f "$STATE_DIR/$name" "$(isolate_marker "$name")"

  if container_exists "$name"; then
    nuke_container "$name"
    container_exists "$name" || info "removed container '$cname'"
  else
    info "no container '$cname' — removed exported commands/launchers only"
  fi
  rm -rf "${HOMES_DIR:?}/$name" 2>/dev/null || true   # isolated/legacy private home

  # drop the golden + rollback images (they pin the base layers).
  podman rmi "$(golden_img "$name")" >/dev/null 2>&1 || true
  podman rmi "$(snap_img "$name")"   >/dev/null 2>&1 || true

  # reclaim the cached base image if no ups container still uses it.
  if [[ $keep -eq 0 && -n "$img" ]] && \
     [[ -z "$(podman ps -a --filter ancestor="$img" --format '{{.ID}}' 2>/dev/null)" ]]; then
    local nm; nm="$(podman image inspect -f '{{index .RepoTags 0}}' "$img" 2>/dev/null || true)"
    podman rmi "$img" >/dev/null 2>&1 && info "reclaimed cached image ${nm:-$img}" || true
  elif [[ $keep -eq 1 ]]; then
    info "kept cached image (per --keep-image)."
  fi

  # --purge: also remove the app's OWN settings from the real home. Only paths
  # the recipe explicitly declares (UPS_DATA), each vetted so a bad entry can
  # never delete a shared dir or your home itself.
  local recipe_data=""
  if recipe_path "$name" >/dev/null 2>&1; then load_recipe "$name"; recipe_data="${UPS_DATA:-}"; fi
  if [[ $purge -eq 1 ]]; then
    if [[ -n "$recipe_data" ]]; then
      local d rp removed=0
      for d in $recipe_data; do
        rp="$(purge_safe_path "$d")" || { info "skipped unsafe purge path: $d"; continue; }
        [[ -e "$rp" ]] && rm -rf "$rp" && { info "purged $rp"; removed=1; }
      done
      [[ $removed == 1 ]] || info "no app settings found to purge."
    else
      info "recipe declares no UPS_DATA — no app settings to purge."
    fi
  elif [[ -n "$recipe_data" ]]; then
    info "note: your '$name' settings remain ($recipe_data). Use 'ups erase $name --purge' to remove those too."
  fi

  info "'$name' erased."
}

# Vet a UPS_DATA path for --purge. Prints the resolved absolute path on success;
# returns non-zero (deletes nothing) for anything unsafe.
purge_safe_path() {
  local p="$1"
  p="${p/#\~\//$HOME/}"; p="${p/#\~/$HOME}"; p="${p//\$HOME/$HOME}"; p="${p%/}"
  case "$p" in
    "$HOME"/?*) : ;;      # must live strictly under $HOME
    *) return 1 ;;
  esac
  case "$p" in *..*) return 1 ;; esac   # no traversal
  # never a shared/root directory
  case "$p" in
    "$HOME"|"$HOME"/.config|"$HOME"/.cache|"$HOME"/.local|"$HOME"/.local/share|"$HOME"/.local/bin|"$HOME"/.local/state|"$HOME"/.config/systemd*|"$HOME"/Documents|"$HOME"/Downloads|"$HOME"/Desktop|"$HOME"/.ssh|"$HOME"/.gnupg|"$HOME"/.mozilla|"$HOME"/.claude*) return 1 ;;
  esac
  printf '%s' "$p"
}

update_one() {
  local name="$1"; local cname="$PREFIX$name"
  load_recipe "$name"
  info "updating '$name' ..."
  podman commit "$cname" "$(snap_img "$name")" >/dev/null 2>&1 && info "  saved rollback point" || true
  if [[ -n "${UPS_SETUP:-}" ]] && ! distrobox enter --name "$cname" -- bash -euo pipefail -c "$UPS_SETUP" </dev/null; then
    info "  '$name' setup failed - keeping the previous version (not marked updated)."
    return 1
  fi
  export_bins "$name"
  export_apps "$name"
  save_golden "$name"
  mark_updated "$name"
  info "updated '$name'."
}

cmd_update() {
  local target="${1:-}"; [[ -n "$target" ]] || die "usage: ups update <name|all>"
  ensure_tools
  if [[ "$target" == "all" ]]; then
    local n found=0 names=()
    mapfile -t names < <(list_names)
    for n in "${names[@]}"; do
      [[ -n "$n" ]] || continue; found=1
      update_one "$n" || info "  '$n' failed - continuing with the rest."
    done
    [[ "$found" == 1 ]] || info "nothing installed to update."
    return
  fi
  valid_name "$target"
  container_healthy "$target" || { info "'$target' needs repair first…"; heal_one "$target"; }
  container_exists "$target" || die "'$target' is not installed."
  update_one "$target"
}

cmd_rollback() {
  local name="${1:-}"; [[ -n "$name" ]] || die "usage: ups rollback <name>"
  ensure_tools; valid_name "$name"
  container_exists "$name" || die "'$name' is not installed."
  local cname="$PREFIX$name" snap; snap="$(snap_img "$name")"
  podman image exists "$snap" 2>/dev/null \
    || die "no rollback point for '$name' — rollback restores the version from before the last 'ups update' (none recorded yet)."
  info "rolling '$name' back to the previous version ..."
  local hargs=(); mapfile -t hargs < <(home_args "$name")
  nuke_container "$name"
  distrobox create --name "$cname" --image "$snap" "${hargs[@]}" --no-entry --yes >/dev/null
  if recipe_path "$name" >/dev/null 2>&1; then load_recipe "$name"; export_bins "$name"; export_apps "$name"; fi
  save_golden "$name"
  mark_updated "$name"
  info "rolled '$name' back.  (ups update $name to move forward again.)"
}

# --- doctor: the reliability spine ---

# Repair one app. Only acts if the container is genuinely unhealthy (re-checked
# here, so a transient probe failure in a shim never triggers a destructive
# rebuild). Prefers the offline golden image; falls back to a recipe rebuild.
heal_one() {
  local name="$1" golden; local cname="$PREFIX$name"
  if container_healthy "$name"; then info "'$name' is healthy."; return 0; fi

  golden="$(golden_img "$name")"
  local have_recipe=0; recipe_path "$name" >/dev/null 2>&1 && have_recipe=1
  [[ $have_recipe == 1 ]] && load_recipe "$name"   # for home_args / re-export / setup

  info "repairing '$name' (its container was orphaned — likely a base or podman upgrade) ..."
  nuke_container "$name"
  local hargs=(); mapfile -t hargs < <(home_args "$name")

  # 1) offline restore from the golden image
  if podman image exists "$golden" 2>/dev/null; then
    if distrobox create --name "$cname" --image "$golden" "${hargs[@]}" --no-entry --yes >/dev/null 2>&1 \
       && container_healthy "$name"; then
      export_bins "$name"; export_apps "$name"; mark_updated "$name"
      info "'$name' restored from its saved image."
      return 0
    fi
    info "  saved image didn't take — rebuilding from the recipe…"
    nuke_container "$name"
  fi

  # 2) full rebuild from the recipe (needs network)
  [[ $have_recipe == 1 ]] || die "cannot repair '$name': no saved image and no recipe. (ups erase $name, then re-add.)"
  create_and_setup "$name"
  export_bins "$name"; export_apps "$name"; mark_updated "$name"
  info "'$name' rebuilt from its recipe."
}

cmd_doctor() {
  ensure_tools
  local target="${1:-}"
  if [[ -z "$target" || "$target" == "all" || "$target" == "--all" ]]; then
    local n any=0 bad=0 names=()
    mapfile -t names < <(known_names)
    for n in "${names[@]}"; do
      [[ -n "$n" ]] || continue; any=1
      if container_healthy "$n"; then info "ok: $n"; else bad=1; heal_one "$n"; fi
    done
    [[ $any == 1 ]] || { info "no upstream apps installed."; return; }
    [[ $bad == 0 ]] && info "all upstream apps healthy."
    return
  fi
  valid_name "$target"
  is_known "$target" || die "'$target' is not installed."
  heal_one "$target"
}

cmd_autoupdate() {
  local freq="${1:-}"
  command -v systemctl >/dev/null 2>&1 || die "systemd not available here; can't manage autoupdate."
  local unitdir="$HOME/.config/systemd/user"
  local svc="$unitdir/ups-autoupdate.service" tmr="$unitdir/ups-autoupdate.timer"
  case "$freq" in
    ""|status)
      if systemctl --user is-enabled ups-autoupdate.timer >/dev/null 2>&1; then
        info "autoupdate: ON"
        systemctl --user list-timers ups-autoupdate.timer --no-pager 2>/dev/null | sed -n '1,2p' >&2 || true
      else
        info "autoupdate: off.  set with: ups autoupdate <daily|weekly|monthly>"
      fi
      return ;;
    off)
      systemctl --user disable --now ups-autoupdate.timer >/dev/null 2>&1 || true
      rm -f "$svc" "$tmr"; systemctl --user daemon-reload >/dev/null 2>&1 || true
      info "autoupdate: off."; return ;;
    daily|weekly|monthly) : ;;
    *) die "usage: ups autoupdate <daily|weekly|monthly|off>" ;;
  esac
  mkdir -p "$unitdir"
  cat > "$svc" <<EOF
[Unit]
Description=ups — update all upstream apps

[Service]
Type=oneshot
Environment=PATH=/run/current-system/sw/bin:%h/.local/bin
# Same connectivity gate as the NixOS daily upgrade: wait until the network is
# really up (survives the post-wake DNS race) before pulling any images.
ExecStartPre=/run/current-system/sw/bin/golem-wait-online
ExecStart=/run/current-system/sw/bin/ups update all
EOF
  cat > "$tmr" <<EOF
[Unit]
Description=ups — scheduled upstream update ($freq)

[Timer]
OnCalendar=$freq
Persistent=true

[Install]
WantedBy=timers.target
EOF
  systemctl --user daemon-reload
  systemctl --user enable --now ups-autoupdate.timer >/dev/null 2>&1
  info "autoupdate: $freq.  (each run snapshots first, so 'ups rollback' can undo a bad release.)"
}

cmd_list() {
  ensure_tools
  local names; names="$(known_names)"
  if [[ -z "$names" ]]; then info "no upstream apps installed."; return; fi
  printf '%-20s %-17s %-8s %s\n' "PACKAGE" "UPDATED" "HEALTH" "COMMANDS"
  local n
  while IFS= read -r n; do
    [[ -n "$n" ]] || continue
    local health="ok"; container_healthy "$n" || health="needs-fix"
    printf '%-20s %-17s %-8s %s\n' "$n" "$(updated_str "$n")" "$health" "$(exported_bins "$n")"
  done <<< "$names"
}

cmd_catalog() {
  printf '%-20s %s\n' "RECIPE" "DESCRIPTION"
  local dir f name seen=" "
  for dir in "$USER_RECIPES" "$SYS_RECIPES"; do
    [[ -d "$dir" ]] || continue
    for f in "$dir"/*.sh; do
      [[ -f "$f" ]] || continue
      name="$(basename "$f" .sh)"
      [[ "$seen" == *" $name "* ]] && continue
      seen="$seen$name "
      ( UPS_DESC=""; # shellcheck disable=SC1090
        source "$f"; printf '%-20s %s\n' "$name" "${UPS_DESC:-}" )
    done
  done
}

cmd_enter() {
  local name="${1:-}"; [[ -n "$name" ]] || die "usage: ups enter <name>"
  ensure_tools; valid_name "$name"
  container_exists "$name" || die "'$name' is not installed."
  container_healthy "$name" || heal_one "$name"
  exec distrobox enter --name "$PREFIX$name"
}

path_hint() {
  case ":$PATH:" in
    *":$BIN_DIR:"*) : ;;
    *) info "note: $BIN_DIR isn't on PATH yet. Run it now via: $BIN_DIR/<app> — and log out/in once so every terminal finds it (first-time only)." ;;
  esac
}

usage() {
  cat >&2 <<'EOF'
ups — the Golem upstream lane. Run bleeding-edge upstream apps, installed under
their real name and backed by per-app rootless containers, without touching the
declarative base. Reversible: erase and the stock app returns.

  ups add    <name>       install the upstream build (real name; GUI icon lands
                          on the app-box automatically). Asks before taking over
                          a stock command; --yes to skip the prompt.
  ups erase  <name>       remove it (container + command + icon + cached image).
                          --purge also deletes the app's own settings.
  ups update <name|all>   pull the latest upstream build
  ups rollback <name>     undo the last update
  ups doctor [name]       check/repair containers (auto-invoked by the apps)
  ups autoupdate <daily|weekly|monthly|off>   schedule automatic updates
  ups list                what is installed (+ health)
  ups catalog             recipes available to add
  ups enter  <name>       drop into the container's shell (debugging)

Add your own apps by dropping a recipe in ~/.config/ups/recipes.d/<name>.sh
(see /etc/ups/recipes.d for the format).
EOF
}

main() {
  local cmd="${1:-}"; shift || true
  cmd="${cmd#--}"
  case "$cmd" in
    add|install)               cmd_add "$@" ;;
    addbox|box)                cmd_add "$@" ;;   # kept as an alias; add now does both
    erase|rm|remove|uninstall) cmd_erase "$@" ;;
    update|upgrade)            cmd_update "$@" ;;
    rollback|undo)             cmd_rollback "$@" ;;
    doctor|repair|heal|fix)    cmd_doctor "$@" ;;
    autoupdate|auto)           cmd_autoupdate "$@" ;;
    list|ls)                   cmd_list ;;
    catalog|available)         cmd_catalog ;;
    enter|shell)               cmd_enter "$@" ;;
    ""|help|-h|h)              usage ;;
    *) die "unknown command '$cmd' — try 'ups help'" ;;
  esac
}

main "$@"
