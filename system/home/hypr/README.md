# Hyprland, in modules

Golem's Hyprland configuration. It was one file of a thousand lines
(`system/home/hyprland.lua`) that `home.nix` rewrote per machine by swapping
strings in it; since 2026-11-19 it is this folder: one file a concern, the
same text on every machine, and ONE generated file that says what differs.

On a machine it is `~/.config/hypr/` (links into the store, made by
`system/home/home.nix`).

## The map

| File | What it holds |
|---|---|
| `hyprland.lua` | The entry. Configures nothing: it loads the modules in order, then the layers after Golem's (below). |
| `golem/lib.lua` | What the modules share: this machine's facts (`machine`), the names the binds use (programs, main modifier, the windows' corner), the one piece of state two files touch (`superBurst`). A table, never globals. |
| `golem/machine.lua` | **Generated, not in this folder.** The machine's facts as a Lua table: `dev`, `ctl`, `plugin`, `dock`, `shell`, `keyboard`, `panel_dpi`, `panel_scale`, `bluetooth`, `effects`, `lab`, `modules`. Written by `home.nix` (`xdg.configFile."hypr/golem/machine.lua"`). Without it (a copy run by hand) `lib.lua` answers as a plain install would. |
| `golem/monitors.lua` | Every screen at its preferred size and a scale for its density; the laptop panel's own scale (`machine.panel_scale`). |
| `golem/layers.lua` | The shell's surfaces (dock, bar, desktop, its menus): blurred behind, frosted glass. |
| `golem/autostart.lua` | What starts with the session: the lock screen FIRST (it is the login), the overview plugin, the cursor, the dock on the dev box, the wallpaper daemon, Bluetooth where there is an adapter. |
| `golem/environment.lua` | What every program started from the session is told (`SHELL`, `TZDIR`, `TERMINAL`, the Wayland hints). |
| `golem/compat.lua` | What apps need to behave: XWayland scaling, popups and dialogs that would open hidden, unfocused or tiled. |
| `golem/gestures.lua` | The touchpad's swipes between desks. |
| `golem/look.lua` | Gaps, borders, magnets, the windows' corner, dimming, shadows, blur; nothing blurred behind a window. |
| `golem/animations.lua` | The curves (the `easy` spring is waveview's too) and what moves on them. |
| `golem/layout.lua` | How tiles split (dwindle beside the pointer), master, scrolling. |
| `golem/misc.lua` | Direct scanout, VRR, the bare grey, DPMS wake-ups, the log, the hardware cursor, no update news. |
| `golem/input.lua` | Keyboard (`machine.keyboard`, the installer's answer), focus by click, touchpad. |
| `golem/binds/apps.lua` | Keys that open a program (terminal, files). |
| `golem/binds/shell.lua` | Keys of Golem's shell: lock, the dock box (a tap of Super), voice to text, fast launch, quick controls, the card, the control panel, the walk round windows and screens, the overview, STAGE and its own keymap. |
| `golem/binds/windows.lua` | Keys that act on the window in hand: close, float, pseudo, focus, move, resize, Super+drag. |
| `golem/screens.lua` | Each screen its own block of desks (remembered in `~/.local/state/golem/screens`), and Super+digits. |
| `golem/binds/keys.lua` | The keyboard's own keys: power, volume, brightness, keyboard light, player, Print Screen. |
| `golem/rules.lua` | The windows' look by state: floating corners, the browser's hairline, floats raised on focus, smart gaps, shadows, the pseudo and stage frames. |
| `golem/effects.lua` | A weak GPU (`machine.effects == "light"`): compositor blur off. |
| `golem/lab.lua` | A lab machine (`machine.lab`): the whole log. |
| `golem/modules/` | The app modules' own Lua (`<name>.lua`): rules and keys a module of programs brings. Loaded for the names in `machine.modules` (`golem.home.hyprlandModules`). Today: `gaming.lua` (a game that fills the screen keeps the computer awake). |
| `golem/extra.lua` | **Generated when set:** this machine's own Lua (`golem.home.hyprlandExtra`). |
| `test/` | The recording mock, the comparison tool, the check (below). Not deployed. |

## The order is the contract

Rules of the same weight are settled by the last one declared, so the entry
loads in this order and nothing may be moved without a reason:

1. **Golem's modules** — in the order the one file had them (monitors, layers,
   autostart, environment, compat, gestures, look, animations, layout, misc,
   input, the binds, screens, the keys, rules, effects, lab). `rules.lua`
   comes after `look.lua` and `compat.lua` because its rules hand corners,
   borders and shadows back to tagged windows; `effects.lua` and `lab.lua`
   come after everything because they take a default away.
2. **The app modules' own Lua** (`golem/modules/<name>.lua`, for the modules
   that are on).
