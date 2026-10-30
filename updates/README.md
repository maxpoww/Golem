# Golem updates

How a Golem machine stays current, from a commit on `main` to a rebuilt
machine. What to DO in each situation is in [RUNBOOK.md](RUNBOOK.md).

## In one minute

An update is new configuration files plus a rebuild. That never changes.
This directory makes the rebuild **fast** (it downloads Golem's own pieces
instead of compiling them for an hour) and **safe** (nothing reaches a
machine before it was built for every kind of Golem machine).

```
 MAINTAINER          BUILD MACHINE — the lane, daily           EVERY GOLEM MACHINE — daily: its own moment of
                                                               the night, or minutes after it is turned on
 ──────────          ───────────────────────────────           ─────────────────────────────────────────────
 push to main  ──▶  1. take main (+ weekly NixOS fixes)   ──▶  1. a new version on stable? wait for my wave
                    2. build every Golem system (the gate)      2. git pull: the new configuration files
                    3. upload its heavy pieces, signed          3. rebuild: DOWNLOAD the pieces (minutes)
                       (github.com/maxpoww/golem-cache)         4. live at the next reboot; a version that
                    4. move `stable` to it                         breaks the desktop rolls back by itself
```

The heavy work happens once, on the build machine. A thousand machines only
download, and nothing about any machine is ever sent anywhere: Golem has no
telemetry.

## The map

| Piece | What it does |
|---|---|
| `lane/golem-lane.sh` | **The lane**: `run` (daily), `release` (NixOS jump), `prune`, `status` |
| `lane/select.py` | Which store paths go into a version's cache |
| `lane/never-publish` | What is never uploaded (licence) |
| `gate.nix` | What must build before a version is published (flake output `packages.x86_64-linux.update-gate`) |
| `boot-test.nix` | What must BOOT before a version is published: the desktop stage in a VM (flake check `boot-test`) |
| `builder.nix` | On the build machine: the `golem-lane` command + its daily timer |
| `client.nix` | On every install: the cache key, the per-version cache, the wave |
| `../system/Modular/base/autoupdate.nix` | The daily update: own moment (or right after power-on), wave, `stable`, pull, rebuild `boot` |
| `../system/golem-seal.nix` (`golem-rebuild`) | Hands every rebuild its version's cache (nightly update, first boot, dock installs, `rebuild-golem`) |
| `../system/Modular/base/seed.nix` | `golem.upstream.branch = "stable"` |
| `../system/Modular/lab/lab-door.nix` | The lab is wave 0 |
| `../system/Modular/effect-matrix.nix` | Asserts the client side (branch, key, timer, wave) |
| `../tools/deploy/lab-pull.sh` | A lab deploy follows the machine's branch; `GOLEM_LAB_BRANCH=main` tries main early |
| github.com/maxpoww/golem-cache | One release per published version |
| Build machine: `~/.local/state/golem-lane/` | `status.json`, `logs/`, the lane's own clone `repo/`, the gate's gc root |
| Build machine: `~/.local/share/golem-lane/cache-key.sec` | The signing key. Never in Golem's repo; backup in the private repo maxpoww/golem-keys |

## Two branches

- **`main`**: where work lands. Pushing to it reaches no machine by itself.
- **`stable`**: what every install follows. Only the lane moves it, only
  forward (a plain push: git refuses anything else), and only after the
  version built and its cache is complete and served. `stable` never holds
  a commit `main` lacks.

A seed that was installed when machines followed `main` is moved to
`stable` by its next nightly update, once `stable` exists on GitHub.

## The lane, step by step (`golem-lane run`)

**Once a week it publishes** (`PUBLISH_DAYS`, 7): one update a week per
machine, with the week's NixOS fixes and whatever landed on `main`. One
download, one boot entry and one store version a week instead of one a
day. Every other day it only **tests**: if `main` moved, it builds and
boots it (step 4) and notifies on a failure, so a break is known before
the publish needs it, and publishes nothing. `golem-lane run --now`
publishes today (an urgent fix). A publish that fails is tried again the
next day.

1. **Prepare**: its own clean clone of Golem, at `origin/main` (or `--base`).
2. **The NixOS release jump, when due** (see "NixOS releases" below):
   both inputs to the next release, the package index with them, then the
   gate. If it fails, the maintainer is told what broke and the run goes on
   with the current release.
3. **Weekly bump**: every `BUMP_DAYS` (7), `nix flake update nixpkgs
   home-manager`. Both follow their release branch: `nixos-YY.MM` is NixOS's
   channel branch, so the commit is one Hydra already built and tested.
   When nixpkgs moved, the dock's package index (the Install list, made for
   one nixpkgs: `tools/package-index/refresh.sh`) is regenerated with it.
   The bump is one commit, "flake.lock: weekly upstream".
4. **Nothing new?** If that commit is already `stable`, stop.
5. **The gate**: build `update-gate`, then every flake check, the boot test
   among them. Any failure stops the run and notifies the maintainer.
   `stable` does not move.
