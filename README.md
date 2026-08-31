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

> Honest caveat: two flake inputs (`waverunner`, `waveview-src`) still point
> at local checkouts, so today only Max's machine can build this. Repinning
> them to GitHub is the next S7 step; the ISO (S9) is the Arc-1 exit.

## Layout

- `flake.nix` — inputs pinned, two systems: `golem` (real hardware), `golem-vm`
- `system/` — the Golem profile: core NixOS modules + `home/` (home-manager)
- `hosts/` — per-machine: `golem/` (nvidia prime laptop), `vm.nix`
- `todo/`, `*.md` — the living plan (section logs, roadmap, feature maps)