3. **This machine's own Lua** (`golem/extra.lua`, from
   `golem.home.hyprlandExtra` in the machine's configuration).
4. **The owner's own file**: `~/.config/hypr/user.lua`, optional, written by
   hand. Saving it reloads the configuration. A mistake in it is shown as a
   configuration error and stops nothing else.
5. **The live settings** (`~/.config/golem/settings.lua`, the control panel's
   choices), run with `dofile`, not `require`: a required file is watched,
   and every click in the panel would reload the whole configuration.

Binds are the exception: Hyprland matches a key event against the binds of
that key only, so binds are grouped by concern, and only the order of binds
on the SAME key matters (kept: `test/compare.lua` checks it).

## How this Hyprland loads it

- `package.path` is `<config dir>/?.lua;<config dir>/?/init.lua`, so
  `require("golem.look")` is `~/.config/hypr/golem/look.lua`.
- Every required file is watched: saving one reloads the configuration, and a
  reload runs every module again (no bind is doubled).
- A required file that is not there raises an error `pcall` can catch (that is
  how the optional layers are optional). A required file with a mistake in it
  does NOT raise: Hyprland lists it among the configuration errors, hands back
  an empty table, and the rest of the configuration stands.
- A file that did not exist at the last (re)load is not watched: a new
  `user.lua` is picked up at the next reload (`hyprctl reload`), and watched
  from then on.

## Adding or changing something

- **A setting, a rule, a key**: in the module of its concern. Keep the
  comment that says why with the line it explains.
- **Something that differs per machine**: a fact in `machine.lua`. Add it in
  `home.nix` (the generated text), give it its default and one line of
  meaning in `golem/lib.lua`, read it where it is used. Never a path under a
  home folder in a module: `home.nix` refuses to build with one.
- **A new module**: a file under `golem/`, one `require` line in
  `hyprland.lua` at its place in the order, one row in the map above.
- **An app module's rules or keys**: `golem/modules/<name>.lua`, and the
  module sets `golem.home.hyprlandModules = [ "<name>" ]` when it is on.

## Testing

No compositor is needed for the first two.

- `test/check.sh [machine.lua]` — the configuration run against a recording
  `hl` (`test/mock.lua`): it loads, no key is bound twice the same way in one
  keymap, no window rule's name is used twice, the lock screen is the first
  thing started, an install runs nothing from `/home/max`, the layers come in
  their order, Gaming's rule is there with the module on and not without. `lua` 5.4 from PATH or `$LUA`.
- `nix build .#checks.x86_64-linux.hypr-config` — the same, with the facts the
  desktop VM's own build generates. `desktop-matrix` and `facts-matrix` assert
  the generated facts (keyboard, panel scale, light effects, the dev shape).
- `lua test/mock.lua <config root> handlers > a.log` writes down everything a
  configuration DOES (every `hl.*` call with its arguments, then what its
  handlers and Lua binds do when run); `lua test/compare.lua a.log b.log` says
  whether two recordings are the same configuration. Use it for any
  restructuring that must change nothing. ⚠ Point `XDG_STATE_HOME` and
  `XDG_CONFIG_HOME` at scratch folders: `screens.lua` WRITES the screens'
  blocks under the first.
