# ASUS

ASUS X550LC · i5-4200U Haswell-ULT (2c/4t) · **muxless NVIDIA hybrid:
Intel Haswell iGPU (boot display, eDP on card1) + NVIDIA GF117M "GeForce
GT 720M" dGPU (3D controller, no connectors, nouveau)** · boots **UEFI** ·
298.1 GB Toshiba MQ01ACF032 (existing Linux: ESP + ext4 288.8G + swap;
guarded) · 8012 MB RAM (lab's highest) · Atheros AR9485 wifi · ath9k ·
**no Bluetooth** (first hasBluetooth=false machine) · panelDpi 102.
Joined the lab 2026-09-07 (the second of the two new beautys).

**Why it matters:** the lab's first NVIDIA machine and first nvidia
HYBRID on lab metal — the #17c working-dGPU path was only ever proven on
the dev box. And its Fermi dGPU sits below the Maxwell id floor →
`nvidiaGen = "unknown"` → the IRON LAW gets its first hybrid test: the
target must stay on the modesetting/nouveau floor and still build.

---

## Round 2 (first contact) — 2026-09-07 — rehearsal PASS 0 findings · but the AUDIT'S FIRST DECIDE FAILURE on metal

- **ISO:** round-2 (frozen stick; hostname fix confirmed). Driven over
  SSH at 192.168.1.85; joined the network on its own (ath9k).
- **THE HEADLINE — `status: FAILED at: golem-hw-decide`:** the boot
  census wrote correct facts, then the decision surface CRASHED:
  `while evaluating the option 'hardware.nvidia.open': expected a set
  but found null`. Root cause: round-2 census says `gpu = "nvidia"` (old
  priority logic — nouveau binds, the dGPU wins) with `nvidiaGen =
  "unknown"` (GF117M is pre-Maxwell). The iron law correctly keeps
  nvidia OUT of videoDrivers — and with the driver inactive the
  upstream nvidia module's internals are null, so decide.nix's
  `nv.open` read for the "kernel module" row kills the whole eval. No
  earlier lab machine had an nvidia GPU, so the trap never fired.
  **The round-3 build had the SAME reads (keyed on gpu2==nvidia) and
  would have crashed here too — caught pre-reflash.** → changes.md #22,
  fixed in the round-3 source same day.
- **Downstream on the surface:** decision.json never written → the
  confirm screen shows NO decision rows (no Zram/Swap/Scheduler/Lid) —
  and says nothing about the absence. A stranger can't tell the audit
  half-failed. → #22 sub-point (a failed audit deserves a visible line).
- **Census facts — correct throughout:** i5-4200U 2c/4t, ramMB 8012,
  `intelLegacy = true` (Haswell → i965, right), `firmware = "uefi"`,
  `nvidiaGen = "unknown"`, both PRIME bus ids (PCI:4:0:0 / PCI:0:2:0),
  `panelDpi = 102` (second panel fact; scale "none" correct),
  **`hasBluetooth = false`** — the lab's first confident "no radio"
  verdict (no BT row on the reveal ✓ — the triangulation saying no).
- **Reveal (round-2 stick):** GPU row shows ONLY the Intel iGPU — the
  dGPU is invisible (this stick predates the multi-row reveal; round 3
  shows both + verdicts). Wi-Fi `AR9485 · ath9k`, Ethernet `RTL8111 ·
  r8169`, Audio `Haswell-ULT HD Audio · snd_hda_intel`, Touchpad
  `ETPS/2 Elantech Touchpad` (a real touchpad this time — no TrackPoint
  to mis-pick). **26 of 26 (100%) drivers** — nouveau counts the dGPU.
- **Rehearsal:** `status: ok`, **0 findings** — which is itself the
  diagnosis: the TARGET on the iron-law floor evaluates fine (`eval
  30 s` → `nixos-system-asus`, second-fastest metal); only decide.nix's
  row rendering reads the poisoned options. UEFI → systemd-boot + ESP,
  target sda ≠ medium sdb, fit (294493 MiB).
- **Disk verified untouched:** ESP `0E2A-C3BA` + ext4 `802943cb…` +
  swap `02325d24…` identical before/after.
- **Findings → changes.md:** #22 (new, blocking the reflash — fixed in
  source same day). Round-3 verification jobs for this machine: gpu →
  intel by boot_vga, gpu2=nvidia + health verdict on a nouveau Fermi,
  iron-law floor holding through the hybrid path, decide surviving.
