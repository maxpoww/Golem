# Hyprland, in modules

Standard's Hyprland configuration. It was one file of a thousand lines
(`system/home/hyprland.lua`) that `home.nix` rewrote per machine by swapping
strings in it; since 2026-11-19 it is this folder: one file a concern, the
same text on every machine, and ONE generated file that says what differs.

On a machine it is ONE folder in the store, this build's **tree**: these
files as they are, and the generated facts beside them. The home holds ONE
link of it, `~/.config/hypr/hyprland.lua`: a generated entry of three lines
that puts the tree first in `package.path` and runs the tree's own entry
(`system/home/hyprland.nix`; why one link: "A rebuild while the session
runs", below).

    local tree = "/nix/store/…-standard-hypr"
    package.path = tree .. "/?.lua;" .. tree .. "/?/init.lua;" .. package.path
    dofile(tree .. "/hyprland.lua")

## The map

| File | What it holds |
|---|---|
| `hyprland.lua` | The entry. Configures nothing: it loads the modules in order, then the layers after Standard's (below). |
| `standard/lib.lua` | What the modules share: this machine's facts (`machine`), the names the binds use (programs, main modifier, the windows' corner), the one piece of state two files touch (`superBurst`). A table, never globals. |
| `standard/machine.lua` | **Generated, not in this folder.** The machine's facts as a Lua table: `dev`, `ctl`, `plugin`, `dock`, `shell`, `keyboard`, `panel_dpi`, `panel_scale`, `bluetooth`, `effects`, `lab`, `modules`. Written into the tree by `../hyprland.nix`; its text is also the option `standard.home.hyprFacts`, which the checks read by evaluation. Without it (a copy run by hand) `lib.lua` answers as a plain install would. |
| `standard/monitors.lua` | Every screen at its preferred size and a scale for its density; the laptop panel's own scale (`machine.panel_scale`). |
| `standard/layers.lua` | The shell's surfaces (dock, bar, desktop, its menus): blurred behind, frosted glass. |
| `standard/autostart.lua` | What starts with the session: the lock screen FIRST (it is the login), the overview plugin, the cursor, the dock on the dev box, the wallpaper daemon, Bluetooth where there is an adapter. |
| `standard/environment.lua` | What every program started from the session is told (`SHELL`, `TZDIR`, `TERMINAL`, the Wayland hints). |
| `standard/compat.lua` | What apps need to behave: XWayland scaling, popups and dialogs that would open hidden, unfocused or tiled. |
| `standard/gestures.lua` | The touchpad's swipes between desks. |
| `standard/look.lua` | Gaps, borders, magnets, the windows' corner, dimming, shadows, blur; nothing blurred behind a window. |
| `standard/animations.lua` | The curves (the `easy` spring is waveview's too) and what moves on them. |
| `standard/layout.lua` | How tiles split (dwindle beside the pointer), master, scrolling. |
| `standard/misc.lua` | Direct scanout, VRR, the bare grey, DPMS wake-ups, the log, the hardware cursor, no update news. |
| `standard/input.lua` | Keyboard (`machine.keyboard`, the installer's answer), focus by click, touchpad. |
| `standard/binds/apps.lua` | Keys that open a program (terminal, files). |
| `standard/binds/shell.lua` | Keys of Standard's shell: lock, the dock box (a tap of Super), voice to text, fast launch, quick controls, the card, the control panel, the walk round windows and screens, the overview, STAGE and its own keymap. |
| `standard/binds/windows.lua` | Keys that act on the window in hand: close, float, pseudo, focus, move, resize, Super+drag. |
| `standard/screens.lua` | Each screen its own block of desks (remembered in `~/.local/state/golem/screens`), and Super+digits. |
| `standard/binds/keys.lua` | The keyboard's own keys: power, volume, brightness, keyboard light, player, Print Screen. |
| `standard/rules.lua` | The windows' look by state: floating corners, the browser's hairline, floats raised on focus, smart gaps, shadows, the pseudo and stage frames. |
| `standard/effects.lua` | A weak GPU (`machine.effects == "light"`): compositor blur off. |
| `standard/lab.lua` | A lab machine (`machine.lab`): the whole log. |
| `standard/modules/` | The app modules' own Lua (`<name>.lua`): rules and keys a module of programs brings. Loaded for the names in `machine.modules`: the app modules that are on (`standard.modules.active`, read by `../hyprland.nix`). Today: `gaming.lua` (a game that fills the screen keeps the computer awake). |
| `standard/extra.lua` | **Generated when set, in the tree:** this machine's own Lua (`standard.home.hyprlandExtra`). |
| `test/` | The recording mock, the comparison tool, the check (below). Not deployed. |

## The order is the contract

Rules of the same weight are settled by the last one declared, so the entry
loads in this order and nothing may be moved without a reason:

1. **Standard's modules** — in the order the one file had them (monitors, layers,
   autostart, environment, compat, gestures, look, animations, layout, misc,
   input, the binds, screens, the keys, rules, effects, lab). `rules.lua`
   comes after `look.lua` and `compat.lua` because its rules hand corners,
   borders and shadows back to tagged windows; `effects.lua` and `lab.lua`
   come after everything because they take a default away.
2. **The app modules' own Lua** (`standard/modules/<name>.lua`, for the modules
   that are on).
