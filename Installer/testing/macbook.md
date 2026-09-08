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

## Round 2 — 2026-09-07 — PASS · the Broadcom delivery proven at rehearsal level

The boss fight's round: the round-2 build carries #5 (auto-enable unfree
`wl` on detection), and this machine is what it was built for.

- **ISO:** round-2 (frozen; `firmware` fact present, `S[es:drv_line]` on
  the stick). Boot: Apple EFI, on HOLA via the Realtek dongle at
  192.168.1.109 (same lease as round 1).
- **Census:** all round-1 facts intact (i5-4250U, cores=2/threads=4, ram
  3858, gpu intel, intelLegacy=true, panelDpi 126, hasBluetooth, laptop)
  plus the two round-2 facts: **`firmware = "uefi"`** (Apple EFI read
  correctly) and **`broadcomWifi = true`** — the BCM4360 detected, first
  time on metal. The fact this machine joined the lab to earn.
- **Surface (frozen round-2 golem-setup, English run):** full reveal —
  GPU `Haswell-ULT · i915`, Wi-Fi `BCM4360 · bcma-pci-bridge` (named;
  bridge driver on the medium, expected), Audio `· snd_hda_intel`,
  Bluetooth `· btusb`, Touchpad `Apple Internal Keyboard / Trackpad`. No
  Ethernet row (no PCI ethernet — correct). **31 of 33 (93%)** (bridge
  exclusion ships round 3). `Device mbp` typed clean over the ghost.
- **Rehearsal:** `status ok`, **0 findings**, bar to 100%. checks.txt
  5/5 green — **`ok firmware: booted UEFI — systemd-boot to the ESP`**
  (Apple EFI walks the UEFI path), target `sda` ≠ medium `sdb`, fit
  (232716 MiB), facts match, **eval 94 s** → `nixos-system-mbp` (round 1:
  58 s — cold store on a fresh boot; noted, not chased).
- **The Broadcom delivery, proven end to end at rehearsal level:**
  1. census fact `broadcomWifi = true` →
  2. target `golem-hardware.nix:14` carries it →
  3. `system/hardware/broadcom-wifi.nix` consumes it (extraModulePackages
     broadcom_sta, kernelModules wl, allowInsecurePredicate scoped to
     broadcom-sta by name) →
  4. **the toplevel drv's requisite closure contains
     `broadcom-wl-5.100.138` / `6.30.163.46` sources + the auth patch** —
     wl is genuinely inside the evaluated system, not just a flag.
  The live proof (wifi up, no dongle, on the installed system) lands at
  round 4's first real install.
- **Medium-side question in broadcom-wifi.nix's comment CLOSED on metal:**
  "does brcmfmac+firmware alone light up the MacBook?" — **No.** Only
  `lo` + the dongle's `wlp0s20u2` exist; brcmfmac is not even loaded
  (bcma holds the card as a bus device). Confirms the round-2 correction
  (no BCM4360 firmware upstream); the comment's "brcmfmac … incl. the
  BCM4360" is wrong → comment fix queued (changes.md #5 note).
- **Disk untouched:** Apple SSD ESP `B710-0CB0` + ext4 "root"
  `9a6ac564…` + swap `a4340a48…` — identical before and after; the
  existing NixOS install is safe.
