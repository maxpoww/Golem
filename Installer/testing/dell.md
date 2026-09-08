# Dell

Dell Latitude E6420 · i5-2430M Sandy Bridge (2c/4t) · Intel HD 3000 (no
dGPU on this unit) · **boots BIOS/legacy** · **built-in keyboard dead**
(only Enter works — enough to pick Start; everything else driven over SSH).
As first seen: **1790 MB RAM, no internal disk** (USB stick + DVD-ROM
only). Reachable via the Realtek USB wifi dongle.

---

## Round 1 — 2026-09-06 — census PASS · install blocked (BIOS + no disk + RAM)

### Phase A: as-first-seen (1790 MB, no disk, BIOS)

- **ISO:** round-1 (`kizf3l8…`); cores fix confirmed (`cores = 2`).
- **Census — correct:** i5-2430M, cores=2/threads=4, **`intelLegacy =
  true` → `video decode = i965`** (2nd legacy machine on metal, correct —
  Sandy Bridge HD 3000, same reason as the MacBook). bluetooth true,
  laptop. **No `panelDpi`** in the facts — the probe found no readable eDP
  panel here, so no scale decision (correctly dropped, not printed empty).
- **Three install blockers, each a deliberate lab catch:**
  1. **BIOS/legacy boot** — the first non-UEFI machine. The install target
     is systemd-boot (UEFI-only). Confirmed directly: `/sys/firmware/efi`
     absent. The rehearsal's UEFI preflight check therefore **FAILS**
     ("this machine booted BIOS/legacy — the target's systemd-boot cannot
     boot here") — its first real catch on metal. → changes.md #8.
  2. **No internal disk** — only the USB medium (`sda`) and DVD (`sr0`).
     Nothing to install to; the only block device is the medium itself, so
     the target≠medium and disk-fit checks also fail. A real fail-early
     case.
  3. **1790 MB RAM** — the lab's lowest, below Golem's memory tuning floor
     (tiers start ~4 GB). The `nix eval` of the target thrashed so hard the
     machine swapped past 5 minutes and starved SSH — it could not
     complete. Reinforces the closure-delivery open question (PLAN.md): a
     sub-2 GB machine cannot self-build/eval an 18.8 GB closure; it needs a
     prebuilt closure, not a local build.
- **Keyboard:** built-in `AT Translated Set 2 keyboard` is dead (hardware
  fault) — a real "a stranger could not complete the keyboard step on this
  machine" data point, and a clean validation of the SSH-driven lab method
  (Enter alone reached Start; the dev box did the rest).
- **Phase A verdict:** census PASS; install correctly impossible here as-is,
  for three independent reasons the rehearsal's preflight is built to name.

### Phase B: RAM + disk added (Max, 2026-09-06) — pending

Max added ~2 GB RAM (→ **3799 MB**) and an internal disk — a 465.8 GB
Hitachi (`sdb`, holding xfs + ext4 "home" from a prior system; guarded
throughout). Could NOT switch to UEFI (dead keyboard can't reach the
firmware menu), so it stays **BIOS** — which gives us the clean result: the
UEFI-check catch WITH a completed eval and a real target.

**Full rehearsal, driven over SSH (dead keyboard, so 100% remote):**

- Six screens walked language(en) → tz(America/Denver, a US zone so the
  keyboard defaulted **English (US)** — no Spanish residue) → keyboard →
  disk(Hitachi `sdb`) → you → confirm. Hostname `dell` typed clean (ghost
  fix).
- **Reveal (fixed golem-setup, `nix copy` overlay):** GPU `Intel 2nd Gen
  Core (HD 3000) · i915`, Audio `Intel 6 Series/C200 HD Audio ·
  snd_hda_intel`, Bluetooth `DW375 Bluetooth Module · btusb`. No Wi-Fi row
  (its wifi is the *USB* Realtek dongle — not PCI — and no internal PCI
  wifi card present) and no touchpad (the E6420's didn't enumerate,
  consistent with its keyboard fault). **24 of 26 (92%)** drivers — honest
  count. Reveal fix verified on a THIRD machine.
- **Rehearsal outcome — the headline:** `status: findings: 1`, bar
  completed to **100% "Rehearsed"** (fix #4 handles the has-findings case),
  surface said "rehearsed — nothing was written, 1 finding". checks.txt:
  - **`FAIL firmware: this machine booted BIOS/legacy — the target's
    systemd-boot cannot boot here`** — the UEFI preflight's **first real
    catch on metal**, the entire reason that check exists.
  - `ok` target `sdb` ≠ medium `sda` · `ok` fit (470 GB root) · `ok` facts
    match boot audit · `ok` **eval instantiates in 171 s** → `nixos-system-dell`.
  - eval 171 s vs Acer 31 s / MacBook 58 s: Sandy Bridge + a 5400 rpm
    Hitachi is slow, but on 3.8 GB it COMPLETES — where 1.8 GB thrashed
    forever. So Golem's practical eval floor sits above 1.8 GB and at/below
    ~3.8 GB.
  - **`sdb` byte-identical before and after** (xfs + ext4 "home") — the
    prior system's data is safe.
- **Phase B verdict:** the rehearsal works end to end on the Dell, the
  reveal fix holds on a third machine, and the BIOS blocker is caught
  cleanly (→ changes.md #8, needs-Max). Census + rehearsal PASS; install
  correctly gated on the firmware decision.

## Round 2 — 2026-09-07 — BIOS/GRUB branch PASS (2nd machine) · 0 findings · machine pathologies documented

- **ISO:** round-2 (markers: `firmware = "bios"` fact present, hostname
  fix in the unwrapped script, cores = 2). Fresh boot of the frozen stick.
- **Boot:** BIOS · attract screen drew correct (Max's photo) · on the LAN
  via the USB Realtek dongle at 192.168.1.109 (mDNS not needed; IP sweep).
- **RAM upgraded again (Max):** now **5809 MB** (round 1 phase B was
  3799). Census sees it in full.
- **Census — correct:** i5-2430M, cores=2/threads=4, `gpu = intel` +
  `intelLegacy = true` → i965 (right for Sandy Bridge HD 3000),
  **`firmware = "bios"`** (new fact, correct), bluetooth, laptop, swap
  8 GiB for hibernation. No panelDpi (same as round 1, correctly absent).
- **Machine pathologies, diagnosed over SSH (NOT Golem bugs — rig/metal):**
  1. **mei/ME dead** — the photo's error: `mei mei0: init clients timeout
     hbm_state = 4` → `reached maximal consecutive resets: disabling the
     device` (fw status `1E000042`). The ME firmware never comes up; the
     driver retries 3× over ~60 s then disables it. **Self-limiting (7
     lines total), harmless** — mei only serves AMT/management. Relevance:
     the 2 `err`-priority lines PAINT on tty1 at the medium's loglevel 4 —
     a second on-metal instance of the #17a console-spam class, different
     driver. `err` = level 3 → `consoleLogLevel = 3` suppresses it. Noted
     on #17a.
  2. **ACPI EC query storm** — load average ~65 on an idle box. The EC's
     GPE 0x10 fires ~27/s (17,944 of 17,981 SCIs at the 11-min mark), each
     queues a `kec_query` work item the EC never answers → **64 kworkers
     blocked in D state** (stable, capped — not growing; re-checked after
     the rehearsal). CPU idle, SSH fine, rehearsal unaffected. A wedged EC
     is also a plausible root cause for this machine's **dead built-in
     keyboard** (it routes through the EC) — round 1 called that a plain
     hardware fault; EC pathology now looks likelier.
  3. **RTC ~10.7 years slow (CMOS battery likely dead):** the audit file
     is stamped `Generated … 2016-01-04` (census ran pre-NTP); after NTP
     jumped the clock, `uptime` claimed "3898 days" — which is exactly
     Jan 2016 → Sep 2026. Harmless here (offline rehearsal; NTP fixes it
     online). Worth remembering when reading timestamps off this box.
- **Reveal — round-1 record CORRECTED:** the confirm screen now shows
  **`Touchpad AlpsPS/2 ALPS GlidePoint`**. Round 1 said "no touchpad —
  didn't enumerate, consistent with keyboard fault": wrong diagnosis. It's
  a vendor-named ALPS pad (same name as the Comodore's) that round 1's
  `ouchpad|rackpad` pattern couldn't match — fix #14, now verified on a
  SECOND ALPS machine. Also new vs round 1: **Ethernet row** `Intel 82579LM
  · e1000e` (fix #15, second machine). GPU `2nd Gen Core … · i915`, Audio
  `6 Series/C200 … · snd_hda_intel`, Bluetooth `DW375 · btusb`, no Wi-Fi
  row (wifi is the USB dongle, not PCI — correct). **24 of 26 (92%)** —
  same metric as round 1; the bridge-exclusion honesty fix (#10) is
  round 3. Observations, not queued: the full lspci names on Audio/
  Ethernet rows are long (the #17 shorten-names note covers GPU rows
  only); the boot stick itself is offered in the drive list ("USB 2.0 FD
  14.4G") — **NOT by design** (corrected at round-3 close): the filter
  chased `/`, which on the medium is a tmpfs, so it excluded nothing.
  → changes.md #20, fixed for round 3 (resolve the medium via /iso).
- **Six screens over SSH (dead keyboard, 100% remote):** en →
  America/Denver → English (US) → Hitachi → dell/max/password ×2 →
  confirm. Ghost fix held (`› dell`). Decision rows as expected (zram
  still "150% of ram" on this frozen stick — R3-2 is round 3).
- **Rehearsal:** `status: ok`, **0 findings** — round 1's BIOS FAIL is
  now the GRUB path: checks.txt **`ok firmware: booted BIOS/legacy — GRUB
  to /dev/sdb (BIOS-boot partition)`**, target sdb ≠ medium sda, fit
  (468747 MiB root), facts match, **eval 170 s** →
  `nixos-system-dell`. Same 170 s as round 1's 171 s despite 5.8 GB vs
  3.8 GB — the eval is CPU+disk-bound here, more RAM doesn't move it
  (floor findings in #16 unchanged). Transcript: exact GPT+BIOS-boot
  layout (sgdisk 1 MiB ef02 "bios", 8 GiB swap, root — no ESP, no
  /mnt/boot). machine.nix: `boot.loader.grub.device = "/dev/disk/by-id/
  ata-Hitachi_HTS545050A7E380_TE85113Q2GEBUR"` (by-id, stable), en_US,
  America/Denver, us/pc104. Synthesized hardware-config: by-label root +
  swap, no /boot filesystem. Bar to **100% "Rehearsed"**.
- **Disk verified untouched:** `sdb` xfs `492cfb55…` + ext4 "home"
  `bd0c3e05…` — identical layout and UUIDs before and after.
- **Findings → changes.md:** no new entries. #17a gains a second on-metal
  instance (mei, this machine); #14 gains a second ALPS verification +
  the round-1 correction.
- **Verdict:** PASS — the BIOS/GRUB branch is proven on a second machine
  with 0 findings, on a box whose ME is dead, whose EC is storming, and
  whose RTC is a decade off. Golem didn't blink.

## Round 3 — 2026-09-08 — PASS · 0 findings · the mei console spam silenced

- **ISO:** round-3 `p5ylp6q6…`. Driven 100% over SSH (dead keyboard) at
  192.168.1.109. BIOS.
- **Census:** i5-2430M, ramMB 5809, gpu=intel (single, no gpu2 phantom),
  intelLegacy=true, BIOS. Consistent with round 2.
- **#17a — the mei spam is gone:** round 2's photo showed the dead ME's
  `mei mei0: … timeout` / `disabling the device` painting the attract
  screen. Round 3: 7 mei reset lines in dmesg, **ZERO on the physical
  console** (loglevel 3). The other-driver case of #17a, confirmed on a
  third machine (radeon/HP, nouveau/ASUS, mei/Dell — all quiet now).
- **Reveal:** GPU verdict row `Intel 2nd Generation Core Processor
  Family Graphics · i915 — tested, working · driving this screen`
  (gpu_short clean), GlidePoint `· psmouse` (#14 + R3-1), Ethernet row
  `82579LM · e1000e` (#15), Audio CORRECT (chipset HDA at 00:1b.0, no
  GPU-HDMI sibling to mis-pick), Bluetooth DW375, no Wi-Fi row (USB
  dongle, not PCI — right). 19 of 20 (95%) — the count line's last lab
  appearance (removed at source, #27).
- **Rehearsal:** `status: ok`, all checks green — BIOS→GRUB to sdb,
  target≠medium, fit, `ok ram: 5809 MB`, facts match, **eval 171 s**
  (round 2: 171 s — identical; Sandy Bridge + 5400rpm Hitachi is the
  lab's slowest eval, but it COMPLETES). Disk untouched: sdb xfs
  `492cfb55…` + ext4 "home" `bd0c3e05…`, same UUIDs.
- **Verdict:** PASS, 0 findings — the BIOS/GRUB branch and the console
  quiet both hold; the machine whose ME is dead, EC storms, and RTC is
  a decade off still sails through.
