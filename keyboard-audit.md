# Keyboard-only audit — every gesture, and whether it works without a pointer

*(todo11 item 2. The compositor half was already settled in
`accessibility-research.md` §5: every window/workspace action has a bind in
`system/home/hyprland.lua:263-329`. This document is the other half — the
surfaces. Method: a static read of the input handling in `~/launcher`
(waverunner daemon) and `~/waveview` (overview plugin), with file:line
citations. Nothing here was verified on a live session; where a claim rests
on running code it says so. "No keyboard path" is a finding, not a defect
list — inventing paths is S11 build work and the Arc-1 freeze forbids it.)*

## The one-paragraph verdict

The launcher popup is genuinely keyboard-usable for its core job — open,
search, arrow-walk, launch, close — and the window manager underneath is
fully bound. Everything else OPTIONS draws is pointer-only: **installing
(the drag IS the install), the clipboard box, the notification box, the
overview's window management, and four of the topbar's nine pills have no
keyboard path.** The daemon's own wire-protocol doc states it plainly:
the OPTIONS surfaces are "normally pointer-only"
(`crates/proto/src/lib.rs:45-46` — the Debug\* verbs exist precisely
because screenshots needed a pointer-free way in).

## 1. Dock (the slim bar)

| Gesture | Keyboard path |
|---|---|
| Reveal the dock (pointer touches bottom edge) | none needed — `SUPER+SPACE` skips the dock state entirely: `ctl toggle` goes Hidden→**Open** (`crates/daemon/src/state.rs:143-145`) |
| Click a dock icon (launch / open pinned folder / Recycle Bin) | **no keyboard path** on the dock itself — and by design: the dock never takes keys (`crates/daemon/src/surface.rs:128-131`, "the dock is pointer-only and must never steal keys"). Equivalent: the same apps/groups are reachable in the popup grid |
| Scroll on the dock (expand to popup) | `SUPER+SPACE` (opens directly) |
| Drag an icon off / onto the dock (unpin / pin), reorder, dock folders | **no keyboard path** (drag arms: `crates/daemon/src/dragging.rs`) |
| Just-installed app temp-pinned on the dock (`InstallNotify`) | **no keyboard path** — and it is *hidden from the grid* until opened-and-closed once (`crates/daemon/src/install.rs:175-187`). Moot today: a keyboard user cannot install (§2) |

## 2. Launcher popup (the grid: Apps / Install / Files)

The good half. While open, the layer holds the keyboard exclusively
(`surface.rs:123-138`), and `handle_key_event` (`main.rs:3288`) gives:

- **Open/close:** `SUPER+SPACE` toggle; `Esc` steps out of an open box
  first, then clears the query and dismisses (`main.rs:3317-3327`).
- **Search:** any printable char types into the query (`main.rs:3398`),
  `Backspace` edits, `Ctrl+V` pastes into the query (`main.rs:3312`).
- **Navigate:** arrows walk one flat selection across Apps → Install →
  Files (`main.rs:3344-3378`, `main.rs:2276`), paging to reveal.
- **Activate:** `Enter` on the selection (`main.rs:3328-3331`) launches an
  app, opens a group box, opens a file via xdg-open (`main.rs:2903-2921`).
- **Icon size:** `Ctrl` `+`/`-` (`main.rs:3296-3311`).

The gaps:

| Gesture | Keyboard path |
|---|---|
| **Drag-to-install** (Install tile → Apps grid), and drag-to-grid webapp install | **no keyboard path.** The drag is not a shortcut for install — it *is* install. `Enter` on a package tile is an explicit no-op: "Packages aren't launchable — installing is a drag" (`main.rs:2962-2964`). A keyboard-only user can search nixpkgs and select a result but cannot act on it |
| "Try it" (drag a catalog webapp out of the box) | **no keyboard path** (`main.rs:2993-2997` — click deliberately does nothing) |
| Retry a *failed* install | works — `Enter` on the failed tile activates the retry arm (`main.rs:2965-2991`). The only Install-section action a keyboard reaches, and it needs a pointer to have started the install |
| Uninstall (drag installed tile → Install section) | **no keyboard path** |
| Cells *inside* an open box (group folder, dock folder, trash) | **no keyboard path** — arrow selection walks the flat grid only; box contents are `Hit::OpenBoxCell`, produced by pointer hit-testing alone (`main.rs:2932`, keyboard `Enter` can only emit `Hit::GridCell`, `main.rs:3330`). Keyboard can open a box (`Enter` on its tile) and close it (`Esc`) but not act inside it |
| Box creation (drag app onto app), grid reorder, drag to trash, trash restore | **no keyboard path** (all drop arms in `dragging.rs`) |
| Search-button pill toggle | not needed — typing opens the search directly |

## 3. Topbar pills (`crates/daemon/src/options.rs:204-226`)

