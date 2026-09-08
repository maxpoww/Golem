# Acer

Acer Aspire E5-573 · i5-5200U Broadwell (2c/4t) · HD 5500 · QCA9377
wifi+BT · 1 TB WDC WD10JPVX (5400 rpm) · ~3833 MB RAM · boots **UEFI**.
The lab's first and lowest-weirdness machine; baseline census in
`../PLAN.md` row 1.

---

## Round 1 — 2026-09-06 — mechanics PASS · 2 surface findings

Rehearsal mechanics and the census pass clean; the reveal SCREEN has two
findings (both queued in changes.md, neither touches the disk or the
decision). Max drove his own run and caught what my automated drive
skimmed past — the "no findings" I first wrote here was premature.

- **ISO:** round-1 (`kizf3l8…-golem-installer.iso`); carries rehearsal
  mode + the sysfs cores fix + the hostname ghost fix + HOLA auto-join.
  Confirmed on the machine: wrapper `GOLEM_REHEARSE='1'`, ghost fix in the
  script, boot audit `cores = 2`.
- **Boot:** UEFI. Joined HOLA on its own (reachable at 192.168.1.99 with no
  nmcli step) — the auto-join works on metal. Menu not re-checked this
  round (booted by Max); styling was verified 2026-09-05.
- **Census:** `status ok`, boot audit at 23:33 UTC. Every fact correct
  against the metal:
  - `cores = 2, threads = 4` — **the round-0 fix, proven on the machine
    that exposed the bug** (was reporting 4 under the boot audit's clean
    PATH; sysfs count is right).
  - i5-5200U · intel · `intelLegacy = false` (Broadwell → iHD) · ram 3833 ·
    `panelDpi 102` · bluetooth true · chassis laptop. All as PLAN.md row 1.
- **Surface (six screens):** walked language(en) → timezone(Madrid) →
  keyboard → disk → you → confirm.
  - **Hostname ghost fix, proven on metal:** typed `acer`, field showed
    clean `acer` (not `Golemacer`); confirm read `Device acer`.
  - Keyboard defaulted to **Español** — correct, not a bug: timezone
    Madrid → country ES → Spanish layout (the intentional
    tz→country→keyboard mapping). Language was English.
  - **FINDING 1 — the hardware reveal only shows Wi-Fi + Touchpad.** It
    should show GPU, audio, Bluetooth too ("23 of 23 drivers" but only two
    named). Root cause: `hardware_reveal`'s `hw_pci` (mockup/install-cli
    ~2739) parses `lspci -k` assuming blank lines between devices — there
    are none — so only the LAST PCI device (Wi-Fi) survives to the `END`
    rule; GPU/audio (earlier) are dropped. Its name-strip also fails on the
    bus-id colon, which is why Wi-Fi rendered as "03:00.0 Network
    controller: …". Verified a corrected parser against the Acer's real
    dump — it yields GPU (HD 5500 · i915), Wi-Fi (QCA9377 · ath10k_pci),
    audio (· snd_hda_intel), all clean. Bluetooth is a second gap: the
    census says present (triangulated) but `hw_usb` greps lsusb for the
    literal "Bluetooth" and this combo card doesn't say that word.
    → changes.md.
  - Also noted: `golem-setup` finds `lspci`/`lsusb` only from the system
    PATH — pciutils/usbutils are NOT in its own runtimeInputs (setup.nix).
    Same class as the gawk bug; works here only because the medium's
    profile leaks them in. → changes.md.
