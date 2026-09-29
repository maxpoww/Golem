# Keyboard-only audit — every gesture, and whether it works without a pointer

*(todo11 item 2. The compositor half was already settled in
`accessibility-research.md` §5: every window/workspace action has a bind in
`system/home/hyprland.lua:263-329`. This document is the other half — the
surfaces. Method: two static reads of the input handling in `~/launcher`
(waverunner daemon @ 7ae5112) and `~/waveview` (overview plugin @ e49da53),
merged 2026-09-01, with file:line citations. Nothing here was verified on a
live session; where a claim rests on running code it says so. "No keyboard
path" is a finding, not a defect list — inventing paths is S11 build work
and the Arc-1 freeze forbids it.)*

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
| Drag an icon off / onto the dock (unpin / pin), reorder, dock folders, drop onto the Recycle Bin (= uninstall, `dragging.rs:133-136`) | **no keyboard path** (drop arms: `crates/daemon/src/dragging.rs`) |
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

One structural save worth naming: **boxed apps are findable by search.**
The filter that hides grouped apps from the grid runs only on the resting
(empty-query) grid (`main.rs:2071`), so typing a member's name surfaces it
as a plain grid cell and `Enter` launches it — the working mitigation for
the open-box row below.

The gaps:

| Gesture | Keyboard path |
|---|---|
| **Drag-to-install** (Install tile → Apps grid), and drag-to-grid webapp install | **no keyboard path.** The drag is not a shortcut for install — it *is* install. `Enter` on a package tile is an explicit no-op: "Packages aren't launchable — installing is a drag" (`main.rs:2962-2964`). A keyboard-only user can search nixpkgs and select a result but cannot act on it |
| "Try it" (drag a catalog webapp out of the box) | **no keyboard path** (`main.rs:2993-2997` — click deliberately does nothing) |
| Retry a *failed* install | works — `Enter` on the failed tile activates the retry arm (`main.rs:2965-2991`). The only Install-section action a keyboard reaches, and it needs a pointer to have started the install |
| Uninstall (drag installed tile → Install section) | **no keyboard path** |
| Cells *inside* an open box (group folder, dock folder, trash) | **no keyboard path** — arrow selection walks the flat grid only; box contents are `Hit::OpenBoxCell`, produced by pointer hit-testing alone (`main.rs:2932`, keyboard `Enter` can only emit `Hit::GridCell`, `main.rs:3330`). Keyboard can open a box (`Enter` on its tile) and close it (`Esc`) but not act inside it. Mitigation: members are searchable (above) |
| Box creation (drag app onto app), grid reorder, drag a file to trash, trash restore | **no keyboard path** (all drop arms in `dragging.rs`; no Delete-key handling on a Files selection either) |
| Search-button pill toggle | not needed — typing opens the search directly |

## 3. Topbar pills (`crates/daemon/src/options.rs:204-226`; clicks `options.rs:1563-1614`)

The topbar surface never takes keys at all (`surface.rs:91`,
`KeyboardInteractivity::None` plus an empty input region at rest).

| Pill | Click action | Keyboard path |
|---|---|---|
| Window (current-task) | left = focus-next, right = focus-other | `SUPER+TAB` / `SUPER+SHIFT+TAB` (`hyprland.lua:273-274`) |
| Close | close focused window (or the overview while it owns the screen) | `SUPER+Q` (`hyprland.lua:267`); Esc / `SUPER+R` for the overview |
| Pseudo | Golem pseudo toggle | `SUPER+P` (`hyprland.lua:279`) |
| Fullscreen | fullscreen the focused window | **no keyboard path** — no fullscreen bind exists anywhere in `hyprland.lua` (grepped). The pill is the only trigger; apps' own F11 covers only themselves |
| Notif (bell) | click the peek pill = open the *newest* notification (`notif.rs:2086-2102`); the history box opens by **scrolling** over the pill (`notif.rs:2359-2363`) | **no keyboard path** to either |
| NotifMute | mute notifications | **no keyboard path** |
| Clipboard | click = **paste the current clip** (`options.rs:1594`); the history box opens by **scrolling** over the pill (`clipboard.rs:2236-2240`) | paste has a native equivalent (Ctrl+V in the app); the box has **no keyboard path** |
| ClipCopyLink | copy the browser's current page URL | **no shell path**; in-browser Ctrl+L, Ctrl+C is the native equivalent |
| Clock | display only | — |