- **Verdict:** rehearsal PASS / audit FAIL — exactly the kind of
  first-contact catch the lab exists for, and it saved the round-3
  reflash from shipping the same crash.

### Round 2, follow-up — nouveau dGPU faults on the physical console (Max's photo, 2026-09-07)

Photo of the attract screen shows **nouveau MMIO faults painting over
the surface** — the #17a console-spam class, THIRD driver (mei/Dell,
radeon/HP, now nouveau):
`nouveau 0000:04:00.0: bus: MMIO write of ffff8d1f FAULT at 6013d4
[ PRIVRING ]` — four over ~138 s (56.8 / 81.3 / 163.1 / 194.9), sporadic
~25–80 s apart, at the dGPU's own PCI address. nouveau's bus-fault
reports print at KERN_ERR → painted at the round-2 stick's loglevel 4,
suppressed by round-3's `consoleLogLevel = 3`. (Machine went offline
before priorities could be read over SSH — the classification is from
the nouveau nvkm error path; verify casually on the round-3 boot.)

**Why this photo matters beyond the spam — it sharpens the #17c
question for THIS machine:** the faults are sporadic background noise at
the dGPU's address, not wake-triggered bursts (the machine sat at the
attract screen). The round-3 health probe counts errors only during its
3 s forced-resume window, twice. Possible verdicts here:
- probe window catches/provokes faults twice → **failing** → powered
  off — arguably right for a connectorless Fermi nouveau can't drive
  well (kills the spam AND the idle draw);
- window stays quiet → **working** → offload config (mostly harmless on
  nouveau, but the background spam stays — only quieted visually);
- one flake → **unspoken** → default stack.
The ASUS is therefore the lab's first timing-dependent verdict risk —
capture WHICH verdict round 3 lands, and whether repeated boots agree
(the verdict-stability question the facts-match check exists for).

### Round 2, second follow-up — A/B proven + health-probe preview (2026-09-07, machine back up)

Fresh boot, driven over SSH:
- **Priorities verified on metal:** the PRIVRING faults are `kern :err`
  — no longer inferred. dGPU sits `suspended / auto` under nouveau
  runtime PM (the HP-radeon pattern). `hasBluetooth = false` confirmed
  righteous: no BT on USB at all (webcam + stick + hubs only).
