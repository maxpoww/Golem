#!/usr/bin/env bash
# golem-parity collector: a snapshot of how THIS machine's desktop actually
# behaves, read from the running session (not from the config we think we
# shipped). Runs as the desktop's owner, on any Golem machine, with nothing
# but bash + coreutils + grep; `golem-parity` runs it over ssh and compares.
#
# Output: sections, each opened by a line "===<name>===".
set -u

# The compositor itself: its process name, never a command line that merely
# mentions it (container launchers carry HYPRLAND_CMD=… in theirs).
hpid=$(pgrep -u "$(id -u)" -x Hyprland 2>/dev/null || pgrep -u "$(id -u)" -x .Hyprland-wrapp 2>/dev/null)
hpid=${hpid%%$'\n'*}
section() { printf '===%s===\n' "$1"; }

if [[ -z "$hpid" ]]; then
  section error; echo "no Hyprland session for $(id -un)"; exit 0
fi

# The environment every bind and app inherits. Hyprland applies its hl.env()
# values (SHELL, …) and its instance signature to the processes it starts, not
# to itself, so read a CHILD of the compositor; fall back to Hyprland's own.
envpid=$hpid
for c in $(pgrep -P "$hpid" 2>/dev/null); do
  grep -qz '^HYPRLAND_INSTANCE_SIGNATURE=' "/proc/$c/environ" 2>/dev/null && { envpid=$c; break; }
done
declare -A henv
while IFS= read -r -d '' kv; do henv["${kv%%=*}"]="${kv#*=}"; done < "/proc/$envpid/environ" 2>/dev/null

