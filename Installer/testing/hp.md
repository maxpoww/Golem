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

## Round 2 — 2026-09-07 — BIOS install branch PROVEN end to end

The HP is the round's key machine: BIOS boot AND 3.7 GB (unlike the
Comodore, enough to complete the eval), so it fully exercises the new
GRUB/BIOS install path.

- **Census:** i5 M 460, gpu=amd, intelLegacy=true, **`firmware = "bios"`**
  (new fact, correct), bluetooth, laptop. No broadcomWifi (Intel Centrino).
- **BIOS rehearsal — the whole branch works (first time on metal):**
  - checks.txt: **`ok firmware: booted BIOS/legacy — GRUB to /dev/sda
    (BIOS-boot partition)`** (a hard FAIL in round 1; now a real path),
    target≠medium, fit, facts, **eval 43 s → `nixos-system-hp`** (the GRUB
    target evaluates to a valid system).
  - transcript: **`sgdisk -n1:0:+1M -t1:ef02 -c1:bios`** (the 1 MiB
    BIOS-boot partition), swap, root — **no ESP, no mkfs.fat, no /mnt/boot
    mount**. Exactly the GPT+BIOS-boot layout, dual-boot-friendly.
  - `machine.nix`: **`boot.loader.grub.device =
    "/dev/disk/by-id/ata-TOSHIBA_…"`** (by-id, stable).
  - synthesized hardware-config: root + swap, **no /boot filesystem**.
  - **`/dev/sda` untouched** — ext4 "root" (`b0f3d418…`) + swap intact.
- **"74% drivers" fully explained (round-1 open question closed):** the 8
  driverless PCI devices are ALL host bridges / PCI bridges / QPI registers
  — chipset glue that no OS binds a driver to. "16/24" counts those in the
  denominator. Every real peripheral is handled. Confirms the round-2
  correction: the number was the metric, not missing support. → changes.md
  #10 gets a concrete fix (exclude PCI bridge class 0x06 from the count).
- **Verdict:** PASS, and the biggest untested code in the round — the BIOS
  install branch — is proven end to end. BIOS decision (#8) delivered.

### Round 2, follow-up — hybrid GPU + honest count, fixed & verified on HP (2026-09-07)

Max: the lid has a big red "AMD Radeon" sticker but the reveal showed only
"GPU: Intel", with "74%" — reads as "they don't know my hardware." Both
fixed, verified live on the HP:
- **#9 both GPUs:** `hw_pci_all` enumerates every display controller. HP
  reveal now shows `Intel … · i915` AND `AMD/ATI Robson CE [Radeon HD
  6370M/7370M] · radeon`.
- **#10 honest count:** exclude PCI bridge-class (0x06xx) glue that never
  binds a driver → **19 of 19 (100%)** (was 23/31 74%).
Now the AMD is named and the count is truthful — matching the sticker.
Both ship in round 3 (frozen round-2 ISO unchanged).

### Round 2, second follow-up — radeon dGPU spam (muxless hybrid) (2026-09-07)

Photo of the HP's physical console (frozen round-2 stick, Spanish UI —
localization works: "Se borrará", "¿Instalar Golem?") showed repeating
kernel errors:
`radeon 0000:01:00.0: No VRAM object for PCIE GART` +
`[drm:evergreen_resume] *ERROR* evergreen startup failed on resume`.
Diagnosed: MUXLESS hybrid — Intel i915 (card0, enabled=1) drives the
display; the AMD Evergreen dGPU (card1, enabled=0, suspended; vgaswitcheroo
DIS:DynOff) keeps being runtime-resumed, fails, re-suspends → console
flood. Display fine, machine not broken. → changes.md #17 (recommend:
Intel primary + dGPU off/quiet; quiet the installer console). Also
corrects the reveal — "AMD · radeon" is bound but not functional here, and
census gpu=amd should have been intel (the enabled GPU).