- **In a real compositor** (a nested Hyprland with a runtime folder of its
  own; never the live one): start it with `-c <a copy of this tree>/hyprland.lua`,
  a `machine.lua` in its `golem/`, `XDG_CONFIG_HOME` and `XDG_STATE_HOME` at
  scratch folders, and a `PATH` that begins with a folder of do-nothing
  stand-ins for `golem-lock-screen`, `awww-daemon`, `bluetoothctl`, `hyprctl`
  and `waverunner-ctl`: the autostart must not lock, start a wallpaper daemon,
  touch the real Bluetooth adapter or load the plugin from a test. Then
  `hyprctl configerrors` (nothing), `hyprctl -j binds` (96), `hyprctl reload`
  (still 96), save a module (it reloads by itself). The nested compositor
  forks: after stopping it by its PID, stop the child that keeps the same
  command line too.
  ⚠ `-c` makes the path canonical: given a LINK, Hyprland looks for the
  modules beside the link's target, and never reads the folder the link is
  in. A session passes no `-c` and takes `~/.config/hypr/hyprland.lua` as it
  is; to test the layout home-manager makes (links into the store), set
  `XDG_CONFIG_HOME` to a folder holding `hypr/` and pass no `-c`.

## A rebuild while the session runs (measured 2026-11-19, not solved)

Hyprland watches the entry and every file it required, and a link that is
replaced or removed counts as a change: it reloads at once, by itself.
home-manager's activation first removes the links the new generation does
not have, then places the new ones one after another, in the order `find`
gives in the store (on ext4 the order of the names' hashes: it differs from
one machine's disk to the next, and on the dev box `hyprland.lua` comes
before `golem/`). Measured in a nested Hyprland, laid out as home-manager
lays it out:

- **From the one file to this tree, the entry placed before `golem/`**: the
  reload it triggers finds no module (`module 'golem.monitors' not found`).
  The configuration is then EMPTY (an error banner, none of Golem's keys or
  rules) and stays so: the modules that arrive next are not watched yet.
  `hyprctl reload` puts everything back (96 binds, no error).
- **The same, `golem/` placed before the entry**: nothing happens until the
  entry is replaced, and the reload it triggers loads the whole tree. Clean.
- **Back to the one file** ("go back a version"): the modules are removed
  first, so the same empty configuration shows for as long as it takes the
  activation to reach the entry; replacing the entry reloads into the one
  file. Clean by itself.

The compositor survives all of them. Until the switch is made atomic, a
rebuild on a running session must be followed by `hyprctl reload`.

A way to make it atomic, tried in the same rig and NOT built: the home holds
one link only, the entry, and the entry is generated. It puts this build's
tree (the modules and the facts, one folder in the store) first in
`package.path` and runs the tree's own entry:

    local tree = "/nix/store/…-golem-hypr"
    package.path = tree .. "/?.lua;" .. tree .. "/?/init.lua;" .. package.path
    dofile(tree .. "/hyprland.lua")

Replacing that one link took the compositor from the one file to a tree,
between two trees and back to the one file, each time by itself, whole and
with no error (96 and 100 binds, one tree carrying four more); `user.lua`
was still found beside the entry and watched. Hyprland sets `package.path`
anew at every reload, so nothing piles up in it.

## How the split was proven (2026-11-19)

The one file as deployed on `main` c702f73 and this tree were both run under
the mock, for four machines (the dev box; a plain install; an install with
light effects, no Bluetooth, a 220 DPI panel, a `ru,us` keyboard and a tail
of its own; a lab machine), with the deployed texts taken from `nix eval` of
`golem-desktop-vm`:

- every call that is not a bind: the same lines in the same order
  (121 to 124 of them);
- the binds: the same 96 and the stage's keymap, each key's in the same order;
- what the handlers and the Lua binds do when run: the same 133 to 136 lines.

And in a nested Hyprland 0.55.4, old against new on the same machine: no
configuration error, the same 96 binds (every field but the Lua handler's
number), ten settings read back equal, a reload leaves 96, a saved module
reloads by itself, a module with a mistake is reported and the rest stands.

Two things changed on purpose:

1. A stray line `ecosystem = { no_update_news = "true" },` between the two
   environment blocks is gone. It set a global nobody read, and only parsed
   because its comma took the next `hl.env(...)` call into its own list of
   values; the call is kept, the real `ecosystem` settings (in `misc.lua`)
   were always there.
2. `~/.config/hypr/user.lua` is loaded when it exists (layer 4 above). It was
   designed in `docs/system/LiveSettings.md` and never built.

`golem.home.hyprlandExtra` was a tail of the one file and could use that
file's local names; it is its own file now and is handed the same names
(`terminal`, `fileManager`, `Suspend`, `mainMod`, `windowCorner`).
