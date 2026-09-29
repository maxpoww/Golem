# History — six rounds to graduation

The full story is in the archive (`testing/PLAN.md` for the arc,
`testing/changes.md` for all ~70 findings, per-machine files for every
run). This is the map.

- **Rounds 0–1 (2026-09-03 → 06):** machine zero (the VM) and the acer.
  The census born fact-by-fact, the evidence collector hardened, the
  first reveal bugs (#1–#4: last-PCI-device parsing, missing combo BT,
  closure escapes, the 83% bar).
- **Round 2 (09-07):** BIOS becomes real (#8), Broadcom Macs keep wifi
  (#5), ancient GMA classified right (#12), the ASUS's first contact
  catches the decide/nvidia-null crash (#22) before the round-3 stick
  could ship it.
- **Round 3 (09-07 → 08):** the big honesty round — hybrid GPUs done
  right (#17 family: boot_vga, quiet console, health probe, two GPU
  rows with measured verdicts), translated end to end (#18), silent
  engine death fixed (#19), the drive list stops offering the stick
  (#20), low-RAM refusal (#16). Verdict-flap caught by its own
  instrument (#23).
- **Round 4 (09-08):** force-cold makes the health probe honest in both
  directions (#23b — Lenovo stops convicting a healthy chip, the hp's
  dead radeon stays convicted), the failing-dGPU path proven end to end
  (#17c closed), Ctrl-C exits once cleanly (#34), F1 cancels (#31),
  the phantom sibling-GPU killed (#26).
- **Round 5 (09-08 → 10):** the ask framework (#33) — hold-and-ask
  replaces unilateral power-off, proven empty on five machines and
  non-empty on both failing-dGPU machines. THE REAL INSTALL (ASUS,
  09-09): the seam end to end, first boot clean, and the first human
  answer catches #35 (the pipeline that reported success while
  changing nothing). Then the first-install dogfood
  (`~/Golem/Installer/installing/FirstInstall.md`) — the desktop's own
  war: #36–#48 in two days, the keystone deadlock, the deployment gap
  (#41), the GLES cubemap, the applier onion — all fixed and made
  permanent in the seed. Round 5 closes 8/8 with the last surface
  trivia (R5-2/3/4).
- **Round 6 (09-10):** the queue worked in one evening, the lock-refresh
  trap caught at the cut (the ISO-level #41), the VM gate passes with
  R5-3 proven live, and the first BIOS install anywhere — SeaBIOS →
  GRUB → running system, in the rig, before any BIOS metal was risked.
  **Graduation declared** (testing/PLAN.md, top).

## What graduation asserted (and its asterisks)

Proven: the census reads real machines truthfully across every class
the lab holds; the surface asks only answerable questions and refuses
what it must; the engine assembles and boots working systems on UEFI
and BIOS; the seed makes every fix permanent. Asterisks, owned by the
installing rounds: BIOS-on-metal, and the MacBook boss fight.

## The successor

`~/Golem/Installer/installing/` — the installing rounds: real installs
across the lab, the desktop dogfooded per GPU generation, the DockMenu
harness at every first boot. The finding number line continues there
and in `~/Golem/docs/shell/dockmenu/FINDINGS.md`.