6. **The cache**: from the gate's closure, the paths cache.nixos.org does
   not have, that are heavy, and that we may share go into release
   `g-<first 12 of the commit>` of golem-cache, signed. Uploaded as a draft,
   made public when complete, then every file is read back until GitHub
   serves it, and one piece is proven against the key.
7. **Publish**: push the commit to `main` if it is not there yet, then to
   `stable`. If `main` moved meanwhile, nothing is pushed: tomorrow's run
   builds the new `main`.
8. **Prune**: keep the newest `KEEP` (6) caches, plus the one `stable` uses.

Every run also keeps **the calendar**: the day it first sees the next
NixOS release branch, and once a week a note of where things are.

`--no-publish` stops after step 6. `--base REF` starts from another ref,
`local/<branch>` with `GOLEM_LANE_LOCAL=<repo>` for a branch that is not on
GitHub yet. The state of the last run: `golem-lane status`.

## The gate

`update-gate` is the baked matrix (one full desktop per hardware class
Golem knows: every lab fixture in both firmwares, plus the generic floor,
which is exactly what an install copies), plus the two synthetic nvidia
desktops (open Turing+ driver and legacy pre-Turing driver).

- **It proves** every one of those systems builds: the configuration
  composes, and the kernel, out-of-tree drivers and initrd go together.
  The flake checks prove the semantic assertions (facts, chooser, effect,
  desktop matrices, keyboards, time zones).
- **The boot test** (`boot-test.nix`, a flake check) boots Golem's desktop
  stage in a VM (`golem-desktop-vm`: the composition and desktop every
  install runs) and waits for the owner's desktop to come up and stay up.
  It catches a kernel that panics, an initrd that cannot find its disk,
  a desktop that never starts. Added 2026-10-29: before it, nothing booted
  a version before users unless the lab laptops happened to be on.
- **It does not prove** that every machine's own hardware works: that is
  what the lab is for. Lab machines are wave 0 and take every version the
  night it is published, before anyone else's turn.

Why build and not only evaluate: on 2026-10-27, kernel 7.3 *evaluated*
fine for every machine and *failed to build* nvidia-open, facetimehd and
broadcom-sta (kernel 7.2 removed `strncpy`). Only a build shows that.

## The cache

- **Where**: GitHub Releases of maxpoww/golem-cache, one release per
  version, tagged `g-<commit 12>`. GitHub allows 1000 files per release and
  2 GiB per file, with no limit on total size or downloads. Each release is
  a complete Nix binary cache in one flat list: `nix-cache-info`,
  `<hash>.narinfo`, `<filehash>.nar.zst` (the narinfo `URL:` lines point at
  the flat name; the signature covers the content, not the location).
- **What goes in** (`select.py`), two rules, both learned on the first
  MacBook update (2026-10-27):
  1. Every closure path cache.nixos.org lacks whose derivation nix would
     *substitute* (`allowSubstitutes`): nvidia, Seam, the dock, patched
     Hyprland **with all its outputs**, the Golem scripts, the drivers. Not
     a size threshold: Hyprland's 20 KiB `man` output fell under the old
     64 KiB rule and the laptop started compiling Hyprland, because nix
     builds the whole derivation when one output it needs is in no cache.
  2. **Closed under references**: whatever those refer to that
     cache.nixos.org lacks comes along, whatever kind it is. Nix downloads a
     path only if it can download every path it refers to; otherwise it
     builds it. The dock compiled for 20 minutes because it refers (through
     waverunner-translate) to translation models, third-party downloads that
     were in no cache. So those downloads (open-licence models, browser
     extensions), trivial config files and source files go in when a Golem
     piece needs them.
  Left out: per-machine pieces nothing else needs (a fixture's initrd,
  system-path, unit lists, toplevel: every machine builds its own), trivial
  builds and downloads nothing cached needs, and never-publish. A cached
  piece that needs a never-publish path is reported as `blocked` (every
  machine builds it). First version: 2675 closure paths, 591 not on
  cache.nixos.org, 171 uploaded, no gaps. A set over 990 files fails
  loudly rather than dropping pieces.
- **Placeholders**: nix adds a path to a binary cache only if every path it
  refers to is already listed there. The lane writes a placeholder narinfo
  for each reference it does not upload, exports, and deletes them before
  uploading; machines get those references where they always have.
- **Licence**: only what we may redistribute. nvidia and broadcom-sta are
  `unfreeRedistributable` (allowed). Apple's FaceTime firmware is not and is
  in `never-publish`; each Mac extracts it itself, in seconds.
- **How a machine uses it**: `golem-rebuild` asks `golem-cache-args` for
  the release matching the checkout's HEAD (read from `.git` files, never
  by running git as root in the owner's repo) and passes it as
  `--option extra-substituters`. A piece is accepted only if the key in
  `client.nix` signed it, so a wrong URL can only make a build slower.
  No release (a local commit, a lab branch) means it compiles, as before.
  cache.nixos.org stays first: it answers for everything NixOS builds.

## The moment and the wave

- **The moment**: the update's timer has `RandomizedOffsetSec=6h`.
  systemd derives the offset from the machine's machine-id and the timer's
  name, on the machine, so each machine asks at its own fixed time between
  00:00 and 06:00, every night the same.
