# INVARIANTS — the bullet-proof contract

> Testable statements the dock/menubox must hold on every Golem machine,
> from first boot to year 5. `harness/aging-check.sh` asserts the
> machine-checkable ones; the rest are held by code + tests in
> `~/launcher`. A violated invariant is a finding, always.

## State

- **S1.** Every store write is atomic (temp + rename). No store is ever
  observable half-written. *(persist.rs; test-covered)*
- **S2.** A corrupt store never loses data silently: the original is
  preserved on disk as `<name>.corrupt-<date>` and the event is loud in
  the journal. *(#49)*
- **S3.** No `*.tmp` file survives a session. *(aging-check)*
- **S4.** Every side file (notif image, clipboard image/preview, pending
  icon) is referenced by a live store entry — orphans are swept by the
  writer that owns them. *(#50 for notif; clipboard + pending verified)*
- **S5.** Every store is bounded: by a hard cap (clipboard 200, notif
  500), by user structure (pins/groups), or by a census-watched slow
  variable (apps-order, usage) with a written revisit threshold.
- **S6.** `pending-installs.json` exists **iff** an install is in
  flight. An idle machine has no pending state. *(aging-check)*

## Install pipeline

- **I1.** A reported install failure means the package is NOT in the
  final generation, and a reported success means it IS. (No #44-class
  false failures, no #45-class mis-attributed successes.)
- **I2.** The package list is never reverted while a rebuild that read
  it is still running. *(#45 liveness)*
- **I3.** Every wait terminates: covered by a run that started after the
  write, an honest failure, or a bounded timeout. Never an infinite
  spin, never a starved resolve. *(#45/#46/#47)*
- **I4.** A finished install's tile resolves within 2 s of its desktop
  entry becoming scannable — idle or busy, changed or unchanged
  fingerprint. *(#46 retry + #47 short-circuit resolve; measured 1.5–2 s
  on the ASUS)*
- **I5.** An install never fabricates an app that doesn't exist: a
  GUI package resolves to its real desktop entry (pre-existing or new);
  only genuine CLI tools get terminal tiles. *(#48 + heal)*
- **I6.** Daemon death at ANY point of an install converges after
  restart: re-arm, fast-complete, or honest failure — never a stuck
  tile, never a lost package. *(#37 + restore path; drilled live)*
- **I7.** The desktop stays interactive during any rebuild (frame
  throttle on GL/software backends). *(#40)*

## Performance

- **P1.** Daemon startup to "daemon up" < 2 s on the weakest map
  machine (5400rpm Haswell).
- **P2.** Startup cost is independent of machine age: no store parse
  grows with years of use beyond its cap (S5).
- **P3.** RSS budget: the dock must not be a top-3 memory consumer on an
  8 GB machine at idle. *(#51 attacks the dictionary share)*
- **P4.** A desktop-entry scan on the weakest machine stays under 250 ms
  end-to-end (measured: 7–19 ms scan + icons).

## Self-maintenance

- **M1.** No user-facing maintenance action exists or is ever needed:
  every cap, sweep, and heal runs automatically in the daemon's normal
  paths (load/save/scan), not in a cron the user could lose.
- **M2.** State from ANY older daemon version loads cleanly in every
  newer one (serde defaults on new fields; unknown fields ignored) —
  a 5-year-old machine upgrades without a state wipe.
- **M3.** The heal passes are idempotent and cheap enough to run every
  scan (misfile relabel #48, stale-tile drop #37, orphan sweeps #50).
