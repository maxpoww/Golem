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

## The other settings (2026-10-13)

Every pill of the control panel but one (Accent colour) now has content, in
the same idiom: a subtitle, then groups of choice pills, the one in use lit.
The dock's `controls.rs` reads the machine and carries out a pick on a thread
of its own. Where each choice lives:

| Setting | Changed with | Kept in |
|---|---|---|
| Keyboard layout, Natural scrolling, Touchpad speed | `hl.config` (live) | `settings.json` → `settings.lua`, the three steps above |
| Language, Time zone | the session's `LANG` / `TZ`: the shell at once, every app the dock starts from then on | `settings.json`; `~/.config/uwsm/env` for the next login |
| Dark mode | `gsettings` (`color-scheme`, `gtk-theme`) | `settings.json`, put back at each dock start (the home layer writes its own default at a rebuild) |
| Night light | the dock's screen memory (`hyprsunset`) | the dock's `screen.json` |
| Wallpaper | `awww img` | `settings.json`, put back a few seconds after the session's own |
| Sound output, Volume, Microphone | `wpctl` | PipeWire / WirePlumber |
| Wi-Fi, Bluetooth | `nmcli radio`, `bluetoothctl power` | their services |
| Power mode | `powerprofilesctl` | its daemon |
| Brightness | `golem-brightness` | the backlight |
| Default apps | `xdg-mime default` | the owner's `~/.config/mimeapps.list` (Golem's table sits below it, in `~/.local/share/applications`) |
| Notifications | the dock's do-not-disturb | the dock |
| Updates, About Golem, Battery, Privacy | read-only, with "More…" into the gear box | — |

```json
{
  "keyboard": { "layout": "latam", "variant": "" },
  "natural_scroll": true,
  "pointer_speed": 0.3,
  "dark": true,
  "language": "es_BO.UTF-8",
  "time_zone": "America/La_Paz",
  "wallpaper": "/home/ana/Pictures/Wallpapers/dunes.jpg"
}
```

**Language and time zone are the SESSION's, not the system's.** The system's
own (`i18n.defaultLocale`, `time.timeZone`, in the machine's `machine.nix`)
need a rebuild and are what the login screen, the console and the logs use.
The installer writes the same answers to both, so they agree from the first
boot; a later pick in the panel moves the session only. That is on purpose:
it is instant, it cannot fail, and it is the owner's, not the machine's.

**The installer seeds the file** (language, time zone, keyboard): the baked
desktop is one image for every language, and this is what makes a first
session come up in the owner's — the dock applies a `settings.json` it did
not write as it starts, and `base/user-dirs` names the home folders from its
`language`.

```
waverunner-ctl display show keyboardlayout|timezone|language|volume|…
waverunner-ctl display pick <group> <n>     # a click on a choice, counted from 0
```

## Next

Accent colour (the home layer's GTK CSS pins the accent; changing it is a
decision about the look), gaps, rounding, transparency: same three steps.
A multi-monitor picker (a setting targets the focused screen).
Code: the dock's `crates/daemon/src/{display,controls,panel}.rs`.