- **Off at its moment** (most machines are, at night): `Persistent=true`
  runs the missed update within 10 minutes of turning the machine on
  (`RandomizedDelaySec=10min`, fixed per machine too); a machine that slept
  runs it as it wakes. So a machine checks once a day: at its moment if it
  is on, otherwise right after it is turned on.
- **Why not `RandomizedDelaySec=6h`** (the first version, until
  2026-10-28): systemd counts a missed run's delay from the boot, so a
  machine turned on in the morning waited its 0-6 h again, and one used for
  less than that a day never updated. Proven on systemd 260 with real
  timers; the effect matrix asserts both settings.
- **The wave** (`client.nix`): a new version waits `wave` days, counted
  from the run that first found the machine behind (so a late-wave machine
  still updates when versions come faster than its wave), or from when the
  version was published if that is earlier: a machine installed from an
  older ISO, or back after weeks off, does not wait its whole wave again
  for a version the others have run for days. The publication time is the
  upload time of the version's cache, which GitHub serves as
  `Last-Modified` (`golem-update-published`). The wave is
  `machine-id mod 7` unless set. The lab is 0. Nothing is reported or
  asked. `/run/golem-update-now` skips the wait on one machine.

## An update never freezes the machine

The nix daemon does every download, unpack and build of an update, so it
runs in the idle I/O class with a low cgroup weight (`IOWeight=10`,
`CPUWeight=10`, CPU policy batch; `client.nix`). With BFQ on rotational
disks (`disk/policy.nix`) the user's programs get the disk first. Learned
on the Acer (2026-10-27): its first update through the cache compiled
nothing, yet unpacking 8.7 GiB onto its HDD froze the desktop at 98% I/O
pressure while BFQ split the disk fairly.

## The machine looks after itself

What keeps an install updating for years with nobody looking, and what
tells its owner when it cannot (audit, 2026-10-29):

- **The boot menu fits**: `/boot` is the 512 MiB ESP and every entry's
  kernel + initrd is copied onto it (~100 MB). The UEFI menu keeps 3
  entries (`boot/grub-efi.nix`). 15 filled it in about a month of weekly
  kernels, after which the entry for the new system was never written and
  the machine silently stayed on its old system. Every update run also
  checks that the newest system IS in the boot menu, writes it again if
  not, and fails loudly if it still is not.
- **The store fits**: 15 system versions are kept; with under 15 GiB free,
  only 3 (`base/store-gc.nix`). Nix also collects during a build when free
  space drops under 5 GiB.
- **The owner is told, and only then**:
  - "Golem has an update ready" when one has waited 2 days for a restart;
  - "Golem could not update for N days" after 7 days without a run that
    worked, and a failure since. Each run marks when it worked or failed in
    `/var/lib/golem-notices/update-{ok,failed}`
    (`desktop/update-notice.nix`).
  Both stay on the machine: there is no telemetry, so without them nobody
  would ever know.

## NixOS releases and the kernel

- Golem follows a NixOS release branch (`nixos-YY.MM` + home-manager
  `release-YY.MM`). The weekly bump brings that release's fixes, including
  the kernel's point releases.
- **The kernel** is NixOS's default, `linuxPackages`: the newest LTS NixOS
  has adopted. Golem never sets `boot.kernelPackages`. The FaceTime quirk
  patches `linuxPackages` only, so a kernel-set change elsewhere would lose
  it silently (eval-proven 2026-10-27).
- **A new LTS series** arrives with the May release, about five months after
  kernel.org declares it, by which time the out-of-tree drivers have caught
  up. 6.12 came with 25.05, 6.18 with 26.05; the LTS of late 2026 is
  expected with 27.05.
- **The calendar**: YY.05 is supported until 31 December, YY.11 until
  30 June of the next year. 26.05 ends **2026-12-31**; 26.11 is expected at
  the end of November 2026.
- **The jump happens by itself** (Max, 2026-10-29: NixOS makes the new
  release, but moving to it is each system's owner's job, and for Golem
  that is the lane). NixOS creates `nixos-YY.MM` about two weeks before it
  announces the release. The lane jumps on the first weekly publish
  `RELEASE_WAIT_DAYS` (28) after it first saw that branch, so the release
  has had its first fixes, or at once when the current release ends within
  14 days. The gate decides, boot test included; if Golem does not build or
  boot on it yet, that week's update goes out on the current release, the
  maintainer is told what broke, and the lane tries again the next week.
  The fix (renamed or removed options, in NixOS's release notes) lands on
  `main`; `golem-lane release` prepares and tests a jump by hand on a
  branch. The jump never changes `system.stateVersion`.

## Growing

The design does not change with the number of machines; these parts would:

- **Build machine**: the lane runs on any NixOS machine (`builder.nix`):
  the dev box today, a server later.
- **Cache host**: GitHub is fine for thousands of machines. For far more,
  a host made for it (Cloudflare R2, mirrors). It is one place in
  `client.nix` (the release URL) and one in the lane (the upload).
- **More hardware classes**: from the lab and public hardware data, as new
  fixtures, never from users' machines.
- **More waves**: `golem.update.waves`, or an early branch before `stable`.
