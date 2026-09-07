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

### 17. Muxless AMD hybrid — dGPU failing/spamming, census picks the wrong GPU — [NEEDS MAX]
- **what (HP Pavilion dm4, round 2):** the kernel spams
  `radeon 0000:01:00.0: No VRAM object for PCIE GART` +
  `evergreen startup failed on resume`, repeatedly, over the installer
  console. Diagnosis: it's a MUXLESS hybrid — card0 i915 `enabled=1` drives
  the display; card1 radeon `enabled=0`, runtime `suspended`;
  vgaswitcheroo shows `IGD:+:Pwr` (Intel active) / `DIS: :DynOff` (AMD off).
  Something keeps runtime-resuming the sleeping AMD Evergreen dGPU, the
  resume fails, it re-suspends, repeat → console flood. **The display is
  fine (Intel); the machine is not broken.**
- **it corrects the reveal:** "AMD … · radeon" is bound but NOT functional
  (dGPU off, can't resume). And the census `gpu = "amd"` is the wrong
  PRIMARY here — the priority nvidia>amd>intel picks the discrete GPU, but
  the ENABLED/display GPU is the Intel iGPU. On a muxless hybrid the
  `enabled=1` card is the real primary.
- **three parts:**
  a. **[round 3, concrete]** quiet the kernel console while golem-setup
     runs (lower console loglevel / installer owns tty1) so the reveal
     isn't buried in radeon errors. They stay in dmesg/journal.
  b. **[NEEDS-MAX]** census GPU logic: on a hybrid, prefer the enabled
     display GPU (check `/sys/class/drm/card*/device/enable` +
     vgaswitcheroo) rather than always winning for the dGPU. Here → intel.
  c. **[NEEDS-MAX]** installed system: cleanly power the failing old dGPU
     OFF (stop radeon resume attempts) for no spam + battery, rather than
     treat it as usable.
- **RECOMMENDATION (pending Max's confirm — he went to bed):** option (a)
  for these old muxless AMD hybrids — **Intel drives the display, the dGPU
  is left powered off/quiet** — the reliable path, over trying PRIME
  offload to a GPU that won't even resume. Fits the broad-old-hardware
  north star (dm4-class machines are common). Console-quiet (17a) can ship
  round 3 regardless.
- **where:** `system/hardware-detect.nix` (hybrid-aware gpu pick),
  `system/hardware/` (dGPU power-off), `iso.nix`/audit (console loglevel).

### 16. Very-low-RAM machines can't run the local install eval — [NEEDS MAX]
- **what:** on ~2 GB the boot census runs (barely) but `golem-install`
  itself makes the machine unresponsive — not only the target eval, even
  the early `nix eval` (swap rule) + seed copy thrash it into a swap spiral
  (Comodore 1931 MB, round 2; Dell at 1.8 GB in round 1 same). A LOCAL
  eval/build install is not viable below ~2–3 GB.
- **why:** reinforces the closure-delivery open question (PLAN.md's biggest
  item). Options: (a) deliver a PREBUILT closure and skip local evaluation
  entirely on such machines; (b) have the installer detect very-low-RAM up
  front and either refuse with a clear message or switch to a
  no-local-eval path, rather than thrash into an unresponsive box; (c)
  accept ~2 GB as below the supported floor and say so.
- **where:** install strategy (closure delivery) + a RAM preflight in
  `install.nix` / the surface.
- **size:** NEEDS-MAX — ties into the closure-delivery decision (round 4).

### R3-1. Touchpad reveal row had no driver — [applied to source · verified on Acer · round 3]
- **what:** every reveal row reads "name · driver" except the touchpad,
  which showed only the name (Max, round 2). `hw_input` returned just the
  /proc Name; now it also reads the block's `S: Sysfs=` path and walks UP
  it to the bound kernel driver. Acer touchpad now reads
  `SYN1B81:01 06CB:2970 Touchpad · hid-multitouch`.
- **also fixed a bug in the doing:** the parse used `exit` on match, and
  awk's exit runs END with the vars still set — the SAME double-print trap
  hw_pci hit in round 1 — which corrupted `$sysfs` and hid the driver.
  Now a `found` flag, no exit.
- **where:** `mockup/install-cli` `hw_input`.

### R3-3. Encryption was too easy to enable by accident — [applied to source · verified live on Acer · round 3]
Max drove the LUKS flow (round 2) and it let a stranger walk into
irreversible data loss too easily. Made it deliberately hard, all verified
live on the Acer (`mockup/install-cli`):
- **passphrase typed twice** (`step_luks`): confirm field + mismatch retry.
  The one secret with no recovery gets the same gate as the account
  password, even though it's shown in the clear.
- **a full-screen red warning** after confirmation — "asked EVERY time …
  no recovery … lost forever" — that must be acknowledged; ESC turns
  encryption off (`luks_warn` / `luks_ack` strings).
- **state reads `LOCKED`** (was "on"), in the danger colour, on the
  Advanced row and the summary item (translated: BLOQUEADO / VERROUILLÉ /
  GESPERRT / BLOCCATO).
- **default selection returns to Back** after enabling (`seed_row=3`), so
  the person sees "— LOCKED" and one ENTER returns to the drive list.
- **disk summary reads "(Will be erased and encrypted)"** when on
  (`erased_enc` string).
- **why:** Max — "we don't want people to use encryption if they don't
  know what that is … they can lose data. so scare them." LOCKED (not
  "on") tells the truth without lying about what it costs.

### R3-2. zram row shows a confusing percentage — [applied to source · verified · round 3]
- **what:** the zram row read "150% of ram". Interpolating the real RAM
  ("150% of 3833 MB") made it WORSE, not better: the % is RAM-tiered and
  EXCEEDS 100% on small machines (1 GB → 150% → a 1.5 GiB device, which
  looks impossible until you know zram is compressed), and even "50% of
  8 GB" is misread as "am I losing half my RAM / do they only see half?".
  **Decision (Max, round 2): show no number — just `active`.** A number a
  stranger will misread is worse than no number.
- **now reads:** `zram   active, zstd, priority 100` on every machine.
- **where:** `system/hardware/decide.nix` (the ram section's zram row).


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

### 10. The driver count counted chipset bridges — [DONE · verified live on HP · round 3]
**Fixed (round-2 build):** `probe_compute` now excludes PCI bridge-class
devices (0x06xx — host/PCI/ISA bridges, QPI registers) that never bind a
driver. HP went from a misleading "23 of 31 (74%)" to an honest **"19 of
19 (100%)"** — every real peripheral driven. (The medium already carries
all firmware; see the round-2 correction below for that story.)


**CORRECTION (round-2 build, 2026-09-07).** Inspecting the round-2 squashfs
showed the medium ALREADY carried `linux-firmware` all along (the
installation-cd profile pulls it via all-hardware.nix) — 10,931 firmware
files, incl. brcmfmac blobs. So the round-1 story "the minimal medium ships
almost no firmware" was WRONG. `enableAllFirmware` in iso.nix now adds the
UNFREE firmware on top (broadcom-bt for the MacBook's BT, facetimehd, etc.,
+4.5 MB) — a real but small gain, not the hundreds of MB I expected.

Consequences to re-examine:
- The HP's "74% (23/31)" is therefore NOT simply missing firmware. The 8
  driverless devices were never enumerated (the HP dropped offline). Needs a
  real look in round 2 — some may be genuinely unhandled on the medium, some
  firmware-gated-but-now-present. The metric's "will be installed" wording is
  still misleading and #10c (fix the wording) still stands.
- The MacBook BCM4360 has NO brcmfmac firmware upstream (Broadcom never
  released it) — which is exactly why it needs `wl`. So firmware-on-medium
  does NOT light up the MacBook wifi; only `wl` does. That lives on the
  INSTALLED target (finding #5, broadcom-wifi.nix) — and since the install
  is OFFLINE, the medium never needs MacBook wifi. Optional future polish:
  add `wl` to the medium for a live-session-with-wifi UX.

**CONCRETE FIX (HP enumerated, round 2):** the HP's "23/31 (74%)" is
chipset glue, not missing support — its 8 driverless PCI devices are ALL
host bridges / PCI bridges / QPI registers (class 0x06xx), which no OS ever
binds a driver to. Fix `probe_compute` (mockup/install-cli) to EXCLUDE PCI
bridge-class devices (0x0600–0x06ff) from both numerator and denominator,
so the count reflects real peripherals. Then the HP reads ~100%. This is
the honest fix, better than rewording — round 3.

Original (round-1) framing below, kept for the record:

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

### 9. Reveal GPU row shows the iGPU, not the decided dGPU (hybrid machines) — [DONE · verified live on HP · round 3]
**Fixed (round-2 build):** `hw_pci_all` enumerates EVERY display controller,
so a hybrid shows both. HP now lists `Intel … · i915` AND `AMD/ATI Robson
CE [Radeon HD 6370M/7370M] · radeon` — matching the big red AMD sticker on
the lid, which was Max's whole point (round 2: "our installer showing only
an intel GPU"). Original diagnosis below.

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

### 8. BIOS/legacy-only machines can't boot the installed target — [DECIDED: support BIOS]
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

### 5. Broadcom Macs lose Wi-Fi after install — [DECIDED: auto-enable unfree on detection]
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
