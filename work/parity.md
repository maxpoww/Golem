# Parity ledger: Golem machines vs the reference desktop

The reference is Max's dev box: the desktop as he settled it. A Golem machine
should behave the same unless a difference is a **decision**. `golem-parity`
reads both LIVE sessions and reports every difference; this file tracks what
each one is.

```sh
~/Golem/tools/parity/golem-parity max@<ip>          # report (exit 1 = findings)
~/Golem/tools/parity/golem-parity max@<ip> --save   # + work/parity/<ip>-<date>.md
```

**The loop:** run it after every install, recut or deploy. A new finding is
one of three things:
1. **Fixed**: fix it at the source and log it under *Fixed* below.
2. **Accepted**: a deliberate difference. It goes in `tools/parity/accepted.toml` with its reason.
3. **Open**: needs a decision or real work. It goes under *Open* below with a P-number.

Checks that need no reference, because they are broken on sight: config errors,
a keybind or autostart whose program doesn't exist, a missing `$SHELL`,
failed units, and menubox launchers that run nothing.

## Open

- **P1 → DONE 2026-09-30: one home layer.** The dev box imports
  `~/Golem/system/home` (and Golem's bluetooth, audio, brightness, apps,
  session, idle, the Hyprland overlay + patches, the launcher's notification
  module). Its own layer is `/etc/nixos/home.nix` + `configuration.nix`,
  holding only this machine: hardware, NVIDIA, power, the dev loop
  (`golem.home.devCheckout`), no idle steps, its grid (`menubox.hidePlumbing
  = false`), and P2's look (`hyprlandExtra`). Verified before the switch by
  building both configs and diffing: identical Hyprland binary, no removals,
  the Lua's effective values unchanged. Retired copies in
  `~/.cache/golem-p1/`. **Still two copies:** `waverunner-apply.nix` (channel
  rebuild vs flake rebuild) until the dev box moves onto the flake.
  Open questions for Max: the menubox debloat on his own grid; idle on his
  machine; GTK theming now applies there (Golem's look).
- **P2. Window opacity + direct scanout.** Golem ships opaque windows and
  direct scanout (2026-09-02 perf pass for weak GPUs). The dev box has 0.95
  and no scanout. Decide whether one look is right for both.
- **P4 → DONE on the dev box 2026-09-30: webapps run in Seam; no other
  browser.** A webapp is Firefox 157's own web-app window (Taskbar Tabs, Linux
  branch: `taskbartabclass` = the Wayland class `webapp-<slug>` = the launcher's
  id) inside the one running Seam: `seam -golem-app <slug> <url>` (seam/golem-chrome.js
  WEBAPPS, ee7db99; the dock half is waverunner 6bffa98 + 4b70533). Chrome, Chromium
  and Edge are gone from the dev box (backups in `~/.cache/golem-p1/`); mailto → Seam.
  - Verified on the dev box, all 71 catalog entries (`~/.cache/golem-webapp-tests/`,
    run.py + results.json + a screenshot each): a window in 0.3–0.7 s, its own class,
    floating with its title bar, in the ONE Seam process, the site's real title,
    a relaunch focuses the same window (never a second), and the copy-link report
    names the page. Four sites move to another domain by themselves (Hulu → Disney+,
    Skype → Teams, mega.nz → mega.io, notion.so → notion.com); the report follows.
  - Title bars on webapps (Max: "mimic the color of the window and feel like one
    thing"): the bar sampled only the toplevel surface, which Firefox leaves as a
    hole under the page (the page is a subsurface), and never re-sampled on the
    page's own commits → waveview 1.83 composites the whole surface tree and
    listens to subsurface commits; the square-top patch also squares a subsurface
    that IS the window's top edge (7082820); userChrome dropped the 1px separator
    under the bar in webapp windows (b2f4dbb). Verified nested: bar = page colour,
    one straight seam. Live on the dev box at the next login (plugin + compositor
    load together).
  - Not yet exercised: an OAuth popup's class, a real Messenger notification from
    another workspace, Ctrl+W in a webapp, each site's own sign-in (one-time:
    WhatsApp's QR, Google, …), Spotify's DRM prompt. The laptops follow on their
    next autoupdate (they were off).
  - Decision for Max: webapps do not reopen when Seam restarts (Firefox never saves
    a web-app window; Chrome's app windows did not come back either).
  Found on the way (dock, fixed in 6bffa98/4b70533): Seam was missing from every
  browser list: the Brain never classified a Seam window as Browsing, link clips from
  Seam got no page snapshot and kept " — Seam" in titles, focus_browser never raised
  Seam; and the new Exec made every Seam window count as the first webapp by name.

- **P5 → CLOSED (2026-09-30): an artifact of the lab door.** With no ssh
  login present, the session's `CanSuspend`/`CanPowerOff` answer **yes**
  (logind's display session = the greeter session, local and active). Every
  earlier "auth needed" was measured while my ssh login existed: logind then
  picks that login (class user) as the display session and polkit sees a
  remote one. Real-user exposure: a second tty/ssh login of the owner would
  break Super+Escape (suspend) and USB mounting until it ends. `golem-deep`
  prints the sessions it saw for this reason.
- **P6. Every session exit crashes Hyprland (SIGSEGV).** Seen on logout,
  session restart and shutdown, on the macbook and the thinkpad. Two stacks:
  1. **Upstream (0.55.4) → FIXED 2026-09-30 (hyprland-screenshare-exit.patch):**
     at `exit()`, `CScreenshareManager`'s destructor stopped a live screencopy
     session (waverunner samples the screen to tint the bar) and posted an IPC
     event after `cleanup()` had freed the event manager (`postEvent.cold` ←
     `screenshareEvents` ← `stop` ← `__run_exit_handlers`; the MacBook's core
     of 2026-09-29 21:08). The stop now skips the IPC once the event manager is
     gone. Intermittent: neither laptop dumped a core at today's reboots.
  2. **Plugin teardown → FIXED 2026-09-30 (waveview 1.84, bda6f2e):**
     `CCompositor::cleanup` deleted a `CWindow` that still carried a title bar
     after the plugin unmapped. Hyprland's unload only QUEUES the removal and
     `updateWindowDecos` skips unmapped/hidden windows, so any titled window
     closed shortly before exit (every logout) kept its bar. Reproduced nested
     2/2, 0/2 without the plugin; the plugin now takes its bars off those
     windows itself: 6/6 clean exits. Stack 1 (screenshare) stays open.

  Cost: slower logout/shutdown (core processing) and 4–5 MB of cores each
  time. Fix: a Hyprland patch (screenshare teardown order), which belongs
  with P3. Meanwhile, waverunner could release its screencopy on the
  compositor's shutdown signal.

- **P7. A session stopped while it is still starting takes ~50 s to go
  down** (macbook, 2026-09-29: restarted 9 s after login; no timeout or kill
  logged, a silent wait in uwsm's stop path). A normal logout takes ~3 s.
  With the greeter wait + backstop the machine still comes back by itself;
  it is just slow.

- Cosmetic (still open): dbus-broker logs "Ignoring duplicate name" ×12 at
  error level on every boot (NixOS lists the system path and the package);
  blueman's GameControllerWakelock warning.
- Dev box only (still open): i915 `drm_WARN_ON(tc->mode == TC_PORT_LEGACY)`
  ×20 per boot (Alder Lake TC port, nvidia-tainted kernel); disk 86% full
  (730/904 GB); coredumps in 7 days: Hyprland 5 (P6), firefox 3, awww 2,
  hyprsunset 2.
- **P16 → FIXED 2026-09-30 (Max: "fix all of it").** greetd's
  `default_session` ran the owner's desktop, so logind classed it `greeter`:
  the root of P5 (CanSuspend/mount refused with a second login) and of the
  `lock-session` refusal. Now `initial_session` autologs the owner once per
  boot (class `user`) and `default_session` is tuigreet on tty1 after a
  logout (name remembered, password, the same wrapped uwsm session).
  Applies at the next boot (greetd never restarts on a switch). Verified in
  `golem-desktop-vm` (new, hosts/vm-desktop.nix: the Modular desktop stage on
  the VM host — `golem-vm` runs the FAT tree, whose greetd block is the old
  plain one): autologin → seat session class `user`; `hl.dsp.exit()` →
  tuigreet as `greeter` in 6 s; typed name + password → a new `user`-class
  Wayland session.
- **P17 → FIXED 2026-09-30 (waveview 1.86, 5af9791).** A switch that changed
  waverunner's unit restarted the dock mid-session (once per laptop today)
  and the windows parked on special:minimized stranded: the tiles lived only
  in the daemon's memory. The plugin, which owns the windows, now watches the
  dock's socket file (inode + birth time, once a second) and announces every
  minimized window again to a new dock. Nested: minimize → min-add; the dock
  restarted → the same min-add again within a second.
- **P15. ThinkPad slow to open apps (2026-09-30): the root is a USB spinning
  disk** (sda "BUP Slim BL", ROTA=1; the internal NVMe is unused). Cold
  `nautilus --version` 3277 ms vs 70 ms warm (47×): an app launch is hundreds
  of scattered reads. Also: its firmware has no _CPC, so amd_pstate cannot load
  (acpi-cpufreq, single-core boost 2.5 GHz of the 4700U's 4.1). Fix = install to
  the internal NVMe (Max's call); the CPU side needs a firmware with CPPC.
- **P14 → measured, no Golem-side cause** (2026-09-30): ThinkPad 66 s =
  19 s firmware (incl. the manual boot-menu pick of the external drive) +
  4 s loader + 18.7 s initrd + 23 s userspace; the initrd is the USB SSD's
  enumeration, userspace's chain ends in NetworkManager (5.4 s) because the
  login waits for network.target (systemd's default; left alone: safe, 5 s).
  MacBook 22 s. Nothing to fix in Golem.

- **P18 → CLOSED 2026-10-01: the MacBook's dock was an override build.**
  The live settings (Scale, Resolution) needed the dock from `~/launcher`
  main, which was 52 commits ahead of GitHub, so the MacBook first ran a
  one-off `--override-input waverunner path:…` build. On Max's go ("make it
  work on the macbook") the launcher line was pushed (0741d0e..98a1186) and
  Golem's lock bumped (3230bf7); the MacBook was switched from the lock, and a
  dry-build there now finds nothing to build, so the nightly autoupdate keeps
  this dock. The ThinkPad was off then; deployed the same way the same
  night (Golem 2a96bb6, dock 02d741a): scale 150 % -> 125 % -> 150 %
  dissolved, pointer pixel unchanged, nothing left saved. Its panel has
  several modes, so Resolution has real choices there; a mode change on
  metal is still untested (the machine locked on its idle timer mid-check).
- **P19. The MacBook's Wi-Fi drops under load (2026-10-01).** BCM4360 on the
  proprietary `wl` driver. During a 2 GB copy to it the 5 GHz AP was dropped
  four times in 21 minutes (22:00, 22:11, 22:16, 22:21, `reason=0`; one drop
  per boot on the three boots before), wpa_supplicant fell back to 2.4 GHz
  and blocked the 5 GHz BSSID for 30 minutes; twice the machine was then
  unreachable for 1 to 2 minutes with nothing in the log. Not investigated
  further. First things to try: power save off for `wl`, or pin the band.

### Deep debug 2026-09-30: verified OK (no finding)

Suspend/resume on the MacBook (rtcwake 25 s: same session, dock, wifi and
brightness; only a facetimehd PLL warning), fonts incl. Noto Color Emoji and
the Nerd font, all portals (FileChooser, Screenshot, ScreenCast, Settings,
OpenURI, Inhibit), dark mode as apps see it (portal 1, dconf prefer-dark),
Chromium runs native Wayland, clipboard, DNS and gateway, NTP, persistent
journal, firewall on, owner password set and root locked, swap + resume set,
zram, /boot at 20%, fstrim and gc timers, ppd/thermald per machine, Seam's
per-machine adaptation (rate, codecs, memory tier), user dirs, keyboard layouts
consistent across console/xkb/Hyprland, no failed units and no restart loops
on either laptop.

## Fixed

| Date | Finding | Fix |
|---|---|---|
| 2026-09-29 | `shell`: Super+E dead, `$SHELL` = a missing zsh | home.nix derives SHELL from the owner's login shell (6bcbd4f) |
| 2026-09-29 | `option:input:float_switch_override_focus`: focus followed the mouse between tiled and floating | ported `= 0` (click to focus, everywhere) |
| 2026-09-29 | `bind:main\|SUPER\|RETURN` + the `stage` submap: STAGE mode missing | ported the bind + submap |
| 2026-09-29 | `bind:…XF86*`: volume/brightness/media died inside submaps | ported `submap_universal = true` |
| 2026-09-29 | `rule:browser-subtle-border`, `rule:no-shadow-tiled`, `rule:golem-stage-frame`, pseudo-frame shadow, fullscreen `no_dim` | ported |
| 2026-09-29 | `option:decoration:shadow:*`, `option:decoration:dim_around` | ported the final values (14 / 0x661a1a1a; 0.8) |
| 2026-09-29 | `motion:curve:easy`, `motion:animation:workspaces*` | ported the faster spring + workspace speeds |
| 2026-09-29 | `command:golem-brightness`: brightness keys ran a missing program | desktop imports golem-brightness.nix |
| 2026-09-29 | `command:easyeffects`, `command:kdeconnectd`: autostarts of programs Golem doesn't ship | removed from Golem's hyprland.lua |
| 2026-09-29 | brightness keys: "Operation not permitted" once the helper existed | golem-brightness.nix ships brightnessctl's udev rule (group `video` can write the backlight) |
| 2026-09-29 | `stale:waveview-plugin`: the macbook ran titlebars 0.78 while 1.80 was installed (plugins load once per session) | new parity check `stale:*` (running vs installed Hyprland, plugin, dock); fixed by a session restart |
| 2026-09-29 | keyboard light off, its keys dead (macbook): XF86KbdBrightnessUp/Down were never bound | bound in Golem's hyprland.lua to `brightnessctl -d '*::kbd_backlight'` (any laptop); permission from brightnessctl's udev rule; systemd-backlight keeps the level across reboots |
| 2026-09-29 | MacBook F3/F4 did nothing: Mission Control and Launchpad were never bound | F3 → waveview `cycle()` (spread, overview, close; v1.81); F4 → apps box, closed by the box itself on the second press (waverunner 378d2d3); desktop-matrix asserts the Mac keys |
| 2026-09-29 | black screen after a session restart: greetd hit its start limit while the old session (Hyprland SEGV on exit, P6) was still going down | greeter waits up to 30 s for the old session's targets, then execs uwsm; greetd retries every 2 s, up to 20 a minute. Proven: two back-to-back restarts both came back by themselves |
| 2026-09-29 | F3 opened the spread and nothing more; volume keys dead over the overview: waveview swallowed EVERY key while the spread/overview was up | control keys (evdev ≥ 113: volume, media, brightness, kbd light, Mission Control, Launchpad) pass through (waveview 1.82) |
| 2026-09-29 | Super+Space/F4 fast: the dock stalled 0.5–1.7 s per press and replayed queued presses; Toggle closed to Hidden while Escape closed to the dock | waverunner 042e265: no vblank wait in present, one close path (dismiss), queued toggles coalesced, keyboard hand-back on a worker. Macbook 16 presses 13.5 s → 2.1 s; thinkpad every press 9–15 ms |
| 2026-09-29 | MacBook YouTube choppy: the 3D engine at 98% during playback (decode itself fine, 15% of the video engine) | `golem.desktop.effects = "light"` from gpu/intel-legacy → compositor blur off (98% → 81-85%); desktop-matrix asserts it |
| 2026-09-29 | Seam pinned a 1 GB memory cache + 12 live back/forward pages (dev box tuning) on every machine; the 4 GB MacBook swapped during video | Seam sizes both from MemTotal (golem-chrome.js PER-MACHINE MEMORY): ≥24 GB keeps the dev box values, <12 GB gets Firefox's RAM-scaled defaults; selftest ALL PASS |
| 2026-09-30 | Lenovo: fast Super+Space froze the dock 1-12 s (worst while the settings panel animated): a saturated iGPU made Vulkan's acquire wait on the event loop | waverunner e78c4fa: GPU pacing on every hardware backend; e964df8: each surface drawn at the output's real fractional scale (Lenovo GPU 74% → 66%, identical look). 60 overlapping presses: worst 13 ms |
| 2026-09-30 | P3 closed: titlebars' straight top edge didn't apply on the laptops (stock Hyprland lacked the square-top patch) | Golem ships the dev box's 4 Hyprland patches (desktop/hyprland-overlay.nix: square-top, vfr-hold, swipe-one-empty, gesture crash fix); waveview is compiled against the same overlay (identical drv); desktop-matrix asserts the patch + ABI match; swipe-one-empty config ported |
| 2026-09-30 | (deep debug) P5's "auth needed" was my ssh login being chosen as the display session | closed as an artifact; golem-deep prints the sessions it saw |
| 2026-09-30 | P8 notifications dead on installs | services.options-notify.enable on golem-desktop + the bake (+ matrix); libnotify; parity `notify` check. Verified: a card posted through the bus on the MacBook |
| 2026-09-30 | P9 no file-opening apps; "open folder" dead; text files could not open | desktop/apps.nix (golem-apps.nix core), desktop/session.nix (gvfs, dconf, udisks2, gsettings), TERMINAL/EDITOR/VISUAL in the session env + bashrc, xdg-terminal-exec → foot, lf keeps its Exec. Verified: Nautilus opens a folder, Text Editor a text file; defaults resolve on both laptops |
| 2026-09-30 | P10 the update loop had no upstream; config-revision unknown | base/seed.nix: golem.upstream + golem-seed-adopt (first-boot and autoupdate). Verified on both laptops: the seed is a checkout of origin/main with the machine files staged, config-revision names the commit, `golem-autoupdate` answers "already up to date", and a real pull + rebuild delivered the next commit |
| 2026-09-30 | P11 nothing on idle | hypridle (lock 5 min, screen off 6, suspend 15) + hyprlock + PAM + Super+L. Verified: hypridle active on both; the lock itself is Max's to try (Super+L) |
| 2026-09-30 | P12 bash without prompt, EDITOR or the OPTIONS bridge | home/bash.nix: starship/zoxide/fzf integrations, exports, the bridge ported (bash-preexec + socat). Verified: hooks defined, starship on, bridge socket present |
| 2026-09-30 | P13 the MacBook's garbage battery gauge | waverunner edd18c9: a self-contradicting gauge reads as no battery (tests carry the MacBook's exact values) |
| 2026-09-30 | (found by P10's first real pull) autoupdate ran `git pull` as root and left root-owned files in the owner's checkout; the owner's next pull failed | every git write into the checkout runs as the owner (runuser): autoupdate, golem-seed-adopt, waverunner-apply, postinstall |
| 2026-09-30 | (found by P11 going live) `loginctl lock-session` is refused for Golem's greeter-class session ("Session does not support lock screen"): the 5-min lock never happened | the idle lock, the pre-sleep lock and Super+L call hyprlock directly; desktop-matrix refuses any lock-session in the idle config or keymap |

| 2026-09-30 | (P1 diff) hyprsunset never shipped: the sunset option's "turn on" did nothing on an install | home.packages; desktop-matrix |
| 2026-09-30 | (P1 diff) the MacBook's gear had no GPU % (the i915 PMU needs perf_event_paranoid 0) | gpu/intel-pmu.nix, imported by both Intel leaves |
| 2026-09-30 | (P1 diff) Bluetooth devices stayed disconnected after hibernate on laptops | the dev box's reconnect service, in Modular + fat bluetooth.nix |
| 2026-09-30 | (P1 switch) a nested test Hyprland (2026-09-29) left the dev box's systemd user env on a dead socket (WAYLAND_DISPLAY=wayland-2, no DISPLAY/HIS): every display-needing user service aborted | re-imported from the session; the nested runner sets HYPRLAND_NO_SD_VARS=1; parity `sd_env` check |
| 2026-09-30 | (P11 live) both laptops woke to a dark screen, keyboard alive: `hl.dsp.dpms("on")` ignores the string and TOGGLES, so after a wake the "on" turned the already-on screen off and every later call ran out of phase | hypridle runs golem-dpms (`hl.dsp.dpms({ action = ... })`, idempotent, proven on the MacBook); misc key_press/mouse_move_enables_dpms as the safety net; desktop-matrix refuses the string form (970553d, deployed to both laptops) |
| 2026-09-30 | (P11, my deploy) both laptops FROZE on the lock screen (last frame, clock only, no input unlocked): hypridle started hyprlock as its own child, and the switch that shipped the dpms fix restarted hypridle while locked; systemd killed hyprlock with hypridle.service, and Hyprland keeps a session locked when its lock client dies. A user would hit it on any `switch` while locked (dock installs use switch) | recovered live, no session lost (allow_session_lock_restore + a hyprlock from the compositor). d191956: golem-lock launches hyprlock from the COMPOSITOR (never a service's child); allow_session_lock_restore = true; Super+L is a locked bind (brings a live lock back). Verified on both: hypridle restarted while locked, the lock screen survives |
| 2026-09-30 | (P9, mine) fcitx5 ran in EVERY session on the installs: desktop/apps.nix imported golem-apps.nix for the file apps and its input method came along; every keystroke went through fcitx5 (the MacBook's main keyboard became its virtual keyboard), it sat in the Apps grid, and no lock-screen password matched while it ran; the dev box would have started it at its next login (P1) | d99c6f0: the desktop's apps come without an IME (desktop/ime.nix is still Max's call); desktop-matrix refuses one. Deployed to both laptops and the dev box |
| 2026-09-30 | (P4, nested test) the compositor SEGVs when a client dies with its subsurface tree still mapped: SIGKILL Seam with WhatsApp open and Hyprland died in `CWLSubsurfaceResource::posRelativeToParent` (upstream 0.55.4 walks a dead parent; 2 of 3 kills with waveview loaded, 0 of 4 without) | hyprland-subsurface-orphan.patch: the walk (and its twin t1Parent + caller) stops at the first dead link |
| 2026-09-30 | (P4, title-bar look) Spotify, Netflix, Tidal… kept Seam's address strip for good: Firefox shows its DRM notice DISMISSED (an address-bar icon, no panel) and the prompt strip went up for any notification, with nothing to take it down | golem-chrome.js: a dismissed notification leaves the strip hidden; webapps-selftest checks it (fails on the old script) |
| 2026-09-30 | (both laptops, after sleep) title bars stopped matching their webapps: the first readback after a resume from suspend came back all but clear ("Gemini: 0 0 0 a=0.012"), the bar took it and went invisible, and a static page never re-sampled | waveview 1.85 (7b41fe2): a sample under alpha 0.25 is a failed read; the bar keeps its last colour and retries (~6 s), then waits for the next commit |
| 2026-09-30 | (all three) a pinch on the [current task] pill resized windows past their own minimum (YouTube in Seam wants >= 856 px; the pinch floored at 360): they shook and wandered; reproduced nested, the compositor threw the window ~900 px off-screen. A hand drag always clamped; the resize dispatcher did not | hyprland-floating-resize-limits.patch (a scripted floating resize keeps the window's min/max, as DragController does) + launcher 07dd7a8 (the pinch centres the size the window actually got). Nested: holds 793x240, centre fixed |
| 2026-09-30 | (laptops) a dragged YouTube window narrowed when grabbed and shook: the float rule's 704x388 is below YouTube's minimum, the window drew itself 804 wide on commit (CWindow::clampWindowSize) but the layout's record stayed 704, so every drag frame re-applied 704; measured live on the ThinkPad (704/804 flips at 12 Hz), reproduced nested (856 → 804 on the first move) | the floating-resize-limits patch grows: commitWindow syncs the record when it clamps, and a floating box is clamped to the window's min/max when placed. Nested: 856 held through every move; the pinch fix still holds |
| 2026-09-30 | (deep debug) installs had NO session guard: a live switch (seam-update, a dock install) on a checkout the autoupdate had already moved to a new nixpkgs would stop wayland-session-bindpid@ and tear the desktop down — the dev box has guarded its uwsm units since 2026-09-07 (P1 drift) | desktop/hyprland.nix: X-RestartIfChanged=false drop-ins on the four uwsm units; desktop-matrix asserts them |
| 2026-09-30 | (deep debug) golem-deep reported `systemd-journald restarts=1` on every machine: the initrd → root journald handoff, not a death | deep-root.sh skips journald |
| 2026-09-30 | (P16 logout test, MacBook) awww-daemon (the placeholder wallpaper) aborts when the compositor exits: a core dump + an error line per self-ended session | launched as `prlimit --core=1 awww-daemon` (limit 1 = no core, no coredumpctl entry, no error line; limit 0 still records it, measured); desktop-matrix asserts it. The wallpaper itself is still to be designed |
| 2026-10-01 | (MacBook, light effects) with the compositor blur off, the dock's glass (dock, apps card, box panels: one theme colour at 50%) showed the page behind straight through the labels | on the light tier the home layer writes `background = "#050709e6"` (90%, picked by Max on the MacBook from live previews of 70/80/85/90); full effects keep the default; desktop-matrix asserts both |
| 2026-10-01 | (data-layout review) the owner's password hash was world-readable: the installer wrote `hashedPassword` into the seed's machine.nix, so it sat in every generation's users-groups.json and every flake source copy in the Nix store (12 on the ThinkPad; four machines' hashes in the dev box's store) | base/users.nix: `hashedPasswordFile` → /var/lib/golem/secrets/owner-password-hash (root 0600), mirrored from /etc/shadow at activation; the installer writes that file instead; autoupdate strips the old line; desktop-matrix asserts it; GolemSecurity.md Phase 1b |
| 2026-09-30 | (deep debug) every Hyprland rebuild restarted xdg-desktop-portal-hyprland mid-session (its unit embeds the package): a screen share in flight died with it | the same X-RestartIfChanged=false guard; the new portal at the next login |
| 2026-09-30 | the "frozen lock" root cause, settled: a lock is only established once a frame reaches the screen. The dpms toggle bug left Hyprland believing the ThinkPad's panel was on while DRM had disabled it, so no frame ever came (lock never finished, unlock refused, clock frozen); only a session restart recovered. In a clean session with the fixes, the idle lock (via the compositor) → screen off → screen on → lock established → unlock worked (ThinkPad, 01:0x) | the fixes above; no stale dpms state can arise now |
| 2026-10-01 | (live settings, first two) a screen's scale and resolution needed a rebuild and a logout: both lived only in the generated hyprland.lua | the control panel's Scale and Resolution set them live (`hl.monitor` through eval), save the owner's choice to `~/.config/golem/settings.json` and a generated `settings.lua` that hyprland.lua now runs last (`home.nix`, the LIVE SETTINGS block; docs/system/LiveSettings.md). Dock: launcher 98a1186 (local main). Verified nested (live change, try/keep/back, reload, cold start with no dock, reset) and on the MacBook (scale 1.25 live, kept across a config reload, reset; then by Max's own hands, 20-odd scale changes, settling on 83 %). Pinned by lock 3230bf7 (P18) |
| 2026-10-01 | (MacBook, live scale) switching scales "jumps as crazy": stretched old buffers for a frame or more, the dock and bar SLIDING to their new place for ~0.4 s (Hyprland animates every layer surface's position on each monitor re-arrangement: `arrangeLayerArray` assigns `m_realPosition`/`m_realSize` animated), windows flying, the lit pill 350 ms late, and the pointer leaping (it keeps its logical position, so 83 % → 125 % throws it half again as far from the corner) | the dock dissolves the change: a still of the screen over everything, the change under it with `no_anim` rules on the shell's layers and on windows and its own motion snapped, a 260 ms cross-fade, the pointer put back on its pixel (launcher 2562eb2 + 02d741a, lock 2454e53; docs/system/LiveSettings.md). Verified by frame bursts in the nested rig and on the MacBook: old picture held, smooth ramp, at rest when the fade ends; pointer pixel unchanged through three switches |
| 2026-10-01 | (install pipeline hardening, from the DaVinci failure) seven more ways an app install from the dock could fail or lie: (1) Seam's update lane writes the browser pin into the checkout every new Firefox, never re-sealed → every install refused, and root's `git add` left owner-unwritable git files; (2) no shared rebuild lock: switch-to-configuration takes its lock without waiting, so an install meeting the nightly or Seam update died "Could not acquire lock" AFTER the new generation became the boot default; (3) a list change while the helper runs is dropped by systemd (measured: 4 edits, 1 run); (4) `rebuild-golem` never re-sealed, so the owner's own rebuild left installs refused; (5) the seal check's `diff -q` SIGPIPE noise in the reported error; (6) the 15-min idle suspend could fire mid-install (DaVinci took 25 min); (7) a first-ever install whose `git add` lost to a busy index "succeeded" without the app; plus the nightly update would stop for good once upstream and the local Seam pin both moved | `golem-rebuild` (golem-seal.nix): every rebuilder waits on /run/golem-rebuild.lock; the helper re-runs (≤5 passes) when the list changed during a pass and refuses clearly when its file can't be staged; Seam re-seals its own write (only if sealed before) and writes git as the owner; rebuild-golem blesses after a successful sudo switch; seal compares strings; idle suspend skips while an install/update runs (the lid still suspends); the nightly update sets a local pin aside, pulls, keeps it only if newer. Tested with the real built scripts in a stubbed harness (re-pass, busy index, bounded passes, failed rebuild, lock queueing, 5 pin cases) |
| 2026-10-01 | (Max: "it cant fail.. we cant fail on this. it have to install") the install helper still refused or gave up on things that are not the app's fault: a checkout whose changes are upstream's own code but were never re-sealed (any un-blessed pull), local edits the owner had not approved yet, a network blip, a full disk, a busy lock | golem-seal-heal: root fetches upstream itself (its own mirror, never the owner's .git), checks every changed file byte-for-byte against the commit the checkout is at, and re-blesses when all are upstream's; with real unapproved edits the install builds from a root-only snapshot of the last approved state (+ the list) — the app installs, the edit waits for `sudo golem-bless`; transient failures (network, disk full → store GC, lock) retried up to 6× with backoff while the dock keeps waiting. Harness: 12 heal cases (upstream pull, local edit, mixed, local commit, dropped file, forged HEAD ref, machine file, hostile .git/config fsmonitor never runs, unreachable upstream, packed refs, detached HEAD, no-op) + 5 helper cases (snapshot build, 3 drops then ok, permanent outage → honest failure after 6, real build error not retried, disk full → GC → ok) |
| 2026-10-01 | (install pipeline, "it have to install") the dock's Install section offered 23,673 packages; on Golem's nixpkgs 617 can never install (macOS-only, end-of-life, insecure, broken — scan of every one), 43 need a file downloaded by hand (requireFile), 28 are compiles of 20+ steps a laptop may never finish. And the index itself was a ~6.5 GB evaluation every laptop ran on its updates (the MacBook has 4 GB) | Golem ships its own checked list (system/home/package-index.tsv, 22,986 entries) generated on the dev box by tools/package-index/refresh.sh (evaluate all, then for the 1,246 not in the binary cache drop manual downloads and big compiles; unfree repackaged apps stay); the dock uses it (programs.waverunner.packageIndex); the matrix refuses an index made for another nixpkgs revision (negative-tested). Regenerate after every nixpkgs bump |
| 2026-10-01 | (golem-deep, MacBook) the owner could run `sudo nixos-rebuild` with NO password (base/users.nix): any program running as the owner could `sudo nixos-rebuild switch --flake <its own flake>` or `nixos-rebuild edit` and own the machine — around the seal entirely; GolemSecurity says no NOPASSWD ships | rule removed from installs (the dev box keeps its dev-loop rule in system/configuration.nix); minimal matrix asserts no NOPASSWD on an install (negative-tested). Also seen: the MacBook's battery gauge is broken (charge_full 60 Ah on a 7 Ah design, 1% while "Full") — hardware, unplugged it would read as empty |
| 2026-10-01 | (ISO acceptance, VM install of a fresh ISO) an install from the ISO booted to a TEXT LOGIN and stayed there: the bake was the stage-0 minimal and nothing climbs to the desktop by itself (the lab laptops had desktops only because they were moved onto #golem-desktop by hand). And with the desktop baked, the first boot sat on a BLACK SCREEN: first-boot (a oneshot wanted by multi-user.target) held graphical.target until its rebuild finished — the 2026-09-26 "can't reach graphical" bug, which the demo bake had only dodged by switching first-boot off | the ISO bakes the real desktop (bakeDesktop, English only — every language as a full desktop took 28 GB to evaluate; another language arrives with first-boot's rebuild); first-boot is started by a timer 30 s after boot at idle priority, outside the boot transaction (effect-matrix asserts it). VM, UEFI, 4 GB: install → desktop on first boot (bar + dock) → first-boot converged in ~60 s (everything already baked) → reboot → desktop → an app installs from the dock list in 20 s |
| 2026-10-02 | (ASUS X550LC, deep probe + parity after an ISO install) `xdg-settings get default-web-browser` named webapp-1password.desktop and `check … seam.desktop` said no: with $BROWSER set, xdg-settings takes the first .desktop whose command is $BROWSER's program, ~/.local/share first, and every webapp runs `seam -golem-app`. FIXED a56a792: BROWSER=seam-open (a launcher no .desktop runs) → the mime default, seam.desktop. |
| 2026-10-02 | (ASUS, parity) `bluetoothctl power on` + `blueman-applet` exec'd at login on a machine without a Bluetooth adapter (census turns the stack off). FIXED a56a792: the three lines are a hyprland.lua needle kept only where hardware.bluetooth is on. |
| 2026-10-02 | (ASUS, deep) OPEN: the post-install ASK framework (system/postinstall.nix) is imported only by the dev box's system/configuration.nix, never by the Modular composition — installed Golems never ask their questions. The ASUS's failing GF117M (gpu2-failing-action) was never asked about and stays powered (D0, control=on, nouveau) forever. Needs: port the asker into the Modular desktop stage (base/options.nix already declares golem.postinstall.answers and says it "arrives with the desktop stage"). |
| 2026-10-02 | (ASUS, deep) noted, not Golem: battery dead (0 %, 41 % health, pending-charge on AC — UPower's critical action only fires on battery, so plugged in is safe); RTC battery likely dead (booted at 1970 until NTP). |
| 2026-10-02 | (ASUS, boot) home-manager-max.service sat on the path to the greeter for 13 s on EVERY boot re-applying an unchanged home. FIXED 4555b6c (desktop/home-boot): ExecCondition skips it when the applied generation is this one and every managed link is intact; a removed link still triggers the full activation (verified). Userspace 30.5–32.6 → 21.8–22.1 s, autologin 42–44 → 34 s, power-on→dock 81–82 → 77–78 s. |
| 2026-10-02 | (ASUS, dock) the dock warned "premultiplied alpha unsupported, transparency may be wrong" on every GL machine. Measured over an orange wallpaper: GL and Vulkan give identical translucent bar/glass (wgpu's GL backend REPORTS Opaque as a TODO; the EGL buffers are ARGB8888). Dock edf54f3: now a debug note; first renderer rung asks for Vulkan alone (skips EGL/libgallium on Vulkan machines). |
| 2026-10-02 | (ASUS, HDD) tried a boot-time prewarm of the desktop's 593 MB: a wash (36 s competing with the boot; power-on→dock 79.5–81 vs 81–82 s). Not shipped; memory hdd-prewarm-no-win. |
| 2026-10-02 | (ASUS, dogfood) dock install of gnome-calculator: 45 s on the HDD, launches in 5 s with Golem's titlebar + dock tile; removal 15 s, no phantom tile. FAST LAUNCH (Super+J's ctl verb) opens/closes on dock edf54f3. OPEN, Max's call: GNOME/libadwaita apps show their OWN close × beside Golem's red titlebar button (org/gnome/desktop/wm/preferences button-layout unset) — hiding it would leave TILED windows (no Golem titlebar) without one. |
| 2026-10-02 | (ASUS, hibernate) two test_resume cycles (HibernateMode=test_resume drop-in + `systemctl hibernate -i`, pm_debug_messages on for the 2nd): "PM: hibernation: Hibernation image restored successfully", screen frozen 18 s, devices restored in 0.5 s; image 266k pages vs 1.68M available (image_size=0 working); the failing GF117M only logged its usual PRIVRING MMIO faults — no hang. Desktop, dock, OPTIONS, audio and caffeine all intact after. Also: Files' Network view FIXED 2063ff8 (wsdd shipped, firewall closed); window memory reopen + fit-to-screen verified; Seam blocks VP9/AV1 → H.264 on the HSW's VAAPI (i965 loaded in RDD). |
| 2026-10-02 | (ASUS, structural) an owner-edited tracked file in ~/Golem + an upstream change to the same file: golem-autoupdate's `pull --ff-only` refused and the machine STOPPED UPDATING FOREVER while the unit reported success (exit 0) — invisible to every probe. FIXED 5edc4ba: edits to Golem's own files are copied to ~/Golem-local-edits/<when>/ and restored before the pull (notification), the machine layer is left alone, and a seed that still cannot fast-forward fails the unit. |
| 2026-10-02 | (ASUS, structural) the owner DELETES ~/Golem (a folder in their home they don't recognise): golem-autoupdate failed forever ("seed is gone") and dock installs had nowhere to write. FIXED 90bd177: golem-seed-adopt rebuilds a missing seed from /var/lib/golem/blessed (the sealed tree, machine files included), hands it to the owner, notifies, then adopts it as a checkout of upstream. Verified: hosts/target identical, tree identical outside .git, autoupdate succeeds. |
| 2026-10-02 | (ASUS, structural) autoupdate stages updates for the NEXT BOOT and a laptop that only sleeps/hibernates never boots; the dock's deploy-health sensor set stale_generation but NOTHING consumed it — an owner could run an old system for months unknowingly. FIXED 49e3b15 (Max: "do the notification"): desktop/update-notice, a user timer notifying "Golem has an update ready" once a day when an update (system ≠ newest, or kernel/initrd changed) has waited 2+ days. Verified on the ASUS: silent when nothing waits / staged minutes ago, notifies at zero wait, no repeat the same day. |
| 2026-10-02 | (ASUS, structural) one package name nixpkgs does not have in the owner's list (a bad entry, or an installed app a nixpkgs update renamed/removed) broke the evaluation of the whole system: apply ok:false, the entry stayed, so every later dock install AND every rebuild (nightly update included) failed. FIXED b41e843: apps.nix looks each name up (lib.attrByPath), a missing one is skipped with a build warning; verified: the same list then applied ok. |
| 2026-10-02 | (double check, MacBook + ASUS on b41e843) MacBook: parity 0, deep clean (2 harmless kernel lines), SSD boot 21.7 s with the home-manager skip, dock ~36 s. Both: open boxes 0.95 (light tier), GNOME button-layout ':', wsdd, update-notice timer active, caffeine on; Bluetooth autostart kept on the MacBook (adapter), gone on the ASUS (none). |
| 2026-10-02 | (ASUS, structural) golem-autoupdate rebuilt only when the pull moved HEAD: a run that pulled and died in the rebuild (lid, power, broken download) left the checkout new and the system old, and later runs said "already up to date" until upstream's next commit. FIXED 3ca5a2f: compares the newest BUILT system's revision with the checkout. Also 07a0cf4: lab-pull treated hosts/target/apps.nix.last-good "AM" (after an adopt) as an owner edit and refused to bless — lab tool only, the seal never cared. |
| 2026-10-02 | (MacBook, structural) a compositor crash (SIGSEGV) restarted Hyprland in STOCK SAFE MODE: no Golem config/plugin, kitty on Super+Q, Hyprland's wallpaper, a yellow "autogenerated config" banner and a "your last session crashed" dialog — the owner was no longer on Golem (only the systemd dock came back). FIXED 4840728: 8th overlay patch crash-restart-normal — a crash after the session ran a minute restarts the owner's desktop (verified: plugin, wallpaper hook, OPTIONS, no dialog); a crash within a minute of starting still falls to safe mode (verified: 8 s → --safe-mode). |
| 2026-10-03 | (MacBook, crash recovery) Max: no Hyprland safe mode, ever. cbb3b69: one crash → the desktop restarts; a crash loop (2 quick crashes) → golem-rollback holds the revision and reboots into the previous generation, with a notice after; nothing to go back to → Golem's black last-resort screen with one Restart button; Hyprland's anime/lockdead images replaced with black (−48 MB). VERIFIED on the MacBook (2 fixed generations): 2 quick crashes → last-resort screen (black, Golem config) → reboot into the previous generation, crashing revision held, checkout moved back with machine files still staged, notice shown, golem-autoupdate "holding" on the held upstream head. Two bugs found in the test and fixed (1d5108f): reset dropped the staged machine files; the notice note was in root-only /var/lib/golem. Test state cleared after. |
| 2026-10-03 | (crash recovery) test generation marker — X4 on top of 4fbfb09. |
| 2026-10-03 | (crash recovery) test generation marker X4 (on top of the fixed rollback). |
| 2026-10-03 | (structural, Max: "how do we recovery the system so it really comes back and rebuild?") A rollback booted an old generation but left the SOURCE broken: no rebuild or dock install could ever work again. FIXED 51494b5/d61753d/2c39583: every generation keeps its machine layer (/etc/golem/machine) beside its revision; golem-recover puts ~/Golem back to exactly what built a system (owner edits kept aside, reset to the revision, hosts/target from the copy, staged, sealed); the crash rollback and a failed update build use it; the update and dock installs hold the rebuild lock for their whole run. VERIFIED on the MacBook: (1) broken machine.nix → recover → evaluates; (2) a broken upstream commit → update fails, source back, a dock install still works, the fixed commit then builds; (3) crash loop on B (calculator removed) → back to generation 69 with A's code AND A's apps.nix (calculator back); the recovered source evaluates to the booted system's exact store path. Bugs found by the tests and fixed: find not following the /etc symlink (restored nothing), a silent set -e exit, an install racing the update. Note: a later switch clears the update's failed state (switch-to-configuration reset-failed) — the failure stays in the journal. |
| 2026-10-03 | (night dogfood, 3 fresh installs: ASUS X550LC, Acer E5-573, MacBook Air) fresh lab ISO from 34a516c on all three: parity 0, deep clean, first-boot converged, the source rebuilds EXACTLY the running system on each. Dock killed 7× in a row: comes back every time (no start limit). Power cut (sysrq b) mid dock-install: ext4 recovered, the install resumed at boot and finished ok. |
| 2026-10-03 | (night, power cuts) FIXED c67bce7: a plug pulled mid dock-install left a store path registered VALID with broken contents (ASUS, openjdk-minimal-jre "was modified!") → nix fsync-store-paths = true; a stale .git/index.lock (a cut mid-git) failed the nightly update every night (Acer) → golem-git-unlock (made before this boot, or >10 min with no git) before the update, installs and golem-recover. |
| 2026-10-03 | (night, power cut mid nightly update, MacBook) the cut left EMPTY git objects (4, incl. the new HEAD: "bad object HEAD") and a truncated working-tree file: the update, installs and recovery could never touch ~/Golem again. FIXED c6ab2c8: git core.fsync = added; golem-git-heal (stale locks; empty objects deleted + re-fetched; else fresh checkout keeping the machine files) before the update, installs and recover. Verified: it repaired the MacBook (4 objects re-fetched, fsck clean). |