- **Rehearsal:** `status ok`, **0 install findings**. checks.txt, all five green:
  - firmware UEFI · target ≠ medium (`/dev/sda` vs `/dev/sdb`) · fit
    (947 GB root vs ~19 GB closure) · **facts match the boot audit fact
    for fact** (last round this WARNED on cores 4≠2; the sysfs fix closed
    it) · eval instantiates in **31 s** → `nixos-system-acer`.
  - `machine.nix`: `hostName = "acer"`, locale en_US.UTF-8, tz Europe/Madrid,
    keyboard `es`/console `es` — all as answered.
  - **Disk untouched:** `/dev/sda` still factory NTFS (ESP · MSR · NTFS
    "Acer" 930 G · NTFS recovery) before AND after — verified on both my
    drive and Max's own run. Rehearsal wrote nothing, Windows intact.
  - **FINDING 2 — the progress bar stops at 83%.** The rehearsal finishes
    correctly (message + report land), but the bar sits at 5/6 = 83% and
    never completes, reading as "stuck". Cause: rehearse emits `##golem 5/6
    evaluating` then `##golem rehearsed` — never `6/6` (that is the reboot
    trigger, correctly reserved). step_go's `rehearsed` arm prints the
    outcome but does not fill the bar. → changes.md.
- **Findings → changes.md:** (1) hardware reveal parser + bluetooth
  detection + setup.nix pci/usb deps; (2) bar completion on rehearsed.
- **Verdict:** mechanics PASS — the round-1 ISO rehearses correctly on the
  Acer, disk safe, both round-0 fixes confirmed on metal, census right. The
  two findings are on the reveal SCREEN, not the install; they do not block
  the rehearsed tick but must be fixed before the round closes. Scoreboard
  "Install rehearsed" box: earned.

### Live-fix phase (same ISO, `nix copy` overlay — 2026-09-06)

Applied the four queued fixes to source, built `golem-setup`,
`nix copy`'d it to the Acer (RAM overlay, ISO untouched), re-ran. **Both
findings resolved, proven on this metal:**

- **Reveal now complete** — the confirm screen showed, as `·` rows:
  - GPU: `Intel Corporation Broadwell-U GT2 [HD Graphics 5500] · i915`
  - Wi-Fi: `Qualcomm Atheros QCA9377 … · ath10k_pci` (clean — no bus-id
    prefix)
  - Audio: `Intel Corporation Broadwell-U Audio Controller · snd_hda_intel`
  - Bluetooth: `Bluetooth adapter · btusb` (census-aligned hci detection —
    the lsusb-grep miss is fixed)
  - Touchpad: `SYN1B81:01 06CB:2970 Touchpad`
- **Bar completes** — reads `████ 100% Rehearsed` instead of stopping at
  83%.
- Rehearsal `status ok`, 0 findings, **`/dev/sda` still factory NTFS** —
  the fixed surface writes nothing either.

So the queued fixes are verified on the Acer. They stay queued in
changes.md (marked verified-live) and ship in the round-close ISO; the
frozen stick is unchanged. The same live overlay will be applied and
re-verified on each subsequent laptop, across its own hardware.

## Round 2 — 2026-09-07 — PASS, no findings

