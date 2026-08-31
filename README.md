# Golem OS

A NixOS-based desktop built around one idea: the whole environment — dock,
launcher, notifications, clipboard, workspace overview — is a single coherent
organism, not a pile of configured parts. See [Golem.md](Golem.md) for the
vision, [roadmap.md](roadmap.md) for where it's going.

**Status: pre-alpha, Arc 1** ("reach metal"). This repo is both the plan
(`todo/`, the design docs) and the distribution itself: the flake at the root
builds a complete Golem PC.

## Build the VM

```sh
nixos-rebuild build-vm --flake .#golem-vm
./result/bin/run-Golem-vm
```

Boots straight into Hyprland as user `max` (password `golem` if you ever need
it) with the full Golem stack: waverunner dock/launcher, OPTIONS surfaces,
options-notify, the waveview workspace overview.

> Every input is pinned to GitHub — any machine with nix (flakes enabled)
> can build this. The ISO (S9) is the Arc-1 exit; until then the VM is the
> distribution's proving ground.

## Layout

- `flake.nix` — inputs pinned, two systems: `golem` (real hardware), `golem-vm`
- `system/` — the Golem profile: core NixOS modules + `home/` (home-manager)
- `hosts/` — per-machine: `golem/` (nvidia prime laptop), `vm.nix`
- `todo/`, `*.md` — the living plan (section logs, roadmap, feature maps)

## License

**GPL-3.0-or-later.** Copyright © 2026 Max Power. See [LICENSE](LICENSE).

Golem is free software: you may use, study, share and modify it. If you
distribute a modified version, you must pass those same freedoms on — nobody
gets to take Golem, add telemetry or ads, and ship it closed. That is the
manifesto written in a form that holds up in court.

GPL-3 also chosen because the planned Android companion forks
[kdeconnect-android](https://invent.kde.org/network/kdeconnect-android), which
is GPL-3.0, so the phone side is copyleft regardless — one license across the
project is simpler than two. The anti-tivoization clause matters too: nobody can
ship Golem on hardware where the user can't replace it.

Golem builds on and ships other people's software under their own licenses —
the Linux kernel (GPL-2.0), NixOS (MIT), Hyprland (BSD-3-Clause), the GNOME
applications (GPL) and others. Those are aggregated, not absorbed; each keeps
its own terms.
