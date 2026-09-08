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

### Round 2, third follow-up — the Spanish run, driven end to end (2026-09-07)

Fresh boot of the frozen round-2 stick; drove the full Spanish flow over
SSH (192.168.1.150, HOLA auto-join) to chase the photo's oddity: a Spanish
screen with an ENGLISH driver-count line. Reproduced it exactly, and the
diagnosis closed same-day.

- **ISO:** round-2 confirmed by the `firmware = "bios"` census fact and by
  the unwrapped script (`valid_host Golem` = 1, `S[es:drv_line]` = 1 —
  **the Spanish translation IS on the stick**). Note: the playbook's
  `grep … "$(command -v golem-setup)"` now greps the WRAPPER (which only
  sets env/PATH and execs); the real script is
  `…-golem-setup/libexec/golem-setup-unwrapped` — CLAUDE.md updated.
  The wrapper's PATH carries pciutils+usbutils — fix #3 visible on metal.
- **Census:** ok; same facts as round 2 (gpu=amd still — #17b pending).
- **Surface, the finding — three English leaks in a Spanish run** (the
  substance is fine: every label, prompt, key-legend line and "(Se
  borrará)" render Spanish; ghost fix held — typed `hp`, row read
  `Dispositivo hp`):
  1. **`23 of 31 (74%) drivers will be installed.`** — the photo's line.
     NOT a missing translation: `probe_start` backgrounds
     `probe_compute > $DRV_FILE` at startup, and probe_compute renders
     `t drv_line` THEN — while `UI` is still the English default. The
     confirm screen just cats the pre-rendered cache. Language chosen
     later never touches it.
  2. **`83% Evaluating the system`** — the label travels as literal text
     in the engine's protocol line (`##golem 5/6 evaluating the system`,
     install.nix:603); the TUI prints what it's handed, no key to
     translate.
  3. **`rehearsed — nothing was written, no findings`** — hardcoded
     printf (install-cli:3171/3173), not in the string table at all.
  - Also of the same family, noted not queued: the decision-row VALUES
    (`Zram 150% of ram…`, `Lid Suspend-then-hibernate`) are audit-time
    English strings; and the new R3-3 LUKS strings (luks_warn, luks_ack,
    erased_enc, e_lcpass, t_lcpass) exist ONLY in English — the scare
    screen wouldn't scare a Spanish stranger. All → changes.md #18.
- **Rehearsal:** status ok, **0 findings**, bar to 100%. checks.txt all
  green — BIOS/GRUB line ok, target sda ≠ medium sdb, fit, facts, **eval
  43 s → `nixos-system-hp`**. machine.nix carries the Spanish answers
  properly: `hostName "hp"`, `es_ES.UTF-8`, `Europe/Madrid`. **`/dev/sda`
  untouched** — ext4 "root" `b0f3d418…` + swap `568830cc…`, identical
  UUIDs before and after.
- **Radeon (#17), quantified this boot:** only 2 resume failures in
  ~18 min — both timestamped during my golem-setup run. The installer's
  own lspci probes are among the runtime-PM pokes that wake the dead
  dGPU. vgaswitcheroo unchanged: `IGD:+:Pwr` / `DIS: :DynOff`.
- **Verdict:** PASS on substance — the Spanish run produces a correct
  Spanish target and a clean rehearsal; the three English leaks are
  surface, queued as #18.

### Round 2, fourth follow-up — dGPU health test prototyped on this metal (2026-09-07)

Max decided #17: health-gated, not blanket ("we can not have Golem
leaving all dedicated GPUs out"). Prototype
(`fixtures/tools/gpu-health-probe`) ran here same day: primary pick by
`boot_vga` → i915; forced runtime resume of the radeon dGPU →
**2 kernel errors → FAILING** (power it off on the installed system).
Notable: after the failed resume the HP's `runtime_status` read
`active` — the power state claims success while the driver failed, so
the dmesg scan is the real signal. Control run on the dev laptop's
RTX 4050 (same script): wake from suspended, 0 errors, **HEALTHY** —
both verdict paths proven. Details + design facts in changes.md #17.

### Round 2, fifth follow-up — console-quiet (#17a) A/B-proven here (2026-09-07)

The photo's error-spam fix, demonstrated on this metal using the radeon
as the error generator and `/dev/vcs1` as the eyes on tty1: at the
medium's default console loglevel (4), a poked resume failure painted
onto the physical screen; at loglevel 3 the same poke logged to dmesg
and tty1 stayed clean. Fix applied to SOURCE (iso.nix
`boot.consoleLogLevel = 3` + install-cli `dmesg -n 3` on a root VT),
ships round 3; the stick is frozen and the HP's loglevel was **restored
to 4** so this boot still behaves like round 2.

## Round 3 — 2026-09-08 — rehearsal PASS · console quiet at last · the health probe's FALSE POSITIVE exposed (#23 sharpened)

- **ISO:** round-3 `p5ylp6q6…`, SSH at 192.168.1.150. BIOS.
- **RAM saga:** first booted at **1833 MB** (Max had pulled a stick) —
  would have tested the #16 refusal on a BIOS machine; Max reinstalled
  RAM → **3718 MB** (round-2 level), and the real round-3 run is below.
- **Fingerprint reader (Max's priority — #29):** the dm4's reader does
  NOT enumerate (absent from lsusb / -t / PCI, no kernel trace, no
  failed-enum error). Present physically, dark to the OS — BIOS-disabled
  or dead. Reveal correctly shows no row (nothing to detect). Flagged as
  a BAD "working"-demo machine anyway: dm4 readers are old Validity VFS,
  poorly supported by libfprint — the machine that would PROVE #29's
  honesty gate, not the happy path.
- **#17b working:** `gpu = intel` (boot_vga), `gpu2 = amd` (Evergreen)
  + address. **#17a WORKING AT LAST:** loglevel 3; 7 radeon faults in
  dmesg this boot, **ZERO on the physical console** (round 2's photo
  showed them painting the screen — the whole point of #17a, delivered).
- **THE HEADLINE — health probe FALSE POSITIVE:** boot audit AND
  rehearsal reprobe both read `gpu2Health = working` for the radeon we
  PROVED failing. facts-match `ok` (no flap, falsely reassuring); reveal
  said "GPU 2 AMD/ATI Radeon HD 6370M · radeon — tested, working · apps
  can use it on demand". Proven wrong SAME BOOT: forced to a genuine
  suspended state then cold-resumed → `No VRAM object for PCIE GART` +
  `evergreen startup failed on resume`, 2 errors — the round-2
  signature exactly. The probe missed it because its poke didn't force
  a COLD resume. → changes.md #23 revised: FORCE suspend before every
  poke, not passive-wait. The HP is the machine the failing→powered-off
  path (gpu-second.nix) has still never run on from a real verdict.
- **Rehearsal:** `status: ok`, checks green — BIOS→GRUB, target≠medium,
  fit, `ok ram: 3718 MB`, facts match, **eval 43 s** (round 2: 43 s —
  consistent). Disk untouched (ext4 "root" + swap, the HP's prior Linux).
- **Verdict:** PASS on substance (install path clean, console finally
  quiet) — but the round's most important negative finding: #17c's
  health verdict is a false positive on the one lab machine with a
  genuinely dead dGPU. The reveal is confidently wrong, which is worse
  than silent. Revised probe → round 4, and the HP is its proof.
