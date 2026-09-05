# GolemInstall — hardware that just works, as a spec

> Design doc for the S9 install story's core promise: **an installed Golem
> has every driver working out of the box.** Written 2026-09-03 at Max's
> direction ("make a spec and land it"), companion to `onboarding-design.md`
> (S8) and `system-landscape.md` (S4). Everything cited to a file in this
> repo is checkable; the few things that live outside it are named as such.
>
> Status: SPEC. Nothing below is built beyond what §3 credits as existing.

## 1. The idea

Linux is the most hardware-compatible OS on earth, and yet the everyday
story of installing it is: *"no audio" / "my wifi card doesn't work" /
"nvidia was such a pain I gave up" / "15 hours to get the fingerprint
reader going."* The kernel supports the chip almost every time. What users
actually spend those hours on is the **decision layer** — knowing that
this Broadcom needs `wl` and not `b43`, that this RTX wants modesetting +
the open kernel module + one suspend flag, that this reader needs fprintd.
On every other distro that knowledge lives in forum threads and dies
there. On NixOS the whole machine is one evaluated expression — so the
decision layer can be **code: versioned, reviewed, tested, and evaluated
per machine**. We are building a system on top of NixOS; if we don't end
the "Linux didn't recognize my..." era, nobody will.

The origin gesture, from Max's own practice: a hand-written `nvidia.nix`
he pasted into `/etc/nixos` after every reinstall of this laptop. It fixed
the machine every time. **Golem generalizes that gesture.** The distro
ships the entire collection of "nvidia.nix-equivalents" for every hardware
family, on every machine, permanently imported but dormant — and a single
machine-written facts file wakes up exactly the ones this hardware needs.
The paste step Max performed by hand for years is what the installer
automates. Nobody pastes anything, ever again.

## 2. The one rule

**Facts, never text assembly.** The installer does not select modules, does
not copy module files, does not generate configuration prose. Its entire
hardware output is two small per-machine files:

- `golem-hardware.nix` — sets `golem.hardware.*` facts (data, not code)
- `hardware-configuration.nix` — the stock nixos-generate-config output
  (filesystems, initrd modules)

Everything else ships identically in the flake to every machine and gates
itself with `lib.mkIf` on those facts. The "decision" is pure Nix
evaluation: deterministic, diffable, reproducible. Consequences that
matter:

- **One code path**, not 2^n assembled variants. A bug is fixed once, for
  every machine, on the next rebuild.
- **Testable without hardware**: CI evaluates any fact permutation by
  faking the facts — the same trick `hosts/vm.nix` already plays with
  `golem.hardware.gpu = "virtio"`.
- **The user stays sovereign**: every module default is `lib.mkDefault`,
  so a hand override in the machine's flake always wins, and the facts
  file itself is human-readable and editable when the probe gets one
  wrong.
- **The install never rots**: the machine's identity is declarative input
  carried in its flake, so `rebuild-golem` keeps producing a correct
  system for as long as the machine lives.

## 3. What already exists (credit where built)

The skeleton is standing; this spec grows it rather than inventing it.

