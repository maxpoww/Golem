# HP

HP Pavilion dm4 Notebook PC · i5 M 460 (Arrandale, 2c/4t) · **switchable
graphics: Intel iGPU + AMD Radeon HD 6370M dGPU** · **boots BIOS/legacy** ·
298 GB Toshiba (existing Linux: ext4 "root" + swap; guarded) · 3718 MB RAM.
Real internal Intel Centrino WiFi (plus the lab's Realtek USB dongle).

---

## Round 1 — 2026-09-06 — census PASS · rehearsal PASS (BIOS caught) · 1 new reveal finding

- **ISO:** round-1; cores fix confirmed (`cores = 2`). Driven over SSH.
- **Census — correct, and a first:** i5 M 460, cores=2/threads=4, ram 3718,
  **`gpu = "amd"`** — the lab's FIRST non-Intel GPU. Two VGA controllers:
  Intel Core Processor iGPU (00:02.0) + AMD/ATI Robson CE [Radeon HD
  6370M] (01:00.0). Census correctly picked the dGPU (priority nvidia > amd
  > intel) and chose **driver `modesetting, fbdev`** — the safe open path,
  iron law satisfied (no proprietary amdgpu-pro, no black screen).
  `video decode: none` (no AMD VA-API decision — conservative; `intelLegacy
  = true` is recorded but moot since gpu=amd). bluetooth true, laptop.
- **Firmware: BIOS/legacy** — the SECOND BIOS machine (with the Dell). So
  BIOS is not a one-off in this lab.
- **Reveal (fixed golem-setup):** GPU `Intel … Integrated Graphics · i915`,
  Wi-Fi `Intel Centrino Wireless-N 1000 · iwlwifi` (real internal card, so
  it shows), Audio `Intel 5 Series/3400 HD Audio · snd_hda_intel`,
  Bluetooth `HP Integrated Module · btusb`. **23 of 31 (74%)** drivers —
  the lowest count in the lab (the AMD dGPU among the 8 unhandled, honest).
  - **NEW FINDING — the GPU row shows the iGPU, not the decided dGPU.** The
    reveal names the Intel iGPU (`hw_pci` takes the FIRST VGA controller,
    00:02.0) while the census DECISION is about the AMD dGPU (01:00.0). So
    the screen says "GPU: Intel" while Golem installs the AMD driver — the
    reveal and the decision disagree on a switchable-graphics machine.
    → changes.md #9.
- **Rehearsal:** `status: findings: 1`, bar **100% "Rehearsed"**, surface
  "rehearsed — nothing was written, 1 finding". checks.txt:
  - **`FAIL firmware: booted BIOS/legacy — systemd-boot cannot boot here`**
    — the UEFI check's second real catch. → changes.md #8.
  - `ok` target `sda`≠medium `sdb` · `ok` fit (298 GB) · `ok` facts match ·
    `ok` **eval 44 s** → `nixos-system-hp` (fastest metal eval yet — warm
    cache + faster than the Dell's Hitachi).
  - **`sda` byte-identical before and after** (ext4 root + swap) — the
    existing Linux install is safe.
- **Verdict:** census + rehearsal PASS. First AMD machine — the driver
  decision is safe (modesetting), and the reveal fix holds on a 4th
  machine, but exposed the hybrid-GPU reveal mismatch (new finding). BIOS
  blocker caught again. Install gated on the firmware decision (#8).

### The "74% drivers" scare, traced (2026-09-06)

Max: "23 of 31 drivers is sad… it's a damn amd, it's supposed to do well."
**Traced to the metric, not AMD.** The count is measured on the minimal
MEDIUM (`probe_compute`: driver-bound devices via `lspci -k` right now),
which ships almost no firmware — so the AMD GPU and other firmware-gated
devices read driverless. But the INSTALLED Golem sets
`hardware.enableAllFirmware = true` (configuration.nix:414, carries the
`radeon` firmware) and `gpu="amd"` adds AMD VA-API (hardware.nix:62), so
this Radeon is properly driven on the installed system. The label "will be
installed" describes the install but the number describes the medium — it
undersells. Same root cause as the MacBook's dark Broadcom wifi (#5): no
firmware on the minimal medium. → changes.md #10 (carry firmware on the
medium, or fix the count), #11 (AMD video-decode reporting). Proof lands at
the wired-install box.
