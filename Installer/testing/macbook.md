# MacBook

MacBook Air (2013, i5-4250U Haswell, HD 5000, **Broadcom BCM4360** wifi +
BCM2046 Bluetooth, Apple SSD 234 G, ~3858 MB) · boots **Apple EFI**. The
lab's boss fight (Broadcom wifi). Its Apple SSD holds an existing **NixOS**
install (ESP + ext4 "root" + swap) — not macOS; guarded the same way.

Lab connectivity: a **Realtek USB WiFi dongle** (`rtw88_8821au`) — the
internal Broadcom card is dark on the minimal medium (no `wl`), so the
dongle bridges it onto HOLA. (One battery-death mid-test, unrelated to
Golem.)

---

## Round 1 — 2026-09-06 — mechanics PASS · reveal fix verified · 1 census finding

- **ISO:** round-1 (`kizf3l8…`); cores fix confirmed (`cores = 2`).
- **Boot:** Apple EFI (UEFI). Reachable at 192.168.1.109 via the Realtek
  dongle.
- **Census — every fact right, and the headline win:**
  - i5-4250U Haswell, cores=2/threads=4, ram 3858, panel 126 DPI,
    bluetooth true, laptop.
  - **`intelLegacy = true` → `video decode = i965`** — the FIRST
    intelLegacy machine on real metal, and the decision is correct: a 2013
    HD 5000 gets the legacy VA-API driver, not iHD (which would CPU-decode
    and cook the chip). This is the exact case that fact was built for,
    proven on the metal at last.

- **Baseline reveal (frozen ISO):** the hw_pci bug manifested harder than
  on the Acer — **all three PCI rows (GPU, Wi-Fi, audio) dropped**, only
  Bluetooth (USB, via lsusb-grep which happens to match Apple's "BCM2046
  Bluetooth") and Touchpad survived. Driver count **31 of 33 (93%)** — the
  honest count doing its job (the Broadcom card is one of the unhandled).

- **Live-fix (nix copy overlay, ISO frozen):** re-ran the fixed
  `golem-setup`. Reveal now complete, and it stress-tested the parser on
  hardware the Acer couldn't:
  - GPU: `Intel … Haswell-ULT Integrated Graphics · i915`
  - Wi-Fi: `Broadcom … BCM4360 802.11ac … · bcma-pci-bridge` (the internal
    card, correctly captured — see the finding on what its driver means)
  - Audio: `Intel … Haswell-ULT HD Audio · snd_hda_intel`
  - Bluetooth: `Bluetooth USB Host Controller · btusb` (the hci-class
    detection gives a cleaner name than the baseline's ugly hub string)
  - Touchpad: `Apple … Internal Keyboard / Trackpad`
  - **Bar completes to 100% "Rehearsed"** (fix #4 on Apple hardware).
  - Rehearsal `status ok`, 5/5 checks (eval 58 s → `nixos-system-mbp`),
    **Apple SSD NixOS install byte-identical before and after** — safe.

- **FINDING (census, boss-fight) — an installed Golem here would have NO
  internal Wi-Fi.** The Broadcom BCM4360 needs the unfree `broadcom-sta`
  (`wl`) module; `nixos-generate-config` never adds it, and the census has
  **no wifi-chipset fact**, so nothing tells the installed target to enable
  it. The rehearsal's target `hardware-configuration.nix` carries only
  generic modules — no Broadcom. On the medium the card binds
  `bcma-pci-bridge` (a bus bridge, not functional wifi), which is why the
  reveal can name it but it does not work, and why the lab needs the USB
  dongle. **This is the MacBook's reason to exist in the lab** (PLAN.md:
  "bringing the MacBook's wifi up natively becomes a measured census win").
  → changes.md, needs-Max (unfree-driver policy + a wifi fact).

- **Findings → changes.md:** the Broadcom-wl census/target gap (needs-Max).
  The reveal + bar fixes (already queued from the Acer) are **re-verified
  here** on Broadcom/Haswell/Apple hardware.
- **Verdict:** mechanics PASS, reveal fix holds on a second, very different
  machine, census right (incl. the intelLegacy win), disk safe. The one new
  finding is about the INSTALLED system's wifi, not the rehearsal — it lands
  when the MacBook reaches the "installed, first boot" box.

### The "Spanish tty" ghost, traced (2026-09-06)

Max reported the fresh-boot tty was Spanish, on both this machine and the
Acer. **Not an ISO bug — proven.** On the freshly-booted MacBook, tty1
keycode 39 = `semicolon` (US). `loadkeys es` (what golem-setup runs
globally at install-cli:2050 on a Spanish pick) flips keycode 39 to `ñ`;
`loadkeys us` restores it. The census-driven test drives picked
Madrid→Español on BOTH machines, so `loadkeys es` ran on both and the
Spanish map persisted to the bare tty until reboot — that was the `ñ`. The
fresh default is English. Hardening queued anyway (pin `console.keyMap`);
golem-setup's keymap persistence noted as a minor UX call. See changes.md
#6, #7.