export XDG_RUNTIME_DIR="${henv[XDG_RUNTIME_DIR]:-/run/user/$(id -u)}"
# hyprctl from the compositor's own package. /proc/<pid>/exe can be unreadable
# (a Toolbx container sees the host session through another user namespace),
# but the command line names the binary too.
hexe=$(readlink -f "/proc/$hpid/exe" 2>/dev/null)
[[ -n "$hexe" ]] || hexe=$(tr '\0' '\n' < "/proc/$hpid/cmdline" | head -1)
hyprctl="$(dirname "$hexe")/hyprctl"
[[ -x "$hyprctl" ]] || hyprctl=$(command -v hyprctl)
# The live instance: the child's signature, else the first socket that answers
# (stale instance dirs from earlier sessions linger in $XDG_RUNTIME_DIR/hypr).
export HYPRLAND_INSTANCE_SIGNATURE="${henv[HYPRLAND_INSTANCE_SIGNATURE]:-}"
if ! "$hyprctl" version >/dev/null 2>&1; then
  for d in "$XDG_RUNTIME_DIR"/hypr/*/; do
    HYPRLAND_INSTANCE_SIGNATURE=$(basename "$d")
    "$hyprctl" version >/dev/null 2>&1 && break
  done
fi

# What a keybind would inherit RIGHT NOW: have the compositor spawn a probe
# (an old child still carries the environment of an earlier config). Falls
# back to the newest child of the compositor.
probe="$XDG_RUNTIME_DIR/golem-parity.env"
rm -f "$probe"
"$hyprctl" eval "hl.exec_cmd(\"env -0 > $probe.tmp && mv $probe.tmp $probe\")" >/dev/null 2>&1
for _ in 1 2 3 4 5 6 7 8 9 10; do [[ -s "$probe" ]] && break; sleep 0.2; done
if [[ -s "$probe" ]]; then
  unset henv; declare -A henv
  while IFS= read -r -d '' kv; do henv["${kv%%=*}"]="${kv#*=}"; done < "$probe"
  rm -f "$probe"
else
  c=$(pgrep -n -P "$hpid" 2>/dev/null)
  if [[ -n "$c" ]]; then
    unset henv; declare -A henv
    while IFS= read -r -d '' kv; do henv["${kv%%=*}"]="${kv#*=}"; done < "/proc/$c/environ" 2>/dev/null
  fi
fi

section meta
echo "host=$(hostname)"
echo "product=$(cat /sys/class/dmi/id/product_name 2>/dev/null)"
echo "hyprland=$("$hyprctl" version 2>/dev/null | head -1)"

# Every option's EFFECTIVE value. `descriptions -j` lists the names, but its
# "current" field misreports options set from the Lua config (rounding 12 shows
# as 0), so the values come from getoption, in one batch.
section options
names=$("$hyprctl" descriptions -j 2>/dev/null | grep -oE '"name": "[^"]+"' | sed -E 's/"name": "(.*)"/\1/')
batch=$(printf 'j/getoption %s;' $names)
"$hyprctl" --batch "$batch" 2>&1
section binds;         "$hyprctl" binds -j 2>&1
section configerrors;  "$hyprctl" configerrors 2>&1
section plugins;       "$hyprctl" plugin list 2>&1

section env
for k in SHELL PATH XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_DATA_DIRS LANG TERMINAL BROWSER EDITOR; do
  echo "$k=${henv[$k]:-}"
done

# $SHELL must exist: every bare terminal (Super+E → foot) execs it.
section shell
s="${henv[SHELL]:-}"
if [[ -n "$s" && -x "$s" ]]; then echo "ok $s"; else echo "MISSING ${s:-<unset>}"; fi

# The config the session actually loaded.
lua="$HOME/.config/hypr/hyprland.lua"
section lua; cat "$lua" 2>/dev/null

# Every command the config can run: does its program exist in the session PATH?
section commands
grep -oE 'exec_cmd\("([^"\\]|\\.)*"\)' "$lua" 2>/dev/null \
  | sed -E 's/^exec_cmd\("//; s/"\)$//' | sort -u | while IFS= read -r cmd; do
    prog=${cmd%% *}
    if [[ "$prog" == /* ]]; then
      [[ -x "$prog" ]] && r=ok || r=MISSING
    else
      PATH="${henv[PATH]:-$PATH}" command -v "$prog" >/dev/null 2>&1 && r=ok || r=MISSING
    fi
    printf '%s\t%s\n' "$r" "$cmd"
  done

section failed_user;   systemctl --user --failed --plain --no-legend 2>/dev/null
section failed_system; systemctl --failed --plain --no-legend 2>/dev/null

# What the menubox can show: desktop entries by ID (first match on the XDG
# path wins, the user dir first), minus NoDisplay/Hidden.
section menubox
{
  echo "$HOME/.local/share"
  tr ':' '\n' <<<"${henv[XDG_DATA_DIRS]:-/run/current-system/sw/share}"
} | while IFS= read -r d; do
  for f in "$d"/applications/*.desktop; do [[ -e "$f" ]] && printf '%s\t%s\n' "$(basename "$f")" "$f"; done
done | awk -F'\t' '!seen[$1]++' | while IFS=$'\t' read -r id f; do
  if grep -qiE '^(NoDisplay|Hidden)=true' "$f"; then continue; fi
  grep -qE '^Type=Application' "$f" || continue
  # Does the entry's program exist? A launcher that runs nothing is a bug.
  exe=$(grep -m1 -E '^Exec=' "$f" | sed -E 's/^Exec=//; s/^env( [A-Za-z_]+=[^ ]*)+ //')
  prog=${exe%% *}
  if [[ "$prog" == /* ]]; then [[ -x "$prog" ]] && r=ok || r=DEAD
  else PATH="${henv[PATH]:-$PATH}" command -v "$prog" >/dev/null 2>&1 && r=ok || r=DEAD; fi
  printf '%s\t%s\t%s\n' "$r" "$id" "$prog"
done

# The owner's installed-app list (the menubox is Seam + these).
section apps
grep -vE '^\s*(#|$)' "$HOME/.config/waverunner/packages.list" 2>/dev/null
