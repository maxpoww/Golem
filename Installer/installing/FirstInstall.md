# First Install — the ASUS, and the first dogfood of an installed Golem

> The lab's first REAL wired install (ASUS X550LC, 2026-09-09 — see
> `../preinstall/testing/asus.md` for the install mechanics) booted a
> working Golem from its own disk. This file is the other half: what
> happened when a HUMAN actually **used** that desktop for the first time.
>
> Every preinstall round so far tested the *installer*. Nobody had ever
> tested the *installed system* on anything but the dev box — a modern
> 2560×high-DPI / scale-1.6 / fast-NVMe machine. The ASUS is a 2013
> 1366×768 / scale-1.0 / Haswell-iGPU / spinning-disk machine, and it is
> the first time waveview, waverunner, the option system and the module
> installer have ever run below the dev box's screen. Almost everything
> below is a consequence of that.
>
> **Method (Max, 2026-09-09):** "all the truth is here, and probably we can
> find all issues we will find after on the installing rounds." So: record
> the whole first-dogfood report, investigate, fix all on source, keep
> catching bugs on the live machine for a while and recording them — THEN
> resume the preinstall rounds. This file is that record; fixes are queued
> in `../preinstall/testing/changes.md` like every other finding.

## The machine under test

ASUS X550LC · i5-4200U Haswell (2c/4t) · Intel iGPU (i915) + failing
GF117M dGPU (held off/on per #33) · 7.5 GB RAM · 1366×768 eDP, **scale
1.00** · Toshiba 5400rpm HDD. Installed Golem, generation 4, user `max`,
Hyprland. Reachable at 192.168.1.85 (ath9k, SSH via the lab key).

---

## Max's report (2026-09-09, verbatim intent) + technician root-cause

Numbered as Max listed them. `[P0/P1/P2]` = severity; `→ #N` = the
changes.md finding it became.

### 1. Bloated — "we don't need all that shit" · NOT a bug, but a real target [P1]
The full closure is 18.9 GiB / 2505 store paths. Not broken, but far more
than an old laptop should carry, and slow to deliver. Max's cut list
(2026-09-08 night): android-studio + jdk×2, cef, chromium, firefox,
gcc + deno + python×2, spotify, inkscape, gimp, obs, vlc, zam+lsp — with
the caveats the dependency trace found: **llvm stays** (it's mesa's
backend, not dev tooling), **webkitgtk stays unless Evolution goes**
(it pulls it). Cutting the rest ≈ **−9 GiB → ~9–10 GiB closure → ~6 GB
ISO**, essentially the existing `golem.lean` shape. Action: reconcile
Max's list with `golem.lean` so "lean" and "what Max wants" are one list.
→ lean-ISO work, own task.

### 2. Installed brave — "it never landed after an hour" [P1] → waverunner-pending-stale
**FIRST root-cause was WRONG, corrected by investigation — recorded as a
lesson.** The install log shows `waverunner-apply: fatal: not a git
repository` and I pattern-matched it to the morning's #35 gitless bug and
called brave dead + release-blocking. Then I actually checked the
machine: **brave installed fine.** `/etc/profiles/per-user/max/bin/brave`
exists, `brave-1.93.138` is in the closure, the apply ran ~3 min
(06:25→06:28), reported `ok:true`, and created **generation 2**. My
`command -v brave` had been run as ROOT — but `home.packages` installs to
the USER profile, so root's PATH never had it. The `git add` error is
`|| true` noise (see #35b below), not the failure.
**The real bug:** brave landed, but `pending-installs.json` still lists
its tile (`"attr":"brave"`, `placeholder:false`) — the pending-install UI
state is **never reconciled after the apply succeeds**, so the grid shows
brave stuck "installing" forever. From the user's chair that reads as
"never landed after an hour." waverunner install-state reconciliation, not
the installer. → new finding waverunner-pending-stale.
*(Lesson, the constitution's "suspect the harness first" applied to
myself: a scary log line is a hypothesis, not a root cause. Verify the
effect before naming the bug.)*

### 3. chromium appeared in BOTH the apps grid and the install section [P2]
Confirmed: `chromium` is in `apps-order.json` (a present app in the grid)
AND is offered as installable. A catalog dedup bug — an app already
present must not also appear in the install list. → new finding.

### 3b. btop reports 1.5 GB RAM — "really good, but is it real?" [not a bug — GOOD]
**Real, and honestly good.** `MemTotal 7.5 GB`, `MemAvailable 6.2 GB`,
`Committed_AS 2.87 GB`; largest process is waverunner itself at ~395 MB,
then easyeffects 176 MB, Hyprland 165 MB. A full Hyprland desktop idling
at ~1.3 GB used on 2013 hardware is a genuine win, not a misread. Worth
keeping as a positive datapoint.

### THE LIKELY COMMON ROOT for the visual cluster (4,5,7,8,9,10-b) — degraded renderer on Haswell [P1] → waverunner-renderer-gl
waverunner's log on the ASUS:
```
MESA-INTEL: warning: Haswell Vulkan support is incomplete
renderer: adapter via gpu: Mesa Intel(R) HD Graphics 4400 (HSW GT2) … backend: Gl
WARN waverunner::renderer: premultiplied alpha unsupported, transparency may be wrong: [Opaque]
```
The renderer (wgpu) falls back to the **GL backend** (no Vulkan on
Haswell) and hits a real capability gap — *premultiplied alpha
unsupported*. This NEVER happens on the dev box (modern GPU, Vulkan). A
degraded compositing/transparency path is a strong candidate common cause
for the icons-don't-show and pill-rendering bugs below. **Investigate this
first among the visual cluster** — it may collapse several items into one.

### 4. The dock never hides — always on top, even on overview [P1] → waveview-layers
The options/dock surface sits on Hyprland **layer level 3 (overlay)** —
overlay renders above everything, including the overview. Wrong layer:
a dock that should yield to the overview is painting over it. (Layer
dump: `waverunner-options` namespace, level 3, `xywh 0 0 1366 510`.)

### 5. In "options", there is no "current" [P1] → waveview-options
The current-task pill is missing. Tied into the options-bar breakage
(items 9/10) — the bar renders but its contents/state are wrong at this
geometry.

### 6. Super+Space does not work [P1] → keybind
To check against the shipped Hyprland keybind config vs. what waveview
expects. (Not yet root-caused — needs the config read.)

### 7. Dock/menubox appear on the overview AND on each tiled view [P1] → waveview-layers
Same overlay/top-layer persistence as #4: the shell surfaces are not
workspace-scoped, so they paint on every view including the overview
itself.

### 8. Opening 2+ tiles on a space shows them on ALL tiled views of the overview [P1] → waveview-overview
Overview mirrors tiles across views — a geometry/workspace-scoping bug in
the overview renderer. Almost certainly the same root as 4/7: surfaces
and tiles computed without correct per-workspace bounds.

### 9. Options pills are hard to hover; the hitbox is in a corner of the pill, and even when caught, the expander doesn't fire (clock/notifs/clipboard never expand) [P1] → waveview-input-scale
The options layer is full-width `0 0 1366 510` — geometry almost
certainly computed for the dev box's ~2560px panel. At 1366 wide and
scale 1.0 the pill **input regions are misplaced/undersized**, so the hover
hitboxes land off the visible pill and the expanders never trigger. The
single most likely "tuned on high-DPI, breaks at 1×" bug in the pile.

### 10. After reboot: current-task pill present (but no hover reveal), dock AND menubox EMPTY — icons gone [P1] → waveview-render (NOT a persistence bug)
Corrected, like #2: the pins **did persist**. `pins.json` on disk holds
`org.gnome.Snapshot`, `android-studio`, `foot`, a group, trash (written
06:39, after Max's drag-drops). So the drag-drop→disk path works; the dock
just **didn't RENDER them at startup**. That points at the renderer/
geometry cluster above (possibly the GL-backend degradation), not the
gitless seed and not a lost write. The "no hover reveal" half is the
item-9 input-region bug.

### NEW. False "battery 0% — Critical" notification [P2] → battery-nobattery
waverunner log: `battery alarm: None → Critical`, `battery: 0%
discharging — notifying`, alongside `wireplumber: Failed to get percentage
from UPower: NameHasNoOwner`. This desktop laptop's battery reads as
absent/0%, and waverunner fires a critical-battery notification off that
instead of recognising "no readable battery → no alarm." First machine
where the battery path met a flaky/absent reading.

### suspend / hibernation — both look like they work [PASS]
Max confirmed both. Consistent with the memory family + resume wiring
verified at first boot (`../preinstall/testing/asus.md`).

---

## Severity summary (after investigation — first triage was corrected)

- **P1 — the waveview VISUAL cluster (4, 5, 7, 8, 9, 10, and likely the
  common root waverunner-renderer-gl).** First run below the dev box's
  screen. Candidate roots, to confirm at source: (a) the renderer falling
  back to the GL backend on Haswell with *premultiplied alpha
  unsupported* — a compositing gap that could explain icons/pills not
  drawing; (b) wrong layer level (overlay vs. a yielding layer, #4/#7);
  (c) geometry/input-regions computed for a wide high-DPI panel, wrong at
  1366×768 scale 1.0 (#9). Item 6 (Super+Space) to be classified. This
  cluster is the real story of the first dogfood.
- **P1 — waverunner state reconciliation (#2, pending tile never clears).**
  Installs succeed but the UI shows them stuck forever. High user-impact,
  purely cosmetic-state, no data loss.
- **P2 — chromium catalog dedup (#3); false battery-critical (new);
  Super+Space (#6).**
- **P3 / latent — the gitless seed (#35b).** Harmless TODAY: the seed is a
  plain-path flake (no `.git`), so `nixos-rebuild --flake` sees every file
  and the `git add ... || true` is just noise. Becomes a real bug only if
  a seed ever gains a `.git` (then only-added-never-committed generated
  files go invisible — the #35 class). Decide the seed policy once, kill
  the dead `git add`s.
- **Not bugs — bloat (#1, own lean task), RAM reading (#3b, good news —
  ~1.3 GB used on 2013 metal), suspend/hibernate (pass).**

## The work, in order

1. **waverunner-renderer-gl first** — it may be the common root of the
   whole visual cluster. Reproduce on the ASUS's real GL path, decide
   whether the fix is a renderer capability-fallback (handle no-premult-
   alpha) or forcing a working config on old Intel. If icons/pills come
   back, several items below collapse.
2. **The rest of the visual cluster (4,5,7,8,9)** — layer level + input-
   region/scale math at source, verified live on the ASUS.
3. **#2 pending-tile reconciliation** — clear the pending state when the
   apply lands (and on daemon start, reconcile against the actual profile).
4. **chromium dedup (#3), Super+Space (#6), false battery-critical.**
5. **#35b seed policy** — Max's call; kill the dead `git add`s either way.
6. Keep using the live ASUS; record anything new here.
7. Resume the preinstall rounds (acer/dell/hp/comodore) once the dogfood
   settles.

## Why this file matters for the installing rounds

Max's bet: the issues a first human hits on the first installed machine
are the issues EVERY installing round would hit. Finding them here, once,
on the machine already sacrificed to the wired install, means the
acer/dell/hp/comodore installs (when they come) start from a desktop
that's been dogfooded — not from a rehearsal that never logged in. This
is the gate `PLAN.md` described ("Installed, first boot OK") turning out
to mean a lot more than "it booted."
