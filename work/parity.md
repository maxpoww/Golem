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
- **P4. Webapps → Seam (IN PROGRESS 2026-09-30).** Installs showed 71 dead
  webapp launchers (Chrome `--app`, and Golem ships no Chrome). Design, proven then
  reviewed by max-79: a webapp is Firefox 157's own web-app window (Taskbar Tabs,
  Linux branch: `taskbartabclass` = the Wayland class `webapp-<slug>` = the launcher's
  id) inside the one running Seam: `seam -golem-app <slug> <url>`.
  - LANDED: the Seam half (ee7db99, seam/golem-chrome.js WEBAPPS, 19-check
    webapps-selftest.sh + selftest.sh green). Dormant until the dock sends the flag.
  - WAITING FOR MAX: the dock half (launcher branch webapps-on-seam, 6bffa98 +
    4b70533, not pushed: the launcher's rule is no push without Max). Then Golem:
    bump waverunner, seed the catalog on installs, drop the Chrome extension, and
    /etc/nixos/home.nix loses its own seedWebappsList (the same key, it would clash).
  - LIVE CHECKS on a laptop (both were idle-suspended): remote relaunch, class/title
    in Hyprland, OAuth popup class, no double bar floating, the prompt strip's
    contents, a real Messenger notification off-workspace, Ctrl+W closes only the
    webapp, relaunch from another workspace brings it.
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
  1. **Upstream (0.55.4):** at `exit()`, `CScreenshareManager`'s destructor
     stops a live screencopy session (waverunner samples the screen to tint
     the bar), and it posts an IPC event after the event manager is gone
     (`CEventManager::postEvent` ← `CScreenshareSession::stop` ←
     `__run_exit_handlers`). Reproduced with waveview 1.80, zero windows open,
     macbook 2026-09-29 16:50.
  2. **Plugin teardown (waveview 0.78, old):** `CCompositor::cleanup` deletes
     a `CWindow` that calls into the already unmapped plugin. Not yet seen
     with 1.80.

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
- **P14 → measured, no Golem-side cause** (2026-09-30): ThinkPad 66 s =
  19 s firmware (incl. the manual boot-menu pick of the external drive) +
  4 s loader + 18.7 s initrd + 23 s userspace; the initrd is the USB SSD's
  enumeration, userspace's chain ends in NetworkManager (5.4 s) because the
  login waits for network.target (systemd's default; left alone: safe, 5 s).
  MacBook 22 s. Nothing to fix in Golem.

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
