# Changes — the deferred queue for the next ISO

Every change the current round teaches us to make lands here, and is
applied **only when the round is done** — when the current ISO has cleared
all five laptops (see [constitution.md](constitution.md)). Nothing here is
built into an ISO mid-round; that is what keeps the five machines testing
the same Golem.

## How to use this file

- While testing round N, when a finding implies a fix, add an entry under
  **Queued for the next ISO**. Keep the raw observation in the laptop's own
  file; keep the *change* here.
- When the round closes: work the queue top to bottom, build the new ISO,
  reflash, then move the applied entries to **Applied** with the round they
  shipped in, and empty the queue for the next round.
- An entry names: **what** to change, **why** (which finding/machine),
  **where** (file:location if known), and **size** (small / medium / needs
  a decision from Max).
- **Live-fix refinement (Max, 2026-09-06):** a queued fix may be applied to
  SOURCE and `nix copy`'d onto the booted laptop as a RAM overlay to verify
  it on real hardware — the frozen ISO is not rebuilt, so the discipline
  holds. Mark such entries **[verified live on \<laptop\>]**. The source
  edit is the round-close change staged early; the ISO rebuild still
  happens once, at round close. Re-verify on each laptop's own hardware.

## Queued for the next ISO

### 1. Hardware reveal shows only the last PCI device — [applied to source · verified live on Acer + MacBook]
- **what:** rewrite `hw_pci` so it captures the FIRST device matching the
  class and strips the "busid class:" prefix. `lspci -k` has no blank lines
  between devices, so the current awk (which prints a device only at a
  blank line, else at `END`) keeps just the last PCI device — Wi-Fi — and
  drops GPU/audio. It also mis-strips the name (bus id has a colon), so
  Wi-Fi rendered as "03:00.0 Network controller: …".
- **why:** round 1, Acer — Max: "why there is not GPU, audio, etc.. only
  WIFI, and touchpad." The reveal is meant to name GPU/Wi-Fi/audio/etc.
- **where:** `mockup/install-cli` `hw_pci()` (~line 2739).
- **verified fix** (against the Acer's real `lspci -k` — GPU/Wi-Fi/audio
  all render clean, exactly one line each):
  ```awk
  hw_pci() {
    printf '%s' "$1" | awk -v want="$2" '
      /^[0-9a-f]+:[0-9a-f]+/ {
        if (matched) exit                      # first match fully captured
        if ($0 ~ want) { matched=1; line=$0
          sub(/ \(rev [0-9a-f]+\)$/,"",line)
          i=index(line,": "); out=substr(line,i+2) }
        next
      }
      matched && /Kernel driver in use:/ { out = out " \xc2\xb7 " $NF }
      END { if (matched) print out }'
  }
  ```
- **size:** small.

### 2. Bluetooth row misses combo cards the census detects — [applied to source · verified live on Acer + MacBook]
- **what:** the reveal's `hw_usb 'Bluetooth'` greps lsusb for the literal
  word "Bluetooth"; the Acer's QCA9377 BT doesn't say it, so no row — even
  though the census reports `hasBluetooth = true` (triangulated: sysfs
  class ∨ rfkill ∨ USB class e0). Align the reveal with the census: show a
  Bluetooth row when the probe says the radio is present (read
  decision.json / the same triangulation), rather than a lone lsusb grep.
- **why:** round 1, Acer — bluetooth present but absent from the reveal.
- **where:** `mockup/install-cli` `hw_usb`/`hardware_reveal` (~2732, 2748).
- **size:** small–medium (decide the source of truth: reuse the probe's
  bluetooth verdict).

### 3. golem-setup reaches outside its closure for lspci/lsusb — [applied to source · verified live on Acer + MacBook]
- **what:** add `pciutils` and `usbutils` to setup.nix `runtimeInputs`. The
  reveal + `driver_count` call `lspci`/`lsusb`, which are NOT declared;
  they resolve only from the medium's system PATH. Same class as the gawk
  bug (a tool that reaches outside its closure works until a stripped PATH).
- **why:** round 1, Acer — noticed while tracing finding 1; works today
  only by the installation-cd profile leaking the tools in.
