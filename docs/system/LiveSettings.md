# Live settings

Settings the owner changes in the **control panel** and sees at once: no
rebuild, no logout, no config reload. Max, 2026-10-01: dark mode, gaps, round
corners, transparency, resolution, scale "dont really need a rebuild … i want
it to happen live".

Built so far: **Scale** and **Resolution** (per screen).

## Who owns what

| Layer | File | Written by | Changes when |
|---|---|---|---|
| Golem's defaults | `~/.config/hypr/hyprland.lua` (a store link) | the system (`system/home/hyprland.lua` + `home.nix`) | the system updates |
| The owner's choices | `~/.config/golem/settings.json` | the control panel (the dock) | the owner changes a setting |
| The compositor's copy of them | `~/.config/golem/settings.lua` | the dock, generated from the JSON | same moment |

`settings.json` is the one file every consumer of a live setting reads; each
part of Golem owns its own keys and must write the others back untouched (the
dock does). `settings.lua` is derived: never edit it, it is rewritten on every
change.

Golem's `hyprland.lua` **ends** by running `settings.lua` (`home.nix`, the
`LIVE SETTINGS` block): after Golem's defaults, after a weak GPU's light
effects, after the machine's own `hyprlandExtra`. So a choice

- wins over everything declared,
- is on the screen from the compositor's first frame (no flash, and it does
  not need the dock to be running),
- comes back on every config reload.

It is run with `dofile` under `pcall`, not `require`: Hyprland watches every
required file and a save would reload the whole config on each click. A
missing or broken file changes nothing.

## How a change happens

1. A click in the control panel (or `waverunner-ctl display …`).
2. The dock applies it live: `hyprctl eval 'hl.monitor({ … })'`, the same
   line the file will hold.
3. The dock saves `settings.json` and regenerates `settings.lua`.

Nothing re-asserts afterwards. The compositor keeps a monitor rule until its
config is read again, and reading the config runs the file.

## Scale

Only scales that divide the panel into whole logical pixels are offered (the
compositor moves any other to the nearest of those and complains), the round
ones first, at least 7.5 % apart, and none so large that the screen would look
smaller than 960 × 540 — the panel that set a scale can always be reached to
undo it. Examples: 1440×900 → 75 83 90 100 113 125 150 %; 1920×1080 → 75 83
100 125 150 167 200 %; 3200×2000 → 80 100 125 160 200 250 %.

A scale is saved the moment it is set.

### The change is dissolved

A change of scale is not one change. The compositor rescales the output at
once; every client is then shown with its old buffer stretched until it has
redrawn; the compositor slides every layer surface (dock, bar) to its new
place over about 0.4 s (its `layers` animation runs on each monitor
re-arrangement); tiled windows fly to new sizes; and the pointer leaps,
because it keeps its logical position while a logical pixel changes size.
Shown bare, that read as the screen "jumping as crazy" (Max, 2026-10-01).

So none of it is shown (the dock's `transition.rs`):

1. the screen is captured and that still is laid over everything (an overlay
   layer surface, `golem-transition`, no input);
2. the scale changes underneath, with nothing gliding: while the still is up
   two named compositor rules turn animation off for the shell's layers and
   for windows, and the dock's own motion snaps;
3. the still fades out: one cross-fade from the old screen to the new;
4. the pointer is put back on the pixel it was on.

The still's size at the new scale is committed just before the change, so it
never shows magnified. If anything is missing or late the change is made bare,
and the still cannot stay up longer than 2 s. With reduced motion there is no
dissolve.

## Resolution

A resolution can leave a screen black, so it is only **tried**: it goes back
by itself after 15 s unless the owner keeps it, and it is written nowhere
until then. A mode the panel cannot show never reaches the file the next
login reads.

## The file

```json
{
  "displays": {
    "desc:Apple Computer Inc Color LCD": { "mode": "1440x900@60.00", "scale": 1.25 }
  }
}
```

A screen is keyed by the rule selector Golem's own rules use (`desc:` + its
description), so a choice follows the panel across ports. `position` is
optional (`auto` when absent); nothing sets it yet.

The dock reads the file back as numbers and writes the Lua from those, never
from the text: an entry that does not read as a mode, a scale and a place is
left out.

## Without a pointer

```
waverunner-ctl display                      # log what is on the screen
waverunner-ctl display scale 1.25
waverunner-ctl display mode 1920x1080@60    # tried: 15 s to keep
waverunner-ctl display keep | back
waverunner-ctl display reset                # Golem's defaults again (reloads the config)
waverunner-ctl display show scale|resolution
```

## Next

Gaps, rounding, transparency, dark mode: same three steps (apply live with
`hl.config`, save to `settings.json`, add to the generated `settings.lua`).
Code: the dock's `crates/daemon/src/display.rs` and `panel.rs`.
