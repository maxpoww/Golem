# ASUS — the modular install (to an external drive)

## 2026-09-15 — DEFERRED for the #92 GRUB-EFI swap: the external drive no longer enumerates

Rule 2 lets a machine be deferred with a recorded reason. This is it.

**The evidence, from three separate boots of the machine:** the Seagate
BUP that carries this machine's stage-0 does not appear as a block
device (`lsblk` shows only the internal Toshiba + the DVD), does not
appear on the USB bus (the ONLY USB device present is the built-in
Chicony webcam), and — the diagnostic part — **logs no USB errors at
all**. A failing drive or a bad enumeration leaves something in dmesg;
silence means nothing is reaching a live port. Max reordered the
firmware boot entries and it kept booting the internal disk, which is
the expected result: firmware cannot offer an entry for a device that
is not electrically there. Cable, port, or drive — not boot order.

**A trap avoided, worth recording:** the machine answers at `.85` as
`asus`, healthy, with a Golem seed — and it is the **FAT DOGFOOD Golem
on the internal Toshiba**, not the stage-0. Told apart by three checks
before anything was written: Hyprland PRESENT (stage 0 is minimal by
definition), **no `hosts/target/modules.nix`** in the seed (that file IS
the modular install; the fat tree has `default.nix` instead), and
`/boot` + root both on `/dev/sda`. Running the #92 rebuild against what
answered would have written GRUB over the dogfood system's
systemd-boot, on the disk this round promised to leave alone. **Writes
to `sda` this session: 0.** Any future visit must repeat those three
checks before a destructive verb — the hostname alone is not identity.

**What is owed when a drive exists again:** the #92 GRUB-EFI swap plus
#89/#93/#95 (quiet boot, graphics handoff, the menu) — i.e. one live
rebuild, ~15 min, exactly the acer's recipe (7384 MB, so it builds
locally). Nothing else; this machine's round-I2 PASS below stands.

**Why deferring costs the round little:** the asus's unique evidence —
`gpu2/failing` on real failing-dGPU hardware, zram-tier2, the
external-drive install — is already banked below. Its remaining
contribution was a SECOND UEFI GRUB-EFI data point, and the acer
provided the first on metal today (including #94). The hp and macbook
have never met the round-I2 ISO and would teach more.

ASUS X550LC · i5-4200U Haswell (2c/4t) · Intel Haswell-ULT iGPU (boot
display) + **GF117M nvidia dGPU that FAILS its wake test** · UEFI ·
7384 MB · internal 298 GB Toshiba = **the lab's dogfooded fat Golem
(kept, untouched)**. Preinstall + first-install history:
`~/GolemOne/Install/Preinstall/testing/asus.md` and
[FirstInstall.md](FirstInstall.md).

## Round I2 — stage 0 on an EXTERNAL drive — 2026-09-11 — PASS; the #33 hold service live on the machine that invented the question

Max: *"i have an external usb drive… we will install in there, ok? so we
can keep the lab Golem."* — the modular stage 0 proven on real ASUS
hardware without losing the fat dogfood install.

### Safety (the point of this shape)
- Target: **`/dev/sdb` — Seagate BUP Slim 1.8 T USB**, blessed by Max
  after a read-only peek showed an old 182 GB system backup ("sdb,
  wipe it"). Three drives present; the drive list offered the internal
  Toshiba + the external and correctly **excluded the install stick**
  (#20). Typing "BUP" narrowed to the external alone — no chance of
  hitting the internal.
- **Internal `sda` untouched: writes-completed = 0 across the whole
  session**, ESP/swap/`golem` labels intact. The lab Golem survives.

### The install
- **ISO:** round-I2 (`m8vkd2jg…`). Answers driven over SSH; real
  `--prepare-only` with **`--lab-ssh` + `--lab-wifi HOLA`**.
- **Chosen leaves (the richest set yet):** systemd-boot ·
  intel-microcode · **gpu/intel-legacy** (Haswell boot_vga → i965) ·
  **gpu2/failing** (the GF117M) · **zram-tier2** (7384 MB — first
  tier-2 install) · hibernation · disk/policy · power/laptop · thermald.
- 2.93 GiB closure delivered over lab wifi to the USB drive;
  `--skip-prepare` wrote systemd-boot to the external's ESP (gen 1).
  EFI now has two "Linux Boot Manager" entries (internal + external,
  distinguishable by partition GUID) — Max picked the external at the
  firmware menu.

### First boot — everything the round was built to prove
- **`asusmin` on `/dev/sdb3`**, `is-system-running: running`, **zero
  failed units**.
- **#64 live on metal:** the machine **rejoined HOLA by itself**
  (`golem-lab:wlp3s0:activated`) — reachable over SSH with no keyboard
  help. This is the property the dell install depends on.
- **#65 live from the ISO:** no `fbcon=map:1` on the booted cmdline —
  the console is visible on a fresh install, not just after a patch.
- **#33 — THE HEADLINE:** `golem-dgpu-hold` **active**,
  `golem-dgpu-off` inactive, and the GF117M reads
  `power/control = on`, `runtime_status = active` — the chip is HELD
  AWAKE (never autosuspended, so it never hits the resume fault that
  "failing" measured), exactly the safe default the ask framework
  ships before an owner answers. **2 PRIVRING faults this boot**
  (driver-init only), matching the fat install's measured payoff.
  The leaf ported from gpu-second.nix behaves identically to the
  original on the machine it was written for.
- **Stage-0 checklist:** zsh, tier2 sysctls (swappiness 60 /
  cache-pressure 10), zram 3.6G prio 100 + 10G disk swap,
  **LIBVA_DRIVER_NAME=i965** (Haswell legacy, verified in a login
  shell), seed + modules.nix present, rebuild-golem present, and NO
  hyprland/waverunner (minimal, correct).
- **SELF-REBUILD proven:** `#golem-minimal` from its own seed →
  **generation 2**, still running, hold service intact.

### Verdict
**PASS.** The modular stage 0 installs, boots, reconnects, and rebuilds
itself on real ASUS hardware — while the fat dogfood install sits
untouched on the internal disk. The #33 failing-dGPU leaf is now proven
INSTALLED (not just built), on the exact machine that taught the lab
what a failing dGPU is. Next: the dell (BIOS + intel-legacy, keyboard-
less — the flow this install just validated end to end).

## 2026-09-23 — I2 CLOSE, roster machine 1 — the final recut (nqm2f3qav…, post nix-flake-update)

**Mode:** real-install + installed-boot, from the frozen final I2 recut
(`nqm2f3qav40q3cvv8hxq6zsr1rpramws`, the #117-fixed cut).

- **Install: 3m 26s** (Max, at the machine).
- **Boot bar (#117) — PASS ON METAL.** The Plymouth OPTIONS bar renders on the
  INSTALLED boot ("shows well") — real Intel Haswell `i915`, the first hardware
  test of the initrd-DRM fix. Closes the VM-only (bochs) caveat: the installed
  boot bar is real. The whole #116/#117 arc — accent-orange, thick, no words,
  boot-only, no shutdown splash — lands on metal.
- Carries the round's install UX (#103–#115): skip-login autostart (no banner),
  the steady 42-cell bar with white flying filenames, silent boot.

### Verdict
**PASS** (headline). First roster machine of the I2 close. Owed to complete the
§6/§8 record: `is-system-running`, failed-unit count, hostname · root device ·
memory tier · self-rebuild — the DockMenu audit numbers.