- **#17a A/B — third driver PROVEN:** at `dmesg -n 3`, a forced resume
  of the dGPU threw the photo's exact fault (`MMIO write … FAULT …
  PRIVRING`, 2 kernel lines at 04:00.0) and **the physical screen did
  not change** (tty1 md5 identical before/after). Loglevel restored
  to 4 — round-2 stick behavior preserved.
- **Health-probe preview — the single-flake rule fires:** wake 1 →
  2 errors at the address; wake 2 (3 s later) → **0 errors** → round-3
  verdict will be UNSPOKEN → conservative default stack. Design insight
  recorded on #17c: the retry is only real if the device RE-SUSPENDS
  between pokes; back-to-back, poke 2 finds the chip still awake and is
  vacuous. For this machine the silence is right (nouveau already
  runtime-suspends it; the spam is invisible at loglevel 3) — but watch
  round 3 for verdict stability across boots.
- **Fixtures:** `fixtures/asus/` — golem-hardware.nix (the #22 crash
  shape: gpu=nvidia + nvidiaGen=unknown), lspci -nnk, input devices,
  nouveau dmesg. Matrix-ready.
## Round 3 (machine 1 of the round) — 2026-09-07 — every round-3 fix verified · 2 new findings · the verdict flap caught

- **ISO:** round-3 `p5ylp6q6…` (freshly flashed). Driven over SSH at
  192.168.1.85.
- **#22 DEAD ON ARRIVAL: `audit: ok`** on the machine that crashed it.
  decide.json complete, with the iron-law row rendering:
  `kernel module: none — open floor (modesetting/nouveau)`.
- **#17b live:** `gpu = "intel"` (boot_vga — round 2 said nvidia),
  `gpu2 = "nvidia"` + address. **#17a live:** loglevel 3; 2 PRIVRING
  faults in dmesg this boot, ZERO on the physical screen.
- **The reveal, as designed (first time in any installer):**
  `GPU  Intel Haswell-ULT Graphics · i915 — tested, working · driving
  this screen` / `GPU 2  NVIDIA GeForce 610M/710M/810M · nouveau —
  tested, working · apps can use it on demand`. Touchpad `· psmouse`
  (R3-1), decision values translated (`Suspend, then hibernate`),
  **20 of 20 (100%)** honest count (#10).
- **NEW FINDING #20b:** the drive list STILL offers the boot stick —
  the /iso fix's PKNAME `head -1` grabs the empty whole-disk row (USB
  isohybrid mounts from /dev/sdb, not a partition). The engine's
  target≠medium check backstops (`ok target: sda is not the boot
  medium (sdb)`). Queued round 4.
- **NEW FINDING #23 — the predicted verdict flap, caught by the
  instrument:** boot audit `gpu2Health = working` (first poke hit a
  still-awake chip — vacuous); install-time re-probe on the
  long-suspended chip: cold-resume faults ×2 through the REAL retry →
  `failing`; checks.txt `warn facts: working → failing`. Fix: the
  first poke needs the same bounded re-suspend wait. Skew note: this
  boot's reveal promised on-demand use while the target powers the
  chip off (the rehearsal evals the re-probed, safer facts).
- **Rehearsal:** `status: ok` (the warn is a warning, not a finding
  count), ram ok (7384 MB), **eval 30 s** → `nixos-system-asus` — the
  FIRST target ever evaluated with gpu-second.nix's power-off branch
  active. Disk untouched (same three UUIDs).
- **Verdict:** round-3 machine 1 PASS with two queued findings — and
  every major round-3 mechanism (boot_vga census, health probe + real
  retry, iron law on a hybrid, quiet console, verdict rows, honest
  count, decide-on-the-floor) proven on the single machine best
  equipped to break them.

- **The Bluetooth challenge (Max: "i think this pc have BT"):**
  investigated to the firmware. Full lsusb (6 devices, no BT), rfkill
  (only phy0, no blocks), zero bluetooth/btusb/ath3k dmesg lines ever,
  asus-wmi loaded with NO BT killswitch, and — the clincher — the
  DSDT/SSDTs contain ZERO Bluetooth references (a BIOS-toggled BT still
  lives in ACPI; an undescribed one was never there). Verdict: this
  UNIT has no BT — X550LC BT was an optional AR3012 module, and the
  AR9485 here is the wifi-only card (possibly a past owner's swap; the
  slot is replaceable). The census's first confident `hasBluetooth =
  false` SURVIVES a direct challenge. Caveat recorded: confident-no
  ships no bluez — adding BT later (combo card / dongle) needs a
  re-detect + rebuild to grow the stack.

### Round 3, follow-up — #23 force-cold fix cross-machine verified (2026-09-08, machine back up on its own)

Max: "asus up." Found at 192.168.1.85 (the usual IP, joined ath9k on its
own again). Read-only checks only — no golem-setup driven this pass.

- **ISO confirms the fix is aboard:** `nixos-version` →
  `26.05.20260829.c5c4a43 (Yarara)`; `golem-hw-detect`'s store path
  contains the `force-cold`/`forceCold` marker (2 hits) — this is the
  same #23/#23b fix commit (`98c29a5`) already validated on the Lenovo
  for the FALSE-NEGATIVE direction (a healthy RTX convicted itself on its
  own GSP boot chatter, changes.md line ~348). This machine is the other
  direction: a chip that genuinely faults.
- **`gpu2Health = failing` — and this time it's not the single-flake
  vacuous-poke problem round 2/3 first contact caught.** dmesg this boot
  shows THREE separate PRIVRING faults at 14.0 s / 22.7 s / 33.3 s (`bus:
  MMIO write of ffff8b1f FAULT at 6013d4 [ PRIVRING ]`), `power/control`
  = `auto` (nouveau runtime-suspending it as before) — a genuinely
  faulting chip, not a boot-chatter miscount. The boot audit alone (no
  install-time re-probe needed this time) landed on `failing` directly:
  `summary.txt` → `gpu 2 health failing / gpu 2 action powered off, kept
  quiet`, `status: ok`.
  - **Cross-machine read: the fix is not overcorrecting.** Lenovo needed
    the fix to STOP calling a healthy chip broken; ASUS needed it to
    KEEP calling a broken chip broken. Same commit, both correct, on the
    two most different dGPU cases in the lab. That is the fix actually
    proven, not just "it built."
- **Disk verified untouched:** ESP `0E2A-C3BA`, ext4
  `802943cb-afba-45b6-b25c-aa855466fd6f`, swap
  `02325d24-c0cf-4a08-9f16-9816ce434962` — all three UUIDs identical to
  every prior round. `hasBluetooth = false` still holds (unchanged
  hardware).
- **Not run this pass:** no `golem-setup`/rehearsal driven over SSH — this
  was an audit-level re-verification only, so no fresh
  `checks.txt`/`rehearsal.tar.gz` this entry. #20b (boot-stick still
  offered in the drive list) was not re-checked here; still open per
  round 3.
- **Verdict:** PASS (audit-level) — #23/#23b confirmed fixed on the
  machine that originally caught it, without breaking the direction that
  was already correct. A full rehearsal pass on this stick is still owed
  before round 3 closes.

### Round 3, full rehearsal + GPU 2 "didn't wake up" investigated (2026-09-08, same session)

Max, on the reveal's `GPU 2 … tested, didn't wake up`: **"that is not
possible, the 720m works."** Investigated directly before dismissing
either side of that.

