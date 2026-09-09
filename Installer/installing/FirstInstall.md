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

## 2026-09-09 afternoon — the pivot: the ASUS was running a STALE waverunner

Investigating the visual cluster surfaced the single most important fact of
the dogfood: **the installed ASUS ran waverunner from Golem's locked rev
(`2de760883`), 18 commits + heavy WIP behind Max's `~/launcher` HEAD
(`4cb0775`)** — and that newer work is squarely on this cluster:
`feat: the OPTIONS UX rules — Leader/Still Bar/One Material/Sticky`,
`fix: page capacity is screen-derived, never content-shrunk` (the item-9
scale bug almost by name), `options: the tooltip finally shows an offer's
detail` (item-9 hover-expand), `style: soften the dock shadow`, plus
untracked `deck.rs`/`stage.rs` (STAGE mode + the task deck → items 7/8).
So most of the P1 cluster was reported against a build that predated its
own fixes. Fixing it blind would have been wasted work.

**Action taken (Max: "rebuild ASUS from current ~/launcher, re-test"):**
built a fresh `golem-target` toplevel on the dev box with
`--override-input waverunner path:/home/max/launcher` (+ the #38 fix
below), `nix copy`'d the delta to the ASUS, and activated it in place
(`nix-env --set` + `switch-to-configuration switch`) — the install's
closure-delivery seam reused for an update, no slow rebuild on the 5400rpm
box. The ASUS now runs Max's current waverunner. **The visual cluster must
be RE-dogfooded on this build before any of it is treated as a live bug**
— several items are expected to be already gone.

### #38 battery false-critical — FIXED IN SOURCE + CONFIRMED LIVE
Root cause: the ASUS has a dead battery present on AC — `BAT0` reads
`status=Not charging, capacity=0` while `AC0` reads `online=1`. The alarm
ladder treated "not charging" as "discharging" and fired Critical at 0%.
Fix (in `~/launcher`, uncommitted, 4 files: `collectors/system.rs`,
`options-engine/state.rs`, `daemon/battery.rs`, `mind/decide.rs`): a new
`on_ac` metric read from Mains `online`; both the alarm and the battery
affordance now clear on `charging || on_ac`. 235 daemon + 148 engine tests
pass (incl. a new ASUS-case assertion). **Verified live:** the red
critical-battery triangle in the top bar is gone (now a normal bell), and
the daemon logs no battery alarm. First waveview/waverunner source fix
driven by the dogfood. → changes.md #38.

## 2026-09-09 late — THE KEYSTONE: one stale tile deadlocked the desktop

