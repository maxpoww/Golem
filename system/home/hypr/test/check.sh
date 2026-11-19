#!/usr/bin/env bash
# test/check.sh [machine.lua]: Golem's Hyprland configuration checked with no
# compositor (check.lua, on the recording mock). With no argument the sample
# facts stand in for a machine's generated ones. `lua` (5.4) from PATH or $LUA.
# The flake's check `hypr-config` runs this with a real machine's facts.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
hypr=$(dirname "$here")
LUA=${LUA:-lua}
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
tree() { # <root> <machine.lua>
  mkdir -p "$1"; cp -r "$hypr/hyprland.lua" "$hypr/golem" "$1/"; chmod -R u+w "$1"; cp "$2" "$1/golem/machine.lua"
}
tree "$work/real" "${1:-$here/machine.sample.lua}"
tree "$work/layers" "$here/machine.sample.lua"
echo 'hl.config({ general = { gaps_in = 21 } })' > "$work/layers/golem/modules/demo.lua"
echo 'hl.config({ general = { gaps_in = 22 } })' > "$work/layers/golem/extra.lua"
echo 'hl.config({ general = { gaps_in = 23 } })' > "$work/layers/user.lua"
mkdir -p "$work/config/golem" "$work/state" "$work/home"
echo 'hl.config({ general = { gaps_in = 7 } })' > "$work/config/golem/settings.lua"
# (The screens' blocks are WRITTEN under XDG_STATE_HOME: never the owner's.)
HOME="$work/home" XDG_STATE_HOME="$work/state" XDG_CONFIG_HOME="$work/config" \
  "$LUA" "$here/check.lua" "$work/real" "$work/layers"