- **The two claims aren't actually in conflict — they're testing
  different things.** Forced the chip fully awake by hand
  (`power/control on`) and watched it, not through a resume transition:
  **exactly one fault fired, at the moment of the resume itself
  (`suspended`→`active`) — then zero new faults across the next 15
  seconds held awake.** `gpu2_dev_errs` count: baseline 5 → 6 right after
  forcing on → still 6, 15 s later. The probe (`system/hardware-detect.nix`
  §"dGPU health test") specifically tests *surviving a runtime-PM cold
  suspend→resume cycle* — not "can the chip render." A one-shot fault
  exactly at the resume edge, then silence while genuinely running, reads
  as **nouveau's dynamic runtime-PM resume path being unreliable on this
  Fermi-class chip (GF117, pre-Maxwell — nouveau's dynamic PM support is
  young and Turing+-first; this repo's own `nvidia_gen` tiering already
  treats pre-Maxwell as the conservative floor for exactly this reason)
  — not the chip being unable to do work once it's actually up.** Max is
  very plausibly right that it "works" in ordinary use; the probe is
  very plausibly right that it doesn't survive being autosuspended and
  woken back up cleanly. `gpu 2 action: powered off, kept quiet`
  (`decide.nix`) is the correct SAFE response to what the probe can
  prove, but "kept quiet" — never offering it at all rather than "on
  but never let it sleep" — may be leaving usable GPU on the table. Not
  fixed tonight — flagging as a real design question, not a probe bug:
  **could a "failing" pre-Maxwell dGPU offer itself with runtime PM
  forced off (`power/control=on`, no autosuspend) instead of being
  powered off entirely?** That trades the power saving for the capability
  Max is describing. No render test was possible to confirm "works" more
  directly — this is a console-only rehearsal environment with no
  compositor and no GL/Vulkan tooling on the medium, and nouveau has no
  Vulkan (nvk) support at all below Turing, so even a tool-equipped test
  would only ever confirm OpenGL, not the modern stack. Genuine limit of
  what this session could check.
- **Full visual rehearsal, driven live over SSH/tmux (English, default
  timezone/keyboard, TOSHIBA target, hostname Golem, user max):** the
  confirm screen showed exactly Max's quoted line —
  `GPU 2   NVIDIA GeForce 610M/710M/810M — tested, didn't wake up` next
  to `GPU   Intel Haswell-ULT Graphics · i915 — tested, working · driving
  this screen` — captured verbatim, not paraphrased.
- **Rehearsal result: PASS, 0 findings, ENTER→100% "Rehearsed."**
  `checks.txt`: firmware/target/fit/ram/facts/eval all `ok`, **facts:
  the probe now matches the boot audit fact for fact** (the earlier
  boot-vs-install-time flap class, #23's own failure mode, did NOT
  recur this pass), eval 31 s → `nixos-system-Golem-26.05….drv`.
  Confirm-screen line said "rehearsed — nothing was written, no
  findings."
- **Disk verified untouched, before AND after the full flow this time**
  (not just the audit-only pass): all three UUIDs (`0E2A-C3BA` /
  `802943cb-afba-45b6-b25c-aa855466fd6f` / `02325d24-c0cf-4a08-9f16-9816ce434962`)
  identical.
- **Verdict:** round 3 rehearsal PASS on this stick, 0 findings — closes
  the "rehearsal still owed" note from the audit-only pass above. #20b
  (boot stick still offered in the drive list) not re-checked this pass,
  still open. New open item: the "failing dGPU → powered off entirely"
  policy question above, worth Max's call before it's treated as settled.