Re-dogfooded on the current waverunner; #38 held (bell, not red triangle).
Survivors: no current-task pill (#5), Super+Space dead (#6), option hover
dead (#9), dock doesn't hide (#4), dock/menubox no icons (#10). Root-caused
the biggest ones to a single shared cause — the day's most important
finding.

**The chain (proven on metal, strace + operational fix):**
- brave installed fine last session but its tile was never cleared from
  `pending-installs.json` (#37).
- Every boot the daemon restores that tile and animates its "installing"
  ring forever (the install is already done — it never completes-and-
  clears).
- That perpetual animation spins the render loop: `ppoll(wl_fd)` 714×/6 s,
  calloop's epoll (IPC + timers + the nix-completion channel) polled 1×,
  `accept()` on the control socket 0×, CPU pegged.
- Starved loop ⇒ the nix-completion event that would clear the tile can
  never be processed ⇒ **deadlock**: the animation blocks the event that
  would stop it.
- Everything downstream falls over: dead control socket (Super+Space +
  all `waverunner-ctl`, #40/#6), no current-task pill (#5), dead option
  hover (#9).

**Proven fix (operational):** clear the stale tile + restart → epoll
serviced 69×/4 s, spin gone, CPU 90.8 % idle, all `waverunner-ctl`
commands exit 0, and the current-task pill (`foot ✕`) renders again. Items
5/6/#40 recovered from one change.

**Fix plan (changes.md #37+40):** (a) targeted — clear a pending tile whose
package is already installed on restore, synchronously (the async path is
itself starved); (b) architectural, the real hardening — no animation may
starve the single-threaded calloop loop; it must yield between frames so
IPC/timers/input/nix keep flowing. (b) is Max's render-loop call. Left the
ASUS with the tile cleared and the loop healthy so the visual survivors
(#4 dock-hide, #9 hover render, #10 icons, #7/#8 overview) can be
re-judged on a responsive daemon.

## 2026-09-09 — #40 loop fix landed + verified, and the deployment gap (#41)

Took the loop-architecture fix (Max: "yes, you do it"). strace pinned the
mechanism: during a perpetual animation the daemon rendered flat out —
5582 GPU ioctls/3 s, calloop's epoll polled once, IPC `accept()` 0×. The
daemon already had an F12 frame-throttle for this, but gated on
`is_software()` (llvmpipe only); the ASUS is the **GL backend on real
Intel** (not software), so it never engaged though GL-on-Wayland present
blocks the thread the same way. Fix: `needs_frame_throttle() = software ||
backend==Gl`; the throttle (calloop-timer-spaced, so the loop services
IPC/input between frames) now covers GL. **Verified with the fix actually
running** (daemon `b22jxjw5`): during a GUI ring, epoll 125×/3 s (was 1),
ioctl 1011 (was 5582), `waverunner-ctl` OK (was EAGAIN), CPU 60 % idle.

All three fixes (#38 battery, #37 clear-on-restore, #40 GL throttle) are
written, compile, tested, and verified working when deployed.

**But #41 — the deployment gap, the session's key operational lesson:**
the installed ASUS rebuilds itself from its seed flake
(`/home/max/Golem`) on every app install and weekly autoupgrade, and that
seed pins the ORIGINAL waverunner. So a dev-box `--override-input` build
delivered by `nix copy` is not permanent — the next in-place rebuild
reverts it (seen repeatedly: install an app → daemon back to `znzgcl`,
desktop frozen again). To make #37/#38/#40 stick, they must live in the
SEED: commit the launcher changes and bump Golem's `waverunner` input,
then rebuild the machine from the updated seed. That is a Max call (his
`~/launcher` WIP). Until then the ASUS is left on the fixed build but will
revert on its next self-rebuild.

## 2026-09-09 — the install-freeze fix, made PERMANENT + proven end-to-end

Closed the loop on #40/#41. Committed the waverunner fixes (#37/#38/#40) to
`maxpoww/launcher` `9ed17b1`, bumped Golem's `waverunner` input to it
(flake.lock), updated the ASUS's own seed lock, and rebuilt it from the
seed. Then the definitive test — **installed xterm on the ASUS for real:**

- **No freeze:** `waverunner-ctl` responded at every poll *during* the
  rebuild (`rebuilding=yes`) — the desktop stayed alive through the whole
  install. (#40 throttle, on the shipped build.)
- **No revert:** the daemon stayed the fixed build (`31s9c39p`)
  before/during/after — it did NOT fall back to the original `znzgcl`. The
  seed now builds the fixed waverunner, so the self-rebuild kept it. (#41.)

So the install-freeze — the worst of the whole first dogfood — is fixed at
the distro level: every future install builds the fixed waverunner, and
installing an app no longer freezes the desktop. (Test residue: xterm is
now installed on the ASUS; harmless.)

### Still open — #42, the next one
App icons render as **solid black squares** on the GL backend (confirmed
on the clean fixed build: dock app-icon slots are black; built-in glyphs
like the trash icon render fine). Almost certainly the GL `Opaque`-alpha
fallback mishandling the RGBA icon textures — the same GL-backend alpha
gap, now on the icon path. A rendering-correctness bug, separate from the
throttle. It's the next thing to fix, via the same iterate-on-the-ASUS
loop. changes.md #42.

## 2026-09-09 — #42 (black-square icons) root-caused + fixed + shipped

Chased the transient black-square icons with debug logging on the ASUS and
caught the exact cause: **wgpu's GLES backend guesses a texture's view
dimension from its layer count** — depth 6 → Cube, depth >6 & %6==0 →
CubeArray. waverunner's icon atlas is `app_count + 97` layers; when that
total is a multiple of 6 the atlas is bound as a **cubemap** and the
sampler reads **black**. Caught live: `137 apps + 97 = 234 = 6×39`, with
`wgpu_hal::gles: … assumed CubeArray rather than D2Array` in the log at
exactly that count. Transient because the count shifts with app/pending
counts; the font/glyph atlas is a separate texture, so those icons stayed
fine — matching "the trash renders, the app icons don't." GL-backend only
(Vulkan honors the explicit D2Array view) — invisible on the dev box.

**Fix** (waverunner `renderer.rs::upload_icon_array`): pad the layer count
by one whenever it is 6 or a multiple of 6, so the GLES heuristic can never
pick Cube/CubeArray. Deterministic — eliminates the trigger for every app
count; pad layer is empty, no effect on Vulkan. Committed launcher
`d8db7ed`, Golem `waverunner` lock bumped, ASUS seed lock updated, and the
ASUS rebooted clean onto it. **Verified on the clean boot:** dock shows the
real colourful icons (Snapshot/Android Studio/Bluetooth/foot/Decibels/
trash), daemon is the fixed build, zero CubeArray errors. Permanent — in
the distro's waverunner lock, so every install/rebuild carries it.

### First-install dogfood — where it stands
Every issue from the first human dogfood is now fixed AND permanent in the
distro: #38 battery-on-AC, #37 stale-install clear-on-restore, #40 the
install-freeze deadlock (GL frame throttle), #41 the seed-flake persistence
gap, #42 the GLES black-icon cubemap. The install-freeze — the worst of
them — no longer happens, and installs no longer revert the fixes. The
ASUS is a working installed Golem. What Max's bet predicted holds: finding
these here, once, means the installing rounds start from a dogfooded
desktop, not a rehearsal that never logged in.

## 2026-09-09 evening — #45: installs STILL failed; the applier couldn't see a live build

Max: "we still have issues installing programs." The journal told the
story. fritzing failed at 16:09 — the #44 exit-4, seven minutes BEFORE
the #44 fix was deployed (pre-fix damage, not a live bug; re-installed
fine at 17:02, 36 s, gen 34). But around it, two patterns that WERE live:
"stale apply status: phase 'building' but the helper is not running"
spamming every 5 s DURING real builds, and xcalc — installed, resolved
"installed" at 16:22 — simply GONE: binary absent, not in packages.list,
no tile, no error ever shown.

**Root cause, proven on metal (#45, changes.md):** the apply helper is a
`Type=oneshot` systemd service, and while its ExecStart runs systemd
reports `ActiveState=activating` — which `systemctl is-active` (the
daemon's liveness probe) treats as NOT active. So the daemon read every
LIVE build as a corpse: polled `is-active` through a real 36 s fritzing
apply → `activating` start to finish while the daemon logged "helper is
not running". A waiter that can't see the build nudges into the void
(systemd drops path triggers while the unit is activating), gives up at
120 s, calls the install FAILED, and **reverts the package list while
the build is still running** — the revert rides the next rebuild as a
real uninstall. That's the xcalc loss, and the general "installing
programs is broken" on any machine slow enough that rebuilds overlap —
i.e. never the dev box, always the ASUS. A second hole compounds it:
a run that merely FINISHED after our list write was accepted as covering
it, though a run that STARTED earlier read the OLD list — the exact
mis-attributed Done from #43's lmms UPDATE.

**Fix (waverunner `b2d59f9`, committed + pushed):** liveness reads
`ActiveState` properly (activating = alive); run coverage is
started-based everywhere (only a run that started after our write
terminates our wait — overlapped installs each block until a run that
provably contains them lands, the #43b "serialize" without a queue);
the start-timeout counts idle time, not wall time; and a corpse
'building' status is nudged past whether the dead run was ours or
foreign. Golem's waverunner lock bumped, ASUS seed updated, rebuilt from
seed — same permanence pipeline as #41.

**Deployed + verified live (17:16):** prebuilt `golem-target` on the dev
box from the ASUS's own seed + bumped lock, `nix copy`'d, updated the
seed lock, and let the machine rebuild itself (pure cache hit, ~70 s).
The deployment staged the exact overlap race by accident — the fixed
daemon's startup reconcile began while a foreign apply was still
building — and the new code ran it perfectly: quiet wait through the
live run (zero "helper is not running" spam), the foreign run refused as
coverage when it landed, one nudge, fresh covering run, "startup
reconcile applied". What's left for the human chair: two GUI
drag-installs back to back; the applier under them is proven. (xcalc was
NOT silently re-added — Max's call whether he still wants it. fritzing
is installed now, as `Fritzing`.)

Also cleared up from the same journal sweep (not bugs): gen 30's weird
old-config build at 16:19 was the dev-box recovery session rebuilding
with stale per-machine files (the fba74c5 cleanup); the F13 drift sweep
then CORRECTLY restored the right config at 16:22 — that subsystem works.
The Hyprland SIGABRT at 15:08 (coredump on disk) predates the current
boot — from the #44-era churn; watch whether it recurs on a healthy
applier.

## Why this file matters for the installing rounds

Max's bet: the issues a first human hits on the first installed machine
are the issues EVERY installing round would hit. Finding them here, once,
on the machine already sacrificed to the wired install, means the
acer/dell/hp/comodore installs (when they come) start from a desktop
that's been dogfooded — not from a rehearsal that never logged in. This
is the gate `PLAN.md` described ("Installed, first boot OK") turning out
to mean a lot more than "it booted."
