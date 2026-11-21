#!/usr/bin/env bash
# test/check.sh [machine.lua | <built tree> [<generated entry>]]: Standard's
# Hyprland configuration checked with no compositor (check.lua, on the
# recording mock). `lua` (5.4) from PATH or $LUA.
#   no argument    this folder's modules with the sample facts;
#   machine.lua    this folder's modules with those facts;
#   <built tree>   the store folder a machine really loads (its modules, its
#                  facts), and with <generated entry> the one file its home
#                  holds (~/.config/hypr/hyprland.lua), run as Hyprland runs
#                  it. This is what the flake's check `hypr-config` does.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
hypr=$(dirname "$here")
LUA=${LUA:-lua}
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
src=$hypr; facts=${1:-$here/machine.sample.lua}; entry=${2:-}; real=$work/real
if [ -d "${1:-}" ]; then src=$1; facts=$1/standard/machine.lua; real=$1; fi
tree() { # <root> <machine.lua>
  mkdir -p "$1"; cp -r "$src/hyprland.lua" "$src/standard" "$1/"; chmod -R u+w "$1"; cp "$2" "$1/standard/machine.lua"
}
[ "$real" != "$work/real" ] || tree "$work/real" "$facts"
tree "$work/layers" "$here/machine.sample.lua"
# The same machine with the Gaming module on: its facts, "gaming" among the modules.
tree "$work/gaming" "$facts"
mv "$work/gaming/standard/machine.lua" "$work/gaming/standard/machine.facts.lua"
printf 'local M = dofile("%s")\nM.modules = { "gaming" }\nreturn M\n' \
  "$work/gaming/standard/machine.facts.lua" > "$work/gaming/standard/machine.lua"
echo 'hl.config({ general = { gaps_in = 21 } })' > "$work/layers/standard/modules/demo.lua"
echo 'hl.config({ general = { gaps_in = 22 } })' > "$work/layers/standard/extra.lua"
echo 'hl.config({ general = { gaps_in = 23 } })' > "$work/layers/user.lua"
# The home as a machine has it: ONE file of Standard's, the generated entry.
# Beside it, the owner's own file, and a file where a module of Standard's
# would be if the modules were looked for here first (they are not).
if [ -n "$entry" ]; then
  mkdir -p "$work/home/standard"; cp "$entry" "$work/home/hyprland.lua"
  echo 'hl.config({ general = { gaps_in = 23 } })' > "$work/home/user.lua"
  echo 'hl.config({ general = { gaps_in = 24 } })' > "$work/home/standard/look.lua"
fi
mkdir -p "$work/config/golem" "$work/state" "$work/homedir"
echo 'hl.config({ general = { gaps_in = 7 } })' > "$work/config/golem/settings.lua"
# (The screens' blocks are WRITTEN under XDG_STATE_HOME: never the owner's.)
HOME="$work/homedir" XDG_STATE_HOME="$work/state" XDG_CONFIG_HOME="$work/config" \
  "$LUA" "$here/check.lua" "$real" "$work/layers" "$work/gaming" ${entry:+"$work/home"}
