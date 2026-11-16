# golem-screenshot — a picture of the screen, kept and on the clipboard.
#
#   golem-screenshot region    drag a rectangle (Esc: nothing happens)
#   golem-screenshot screen    the screen the keyboard is on, whole
#   golem-screenshot window    the window the keyboard is in
#
# Every shot does the same three things: a PNG in the Pictures folder's
# Screenshots ("Screenshot 2026-11-16 14-03-21.png"), the same picture on the
# clipboard, and a notification that shows it (a click on it opens the file).
# The clipboard never waits for the file: a full disk or a read-only home
# still gives a shot that pastes, and the notification says the file is not
# there.
#
# The keys are in hyprland.lua (Print, Shift+Print, Alt+Print). The body of
# the `golem-screenshot` command (screenshot.nix). golem-screenshot-test.sh,
# beside this, runs it against stand-ins for the screen and the clipboard.
#
# GOLEM_SHOT_NOW: the moment in the file's name, as `date -d` reads it (tests).

mode=${1:-region}
case $mode in
  region | screen | window) ;;
  *)
    echo "usage: golem-screenshot region|screen|window" >&2
    exit 2
    ;;
esac

say() { golem-say "$@"; }

runtime=${XDG_RUNTIME_DIR:-/tmp}
tmp=$(mktemp "$runtime/golem-screenshot.XXXXXX.png") || exit 1
trap 'rm -f "$tmp"' EXIT

failed() {
  notify-send -a Golem "$(say "The screenshot could not be taken")" || true
  exit 1
}

# The screen the keyboard is on. Empty when the compositor does not answer:
# grim then takes every screen, which is still a screenshot.
focused_screen() {
  hyprctl -j monitors 2>/dev/null \
    | jq -r 'first(.[] | select(.focused == true) | .name) // empty' 2>/dev/null
}

# grim, with a limit: a screen that is not being drawn (off, or the session
# stalled) never answers, and the key must not leave a process waiting on it.
shoot() { timeout 10 grim "$@" "$tmp"; }

shoot_screen() {
  local out
  out=$(focused_screen) || out=
  if [ -n "$out" ]; then
    shoot -o "$out"
  else
    shoot
  fi
}

case $mode in
  region)
    # Esc, or a click without a drag: slurp says so with a non-zero exit and
    # nothing is shot, nothing is said.
    geom=$(slurp -d 2>/dev/null) || exit 0
    [ -n "$geom" ] || exit 0
    shoot -g "$geom" || failed
    ;;
  screen)
    shoot_screen || failed
    ;;
  window)
    # "x,y wxh" of the window, in the layout's own units (what grim -g takes).
    # A window that is hidden or has no size (none focused: an empty desk)
    # gives the whole screen instead.
    geom=$(hyprctl -j activewindow 2>/dev/null \
      | jq -r 'select(.mapped == true and .hidden != true and .size[0] > 0 and .size[1] > 0)
               | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' 2>/dev/null) || geom=
    if [ -n "$geom" ]; then
      shoot -g "$geom" || failed
    else
      shoot_screen || failed
    fi
    ;;
esac
[ -s "$tmp" ] || failed

# The clipboard first: it is what a hand reaches for next.
copied=1
wl-copy --type image/png < "$tmp" || copied=0

# The Pictures folder as the owner's language names it (~/Imágenes). An
# unset one answers $HOME: then ~/Pictures.
pictures=$(xdg-user-dir PICTURES 2>/dev/null) || pictures=
if [ -z "$pictures" ] || [ "${pictures%/}" = "${HOME%/}" ]; then
  pictures=$HOME/Pictures
fi
dir=$pictures/Screenshots
stamp=$(date ${GOLEM_SHOT_NOW:+-d "$GOLEM_SHOT_NOW"} '+%Y-%m-%d %H-%M-%S')
file=
if mkdir -p "$dir" 2>/dev/null; then
  # Two shots inside one second: the second is "… (2).png". The file arrives
  # whole under its name (written beside it, then moved without replacing).
  n=1
  while [ "$n" -le 50 ]; do
    if [ "$n" -eq 1 ]; then
      try="$dir/Screenshot $stamp.png"
    else
      try="$dir/Screenshot $stamp ($n).png"
    fi
    if [ ! -e "$try" ] && cp -- "$tmp" "$try.part" 2>/dev/null \
      && mv -n -- "$try.part" "$try" 2>/dev/null && [ ! -e "$try.part" ]; then
      file=$try
      break
    fi
    rm -f -- "$try.part"
    # A folder that takes no file at all: stop, not 50 tries.
    [ -e "$try" ] || break
    n=$((n + 1))
  done
fi

# The folder as it is read: ~/Pictures/Screenshots.
case $dir in
  "$HOME"/*) shown="~"/${dir#"$HOME"/} ;;
  *) shown=$dir ;;
esac

if [ -n "$file" ] && [ "$copied" -eq 1 ]; then
  title=$(say "Screenshot saved")
  body=$(say "It is in {0} and on the clipboard." "$shown")
elif [ -n "$file" ]; then
  title=$(say "Screenshot saved")
  body=$(say "It is in {0}." "$shown")
elif [ "$copied" -eq 1 ]; then
  title=$(say "The screenshot is on the clipboard")
  body=$(say "It could not be saved in {0}." "$shown")
else
  failed
fi

if [ -z "$file" ]; then
  notify-send -a Golem "$title" "$body" || true
  exit 0
fi

# The notification carries the picture, and a click on it opens the file.
# notify-send stays until the notification is answered or gone, so it is left
# behind (with a limit: a notification kept in the list all day does not keep
# a process). The shot itself is done; the key never waits for this.
(
  trap - EXIT
  answer=$(timeout 300 notify-send -a Golem -i "$file" -h "string:image-path:$file" \
    -A "default=$(say "Open")" "$title" "$body" 2>/dev/null) || answer=
  if [ "$answer" = default ]; then
    xdg-open "$file" >/dev/null 2>&1 || true
  fi
) </dev/null >/dev/null 2>&1 &
disown 2>/dev/null || true
exit 0
