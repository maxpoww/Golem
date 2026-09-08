# Installing — the wired-install phase

> Companion to `../preinstall/PLAN.md` (the medium, the census, the
> rehearsal loop, the offline matrix) and `../../postinstall/postinstall.md`
> (what happens after first login). `preinstall/` proves the whole decision
> chain without touching a disk; this directory is where the REAL install —
> actual partitioning, actual `nixos-install`, actual first boot — gets
> recorded, one machine at a time, once it earns the right to run.
>
> Opened 2026-09-08 as the sibling `Installer/preinstall/` needed once that
> name stopped being accurate for the whole directory: the install engine
> and the census/rehearsal machinery had been sharing one folder. This is
> the split's other half — currently empty on purpose (see "The gate").

## The gate

Per `../preinstall/testing/constitution.md`'s standing rule — *"Rehearsal
writes nothing. Until a round explicitly graduates a machine to the wired
install, no test touches a disk."* — a machine's record only starts in this
directory once:

1. its rehearsal is green on the frozen ISO under test (`checks.txt` all
   `ok`, no open findings), and
2. the round it belongs to has been decided closed — Max's call, under the
   constitution's round discipline (no mid-round fixes, no mid-round
   graduations).

**As of 2026-09-08: nothing has cleared that gate.** Round 4 on the lab's
NVMe machine (the Lenovo, rehearsal-only forever — see `testing/lenovo.md`)
still found and fixed two things (#34, R4-1) before round 5 even cut.
Round 2 on the five guinea-pig laptops (acer/dell/hp/macbook/comodore) is
still open. `../preinstall/PLAN.md`'s scoreboard has the honest state of
every machine's four boxes; this directory exists to fill in the last one,
"Installed, first boot OK," when a machine gets there.

## What will land here

The same shape `preinstall/testing/` uses for rehearsal, adjusted for the
one thing that's different: one file per machine, dated entries, disk
state checked before *and* after — except "before/after" now means
"factory state" vs. "booted Golem," not byte-identical, because a wired
install's whole point is that the disk changes. Findings still go through
`preinstall/testing/changes.md`'s queue; a wired install is a test like any
other, just the one with no rehearse flag.

## The mechanism (already built, still lives in preinstall/)

The engine that does the actual writing is `../preinstall/install.nix`
(`golem-install`) — the *same* control flow `--rehearse` already exercises
safely across the lab (PLAN.md's rule: "same code path, not a parallel
fake"). Dropping `--rehearse` is the only thing that changes; the mode
ladder (`GOLEM_REHEARSE=1` → `GOLEM_LAB=1` prepare-only → the product
install) is documented in `../preinstall/setup.nix` and PLAN.md's
"rehearsal loop" section. Whether the engine itself relocates into this
directory once real installs start is an open question, not decided here —
this file only claims the record-keeping side of the split.

## Working agreements

Same as `../preinstall/PLAN.md`'s: Max is the idea guy and manages scope
and the graduation call; the technician builds what's agreed and reports
numbers. Nothing here is a green light — it's the shelf the first real
result goes on.
