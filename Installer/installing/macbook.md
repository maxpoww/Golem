# MacBook — the module-database sweep (the boss fight)

MacBook Air 2013 · i5-4250U Haswell · HD 5000 · **Broadcom BCM4360**
wifi + BCM2046 BT · Apple EFI · ~3858 MB · Apple SSD (**NixOS —
guarded**). The lab's boss fight (Broadcom). Preinstall history:
`~/GolemOne/Install/Preinstall/testing/macbook.md`.

## Round I2 sweep — 2026-09-11 — fixtured; the BROADCOM wl leaf BUILT on source · NO install (census only)

- **Reachable at 192.168.1.109 via the Realtek USB dongle** (the
  internal BCM4360 is dark on the medium — no wl — so the dongle is the
  only path; Max reconnected it). Apple EFI booted the round-I1 stick.
- **Census (fixtured → `fixtures/macbook-air-2013/`):** i5-4250U 2c/4t,
  3858 MB, gpu=intel, **intelLegacy=true** (Haswell HD 5000 → i965),
  firmware=uefi (Apple EFI), **broadcomWifi=true**, panelDpi=126,
  hasBluetooth=true, cpuVendor=intel, laptop. Internal SSD (ESP + ext4
  "root" + swap) untouched, 0 writes.
- **Chosen leaves — the FIRST broadcom machine, unlocks the boss-fight
  leaf:** systemd-boot · intel-microcode · gpu/intel-legacy ·
  zram-tier1 · hibernation · disk/policy · power/laptop · power/thermald
  · **quirks/broadcom-wl**.
- **BUILT on source (2.94 GiB):** the composed toplevel compiles WITH
  the unfree module — **broadcom-sta 6.30.223.271 (`wl`) is in the
  built closure**, `wl` in boot.kernelModules, LIBVA=i965 for the
  Haswell iGPU. The allowInsecurePredicate scoping (broadcom-sta is
  flagged insecure) evaluates cleanly. chooser-matrix + minimal-matrix
  lock the list and the effects (wl module requested, broadcom_sta in
  extraModulePackages, i965, systemd-boot, thermald, tier1).
- **Verdict:** the boss fight's LEAF is proven to compile on source —
  the BCM4360 driver a MacBook needs is chosen from the census fact and
  builds. What's NOT yet proven (needs a real install, a future
  blessing): wl actually bringing the internal card UP on the installed
  MacBook — the #5 "live proof" still owed, now one blessing away.