- **where:** `setup.nix` runtimeInputs / makeWrapper `--prefix PATH`.
- **size:** small.

### 4. Progress bar stops at 83% on a rehearsal — [applied to source · verified live on Acer + MacBook]
- **what:** when step_go sees `##golem rehearsed`, fill the bar to 100%
  with a "rehearsed" label before printing the outcome. Rehearse emits up
  to `5/6` (83%) then `rehearsed` (never `6/6`, which is the reboot
  trigger), so the bar currently sits at 83% and reads as stuck.
- **why:** round 1, Acer — Max: "stop at 83% … the bar has stuck at 83%."
- **where:** `mockup/install-cli` step_go, the `'##golem rehearsed'*)` arm
  (~line 2958) — call `paint_bar "$max" "$max" "<rehearsed label>"`.
- **size:** small.

### 6. Medium's console keymap is implicit (English by accident) — [small]
- **what:** pin `console.keyMap = lib.mkDefault "us"` on the MiniGolem ISO
  (iso.nix). Today the fresh-boot tty is English only because it's the
  kernel default — `systemd-vconsole-setup` logs "Configuration of first
  virtual console was skipped", so `KEYMAP=us` from vconsole.conf is never
  actively applied. Pinning makes English-on-fresh-boot a guarantee, not an
  accident. Also investigate WHY vconsole-setup skips, so the pin takes.
- **why:** round 1, MacBook+Acer — chasing a reported "Spanish tty on fresh
  boot". PROVEN NOT an ISO bug: the fresh default is us (keycode 39 =
  semicolon on a freshly booted machine); the Spanish was `loadkeys es`
  residue from golem-setup runs that picked Español (Madrid timezone → ES →
  Spanish). `loadkeys es` globally → keycode 39 = ñ; `loadkeys us` restores.
  This item is hardening, not a fix for a live bug.
- **where:** `iso.nix` — add `console.keyMap`. Possibly `console.earlySetup`.
- **size:** small.

### 7. golem-setup leaves the global console keymap changed — [needs-Max, minor]
- **what:** the keyboard step runs `loadkeys "$KB_CONSOLE"` globally
  (install-cli:2050) so the live echo box reflects the chosen map — correct
  DURING setup, but it persists to the bare tty after exit/back-out. Decide
  whether to restore the prior keymap when the user backs out of the step
  or quits before installing.
- **why:** round 1 — this is what made the medium look "stuck in Spanish"
  after test runs. Harmless for a real one-shot install (the machine
  reboots into the chosen keymap), so low priority.
- **where:** `mockup/install-cli` around the apply seam (~2025-2050) and
  step exit paths.
- **size:** needs-Max — is persisting the applied keymap desired or not?

### 10. The driver count measures the bare medium but says "will be installed" — [NEEDS MAX]
- **what:** `probe_compute` counts devices with a kernel driver bound ON
  THE RUNNING MEDIUM (`lspci -k | grep -c 'Kernel driver in use'` +
  USB with /driver), and the label says "%h of %t drivers **will be
  installed**". But the medium is minimal and ships almost no firmware, so
  firmware-gated devices (the AMD Radeon, some controllers, Broadcom wifi)
  show driverless — undercounting what the INSTALLED Golem delivers. The
  installed system sets `hardware.enableAllFirmware = true`
  (configuration.nix:414) and drives them. HP read "23 of 31 (74%)" and
  looked poorly supported when it is not.