3. **This machine's own Lua** (`standard/extra.lua`, from
   `standard.home.hyprlandExtra` in the machine's configuration).
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

- Hyprland sets `package.path` to `<config dir>/?.lua;<config dir>/?/init.lua`
  before every load and reload; the generated entry puts the tree in front
  of it. So `require("standard.look")` is `<tree>/standard/look.lua`, and
  `require("user")`, which the tree does not have, is
  `~/.config/hypr/user.lua`. A file under `~/.config/hypr/standard/` can no
  longer shadow one of Standard's modules: the tree is asked first. What an
  owner wants changed goes in `user.lua`, which runs after all of them.
- The entry (the link in the home) and every required file are watched. The
  tree's files are in the store and never change; what changes is the link:
  a rebuild replaces it, Hyprland reloads once, by itself, into the new
  tree. Saving `user.lua` reloads too. A reload runs every module again (no
  bind is doubled).
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
  `../hyprland.nix` (the generated text), give it its default and one line of
  meaning in `standard/lib.lua`, read it where it is used. Never a path under a
  home folder in a module: `../hyprland.nix` refuses to build with one.
- **A new module**: a file under `standard/`, one `require` line in
  `hyprland.lua` at its place in the order, one row in the map above.
- **An app module's rules or keys**: `standard/modules/<name>.lua`, and the
  file is loaded while the module is on: nothing to wire (`../hyprland.nix`
  reads `standard.modules.active`).

## Testing

No compositor is needed for the first two.

- `test/check.sh [machine.lua]` — the configuration run against a recording
  `hl` (`test/mock.lua`): it loads, no key is bound twice the same way in one
  keymap, no window rule's name is used twice, the lock screen is the first
  thing started, an install runs nothing from `/home/max`, the layers come in
  their order, Gaming's rule is there with the module on and not without.
  `lua` 5.4 from PATH or `$LUA`. With `<built tree> <generated entry>` in
  place of the facts it checks what a machine really loads, through the one
  file its home holds: every call the same as the tree run directly,
  `user.lua` beside the entry loaded, a stray `standard/look.lua` beside it not.
- `nix build .#checks.x86_64-linux.hypr-config` — that last form, on the tree
  and the entry the desktop VM's own build makes. `desktop-matrix`,
  `facts-matrix` and `machine-layout` assert the generated facts (keyboard,
  panel scale, light effects, the dev shape, the one link).