- **Findings → changes.md:** only the broadcom-wifi.nix comment
  correction (cosmetic, #5 note). Nothing blocking.
- **Verdict:** PASS. The round-2 ISO on Apple EFI rehearses clean, and
  the Broadcom pipeline — detect → fact → target config → wl in the
  closure — is proven as far as a rehearsal can prove it.

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

## Round 3 — 2026-09-08 — PASS · wl re-proven on round-3 metal · the #19b trap earned its keep

- **ISO:** round-3 `p5ylp6q6…`, SSH at 192.168.1.109 (via the Realtek
  USB-ethernet dongle — internal BCM4360 is bcma-pci-bridge on the
  medium, the machine's whole reason to be here).
- **Audit ok.** Census: MacBookAir6,2, gpu=intel, intelLegacy=true →
  `video decode: i965` (Haswell HD5000 — matches the Dell/Comodore
  legacy path), **`broadcomWifi = true`**, UEFI (Apple EFI). No gpu2
  (single GPU) — the boot_vga census correctly finds one.
- **THE WL PROOF holds on round 3:** the target closure carries the
  unfree broadcom-wl (6 broadcom store paths incl.
  broadcom-wl-5.100.138 + the auth patch) — census fact →
  broadcom-wifi.nix → wl in the toplevel drv. Re-verified through the
  round-3 build's edits (the corrected comment, unchanged mechanism).
- **Reveal:** GPU verdict row `Intel Haswell-ULT Graphics · i915 —
  tested, working · driving this screen`, Wi-Fi names the BCM4360 ·
  bcma-pci-bridge (present-but-not-functional on the medium, honest),
  Bluetooth present, **Touchpad `Apple Internal Keyboard / Trackpad ·
  apple`** (Apple's own driver — a new touchpad name, matched by the
  round-3 two-tier logic without help). Console CLEAN (bcma noise in
  dmesg, 0 on tty1).
- **The transcript anomaly — the trap working, not a bug:** the first
  rehearsal (memory-pressured, 3.8 GB, an 84 s eval) hit a TRANSIENT
  `cp -a "$seed/hosts/target" "$logdir/target"` failure at the bundle
  step; the #19b ERR trap recorded `died line 647 (exit 1): cp …` to
  the transcript + `error:` status — EXACTLY its job, and the first
  time it has fired on real metal. A clean re-run: exit 0, status ok,
  one header, zero died lines, eval 59 s. Residue from two overlapping
  engine invocations sharing $logdir (my doing — driving + inspecting
  at once); not reproducible single-threaded. Low-severity note, not a
  finding: in production the surface serializes the engine, so the race
  cannot occur. Watch: on <4 GB metal the bundle cp can transiently
  fail under pressure — the trap catches it, but a retry-on-transient
  around the bundle copy would be belt-and-suspenders (noted, not
  queued).
- **Disk verified SAFE:** `blkid -L golem` empty (no golem fs ever
  created), /mnt unmounted, no swap active. sda2 ext4 LABEL "root" (the
  MacBook's own prior Linux) untouched.
- **Verdict:** PASS — the boss fight's wl path survives round 3, the
  console is quiet, and the one scary-looking transcript line turned
  out to be the new safety net catching a real transient exactly as
  designed.

### Round 3, follow-up — Max's physical run: the audit/installer race (2026-09-08)

Max's photo (device "Golem"/user "g" — solving the transcript's
dual-owner mystery: that "g" run was HIS, not VM residue) shows two
things, one root cause, plus a third separate one:
- **"audit incomplete — the decisions could not be shown"** + a
  **staircase-garbled census dumped over the confirm screen.** Root
  cause confirmed on the live box: the boot audit took **~60 s** (slow
  on 3.8 GB), and `golem-audit-start` prints its census to /dev/tty1 on
  completion. Auto-login + a fast start put golem-setup on screen
  BEFORE the audit finished → reveal drew "audit incomplete" (json not
  ready — #22's line, literally true here), then at ~87 s the audit's
  tty1 dump landed over the installer, staircased by raw-console \n.
  → changes.md #28.
- **"the install stopped at 83%" on the repeat run** — the eval died
  mid-way. At 3858 MB (just over the 3300 cutoff) the wl-carrying
  closure's eval is tight; a second back-to-back run exhausted
  headroom. Non-destructive (go_fail worked), disk confirmed safe.
  Note: this machine passes the RAM check but sits at the fragile edge
  — the heavy unfree closure makes its eval heavier than a plain box
  at the same RAM. Not a floor change (clean single runs complete,
  59–84 s), but the closest thing to a floor counter-example the lab
  has; watch if wl-class closures need a higher cutoff.
- **The count line** in the photo ("18 of 20 (90%)") is already
  removed at source (#27); the frozen stick still shows it.
