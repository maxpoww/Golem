# MiniGolem — the metal lab plan

> The build-and-track doc for raising Golem's install story from scratch on
> real hardware. The spec (WHAT and WHY) is `../GolemInstall.md`; this file
> is the HOW and the scoreboard — keep it current as machines pass.
>
> **Separation rule (Max, 2026-09-03): this ISO does not mix with the full
> live ISO (`..#iso` / `../hosts/iso.nix`).** MiniGolem is the minimal
> console medium in this directory, built as `.#iso` FROM HERE. The two
> merge later, deliberately, not by drift. Shared code is fine when it
> comes from `../system/` as a module import (same probe everywhere —
> that's reuse, not mixing).

## The method

Five old laptops, all different hardware, all currently running NixOS —
the compatibility lab. They boot MiniGolem from USB, we drive everything
from the dev machine over SSH, and the census earns trust one machine at a
time:

1. boot the stick → **it audits itself, unprompted** (2026-09-04). No
   command to type: `golem-audit.service` runs the collector, the probe
   and the decision at boot and leaves everything in
   `/var/log/golem-audit/`. The console shows the facts and the headline
   choices; the getty helpLine says where the full table is. ~8 s.
   The stick has no persistence, so every boot needs the network re-joined
   first (learned 2026-09-04 — a reflashed stick sat dark until):
   `sudo nmcli device wifi connect "<SSID>" password "<psk>"` — or ethernet.
   Note the ordering: the audit does not need the network, so the verdict
   is on the screen *before* the machine is reachable.
2. SSH in and read `summary.txt` — compare against what we KNOW is true of
   that machine. `evidence.tar.gz` is already built, ready to scp straight
   into `fixtures/<machine>/`.
3. iterate the probe logic **over SSH** (`nix build .#hw-detect` →
   `nix copy` → `systemctl restart golem-audit`; the stick is reflashed
   only for boot-level changes) until the verdict is right
4. next machine, by increasing weirdness; MacBook last (Broadcom + Apple
   EFI = the boss fight)
5. only once the census is right across the lab: install to a laptop's
   disk (guinea pigs — wipe them) and watch first boot. The mechanics are
   built and proven in the VM, but **this is the last step, not the
   next one** — a machine whose census is wrong installs the wrong Golem,
   and the whole point of the lab is to find that out before any disk is
   touched.

**Fixtures are the multiplier**: detection is a pure function of evidence,
so every committed dump lets CI re-verify all past machines in
milliseconds when the probe changes for a new one. The laptops teach once;
the repo remembers forever.

## Network reality (recorded 2026-09-03)

All five laptops run NixOS today and their wifi works out of the box —
**except the MacBook** (Broadcom, needs the `wl` quirk that
`../system/hardware-runtime.nix` already carries for the live session);
Max has a USB ethernet dongle for it anyway. So first contact over SSH is
a non-problem on four machines and dongle-bridged on the fifth — and
bringing the MacBook's wifi up natively then becomes a measured census
win, not a bootstrapping fight.

## The scoreboard

| # | Machine | Weirdness | Evidence | Census right | Installed, first boot OK |
|---|---------|-----------|----------|--------------|--------------------------|
| 0 | qemu VM (virtio) — the loop's dry run | none | ✅ `fixtures/qemu-virtio/` (regenerated as root 2026-09-04 from a live MiniGolem boot — the old dump predated `vmGuest`, which is why the probe now *measures* the hypervisor instead of the matrix guessing at it) | ✅ 13/13 facts+decisions, live on the medium, offline, 5.9 s | ✅ **installed + booted + audited at runtime 2026-09-04, hibernation performed** |
| 1 | Acer Aspire E5-573 (i5-5200U Broadwell, HD 5500, QCA9377 wifi+BT) | low | ✅ `fixtures/acer-aspire-e5-573/` (regenerated 2026-09-04 by the machine's OWN boot-time audit — no hand-driving) | ✅ **8/8 facts + 13 decisions, self-audited at boot in 20.9 s, every fact cross-checked against the metal** (see below) | ☐ (census first — install is the lab's last step) |
| 2 | (laptop TBD) | | ☐ | ☐ | ☐ |
| 3 | (laptop TBD) | | ☐ | ☐ | ☐ |
| 4 | (laptop TBD) | | ☐ | ☐ | ☐ |
| 5 | MacBook (Broadcom wl, Apple EFI) | boss fight | ☐ | ☐ | ☐ |

Fill in the roster as Max hands over machines; a row passes only when all
three boxes tick, and a probe change must keep every earlier row's
fixtures green.

## MiniGolem build state

- [x] Minimal console ISO, own flake pinned to the parent's nixpkgs
      (`flake.nix`, `iso.nix`)
- [x] Boot menu: Start / Install only, centered, tight selection, no
      timeout (`iso-image-golem.nix` vendored — header documents the diff);
      Install carries `golem.install` on the kernel cmdline
- [x] SSH-ready stick: key-only sshd, dev-machine key baked in
      (`~/.ssh/id_ed25519.pub` embedded in iso.nix), IP printed on the
      console (agetty `\4` helpLine)
- [x] Probe on board: `../system/hardware-detect.nix` imported into the
      medium
- [x] Evidence collector on board: `golem-hw-evidence` (`evidence.nix`).
      Hardened 2026-09-04 after the row-1 live check caught three failures:
      (a) sysdump's `card*` glob read connector nodes' `device/device`
      directory → junk lines + tr noise (now `-f`, regular files only);
      (b) a stale tarball from another user made tar fail under
      `fs.protected_regular` — every run now clears its output first, and
      an unclearable stale dir aborts loudly; (c) non-root runs silently
      lost dmidecode/lspci -vv/lsusb -v — both first dumps (rows 0+1) were
      degraded this way; now warned on stderr. Run it as root.
- [x] VM dry run of the loop's census half (row 0, 2026-09-03): booted,
      Enter sent via the monitor socket (`/tmp/golem-vm-hmp`), SSH'd on
      2222 key-only, evidence dumped + pulled to `fixtures/qemu-virtio/`,
      probe verdict correct (virtio / 4 cores / 3917 MB). Install half
      opens with the install flow.
- [~] Census growth per `../GolemInstall.md` §4 (facts driven by what the
      lab machines actually expose — build the fact when a machine
      demands it, against its fixture).
      Row 1 (Acer) demanded + delivered 2026-09-03: `hasBluetooth`
      (triangulated — sysfs class ∨ rfkill ∨ USB class e0; the radio hid
      from a lone sysfs glob), `cpuVendor` (→ microcode, consumer in
      hardware.nix), `chassis` (DMI type + battery tell; consumer-free
      until the power module lands). Bluetooth stack now rides the fact
      (system/bluetooth.nix gate, default-true conservatism). Verified
      over the wire: `nix build .#hw-detect` → `nix copy` to the live
      medium → re-run, no reflash — the fast path works as designed.
- [x] **The mechanism — WHAT the install installs** (2026-09-04, parent
      repo): the flow finally has a target. `hosts/target/` +
      `..#golem-target` is the installed-Golem shape (per-machine surface =
      the three dropped files); the module library opened
      (`system/hardware/gpu-nvidia.nix` — the dev-host port, generation-
      gated with the iron-law nouveau floor; `power-laptop.nix` — the
      chassis fact's first consumer); the probe grew `nvidiaGen` + PRIME
      bus ids (verified live on the Slim Pro 9i: byte-identical to the
      hand-written host facts; Acer replay unchanged); and the §8 eval
      matrix (`..#checks.x86_64-linux.facts-matrix`) evaluates 10
      permutations — BOTH lab fixtures included, so this lab's dumps now
      gate the parent repo's CI. Green.
- [x] Memory family (2026-09-04, parent repo): hibernation LOCKED per Max
      — every install gets disk swap (`..#lib.golem.swapForHibernationMB`
      sizes it: RAM+10%, 2 GiB floor, whole GiB) + zram in front
      (priority 100); swappiness/cache-pressure/dirty/page-cluster tiered
      on `ramMB` (180/50/5-2 on the 4 GB class → 10/10/10-5 at 16 GB+);
      resume device derived from the swap; laptop lid →
      suspend-then-hibernate at 120 min. All matrix-asserted.
- [x] Census wave 2 (2026-09-04, "do the all"): vmGuest→guest tools,
      fingerprint→fprintd, panelDpi→Hyprland eDP scale (dev 239→1.6 =
      Max's hand value; Acer 102→none), thermald (intel laptops), BFQ on
      HDDs + fstrim (fact-free, runtime-keyed), fwupd, low-RAM nix build
      limits; fq+BBR confirmed as deliberate distro policy. Evidence
      collector grew panel dumps (drm-conn.txt, edid.txt); Acer fixture
      refreshed; matrix at 13 rows, green. Live-verified on BOTH metal
      testbeds over the wire.
- [x] **The medium carries the whole distro, and decides on it**
      (2026-09-04, Max: "i want golem (on start) to decide which modules
      will use for the installation, the zram, the drivers, etc").
      MiniGolem's flake now takes the parent as a `path:../` input and
      every other input `follows` it — the duplicated nixpkgs rev that
      used to sit in `flake.nix` under a comment promising no drift is
      gone; there is one pin, upstairs. The stick carries
      `/etc/golem/src`, every input's source (`offlineSeed`, 213 MiB,
      almost all nixpkgs), and flakes enabled.
      **This closes `../hosts/iso.nix:83-85`**, which flagged that source
      on a medium is not an offline install because the lock still wants
      fetching: `golem-hw-decide` pins each input with `--override-input`
      to its on-medium store path, so the lock's github URLs are never
      consulted. Verified with a deliberately cold fetcher cache, and
      `--offline` keeps it honest.
- [x] `golem-hw-decide` (`decide.nix` + `../system/hardware/decide.nix`):
      probe the machine, then evaluate the REAL `golem-target` on it and
      print every choice — zram/swappiness/page-cluster, video drivers,
      nvidia gen+PRIME, microcode, bluez, thermald, fprintd, swap size,
      resume, lid, panel scale, BFQ, nix job limits. It runs through
      `lib.golem.mkTarget`, the one composition the matrix and the
      installer also use, so CI, the stick and the install cannot drift.
      **Live on the VM 2026-09-04: 5.9 s, offline, on 4 GB**, verdict
      correct on all 13 facts+decisions. Laziness is load-bearing — the
      panel scale is the only field that forces the home-manager fixpoint
      and it is gated on `panelDpi > 0`.
- [x] **The machine audits itself at boot** (`audit.nix`, 2026-09-04 —
      Max: "i press [start], Golem audits the device, makes the decisions,
      chooses the modules, and generates a summary that you audit via
      ssh"). `golem-audit.service` runs collector + probe + decide as root
      at boot and leaves `summary.txt`, `decision.json`,
      `golem-hardware.nix`, `evidence/` and `evidence.tar.gz` in
      `/var/log/golem-audit/`, plus a `status` file. Facts and the
      headline choices go to tty1 so a laptop that has not joined wifi yet
      can still be read off its own screen. **8.0 s, no disk touched, no
      command typed.** Runs on both boot entries — Start and Install boot
      the same system, and an audit is harmless either way;
      `golem.install` stays reserved for the disk flow.
- [x] The census reads like a report (2026-09-05, Max: "format it for the
      user, but keep it simple"). `decide.nix` now returns an ORDERED LIST
      of sections — cpu, ram, gpu first, then the rest — because a Nix
      attrset sorts alphabetically into JSON and the report used to open
      with BIOMETRICS. Lowercase labels, no box-drawing, measurement and
      decision shown together per subsystem ("the radio is there, so the
      stack is on"), and sections that do not apply to the machine (panel,
      VM, fingerprint) are dropped rather than printed empty. The renderer
      is deliberately dumb — it prints what it is given, so wording and
      order stay next to the values in `decide.nix`, and the tty1 banner
      is just the first three sections.
- [x] Install flow v1, mechanics (`install.nix`, whole-disk,
      **unencrypted — LUKS still pending Max's call**): asks the flake for
      the swap rule rather than copying it, GPT ESP/swap/root, `swapon`
      *before* `nixos-generate-config` so `swapDevices` lands in
      `hardware-configuration.nix` and hibernation actually gets wired,
      seeds the checkout into the owner's home, drops the three spec §6
      files, `nixos-install --system`. Split into `--prepare-only` /
      `--skip-prepare` because no medium's tmpfs store can hold an 18.8 GiB
      system closure: the closure is delivered to the *mounted target*
      between the halves (lab: `nix copy` from the dev box; a product
      stick would carry a prebuilt closure).
- [x] **Install flow v1, proven end to end** (row 0's third box,
      2026-09-04). MiniGolem booted UEFI in the VM, partitioned
      `/dev/vda`, dropped the three files, took an 18.8 GiB closure, and
      `nixos-install`ed it. The machine then booted **from its own disk**
      and every decision was checked at RUNTIME — the first time any
      Golem decision has ever actually run:

      | decision | eval said | the booted machine says |
      |---|---|---|
      | zram | 150 % of 3912 MB | `/dev/zram0` zstd **5.7 GiB**, prio 100 |
      | disk swap | 6144 MiB | `/dev/vda2` **6 G**, prio −2 |
      | swappiness | 180 | `vm.swappiness = 180` |
      | cache pressure | 50 | `vm.vfs_cache_pressure = 50` |
      | page-cluster | 0 | `vm.page-cluster = 0` |
      | dirty / bg | 5 / 2 | `5` / `2` |
      | nix limits | 1 job, 2 cores | `max-jobs = 1`, `cores = 2` |
      | resume device | the swap partition | `resume=…03d31a94` → `../../vda2` |
      | bluetooth | off (confident no) | no `bluetooth.service` at all |
      | thermald / fprintd | off | absent |
      | guest tools | on (`vmGuest="qemu"`) | `spice-vdagentd` + `qemu-guest-agent` **active** |
      | GPU | modesetting/fbdev | `virtio_gpu` loaded, no nvidia/i915 |
      | GECOS | "Max Power" | `getent passwd max` → Max Power |

      **And hibernation — the LOCKED decision — actually works.** Marker
      process PID 2060, `systemctl hibernate`, VM powered off, booted
      again: same `boot_id` (`7b989e8c…`), PID 2060 still alive. Not
      "wired", *performed*.
- [ ] Then: rows 1–5, in order

## Row 1 audit — Acer Aspire E5-573, 2026-09-04

First machine to boot MiniGolem from USB and audit itself. Pressed Start,
waited, SSH'd in at `192.168.1.99` (the router registered
`golem-installer.lan`). `status: ok`, 20.9 s — slower than the VM's 8 s,
which is the 5400 rpm disk and a 2015 CPU, not a problem.

Every fact cross-checked against the machine, not just accepted:

| Fact | Probe said | Metal says | |
|---|---|---|---|
| `ramMB` | 3833 | MemTotal 3925132 kB | ✅ |
| `cores` | 4 | i5-5200U: 2 physical / 4 threads | ✅ (informational; see note) |
| `gpu` | intel | only `8086:1616` HD 5500, no dGPU on this variant | ✅ |
| `intelLegacy` | false | `0x1616` ≥ `0x1600` → Broadwell, iHD-capable | ✅ **the one that matters** |
| `hasBluetooth` | true | `hci0`, not blocked | ✅ |
| `cpuVendor` | intel | i5-5200U | ✅ |
| `chassis` | laptop | DMI + battery | ✅ |
| `panelDpi` | 102 | eDP 1366×768, EDID 34 cm → 1366×254/3400 = 102 | ✅ |
| `fingerprint` | false | no reader on USB | ✅ |
| `nvidiaGen` | unknown | no nvidia present | ✅ |

Decisions that follow, all correct for this box: zram 150 % + swappiness
180 (3833 < 6144, the tight tier this laptop *is*), 6 GiB hibernation
swap, `iHD` VA-API (the whole point of `intelLegacy` — i965 here would
mean CPU-decoding video on a chip that cooks), intel microcode, bluez on,
thermald + upower + power-profiles-daemon on, lid →
suspend-then-hibernate, BFQ (the disk is a 1 TB WDC WD10JPVX, `ROTA=1` —
exactly the machine storage.nix was written for), no fprintd, no guest
tools, no eDP scale at 102 DPI.

**Reproducibility, checked three boots deep (2026-09-04).** Facts came out
byte-identical every time — detection is not racing udev. And on the third
boot the machine's own `decision.json` was compared against what CI
computes from the committed fixture:

```
nix eval …#lib.golem.decide (import fixtures/acer-aspire-e5-573/facts.nix)
  ==  /var/log/golem-audit/decision.json   # byte for byte
```

That closes the loop this lab is built on: **the fixture replay in CI is a
faithful stand-in for the machine.** "The laptops teach once; the repo
remembers forever" is no longer an aspiration.

Two smaller notes from the double-check:

- All three bluetooth legs (sysfs class ∨ rfkill ∨ USB class `e0`) fired
  on every boot, so the triangulation is currently insurance rather than
  load-bearing here — but leg 1 *was* empty in the original 2026-09-03
  dump of this same machine, which is why it exists.
- The console banner lands ~21 s in and can scroll off if someone uses the
  console meanwhile; on the third boot tty1 showed only a prompt.
  `systemctl restart golem-audit` re-runs the whole census in ~21 s
  without a reboot and reprints it — that is also the fast path for
  iterating probe logic over SSH.

*Fixed 2026-09-05 (Max: "Golem now confuses 4 threads = 4 cores on a
2 cores cpu"):* `cores` used to be `nproc`, i.e. logical CPUs, so this
machine's dual-core i5-5200U with SMT read as a quad. The probe now
reports **`cores`** (distinct `physical id`:`core id` pairs — 2 here) and
**`threads`** (4) separately, plus **`cpuModel`** so a lab machine names
itself in the census. All three are informational; nothing gates on them.
The Acer's `facts.nix` was re-derived from its own committed `cpuinfo.txt`
rather than guessed — detection is a pure function of evidence, so that is
the same answer the machine gives — and should be re-confirmed on its next
boot.

## What running it on a real machine cost, in bugs

Eight findings. Every one was invisible to the eval matrix and fell out of
actually booting the thing. Recording them because they are the argument
for putting the census on real hardware early — and note that **two of the
seven were the test rig lying to the probe**, not Golem being wrong. When
a census result looks wrong, suspect the harness first.

1. **`gpu = "auto"` on a machine with a GPU** — not a probe bug: the
   headless VM runner passed `-vga none`, so `/sys/class/drm` was empty
   and the census honestly described a machine nobody owns. A test
   harness that lies to the probe is worse than no test. `run-vm.sh`
   headless now keeps a `virtio-gpu-pci`.
2. **`path:` is not decoration** — `nix eval /nix/store/…#attr` parses the
   ref as a *store path* installable and dies with "does not correspond to
   a Nix language value". It happened to work on the dev host and failed
   on the medium. Spell the scheme.
3. **`HandleLidSwitch` is absent, not false** — `services.logind.settings`
   is freeform, and `power-laptop.nix` defines the lid only on a laptop.
   Reading it unguarded threw on the qemu fixture (`chassis="unknown"`).
   The matrix never caught it because it only asserts lid policy on a
   laptop row.
4. **The owner's GECOS could not be set by the installer** — the very
   thing `../system/configuration.nix:54` says "stays the installer's to
   set" was defined at normal priority, so the `machine.nix` that
   `golem-install` writes collided with it: *"conflicting definition
   values: Max / Max Power"*. Now `lib.mkDefault`. A base value a
   per-machine file cannot override is not a default, it is a decision.
   **This one would have broken every real install**, and no amount of
   matrix rows would have found it — the matrix never writes a
   `machine.nix`.
5. **A systemd unit cannot see `environment.systemPackages`** — the
   boot-time audit failed instantly with "golem-hw-detect: command not
   found". Units get an explicit PATH; the system profile
   (`/run/current-system/sw/bin`) is not on it. The tools are now passed
   as derivations through `specialArgs` and named in `path`.
6. **Silent error suppression hid a broken banner** — the console's
   decision lines used `join(\", \")`, a jq syntax error, and the
   `2>/dev/null || true` around it meant four lines simply never appeared
   with no trace. stderr now reaches the journal. (Also: the kernel
   console font has no box-drawing glyphs — the banner is ASCII.)
7. **Half the lab was seeing an unstyled boot menu** (Max, 2026-09-05:
   "on the acer i just see Start at the left top corner, the selection is
   blue and it's the whole screen width... on an older pc it looked as we
   designed it"). Same stick, different firmware: BIOS boots
   isolinux/syslinux, which WAS themed; UEFI boots GRUB, whose
   `isoImage.grubTheme` was `null`. `iso.nix` called that "close enough" —
   it was not, and it is the first thing a stranger sees. Now
   `grub-theme.nix` draws the same design for GRUB, verified by
   screenshot on both paths.

   Getting there cost three ISO rebuilds of guessing, because **every GRUB
   theme failure is silent** — a rejected theme looks exactly like no
   theme. Two real causes, in order of discovery:
   - the font name in `theme.txt` must be the name *inside* the `.pf2`
     (`DejaVu Sans Regular 20`), not the `DejaVu Regular` that
     nixos-grub2-theme's own theme.txt uses. It is now read out of the
     font at build time so it cannot drift.
   - **the actual killer:** GRUB's png module supports only truecolour
     RGB/RGBA, and ImageMagick encodes a solid-colour swatch as 1-bit or
     4-bit *grayscale*. `error: png: color type not supported`. Forced
     with `PNG32:`, and the build now asserts the IHDR colour type byte
     rather than trusting it.

   The lesson worth keeping: that error is invisible during boot. It only
   surfaces by dropping to the GRUB command line (`c`) and re-running
   `normal` by hand. Do that FIRST next time instead of rebuilding.
8. **`qemu-guest-agent` enabled but dead** — again the harness, not
   Golem: no `virtio-serial` + `org.qemu.guest_agent.0` port in the VM,
   so the unit could never start. `run-vm.sh` now provides the channel;
   agent confirmed `active` afterwards. Two of five findings were the
   test rig lying about the hardware — worth remembering when a census
   result looks wrong.

## The closure-delivery seam (how the lab installs)

No medium's store can hold what it installs: the stick's store is a tmpfs
overlay in RAM and the system closure is **18.8 GiB** (8.4 GiB with
`golem.lean`). So `golem-install` splits at `--prepare-only` /
`--skip-prepare`, and the closure is delivered to the *mounted target*
between the halves. In the lab that is, from the dev box:

```sh
nix copy --no-check-sigs \
  --to "ssh-ng://root@127.0.0.1?remote-store=local%3Froot%3D/mnt" <toplevel>
```

`--no-check-sigs` is required (locally built paths are unsigned) and root
is required (the `nixos` user cannot create `/mnt/nix/store`). ~1 min over
loopback.

**This is a lab stand-in, not the product answer.** A stranger's install
still has nowhere to get 18.8 GiB from: cache.nixos.org does not have
waverunner or waveview, and building those on a 4 GB laptop is not a
plan. The real options are (a) carry a prebuilt closure on a bigger
medium, (b) install lean and let the machine fill itself in later, or
(c) require a network install and accept the download. **That is a Max
call, and it is now the biggest open question in the install story.**

## Working agreements

- Max is the idea guy and manages scope; the technician builds what's
  agreed and brings back numbers for curation calls (offline matrix, spec
  §7).
- Everything lands `git add`ed; commits are Max's call.
- The iron law travels with every change: uncertain detection lands on the
  safe open stack; a stranger's first boot must never be a black screen.
