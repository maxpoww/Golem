# Comodore — the module-database sweep (BIOS + legacy Intel)

Max's treasure. Intel GM45 whitebox · Pentium T4200 (2c/2t) · GMA 4500
(Gen4) · BIOS/legacy · 1931 MB · no BT · wired-only (Marvell sky2) ·
931 GB HGST (**Linux — guarded**). Preinstall history:
`~/GolemOne/Install/Preinstall/testing/comodore.md`.

## Round I2 sweep — 2026-09-11 — fixtured; the i965-legacy + grub-bios path built on source · NO install (census only)

- **Reachable at 192.168.1.129, no bounce needed** (working ssh/ping
  check — the corrected method; another auto-join datapoint against the
  downgraded #63).
- **Census (fixtured → `fixtures/comodore-gm45/`):** T4200 2c/2t, 1931
  MB, gpu=intel, **intelLegacy=true** (GMA 4500 Gen4 — the #12 fix
  holds), firmware=bios, hasBluetooth=false, cpuVendor=intel, laptop.
  Linux disk (ext4 + swap) untouched, 0 writes.
- **Chosen leaves — the FIRST intel-legacy AND second BIOS in the
  database:** **boot/grub-bios** · cpu/intel-microcode ·
  **gpu/intel-legacy** · zram-tier1 · hibernation · disk/policy ·
  power/laptop · power/thermald.
- **BUILT on source (2.95 GiB):** the composed toplevel compiles, and
  the built system carries the right things — `LIBVA_DRIVER_NAME=i965`
  (not iHD — the Gen4 GMA has no iHD decode), the enhanced-h264ify
  Chrome policy, GRUB enabled + systemd-boot disabled + device
  /dev/sda. chooser-matrix + minimal-matrix pin the list and the
  effects (i965, grub-not-systemd-boot, tier1 swappiness 180 / one
  build job, thermald on).
- **Verdict:** fixtured and source-built. The i965-legacy + grub-bios
  combination — the oldest-hardware path in the lab — is proven to
  compile without touching the treasure's disk.