| Piece | Where | State |
|---|---|---|
| Facts schema (`golem.hardware.{ramMB,cores,gpu,intelLegacy,intelBusId,nvidiaBusId}`), zram tiering, VA-API, nvidia switch | `system/hardware.nix` | built |
| `golem-hw-detect` probe (RAM, cores, GPU vendor by PCI id, intel-legacy; `-o` writes both per-machine files) | `system/hardware-detect.nix` | built, GPU-vendor-deep only |
| Runtime sibling for the live ISO (per-boot libva i965/iHD pick, Broadcom wl quirk) | `system/hardware-runtime.nix` | built |
| Fake-facts proof path | `hosts/vm.nix` (`gpu = "virtio"`) | built |
| Installer medium: minimal console ISO, Start/Install menu (vendored `iso-image-golem.nix`), **Install boots with `golem.install` on the kernel cmdline** — the hook the flow rides | `Installer/` | built 2026-09-03 |
| Source on the medium for offline instantiation | `hosts/iso.nix:86` (`/etc/golem/src`) | built, with the honest caveat at `hosts/iso.nix:82` that source-on-medium ≠ offline eval |
| Owner as an option (the installer's rename job) | `system/configuration.nix` (`golem.owner`), release-checklist §2.2 | built |
| Hardened NVIDIA module: open kmod, modesetting, the suspend/hibernate `powerManagement` fix (kernel_gsp.c:1447 assert, fixed & metal-verified 2026-09-03), PRIME ids as the only per-host value | `system/hardware/gpu-nvidia.nix` — ported 2026-09-04, generation-gated (`nvidiaGen`: turing+ → open/stable, pre-turing → legacy_580, unknown → nouveau floor per §8) | built |
| Probe fills the generation + PRIME bus ids (§4's "probe must fill them") — verified live on the Slim Pro 9i: emits byte-for-byte what `hosts/golem/nvidia.nix` hand-states | `system/hardware-detect.nix` | built 2026-09-04 |
| Laptop power stack — the `chassis` fact's first consumer (upower + power-profiles-daemon, gated on a confident "laptop") | `system/hardware/power-laptop.nix` | built 2026-09-04 |
| **The install target** (§6's "what to install"): `nixos-install --flake <seeded>#golem-target`; per-machine surface = the three files the flow drops into `hosts/target/` | `hosts/target/default.nix`, `flake.nix` (attr appears once hardware-configuration.nix is dropped) | built 2026-09-04 |
| Eval matrix (§8 leg 1): 10 fact permutations — lab fixtures included — evaluate as full golem-target systems with semantic assertions (iron-law row: unclassified nvidia must NOT activate the driver) | `system/hardware/matrix.nix`, `checks.x86_64-linux.facts-matrix` | built 2026-09-04, green |
| Memory family, RAM-tiered (decision: **hibernation locked in**, disk swap on every install): zram %, swappiness, cache pressure, dirty ratios, page-cluster, resume-device wiring, low-RAM nix build limits; lid → suspend-then-hibernate on laptops with swap; installer's swap sizing rule as flake code (`lib.golem.swapForHibernationMB`, RAM+10% ⌈GiB⌉) | `system/hardware/memory.nix`, `system/hardware/power-laptop.nix`, `flake.nix` | built 2026-09-04, matrix-asserted |
| Storage policy, fact-free by design (runtime-keyed): BFQ on rotational disks via udev (demanded by row 1's spinning WD), weekly fstrim | `system/hardware/storage.nix` | built 2026-09-04 |
| `vmGuest` fact (DMI vendor strings) → per-hypervisor guest tools; `fingerprint` fact (USB vendor ids 138a/06cb/27c6) → fprintd; thermald on Intel laptops; fwupd always-on | `system/hardware/virt-guest.nix`, `fingerprint.nix`, `power-laptop.nix`, `configuration.nix` | built 2026-09-04 |
| `panelDpi` fact (EDID physical width vs native mode, eDP, status-gated — sysfs stats edid as 0 bytes) → generated Hyprland eDP scale rule in the home layer (≥280→2.0, ≥210→1.6, ≥170→1.25, else none). Calibrated on the Slim Pro 9i: probe says 239 DPI → 1.6, agreeing with the owner's hand-tuned 1.60; the 102-DPI Acer correctly gets no rule | `system/hardware-detect.nix`, `system/home/home.nix` | built 2026-09-04, verified on both metal testbeds |

Decision record (Max, 2026-09-03): installer surface = **Golem-native**
(not calamares, not a CLI wizard); disk scope v1 = **whole-disk + LUKS
toggle**; boot menu = Start/Install only, no timeout (shipped, see
`Installer/iso.nix`).

## 4. The census — what `golem-hw-detect` grows into

Read-only probe of the target machine. Sources: PCI (class/vendor/device
ids), USB ids, DMI (chassis type, VM vendor strings), `/proc/cpuinfo`,
`/sys/class/{drm,bluetooth,power_supply,net,input}`. Emits facts:

| Fact | Drives | Detection |
|---|---|---|
| `gpu` vendor **and generation** | which GPU stack | PCI vendor id + device-id table: NVIDIA Turing+ → open kmod path; pre-Turing → legacy/nouveau path; AMD modern (amdgpu) vs old Radeon (SI/CIK flags); intel + `intelLegacy` (exists) |
| `intelBusId`/`nvidiaBusId` | PRIME offload on hybrids | sysfs PCI_SLOT_NAME, hex→decimal for X11 BusID — the only truly per-host values (probe fills them since 2026-09-04, emitted only on hybrids) |
| `cpuVendor` | intel/amd microcode | `/proc/cpuinfo` |
| `hasBluetooth` | bluez + blueman stack | `/sys/class/bluetooth`, USB/PCI radio ids |
| `wifiQuirk` | Broadcom `wl` etc. at install time (runtime version exists for the live boot) | PCI id families |
| `chassis` (laptop/desktop) + battery | power tuning, lid behavior | DMI + `/sys/class/power_supply` |
| `fingerprint` | fprintd | USB id table (fprintd-supported readers) |
| `vmGuest` (qemu/vbox/vmware/hyperv/none) | guest tools | DMI vendor strings |
| `ramMB`, `cores` | zram/swap tiers | exists |

**Conservatism rule:** every fact has an "unknown" value and unknown means
the safe generic default — `system/hardware.nix` already states this ethos
("0 = unknown → nothing regresses"); it is promoted here to a law for
every fact (§7).

## 5. The module library — `system/hardware/`, one family each

All permanently imported by the profile; each internally `mkIf`-gated on
facts; every value `mkDefault`:

- `gpu-nvidia.nix` — the ported dev-host module: modesetting, open kmod +
  current driver for Turing+, the suspend/hibernate powerManagement fix,
  PRIME from facts; `legacy_580` for pre-Turing; nouveau as the floor.
- `gpu-amd.nix` — amdgpu + VA-API/Vulkan; old-Radeon SI/CIK support flags.
- `gpu-intel.nix` — exists (both libva drivers shipped, per-boot pick).
- `cpu-microcode.nix`, `bluetooth.nix` (gate the existing stack),
  `wifi-quirks.nix`, `power-laptop.nix`, `fingerprint.nix`,
  `virt-guest.nix`.

**Anti-over-gating rule:** a gate is only added where the cost of
always-on is real (GPU driver choice, microcode, laptop power stack).
Harmless-when-idle stacks stay unconditional — every gate added is a test
permutation owed.

## 6. The install wiring

The `Install` menu entry boots the medium with `golem.install`. The flow
(surface per the decision record; engine is surface-independent):

1. probe the target: `golem-hw-detect -o` → the two per-machine files
2. disk step (whole-disk, LUKS toggle), owner/hostname step (`golem.owner`
   + GECOS — release-checklist §2.2)
3. seed the flake checkout onto the target (the `hosts/vm.nix`
   `seedGolemFlake` shape, from `/etc/golem/src`), drop the two files in
4. `nixos-install --flake` against the seeded checkout — offline, which
   requires §7's matrix
5. first boot comes up already correct; the facts file lives on in the
   machine's flake forever

## 7. The offline matrix — the open curation call

Facts select derivations, and an offline install means those store paths
must already be on the stick (`hosts/iso.nix:82` names this precisely: the
source being on the medium does not make evaluation or building offline).
Plan: at ISO build time, pre-evaluate the common fact permutations —
open stack, nvidia-open hybrid, nvidia-open desktop, AMD, intel-legacy —
and bake their closures into the medium (they share almost everything
except driver bits). Exotic paths (the legacy NVIDIA blob) say honestly in
the flow: *"this GPU needs a download."* **The size numbers get measured
before the line is drawn, and where it is drawn is Max's call.**

## 8. Proof, and the iron law

- **Eval matrix in CI**: every fact permutation evaluates with faked facts
  (no hardware needed — the technique that validated the nvidia module's
  AMD/desktop/closed-driver scenarios on the dev host).
- **End-to-end in qemu**: boot the ISO, install to a blank disk with faked
  facts, boot the result.
- **Metal testbeds**: the Slim Pro 9i (NVIDIA hybrid path) and the 2013
  Air (intel-legacy + Broadcom path) — then, per todo9, a machine that
  isn't ours.
- **The iron law**: a wrong confident guess is worse than a slow safe one.
  NVIDIA activates only on an exact device-id match; anything uncertain
  lands on the modesetting floor that boots on everything. A stranger's
  first boot must never be a black screen — an RTX on modesetting is a
  bug report; a black screen is a dead distro.

## 9. Later: detection as a sense (the Golem ending)

The probe doesn't die on install day. On the installed machine it can run
again when hardware changes, and OPTIONS surfaces the delta the diegetic
way: plug in a Bluetooth dongle → a pill offers to enable the stack. That
turns "good installer" into "the machine knows itself" — but it is a later
arc, recorded here only so the probe is written re-runnable (it already
is: read-only, output-to-stdout by default).

## Non-goals / refusals

- No imperative driver installation, no postinstall scripts mutating the
  system — facts in, evaluation out.
- No per-machine forks of module code; the machine-specific surface is
  exactly two files, one of them pure data.
- No hardware database service, no telemetry: the id tables live in this
  repo, the probe reads only local sysfs/DMI, nothing leaves the machine.
