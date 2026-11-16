#!/usr/bin/env bash
# golem-screenshot-test.sh — golem-screenshot.sh run against stand-ins for the
# screen (grim, slurp, hyprctl), the clipboard (wl-copy) and the notification
# (notify-send). Builds nothing: needs bash, coreutils and jq on PATH.
#
#   bash system/home/golem-screenshot-test.sh
#
# Each stand-in writes what it was asked into $log, so a case reads back
# exactly which screen or rectangle was shot and what was said. Exits non-zero
# on any failure.

set -u
here=$(cd "${BASH_SOURCE[0]%/*}" && pwd)
command -v jq >/dev/null || { echo "golem-screenshot-test.sh: needs jq on PATH" >&2; exit 2; }

fails=0
bad() { echo "FAIL $*"; fails=$((fails + 1)); }

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
bin=$scratch/bin
mkdir -p "$bin"
log=$scratch/log

# grim: its last argument is the file. GRIM_FAILS=1: no picture.
cat > "$bin/grim" <<'EOF'
#!/usr/bin/env bash
echo "grim $*" >> "$LOG"
[ -z "${GRIM_FAILS-}" ] || exit 1
for last; do :; done
printf 'PNG %s' "$*" > "$last"
EOF
# slurp: the rectangle in SLURP, or Esc (exit 1) without one.
cat > "$bin/slurp" <<'EOF'
#!/usr/bin/env bash
echo "slurp $*" >> "$LOG"
[ -n "${SLURP-}" ] || exit 1
echo "$SLURP"
EOF
cat > "$bin/hyprctl" <<'EOF'
#!/usr/bin/env bash
[ -z "${HYPR_DEAD-}" ] || exit 1
case "$*" in
  "-j monitors") echo "${MONITORS-[]}" ;;
  "-j activewindow") echo "${WINDOW-{\}}" ;;
  *) exit 1 ;;