- **twin problem, same root cause:** the MacBook's internal Broadcom wifi
  was dark on the medium for the same reason (finding #5) — no firmware on
  the minimal medium.
- **fix options (Max's call):**
  a. **Carry all-hardware firmware on MiniGolem** (like the full live ISO
     does) → the count is honest AND internal wifi works during install (no
     USB dongle). Cost: a bigger image. This also softens #5.
  b. Make the count reflect the INSTALLED target's driver coverage, not the
     medium's loaded set (harder to measure honestly from the medium).
  c. At minimum, stop the label promising "will be installed" about a
     present-tense medium measurement.
- **where:** `Installer/iso.nix` (firmware on the medium) and/or
  `mockup/install-cli` `probe_compute`/`drv_line`.
- **size:** NEEDS-MAX — image-size vs honesty tradeoff.

### 13. The rotating welcome shows boxes for non-Latin scripts on the console — [applied · option A · console-visual confirm pending]
Max chose **option A**. Applied to source: on the console (ASCII=yes) the
invitation keeps only the PURE-ASCII welcomes (tested by bytes, not a
per-language flag), so the 7 that render rotate (en/es/fr/pt/it/id + the
romanized hi) and CJK/Arabic/Cyrillic/accented lines are dropped;
off-console the full native set still rotates. Verified via `--dump invite`
(console = ASCII-only, endonym = native scripts present). Still wants a
LOOK at the physical console to confirm no boxes — can't be seen over SSH.
**Also (Max): rotation beat 5s → 4s** (`SECONDS_PER`), so `./mockup/install-cli
--fake-disks` shows the faster beat.

### 14. Touchpad reveal missed vendor-named pads (ALPS GlidePoint) — [applied · verified live on Comodore]
- **what:** `hw_input`'s pattern was `ouchpad|rackpad`; the Comodore's pad
  is `AlpsPS/2 ALPS GlidePoint` — no "touchpad"/"trackpad" in the name, so
  no row. Broadened to `[Tt]ouch[Pp]ad|[Tt]rackpad|GlidePoint|Synaptics|
  ALPS|Elan|Cypress`. A capability probe (input device with ABS axes +
  BTN_TOOL_FINGER) would be fully robust — noted, not done.
- **verified:** the Comodore reveal now shows `Touchpad AlpsPS/2 ALPS
  GlidePoint`.
- **where:** `mockup/install-cli` `hardware_reveal` touchpad row.

### 15. Reveal showed no networking on a wired-only machine — [applied · verified live on Comodore]
- **what:** `hardware_reveal` only queried the Wi-Fi PCI class (`Network
  controller`), so a machine with only wired Ethernet (Comodore: Marvell
  88E8055) showed no network at all. Added an Ethernet row (`hw_pci
  'Ethernet controller'`). Machines with both now show Wi-Fi AND Ethernet.
- **verified:** the Comodore reveal now shows `Ethernet Marvell … 88E8055 ·
  sky2`.
- **where:** `mockup/install-cli` `hardware_reveal` (+ the fake block).

### 12. intelLegacy misclassifies ancient GMA GPUs (0x2xxx) as iHD-capable — [medium]
- **what:** the probe decides `intelLegacy` with `device-id < 0x1600 →
  legacy (i965)`, else iHD. That holds from Ironlake through Skylake, but
  the pre-Ironlake GMA parts have numerically HIGH ids (GM45 GMA 4500 =
  0x2a42) despite being the OLDEST — so they fall above the threshold and
  are wrongly marked iHD-capable. iHD supports Broadwell+ only; a Gen4 GMA
  gets NO hardware video decode from iHD (needs i965, or accept none).
  Fix: extend the legacy condition to cover the old GMA ranges (roughly
  0x2500–0x2fff, the Gen4/GMA 4500 family), or replace the single threshold
  with a generation lookup. Display is unaffected (kernel i915 handles
  GMA 4500), so this is decode-quality, not a black-screen risk.
- **why:** round 1, Comodore — `8086:2a42` GMA 4500 read as `intelLegacy =
  false → iHD`.
- **where:** `system/hardware-detect.nix` — the `intel_legacy` test
  (~line 92, `(( dev < 0x1600 ))`).
- **size:** medium — needs the right GMA id ranges; keep a fixture (the
  Comodore's facts) so CI covers it.

### 11. `video decode: none` reported for AMD/nvidia — [small]
- **what:** decide.nix's GPU "video decode" row only knows the Intel VA-API
  driver names (i965/iHD) and prints "none" for AMD/nvidia — even though
  `gpu="amd"` enables the AMD VA-API (hardware.nix:62). A reporting gap, not
  a missing feature. Surface the AMD/nvidia VA-API in the census instead of
  "none".
- **why:** round 1, HP — `gpu="amd"` showed `video decode: none`,
  reinforcing the "AMD unsupported" misimpression.
- **where:** `system/hardware/decide.nix` (the gpu section's video-decode row).
- **size:** small.

### 9. Reveal GPU row shows the iGPU, not the decided dGPU (hybrid machines) — [small-medium]
- **what:** on a switchable-graphics laptop, `hw_pci 'VGA|3D|Display'`
  returns the FIRST VGA controller — the Intel iGPU — so the reveal says
  "GPU: Intel · i915" while the census DECISION is about the discrete GPU
  (AMD/nvidia) and installs its driver. The screen and the decision
  disagree. Fix: for the GPU row, enumerate ALL display controllers (show
  both on a hybrid), or prefer the discrete one to match the census
  priority (nvidia > amd > intel). Showing both is the honest option — a
  hybrid laptop has two.
- **why:** round 1, HP Pavilion dm4 — `gpu = "amd"` (Radeon HD 6370M) but
  reveal named the Intel iGPU.
- **where:** `mockup/install-cli` `hardware_reveal`/`hw_pci` (GPU row).
- **size:** small–medium (hw_pci returns one device by contract; showing
  all GPUs means iterating matches for that row).

### 8. BIOS/legacy-only machines can't boot the installed target — [NEEDS MAX]
- **what:** the target installs systemd-boot, which is UEFI-only. A machine
  that can only boot BIOS/legacy (or is set to legacy) takes the install and
  then can't boot it. The rehearsal's UEFI preflight already REFUSES this
  cleanly (good) — the open question is whether Golem should SUPPORT such
  machines (a GRUB-BIOS bootloader path on the target, chosen by a firmware
  fact) or stay UEFI-only and rely on the refusal + telling the user to
  enable UEFI in their firmware.
- **why:** round 1 — Dell E6420, HP Pavilion dm4, AND the Comodore all
  booted BIOS: **3 of the 5 lab machines**. Legacy boot is the MAJORITY
  among old laptops, not an edge case. Some can likely do UEFI via a
  firmware setting (so part of the answer may be "tell the user"), but 3/5
  means Golem needs a real position on BIOS boot, not just a refusal.
- **where:** target bootloader (`system/configuration.nix` boot.loader) +
  possibly a firmware fact in the census; the refusal already lives in
  `install.nix` preflight.
- **size:** NEEDS-MAX — support-scope decision (UEFI-only vs BIOS fallback).

### 5. Broadcom Macs lose Wi-Fi after install — [NEEDS MAX]
- **what:** the installed Golem on a Broadcom-wifi Mac comes up with no
  working internal wifi. The BCM4360 needs the UNFREE `broadcom-sta` (`wl`)
  kernel module; `nixos-generate-config` never emits it, the census has no
  wifi-chipset fact, and nothing tells the target to enable it. On the
  medium the card binds `bcma-pci-bridge` (a bus bridge, not functional
  wifi) — the reveal names it but it does not work, hence the lab's USB
  dongle. This is the MacBook's whole reason to be in the lab.
- **why:** round 1, MacBook — installed target's hardware-config carries no
  Broadcom module; census has no wifi fact.
- **where:** census (`system/hardware-detect.nix` — a wifi/broadcom fact)
  + target (`system/hardware/` — enable `boot.extraModulePackages` /
  `broadcom_sta` on that fact). PLAN.md already notes
  `system/hardware-runtime.nix` carries the `wl` quirk for the LIVE
  session; the open question is the INSTALLED system.
- **size:** NEEDS-MAX — turns on an **unfree** driver (broadcom-sta), which
  is a distro policy call (allowUnfree, and whether to auto-enable on
  detection or ask). Also: which Broadcom chips get it. Not a mechanical
  fix; Max decides scope before it's built.

<!--
Entry template:

### <short title>
- **what:** …
- **why:** … (round N, surfaced on <laptop(s)>)
- **where:** `path/to/file.nix:line` (if known)
- **size:** small | medium | needs-Max
-->

## Applied

- **Round 0 → Round 1 (2026-09-06, pre-constitution):** sysfs cores fix
  (`system/hardware-detect.nix` — dropped the awk dependency the boot
  audit's clean PATH stripped) and the hostname ghost-placeholder fix
  (`mockup/install-cli` — typing no longer appends to the "Golem"
  default). Both surfaced by the Acer's first rehearsal and baked into the
  round-1 ISO before the queue discipline began.
