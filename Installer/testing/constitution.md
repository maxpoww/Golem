# The testing constitution — how the lab runs

The method for raising Golem's install story on real hardware, agreed with
Max (2026-09-06). This file is the process; the laptop files are the
records; [testing.md](testing.md) is the synthesis; [changes.md](changes.md)
is the queue. Read this before running a test or writing a finding.

## The idea in one line

**One ISO, tested across all five laptops, before anything changes.** A
round tests a single frozen ISO on every machine, so the five results are
comparable — the same code meeting five different pieces of hardware. Only
when the round is complete do we change anything.

## The unit of work: a ROUND

A round is one ISO taken across the whole lab:

1. **Freeze the ISO.** The current `.#iso` is the round's subject. Its
   store path is its identity — record it (below). It does not change for
   the duration of the round, no matter what the tests turn up.
2. **Test each laptop** (the five files: acer, dell, hp, macbook,
   comodore). Append a dated finding block to that machine's file for this
   round. A machine that is down is skipped and its box left open — a round
   completes when all five that are available have run.
   - **Two phases per laptop (Max, 2026-09-06):** first the FROZEN-ISO
     baseline (what today's stick does), then a LIVE-FIX phase — apply the
     round's queued fixes to source, `nix copy` the rebuilt tool onto the
     booted medium (RAM overlay, ISO untouched), and re-test to verify the
     fixes on THAT machine's real hardware. Record both. This validates a
     fix across all five hardware profiles before it is ever baked into an
     ISO — a bigger picture than fixing once at the end.
3. **Findings go two places.** The raw finding is recorded in the laptop's
   file (what THAT machine did). Any change the finding implies for Golem
   is queued in [changes.md](changes.md) — never applied mid-round.
4. **Close the round.** When the five are done, read all five files, write
   the *big picture* — what held everywhere, what only one machine
   exposed, what the round proved — into [testing.md](testing.md).
5. **Turn the crank.** Apply the queued changes from changes.md, build a
   new ISO, reflash, clear the queue, and open the next round.

The discipline that makes this work: **no ISO change lands mid-round.** A
bug found on laptop 2 is not fixed before laptop 3 runs — it is written
down and the same ISO meets laptop 3, so laptop 3's result describes the
same Golem. Fixing as you go would mean five machines each testing a
slightly different distro, and nothing could be compared. (The cores +
hostname fixes on 2026-09-06 predate this constitution; they are baked into
the round-1 ISO below, and from here the queue is honored.)

## The test, per laptop

What "the test" is (Max: "test is for general changes on Golem"): boot the
stick and drive the whole install flow as a stranger would, writing
nothing to any disk. Concretely:

1. **Boot the stick, press Start.** Note the boot path (UEFI vs BIOS) and
   whether the styled menu drew correctly — the firmware differs per
   machine and the menu is the first thing a stranger sees.
2. **Let the census run.** The boot audit probes the machine unprompted.
   Confirm it joins the lab network on its own, then SSH in and read
   `/var/log/golem-audit/summary.txt`. Cross-check every fact against what
   we KNOW of the machine — the probe describing hardware wrong is the
   highest-value finding there is.
3. **Run `sudo golem-setup`** and walk all six screens as a stranger:
   language, timezone, keyboard, disk, you, confirm. Watch for anything a
   stranger could get wrong or be surprised by (this is how the hostname
   append bug surfaced).
4. **Confirm the install — it REHEARSES** (`GOLEM_REHEARSE=1` in the
   wrapper). Nothing is written; `golem-install --rehearse` records what it
   would do, evaluates the real target system, and leaves a bundle in
   `/var/log/golem-rehearsal/`.
5. **Pull and audit the bundle** from the dev box. Read `checks.txt`
   first, then the transcript, the dropped `machine.nix`, and the eval
   verdict. **Verify the target disk is untouched** (`lsblk`/`sgdisk -p`) —
   the whole promise of rehearsal is that a stranger's factory install
   survives.
6. **Record the finding** in the laptop's file: ISO identity, what passed,
   what the machine exposed, and the bundle's headline numbers. Findings
   worth keeping as fixtures go to `fixtures/<machine>/`.

Later rounds add the wired install (real partitioning, real
`nixos-install`, first boot) as the last step — but only after the
rehearsal rounds have stopped finding things. Rehearsal proves the whole
decision chain; it does not prove mkfs, the bootloader write, or first
boot.

## What a finding is

Anything the machine did that we would want to know before shipping: a
census fact that is wrong or uncertain, a screen a stranger could
misread, a check that fired, a rehearsal that recorded the wrong plan, a
boot menu that drew wrong, a machine that would not join the network. "It
worked" is also a finding — record the pass, with the numbers, because a
green result on new hardware is what earns the next box on the scoreboard.

## Standing principles (they travel with every round)

- **The iron law.** Uncertain detection lands on the safe, open stack; a
  stranger's first boot must never be a black screen.
- **Suspect the harness first.** When a census result looks wrong, the test
  rig lying to the probe is more likely than Golem being wrong — it has
  happened repeatedly (headless `-vga none`, missing virtio channels, a
  stripped systemd PATH). Rule out the rig before blaming the distro.
- **Metal earns what the VM and CI cannot.** Fixtures replay in
  milliseconds and gate CI, but only real hardware in the real boot audit
  finds the boot-timing, firmware, and clean-PATH bugs. That is why the lab
  exists.
- **Rehearsal writes nothing.** Until a round explicitly graduates a
  machine to the wired install, no test touches a disk.

## The scoreboard lives in PLAN.md

The per-machine pass/fail grid (Evidence · Census right · Install
rehearsed · Installed) stays in `../PLAN.md`. This directory is the
working record behind those boxes; PLAN.md is the summary in front of them.

## Rounds

### Round 1 — open (2026-09-06)

- **ISO under test:** `/nix/store/kizf3l8kl0qbq2hpjw9hl3qvck8jgf6c-golem-installer.iso`
- **Tree:** on top of `4461600`, dirty (rehearsal mode + cores/hostname
  fixes, staged, uncommitted).
- **Carries:** rehearsal mode (`GOLEM_REHEARSE=1`), the sysfs cores fix,
  the hostname ghost-placeholder fix, HOLA auto-join.
- **Laptops:** acer ☑ (mechanics pass; 2 reveal findings, fixes verified
  live) · dell ☐ · hp ☐ · macbook ☐ · comodore ☐
- **Queued fixes (changes.md):** 4, all applied to source + verified live
  on Acer — hw_pci reveal parser, bluetooth reveal detection, setup.nix
  pci/usb deps, bar completes on rehearsed. Re-verify per laptop; ship at
  round close.
- **Big picture:** _pending round completion._