- `lua test/mock.lua <config root> handlers > a.log` writes down everything a
  configuration DOES (every `hl.*` call with its arguments, then what its
  handlers and Lua binds do when run); `lua test/compare.lua a.log b.log` says
  whether two recordings are the same configuration. Use it for any
  restructuring that must change nothing. ⚠ Point `XDG_STATE_HOME` and
  `XDG_CONFIG_HOME` at scratch folders: `screens.lua` WRITES the screens'
  blocks under the first.
- **In a real compositor** (a nested Hyprland with a runtime folder of its
  own; never the live one): start it with `-c <a copy of this folder>/hyprland.lua`,
  a `machine.lua` in its `standard/`, `XDG_CONFIG_HOME` and `XDG_STATE_HOME` at
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
  is; to test what a machine has (the generated entry, a link into a
  generation's folder), set `XDG_CONFIG_HOME` to a folder holding
  `hypr/hyprland.lua` and pass no `-c`. A line appended to a file by the
  rig's own `golem/settings.lua` (the live settings run last, every time)
  counts the configuration's runs exactly; Hyprland's log lags.

## A rebuild while the session runs: solved, and how (2026-11-19)

Hyprland watches the entry and every file it required, and a link that is
replaced or removed counts as a change: it reloads at once, by itself.

**What went wrong with a folder of links** (the first layout of the modules:
`~/.config/hypr/standard/`, one link a module, never shipped). home-manager's
activation first removes the links the new generation does not have, then
places the new ones one after another, in the order `find` gives in the
store (on ext4 the order of the names' hashes: it differs from one machine's
disk to the next, and on the dev box `hyprland.lua` comes before `standard/`).
Measured in a nested Hyprland laid out as home-manager lays it out:

- from the one file to that folder of links, the entry placed before
  `standard/`: the reload it triggers finds no module
  (`module 'standard.monitors' not found`), the configuration is EMPTY (an
  error banner, none of Standard's keys or rules) and stays so, because the
  modules that arrive next are not watched yet. Only `hyprctl reload` put it
  back;
- `standard/` placed before the entry: clean;
- back to the one file: the modules are removed first, so the same empty
  configuration showed until the activation reached the entry.

**What is built instead: one link.** All of Standard's configuration is one
folder in the store, and the home holds a single link, the generated entry
that names it. A rebuild replaces that one link; there is no order to get
wrong and nothing half placed: the reload Hyprland does by itself finds the
whole new tree. Measured the same way (the entry a link into a generation's
folder, the real built trees, no reload asked anywhere), each step one
replaced link:

| Step | Binds | Errors | Runs of the configuration |
|---|---|---|---|
| the one file as deployed on `main`, started | 96 | none | 1 (the start) |
| → the tree | 96 | none | 1 |
| the owner writes `user.lua` (one key) | 96 | none | 0: not read until the next load |
| → a second tree, one module changed (one more key) | 98 | none | 1: the module's key and `user.lua`'s first |
| `user.lua` saved again (a second key) | 99 | none | 1: it is watched now |
| → the tree with the Gaming module on | 98 (96 and `user.lua`'s two) | none | 1; a fullscreen `steam_app_1` holds the idle clock |
| → back to the one file ("go back a version") | 96 | none | 1 |
| → the tree again | 98 | none | 1 |

The compositor lived through all of it, and `package.path` held the last
tree and the config folder, nothing piled up.

## How the split was proven (2026-11-19)

The one file as deployed on `main` c702f73 and this tree were both run under
the mock, for four machines (the dev box; a plain install; an install with
light effects, no Bluetooth, a 220 DPI panel, a `ru,us` keyboard and a tail
of its own; a lab machine), with the deployed texts taken from `nix eval` of
`standard-desktop-vm`:

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

`standard.home.hyprlandExtra` was a tail of the one file and could use that
file's local names; it is its own file now and is handed the same names
(`terminal`, `fileManager`, `Suspend`, `mainMod`, `windowCorner`).
