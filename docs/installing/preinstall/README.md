# Preinstall — the Golem installer, maintained

The installer that boots a stranger's machine, learns what it is, asks
six answerable questions, and installs a working Golem. **Graduated
2026-09-10** after six lab rounds on eight machines (~70 findings, all
worked); this directory is what keeps it maintainable from here.

## Where things are

| What | Where |
|---|---|
| **Implementation** (the flake the ISO builds from) | `~/Golem/Installer/preinstall/` |
| The spec (WHAT/WHY) | `~/Golem/GolemInstall.md` |
| The census + decision modules (shared with the full distro) | `~/Golem/system/` |
| **These docs** (HOW it works, how to run/debug/extend it) | here |
| **The lab archive** (PLAN + scoreboard, finding ledger, per-machine records, constitution, playbook) | `testing/` |
| The live successor program | `~/Golem/Installer/installing/` |

## The documentation set

- [ARCHITECTURE.md](ARCHITECTURE.md) — the pieces and the data flow:
  ISO → boot census → decide → surface → engine → target → postinstall.
- [OPERATIONS.md](OPERATIONS.md) — the runbook: build an ISO (the lock
  rule), gate it on the VM, flash it, drive a machine over SSH, run a
  real install through the closure-delivery seam.
- [DEBUGGING.md](DEBUGGING.md) — where every log lives, the failure
  classes the lab already paid for, and the harness-first rule.
- [EXTENDING.md](EXTENDING.md) — how to add a census fact, a decision,
  a reveal row, a question, a language — and the discipline that keeps
  changes honest.
- [TESTING.md](TESTING.md) — the lab method: what "proven" means here,
  the record format, the VM gate, the fixtures/eval matrix.
- [HISTORY.md](HISTORY.md) — the six rounds and the graduation, with
  pointers into the archive.

## The three rules that outrank everything in these docs

1. **The reveal says only true things.** A verdict is measured, an
   absence is honest, uncertainty renders dim. Every feature inherits
   this (`testing/constitution.md`).
2. **Suspect the harness first.** A wrong-looking result is more often
   the rig lying than Golem being wrong.
3. **A fix is not real until the artifact that ships it provably
   carries it.** Locks, seeds and sticks do not refresh themselves —
   see the #41 family in DEBUGGING.md.
