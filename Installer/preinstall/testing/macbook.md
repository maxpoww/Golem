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

## Round 4 (rehearsal check) — 2026-09-08 — round-4 build verified · wl closure holds · #21c fixed here too

- **ISO:** round-4 (`yz5nqhsv…`, frozen). Apple EFI (UEFI), 3858 MB.
  Audit ok. Via the USB-ethernet dongle (internal BCM4360 dark on the
  medium, as always).
- **#21c AUDIO FIXED:** row reads `Intel 8 Series HD Audio Controller ·
  snd_hda_intel` — the real PCH codec (00:1b.0). Round 3 showed
  "Haswell-ULT HD Audio Controller" (00:03.0 display audio); the Intel
  00:03-beside-00:02 rule catches it.
- **wl STILL in the target closure:** 6 broadcom store paths (broadcom-wl
  + the auth patch) — census `broadcomWifi = true` → broadcom-wifi.nix →
  wl, unchanged through the round-4 build. Wi-Fi row honestly names the
  BCM4360 · bcma-pci-bridge (present-not-functional on the medium).
- **Other round-4 fixes:** Scheduler wording, GPU verdict row, Apple
  trackpad · apple, no count line. i965 legacy decode (Haswell).
- **Rehearsal:** `status: ok`, all green, `ok ram: 3858 MB`, **eval 93 s**
  (memory-pressured — the wl-carrying closure is heavy on 3.8 GB, but it
  completed clean this time, single-threaded). **Disk SAFE:** blkid -L
  golem = none (no golem fs created), sda2 ext4 "root" (the MacBook's own
  prior Linux) intact.
- **Verdict:** PASS — the boss fight's wl path survives the round-4 build,
  audio fixed, disk safe. wl live-up proof still awaits the first REAL
  install (round 4's install phase).

## Round 5 (rehearsal check) — 2026-09-08 — #34, #31 and #33's empty-array (no-gpu2 case) all PROVEN · wl closure holds a 4th round · 0 findings

Driven from the dev box, over the Realtek USB-ethernet dongle (internal
BCM4360 still dark on the medium, as every round).

- **ISO:** round-5 stick (`GOLEM_INST`, `/dev/sdb`). Markers confirmed:
  `golem-setup` unwrapped has 1 `valid_host Golem` hit and 4
  `cancel_install` hits with the `#34` trap pair (`trap cleanup EXIT` /
  `trap cancel_install INT TERM`) at 3933–3934; `golem-postinstall-questions`
  (`n4q18b3x…`) present on the medium. Apple EFI (UEFI). `GOLEM_REHEARSE='1'`
  baked into the wrapper.
- **Boot:** DMI `MacBookAir6,2` / `Apple Inc.` confirmed. `golem-audit.service`
  finished before driving started.
- **Census:** every fact identical to every prior round — i5-4250U,
  cores=2/threads=4, ram 3858, `gpu=intel`, `intelLegacy=true` → i965,
  `firmware=uefi`, `broadcomWifi=true`, `panelDpi=126` (→ no scale row,
  correct), `hasBluetooth=true`, laptop. Nothing wrong, nothing new.
- **#34 — Ctrl-C exits, once, cleanly. PROVEN on this machine.** On the
  confirm screen: before → marker + `golem-drv.9HJtCC` +
  `golem-kb-orig.rCUXs9` present; Ctrl-C → prompt back immediately, no
  `golem-setup-unwrapped` instance, marker gone, both temp files gone.
- **#31 — F1 cancels from the language page AND the confirm screen.**
  Exercised on both (the language-page case first, live, recovering from
  a mistyped filter — a real F1 use, not a staged one): `\eOP` → prompt
  back, marker gone, temp files gone, no instance, each time.
- **#33 — the fourth bundle file is the empty array — the NO-gpu2 case,
  a new angle on this proof.** `target/postinstall-questions.json` = `[]`,
  transcript `note postinstall questions: 0 pending`. Unlike the Lenovo
  (empty array because the one dGPU is healthy), this machine has no
  `gpu2` fact at all — single GPU. Same empty result, different reason;
  the ASK framework's "nothing to ask" path now proven from two distinct
  facts-shapes.
- **#32 / #26-reveal:** not applicable — no `GPU 2` row exists to dim or
  double-count on a single-GPU machine; confirmed absent, as it should be.
- **THE WL PROOF holds a 4th round:** `nix-store -qR` on the evaluated
  toplevel drv finds 6 broadcom store paths — both `broadcom-wl` sources
  (5.100.138, 6.30.163.46), the auth-revert patch, `broadcom-sta`, and
  (new to note, always implied by `hasBluetooth` + Broadcom, not
  previously called out by name) `broadcom-bt-firmware` ×2. census
  `broadcomWifi=true` → `broadcom-wifi.nix` → wl, unchanged through five
  ISO builds now.
- **Surface (six screens):** English → America/Denver → English (US),
  default from the top of the list → drive (**only** the Apple SSD + SD
  reader + Advanced — `#20b` holds, the boot stick on `/dev/sdb` is not
  offered) → `mbp` (ghost replaced cleanly) → `max` + password ×2 →
  confirm. Rows: Zram, Swap 6 GiB, `Scheduler Bfq on hard disks, default
  on SSD/NVMe`, Thermald On, Lid, GPU (`Intel Haswell-ULT Graphics · i915
  — tested, working · driving this screen`), Wi-Fi (BCM4360 ·
  bcma-pci-bridge, present-not-functional, honest), Audio (`8 Series HD
  Audio Controller · snd_hda_intel` — the `#21c` PCH-codec fix still
  holds), Bluetooth `btusb`, Touchpad `Apple Internal Keyboard / Trackpad
  · apple`. No count line, no phantom rows.
- **Disk verified untouched, before AND after:** `lsblk` UUIDs (ESP
  `B710-0CB0`, root `9a6ac564…`, swap `a4340a48…`), `sfdisk -d`, and the
  first-4-MiB SHA256 (`90bc2174…`) all identical pre/post; no `sda`
  mounts; `/sys/block/sda/stat` **writes-completed = 0, sectors-written =
  0** for the whole session. Transcript: 17 `would` lines, 0 `run` lines.
- **Rehearsal:** `status: ok`, **no findings**, all six checks `ok`
  (UEFI → systemd-boot, target `sda` ≠ medium `sdb`, fit 232716 MiB root
  for ~19 GiB, `ok ram: 3858 MB`, facts match, **eval 97 s** →
  `nixos-system-mbp`). In line with this box's known memory-pressured
  range (round 1: 58 s cold, round 2: 94 s, round 4: 93 s) — still the
  heaviest eval in the lab, still completes clean single-threaded.
- **Console quiet (#17a):** `loglevel=3`, printk `3 4 1 7`; **0 lines at
  emerg/alert/crit**, 3 at err; nothing new since the boot audit.
- **Findings → changes.md:** none. `R5-1` (the `#28` hold-line fix,
  already applied to source on the Lenovo) was not re-exercised here —
  this run's audit had already finished before golem-setup started, so
  the race path never triggered; not a gap in this machine's coverage,
  just nothing to add to what the Lenovo already proved.
- **Verdict:** **PASS.** Every round-5 item this machine can prove is
  proven: Ctrl-C and F1 both exit clean from two different screens, the
  ASK framework's empty-array case now has a second, structurally
  different proof (no gpu2 vs. healthy gpu2), and the `wl` pipeline —
  this machine's whole reason to be in the lab — survives a fifth ISO
  unchanged. Zero writes to the Apple SSD across the whole session.