One more pointer-only gesture lives here: **revealing the bar during
fullscreen** is a pointer-at-the-top-strip hover (`surface.rs:75-77`,
the Overlay-layer reveal strip). With no fullscreen bind (above), a
keyboard-only user can neither enter compositor fullscreen nor reach the
bar that exits it.

## 4. Clipboard box, metadata sheet, dictionary, note editor

Opening the box at all requires the pointer — a scroll over the pill (§3).
Once open:

| Gesture | Keyboard path |
|---|---|
| Scroll history, click a row to paste, pin, delete, Clear all | **no keyboard path** |
| Open a row's metadata sheet (right-click); the sheet's pills; Back | **no keyboard path** (`Back` is a drawn pointer target, `clipboard.rs:1992`) |
| Note editor (footer pencil) | **no keyboard path to open**; typing inside it is keyboard by nature |
| Dictionary panel (footer book) | **no keyboard path to open** (pointer or the debug-only `ctl debug-dict`). Once open it grabs every key (`main.rs:3290-3294`): type to look up, `Backspace`, `Esc` closes (`clipboard.rs:2505-2529`). Scrolling a long definition: **pointer wheel only** |

## 5. Notification box and toast cards

| Gesture | Keyboard path |
|---|---|
| Open the history box (scroll over the bell) | **no keyboard path** |
| Dismiss a card (✕), invoke a notification's action (click = default action / open webapp), Clear all (`notif.rs:2104-2120`) | **no keyboard path** |
| Mute | **no keyboard path** (§3, NotifMute) |

Nothing arriving as a toast can be acted on, silenced, or even dismissed
without a pointer.

## 6. Overview (waveview)

Input handling: `~/waveview/src/main.cpp` `onKey` (`main.cpp:2485-2529`).

| Gesture | Keyboard path |
|---|---|
| Open / close | `SUPER+R` toggle; `Esc` always closes (`main.cpp:2526-2527`) |
| Tour (visit the other inhabited page) | second `SUPER+R` while open (`main.cpp:2361-2367`) |
| Wheel → page flip (the 3×6 grid as two pages, `main.cpp:172-178`) | covered — the `SUPER+R` tour flips to the other page |
| Jump to workspace N | digits `1-9`, page-relative, with or without Super held (`main.cpp:2504-2517`) — this is the designed keyboard route and it works |
| Focus a *specific window* on a workspace | **no keyboard path** — selection inside the grid is pointer hover + click only. Digits land you on the workspace; picking the window is then `SUPER+WASD` back on the desktop, which is a real (two-step) keyboard route, just not an in-overview one |
| Close the hovered window | `Q` (`main.cpp:2519-2524`) — a key, but its *target* is pointer hover; with no pointer there is no hovered window, so effectively **no keyboard path**. Fallback: `SUPER+Q` on the focused window, outside the overview |
| Move a window to another workspace (real compositor drag, split-aware: `main.cpp:309-310`) | **no keyboard path in the overview.** Equivalent outside it: `SUPER+SHIFT+digit` (`hyprland.lua:305`) — focused window only, no split-position choice |
| Resize inside a tile (borders scaled into the thumbnail, `main.cpp:258-266`) | **no keyboard path in the overview**; `SUPER+arrows` resize the focused window on the desktop (`hyprland.lua:295-298`) |
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
docs for 0.55, not verified live — queued as item 7 in
`accessibility-research.md` §7.)

## 8. What this adds up to (for S11, after the freeze)

Reachable today with a keyboard alone: launch anything, search anything
(including apps folded into boxes), open files, manage windows and
workspaces, tour the overview, use the dictionary *if* something else
opened it. Not reachable: **install, uninstall, everything clipboard,
everything notifications, fullscreen, and any action inside an open box.**
The pattern behind almost every "no keyboard path" row is the same:
OPTIONS boxes open on hover/scroll and act on pointer hits, with no focus
model and no activation order — which is the same missing structure
AccessKit needs (`accessibility-research.md` §6.0). One future mechanism —
focusable surface elements with names, roles, and an activation key —
closes both audits at once. The popup shows the spine already exists (one
flat selection spanning its sections); what's missing is verbs, not
structure. That is Arc-2 work; this document is the map.
