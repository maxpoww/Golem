# ASUS — the modular install (to an external drive)

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