- **ISO:** round-2 (`6k589761…`, HEAD `ec093ef`). Confirmed by the NEW
  `firmware = "uefi"` census fact (didn't exist in round 1). All round-1
  fixes now frozen in — no live overlay needed.
- **Boot:** UEFI. Joined HOLA on its own (192.168.1.99), census ok.
- **Census:** i5-5200U, cores=2/threads=4, ram 3833, gpu intel,
  intelLegacy=false (Broadwell → iHD), **firmware = "uefi"** (new),
  panelDpi 102, bluetooth, laptop. No broadcomWifi (correct — QCA9377 is
  Qualcomm). All correct.
- **Surface / reveal (frozen round-2 golem-setup):** full list — GPU
  (HD 5500 · i915), Wi-Fi (QCA9377 · ath10k_pci), **Ethernet (RTL8111 ·
  r8169 — NEW, round 1 missed it)**, Audio (· snd_hda_intel), Bluetooth
  (· btusb), Touchpad. **23 of 23 (100%)**. Hostname `acer` typed clean.
- **Rehearsal:** status ok, 0 findings, bar to 100%. checks.txt all green
  incl. the round-2 firmware line **`ok firmware: booted UEFI —
  systemd-boot to the ESP`** (was a hard FAIL for BIOS machines in round 1;
  now a real path). eval 31 s → `nixos-system-acer`. `/dev/sda` factory
  NTFS intact before and after (2 NTFS partitions) — Windows safe.
- **Findings → changes.md:** none.
- **Verdict:** PASS. The round-2 ISO boots and rehearses correctly on the
  Acer; the new firmware fact and Ethernet row work; every round-1 fix
  carried forward frozen.

### Round 2 — LUKS rehearsal + encryption UX (2026-09-07)

**The LUKS engine, proven on metal for the first time** (PLAN.md had it as
"not yet proven on metal or in the VM"). Drove golem-setup → Advanced →
encryption on the Acer (UEFI). Rehearsal `status ok`, eval 18 s, checks all
green. Transcript recorded the encrypted plan: `cryptsetup luksFormat` →
`open` → `pvcreate`/`vgcreate`/`lvcreate swap`+`root` (ESP + one LUKS2
container + LVM inside, per the design). `machine.nix` carried
`boot.initrd.luks.devices.golem.device` (placeholder UUID in rehearsal, as
built). Keyfile kept (rehearsal opened nothing), then shredded.
**`/dev/sda` still factory NTFS (2 partitions) — Windows intact.**

**Encryption UX — Max drove it and found gaps; all fixed and verified live
(round-3 golem-setup overlay, ISO frozen).** → changes.md R3-3:
- **Passphrase now typed TWICE.** Verified the match path AND the mismatch
  path ("The passphrases do not match — type both again." → back to the
  first field).
- **Warning screen** after confirmation, in the danger colour: "asked
  EVERY time this device starts … no recovery … lost forever". ESC there
  turns encryption back off.
- **State reads `LOCKED`** (was "on"), in red, on the Advanced row AND the
  summary — not the same ink as everything else.
- **Default selection returns to Back** after enabling, so one ENTER goes
  back to the drive list.
- **Summary disk line reads "(Will be erased and encrypted)"** when on.
- Also confirmed here: the round-3 touchpad-driver fix (`· hid-multitouch`)
  renders in golem-setup.
- **Verdict:** LUKS engine PASS on metal; encryption is now deliberately
  hard to enable by accident, which is the point.

## Round 3 — 2026-09-07 — PASS · 0 findings on substance · 1 new reveal refinement (#21c)

- **ISO:** round-3 `p5ylp6q6…`. Driven over SSH at 192.168.1.99.
- **Audit ok.** Census: gpu=intel, **intelLegacy=false → `video decode:
  iHD`** (Broadwell HD 5500 is iHD-capable — the legacy split's
  above-the-line case, correct), ramMB 3833, UEFI, bluetooth true.
- **The RAM boundary machine:** `ok ram: 3833 MB is enough` — the
  closest pass to the 3300 cutoff in the lab. The sticker-4GB /
  usable-3.7-3.8GB reasoning holds on its narrowest case.
- **Reveal:** `Intel HD Graphics 5500 · i915 — tested, working ·
  driving this screen` (verdict row, clean short name), QCA9377 ·
  ath10k_pci, Bluetooth row present (the round-1 triangulation machine),
  touchpad `· hid-multitouch` baked (R3-1 was live-verified here — now
  on the stick), zram `Active`, **18 of 18 (100%)**.
- **NEW FINDING → #21c:** the Audio row names "Broadwell-U Audio
  Controller" — the iGPU's HDMI audio function (00:03.0), not the
  speakers (Wildcat Point-LP HD Audio, 00:1b.0). Intel puts no "HDMI"
  in the name, so #21a's name filter passes it. Same story spotted
  retroactively on the ASUS ("Haswell-ULT HD Audio", 00:03.0). Round 4:
  filter by topology (audio functions adjacent to display devices), not
  names.
- **Rehearsal:** `status: ok`, all checks green, **eval 30 s** (round 1:
  31 s — consistent), UEFI→systemd-boot, disk untouched (the WDC's
  Windows partitions intact).
- **Verdict:** PASS — row 1 confirms round 3 on the UEFI/Intel/iHD
  path; one cosmetic refinement queued.
