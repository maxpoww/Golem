# Golem OS

A NixOS-based desktop built around one idea: the whole environment — dock,
launcher, notifications, clipboard, workspace overview — is a single coherent
organism, not a pile of configured parts. OPTIONS is its soul. See
[docs/vision/Golem.md](docs/vision/Golem.md) for the vision and
[docs/vision/roadmap.md](docs/vision/roadmap.md) for where it's going.

**Status: pre-alpha.** This repo is the distribution itself (the flake at the
root builds every Golem machine, the installer ISO and the test matrices), plus
its documentation and worklog.

## The map — where everything lives

### This repo (`~/Golem`)

| Path | What | Rule |
|---|---|---|
| `flake.nix`, `flake.lock` | Every build output: machines, ISO, checks | Pins for the component repos live here |
| `system/Modular/` | **The distro**: one leaf per concern (base, boot, cpu, gpu, disk, desktop…), `composition.nix` + the `choose.nix` chooser | ⚠ Path is rendered into installed machines' `modules.nix`. Never rename |
| `system/` (other files) | The older all-in-one profile (`configuration.nix`, `home/`, `golem-apps.nix`…), ported into `Modular/` leaf by leaf | Port, don't grow |
| `system/home/` | The home layer (home-manager): hyprland.lua, waverunner, zsh | |
| `hosts/` | Per-machine instances: `target/` (installed Golem), `golem/`, `vm.nix`, `iso.nix` | |
| `Installer/preinstall/` | The installer ISO's implementation (the flake the ISO is built from, `fixtures/` for the eval matrix, `run-vm.sh`) | `fixtures/` is read by the build. Don't move it |
| `Installer/installing/` | The live INSTALLING program: `spec.md`, per-machine ledgers, delivery `tools/` | |
| `seam/` | Seam, Golem's browser (Mozilla build + policies + chrome + 4h update lane) | ⚠ The dev box's `/etc/nixos` and `seam-update.service` use this absolute path. Never move |
| `golem-connectd/` | Rust daemon (phone link) | |
| `docs/` | All design and maintainer documentation (below) | |
| `work/` | The living worklog: `GRIND.md`, `NOTES.md`, `todo/` (incl. `issues.md`) | Scratch, not spec |
| `tools/` | Dev scripts: `iso-smoke.sh`, `golem-mirror`, `loop/` (Gulum overnight loop) | |

### `docs/`, following the Modes / Shell / Installing sketch ([docs/STRUCTURE-sketch.md](docs/STRUCTURE-sketch.md))

| Path | What |
|---|---|
| `docs/vision/` | Manifesto, roadmap, features, apps, android, system landscape, accessibility research |
| `docs/shell/options/` | **OPTIONS**: constitution, UXRules, catalog, contexts, options-list, modules, method, PLAN |
| `docs/shell/actions/` | ACTIONS (Golem speaks first): constitution, conditions, the research agent + its `work/` output |
| `docs/shell/dockmenu/` | Dock + menu box maintainer program: README, INVARIANTS, SECURITY, AUDIT, harness, machines |
| `docs/shell/` | onboarding design, keyboard audit |
| `docs/installing/` | `GolemInstall.md` (the install spec), `postinstall.md`, `preinstall/` (maintainer docs: ARCHITECTURE, OPERATIONS, DEBUGGING, EXTENDING, TESTING, HISTORY + the six-round lab archive) |
| `docs/system/` | `GolemModules.md` (the module/app-bundle design) |
| `docs/security/` | `GolemSecurity.md` |
| `docs/release/` | `release-checklist.md` |

### The other repos (components pinned by `flake.lock`)

| Repo | What | Flake input |
|---|---|---|
| `~/launcher` | **waverunner**: the OPTIONS engine (Rust), bar, dock, menu box, options-notify | `waverunner` |
| `~/waveview` | Hyprland plugin: overview, spread, titlebars, minimize | `waveview` |
| `~/Golem-web` | golem-os.com | none |
| `/etc/nixos` | The dev box's own config (Max's machine; imports `~/Golem/seam`) | none |

A component change reaches Golem machines only after it is **pushed** and the
pin is **bumped** here: `nix flake lock --update-input waverunner` (or
`waveview`), then commit `flake.lock`.

### Outside every repo

- `~/VMs/golem/`: VM disks (qcow2) and old loop logs. Pass disks to
  `Installer/preinstall/run-vm.sh --disk ~/VMs/golem/<name>.qcow2`.

## Everyday commands

⚠ **Always evaluate as `git+file:///home/max/Golem`, never `path:`.** `path:`
copies the whole working tree into the store (it filled the disk twice). The
flake only sees **git-tracked** files, so `git add` a new file before building.

```sh
G=git+file:///home/max/Golem
nix build --no-link "$G#checks.x86_64-linux.minimal-matrix"   # base composes, all classes
nix build --no-link "$G#checks.x86_64-linux.desktop-matrix"   # the desktop stage composes
nix build --no-link "$G#nixosConfigurations.golem.pkgs.golem-seam"
~/Golem/seam/selftest.sh                                      # Seam, headless (~10 min)
nix build "$G#iso"                                            # installer ISO
```

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