esac
EOF
cat > "$bin/wl-copy" <<'EOF'
#!/usr/bin/env bash
echo "wl-copy $*" >> "$LOG"
[ -z "${COPY_FAILS-}" ] || exit 1
cat > "$CLIP"
EOF
# notify-send: one argument a line. ANSWER: what the click answered.
cat > "$bin/notify-send" <<'EOF'
#!/usr/bin/env bash
{ echo "notify-send"; printf '  %s\n' "$@"; } >> "$LOG"
[ -z "${ANSWER-}" ] || echo "$ANSWER"
EOF
cat > "$bin/xdg-open" <<'EOF'
#!/usr/bin/env bash
echo "xdg-open $*" >> "$LOG"
EOF
cat > "$bin/xdg-user-dir" <<'EOF'
#!/usr/bin/env bash
echo "${PICTURES-$HOME}"
EOF
cat > "$bin/golem-say" <<EOF
#!/usr/bin/env bash
GOLEM_SAY_DIR=$here/../i18n
. "$here/../i18n/golem-say.sh"
EOF
chmod +x "$bin"/*

two_screens='[{"name":"eDP-1","focused":false},{"name":"HDMI-A-1","focused":true}]'
a_window='{"mapped":true,"hidden":false,"at":[100,50],"size":[800,600]}'

# run MODE [VAR=value…] — a fresh home each time; the shell options are the
# packaged command's (writeShellApplication: errexit, nounset, pipefail).
run() {
  local mode=$1
  shift
  home=$scratch/home.$RANDOM$RANDOM
  mkdir -p "$home" "$scratch/rt"
  : > "$log"
  rm -f "$scratch/clip"
  env -i PATH="$bin:$PATH" HOME="$home" XDG_RUNTIME_DIR="$scratch/rt" LANG=C \
    LOG="$log" CLIP="$scratch/clip" GOLEM_SHOT_NOW="2026-11-16 14:03:21" "$@" \
    bash -euo pipefail "$here/golem-screenshot.sh" "$mode"
  status=$?
  # The notification is posted from a process left behind: wait for it.
  local i=0
  while [ "$i" -lt 40 ] && pgrep -f "$scratch/rt" >/dev/null 2>&1; do sleep 0.05; i=$((i + 1)); done
  sleep 0.2
}
said() { grep -qF -- "$1" "$log"; }
shot=$'Screenshot 2026-11-16 14-03-21.png'

# 1. The whole screen: the one the keyboard is on, saved, copied, shown.
run screen MONITORS="$two_screens"
f="$home/Pictures/Screenshots/$shot"
[ "$status" -eq 0 ] || bad "screen: exit $status"
said "grim -o HDMI-A-1 " || bad "screen: not the focused screen: $(grep ^grim "$log")"
[ -s "$f" ] || bad "screen: no file at $f"
cmp -s "$f" "$scratch/clip" || bad "screen: the clipboard is not the file"
said "wl-copy --type image/png" || bad "screen: clipboard type"
said "  Screenshot saved" || bad "screen: no title"
said "  It is in ~/Pictures/Screenshots and on the clipboard." || bad "screen: body: $(cat "$log")"
said "  string:image-path:$f" || bad "screen: the notification has no picture"
said "  default=Open" || bad "screen: no click answer"
said "xdg-open" && bad "screen: opened without a click"
[ -z "$(ls "$scratch/rt")" ] || bad "screen: left $(ls "$scratch/rt") behind"
[ -z "$(ls "$home/Pictures/Screenshots" | grep -v "^$shot$")" ] || bad "screen: stray files in the folder"

# 2. A click on the notification opens the file.
run screen MONITORS="$two_screens" ANSWER=default
said "xdg-open $home/Pictures/Screenshots/$shot" || bad "click: did not open the file"

# 3. No compositor answer: every screen.
run screen HYPR_DEAD=1
said "grim $scratch/rt/" || bad "no compositor: $(grep ^grim "$log")"
[ -s "$home/Pictures/Screenshots/$shot" ] || bad "no compositor: no file"

# 4. A region.
run region SLURP="10,20 300x200"
said "grim -g 10,20 300x200 " || bad "region: $(grep ^grim "$log")"
[ -s "$home/Pictures/Screenshots/$shot" ] || bad "region: no file"

# 5. Esc in the region: nothing shot, nothing said, nothing left.
run region
[ "$status" -eq 0 ] || bad "esc: exit $status"
said grim && bad "esc: shot anyway"
said notify-send && bad "esc: said something"
[ ! -e "$home/Pictures" ] || bad "esc: made a folder"
[ ! -e "$scratch/clip" ] || bad "esc: touched the clipboard"
[ -z "$(ls "$scratch/rt")" ] || bad "esc: left a file behind"

# 6. The window the keyboard is in.
run window WINDOW="$a_window" MONITORS="$two_screens"
said "grim -g 100,50 800x600 " || bad "window: $(grep ^grim "$log")"

# 7. No window (an empty desk), and a hidden one: the screen.
run window MONITORS="$two_screens"
said "grim -o HDMI-A-1 " || bad "no window: $(grep ^grim "$log")"
run window WINDOW='{"mapped":true,"hidden":true,"at":[0,0],"size":[10,10]}' MONITORS="$two_screens"
said "grim -o HDMI-A-1 " || bad "hidden window: $(grep ^grim "$log")"

# 8. The Pictures folder in the owner's language.
mkdir -p "$scratch/es"
run screen PICTURES="$scratch/es/Imágenes"
[ -s "$scratch/es/Imágenes/Screenshots/$shot" ] || bad "localized: no file"
rm -rf "$scratch/es"

# 9. Spanish: the words, and the folder inside them.
run screen LANG=es_BO.UTF-8
said "  Captura guardada" || bad "spanish: $(cat "$log")"
said "~/Pictures/Screenshots" || bad "spanish: the folder is not in the line"
said "  default=Abrir" || bad "spanish: the click answer"

# 10. Two shots in one second: both kept.
run screen
env -i PATH="$bin:$PATH" HOME="$home" XDG_RUNTIME_DIR="$scratch/rt" LANG=C LOG="$log" CLIP="$scratch/clip" \
  GOLEM_SHOT_NOW="2026-11-16 14:03:21" bash -euo pipefail "$here/golem-screenshot.sh" screen
sleep 0.3
[ -s "$home/Pictures/Screenshots/Screenshot 2026-11-16 14-03-21 (2).png" ] || bad "same second: the second shot is missing"
[ "$(ls "$home/Pictures/Screenshots" | wc -l)" -eq 2 ] || bad "same second: $(ls "$home/Pictures/Screenshots")"

# 11. The folder cannot be written: the clipboard still has it, and it says so.
if [ "$(id -u)" -ne 0 ]; then
  home=$scratch/home.ro
  mkdir -p "$home/Pictures"
  chmod 555 "$home/Pictures"
  : > "$log"
  env -i PATH="$bin:$PATH" HOME="$home" XDG_RUNTIME_DIR="$scratch/rt" LANG=C LOG="$log" CLIP="$scratch/clip" \
    bash -euo pipefail "$here/golem-screenshot.sh" screen
  status=$?
  sleep 0.3
  [ "$status" -eq 0 ] || bad "read-only: exit $status"
  [ -s "$scratch/clip" ] || bad "read-only: nothing on the clipboard"
  said "  The screenshot is on the clipboard" || bad "read-only: $(cat "$log")"
  said "  It could not be saved in ~/Pictures/Screenshots." || bad "read-only: body"
  chmod 755 "$home/Pictures"
fi

# 12. The clipboard fails: the file is there, and the line does not promise it.
run screen COPY_FAILS=1
[ -s "$home/Pictures/Screenshots/$shot" ] || bad "no clipboard: no file"
said "  It is in ~/Pictures/Screenshots." || bad "no clipboard: $(cat "$log")"

# 13. No picture at all: it says so, and fails.
run screen GRIM_FAILS=1
[ "$status" -ne 0 ] || bad "no picture: exit 0"
said "  The screenshot could not be taken" || bad "no picture: said nothing"
[ ! -e "$home/Pictures" ] || bad "no picture: made a folder"
[ -z "$(ls "$scratch/rt")" ] || bad "no picture: left a file behind"

# 14. A wrong word.
run nonsense
[ "$status" -eq 2 ] || bad "usage: exit $status"

if [ "$fails" -eq 0 ]; then
  echo "golem-screenshot: all cases pass"
else
  echo "golem-screenshot: $fails failed"
  exit 1
fi
