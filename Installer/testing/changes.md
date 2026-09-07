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

### 1. Hardware reveal shows only the last PCI device — [applied to source · verified live on Acer]
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

### 2. Bluetooth row misses combo cards the census detects — [applied to source · verified live on Acer]
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

### 3. golem-setup reaches outside its closure for lspci/lsusb — [applied to source · verified live on Acer]
- **what:** add `pciutils` and `usbutils` to setup.nix `runtimeInputs`. The
  reveal + `driver_count` call `lspci`/`lsusb`, which are NOT declared;
  they resolve only from the medium's system PATH. Same class as the gawk
  bug (a tool that reaches outside its closure works until a stripped PATH).
- **why:** round 1, Acer — noticed while tracing finding 1; works today
  only by the installation-cd profile leaking the tools in.
- **where:** `setup.nix` runtimeInputs / makeWrapper `--prefix PATH`.
- **size:** small.

### 4. Progress bar stops at 83% on a rehearsal — [applied to source · verified live on Acer]
- **what:** when step_go sees `##golem rehearsed`, fill the bar to 100%
  with a "rehearsed" label before printing the outcome. Rehearse emits up
  to `5/6` (83%) then `rehearsed` (never `6/6`, which is the reboot
  trigger), so the bar currently sits at 83% and reads as stuck.
- **why:** round 1, Acer — Max: "stop at 83% … the bar has stuck at 83%."
- **where:** `mockup/install-cli` step_go, the `'##golem rehearsed'*)` arm
  (~line 2958) — call `paint_bar "$max" "$max" "<rehearsed label>"`.
- **size:** small.

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
