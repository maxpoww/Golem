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

- **P1. Two copies of the desktop (THE root cause).** The dev box runs
  `/etc/nixos/{hyprland.lua,home.nix}`. Golem ships `system/home/{hyprland.lua,home.nix}`,
  a copy taken months ago. Every change Max made on his machine since then
  (click-to-focus for floats, STAGE mode, submap-proof control keys, shadows,
  motion) never reached Golem. Parity catches the drift after the fact. Only
  ONE source prevents it: the dev box becomes a Golem machine that imports
  `~/Golem/system/home` (as it already imports `~/Golem/seam`), with its
  personal bits (the Lenovo panel, dev toolchain, patched Hyprland) as a
  per-machine layer. **Needs Max's go.**
- **P2. Window opacity + direct scanout.** Golem ships opaque windows and
  direct scanout (2026-09-02 perf pass for weak GPUs). The dev box has 0.95
  and no scanout. Decide whether one look is right for both.
- **P3. Golem runs stock Hyprland.** The dev box's patched build adds
  swipe-one-empty, vfr-hold (VRR flicker), square-top (titlebar seam) and the
  gesture-crash fix. Golem has none of them. Ship the patch overlay in the
  distro, which also locks the waveview plugin ABI to Golem's Hyprland.
- **P4. 71 dead webapp launchers** (`google-chrome-stable`) on machines seeded
  before the debloat (thinkpad, macbook). Fresh installs don't seed them. They
  go away with the webapps-to-Seam move, or with a one-time cleanup of
  `~/.config/webapps.list` + `~/.local/share/applications/webapp-*`.

- **P5. The desktop is not a seat session.** greetd runs Hyprland in its
  `default_session` (logind Class=greeter), and under uwsm the apps belong to
  the systemd-user *manager* session (no seat). Anything gated on an active
  seat session by logind or polkit can be refused. Brightness was
  (fixed with a udev rule instead); USB mounting (udisks2), suspend
  inhibitors and some NetworkManager actions are suspects. The dev box has
  the same greetd setup. Investigate with a parity check that asks polkit for
  the session's rights.

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