| Pill | Click action | Keyboard path |
|---|---|---|
| Window (current-task) | left = focus-next, right = focus-other | `SUPER+TAB` / `SUPER+SHIFT+TAB` (`hyprland.lua:270-272`) |
| Close | close focused window | `SUPER+Q` (`hyprland.lua:265`) |
| Pseudo | Golem pseudo toggle | `SUPER+P` (`hyprland.lua:278`) |
| Fullscreen | fullscreen the focused window | **no keyboard path** — no fullscreen bind exists anywhere in `hyprland.lua` (grepped). The pill is the only trigger |
| Notif (bell) | open notification box | **no keyboard path** |
| NotifMute | mute notifications | **no keyboard path** |
| Clipboard | open clipboard history box | **no keyboard path** |
| ClipCopyLink | copy the browser's current page URL | **no keyboard path** |
| Clock | display only | — |

## 4. Clipboard box, metadata sheet, dictionary, note editor

Opening the box at all requires the pointer (§3). Once open:

| Gesture | Keyboard path |
|---|---|
| Scroll history, click a row to paste, pin, delete, Clear all | **no keyboard path** |
| Open a row's metadata sheet; the sheet's pills; Back | **no keyboard path** (`Back` is a drawn pointer target, `clipboard.rs:1992`) |
| Note editor (footer pencil) | **no keyboard path to open**; typing inside it is keyboard by nature |
| Dictionary panel (footer book) | **no keyboard path to open** (pointer or the debug-only `ctl debug-dict`). Once open it grabs every key (`main.rs:3290-3294`): type to look up, `Backspace`, `Esc` closes (`clipboard.rs:2505-2529`). Scrolling a long definition: **pointer wheel only** |

## 5. Notification box and toast cards

| Gesture | Keyboard path |
|---|---|
| Open the history box (hover/click the bell) | **no keyboard path** |
| Dismiss a card (✕), invoke a notification's action (click = default action / open webapp), Clear all | **no keyboard path** |
| Mute | **no keyboard path** (§3, NotifMute) |

Nothing arriving as a toast can be acted on, silenced, or even dismissed
without a pointer.

## 6. Overview (waveview)

Input handling: `~/waveview/src/main.cpp` `onKey` (`main.cpp:2485-2529`).

| Gesture | Keyboard path |
|---|---|
| Open / close | `SUPER+R` toggle; `Esc` always closes (`main.cpp:2526-2527`) |
| Tour (visit the other inhabited page) | second `SUPER+R` while open (`main.cpp:2361-2367`) |
| Jump to workspace N | digits `1-9`, page-relative, with or without Super held (`main.cpp:2504-2517`) — this is the designed keyboard route and it works |
| Focus a *specific window* on a workspace | **no keyboard path** — selection inside the grid is pointer hover + click only. Digits land you on the workspace; picking the window is then `SUPER+WASD` back on the desktop, which is a real (two-step) keyboard route, just not an in-overview one |
| Close the hovered window | `Q` (`main.cpp:2519-2524`) — a key, but its *target* is pointer hover; with no pointer there is no hovered window, so effectively **no keyboard path** |
| Move a window to another workspace | **no keyboard path in the overview** (real compositor drag: `main.cpp:309-310`). Equivalent outside it: `SUPER+SHIFT+digit` (`hyprland.lua:305-309`) |
| 3-finger swipe open/close, swipe-down escape | touchpad gestures — alternatives to `SUPER+R`, not keyboard paths themselves (`main.cpp:99-101`, `284-289`) |

While open the overview swallows all other typing so keys can't leak to the
window underneath (`main.cpp:2512` `info.cancelled`) — correct behaviour
for a keyboard user, worth preserving through any future work.

## 7. The `follow_mouse = 2` question (`hyprland.lua:250`)

The item asked whether this "lets the pointer move focus" and fights
keyboard navigation. Per Hyprland's semantics for value **2**, cursor focus
is detached from keyboard focus: hovering retargets pointer actions
(scroll), but *keyboard* focus moves only on click or via binds. So a stray
touchpad brush cannot yank typing away from the window `SUPER+WASD` put it
in — which is exactly the failure mode the default (`1`, focus follows
hover) would have. For a pure keyboard session the pointer never moves and
the setting never fires. **Finding: no conflict; `2` is the
keyboard-friendly middle setting; leave it.** (Semantics from the Hyprland
docs for 0.55, not verified live — §7 of `accessibility-research.md` is
where live checks queue.)

## 8. What this adds up to (for S11, after the freeze)

Reachable today with a keyboard alone: launch anything, search anything,
open files, manage windows and workspaces, tour the overview, use the
dictionary *if* something else opened it. Not reachable: **install,
uninstall, everything clipboard, everything notifications, fullscreen, and
any action inside an open box.** The pattern behind almost every "no
keyboard path" row is the same: OPTIONS boxes open on hover and act on
pointer hits, with no focus model and no activation order — which is the
same missing structure AccessKit needs (`accessibility-research.md` §6.0).
One future mechanism — focusable surface elements with names, roles, and
an activation key — closes both audits at once. That is Arc-2 work; this
document is the map.
