# DockMenu — the dock/menubox as a distro-grade component

> The permanent home for making waverunner's dock + apps/menu box
> **bullet-proof for every Golem user**: perfect on a fresh install, and
> identical after 5 years of intense daily use. Created 2026-09-09 at
> Max's direction, on the day the install pipeline got its #45–#48 fixes.

## The bar

- **Day 1 == Year 5.** No state file, cache, or side dir may degrade the
  experience over time: no unbounded growth, no startup slowdown, no
  silent data loss, no orphaned files.
- **Bullet-proof.** Every failure mode has a defined, tested recovery:
  corrupt store → preserved + rebuilt; crashed daemon → clean restore;
  interrupted install → converges; missing dependency → honest error.
- **Lightweight + fast.** A dock on 2013 hardware must stay invisible in
  `btop`: RSS as low as achievable, startup instant, scans cheap.
- **Self-maintaining.** The system prunes, sweeps, and heals itself; the
  user never runs maintenance.

## The map (the two reference machines)

| | dev box (`Golem`, local) | ASUS (`192.168.1.85`) |
|---|---|---|
| role | **aging dataset** — Max's daily driver, months of real usage | **fresh-install dataset** — first real installed Golem, 2026-09-09 |
| hardware | Slim Pro 9i, i9-13905H, 32 GB, NVMe, high-DPI | X550LC, i5-4200U Haswell, 7.5 GB, 5400rpm HDD, 1366×768 |
| renderer | Vulkan | GL fallback (the #40/#42 class lives here) |
| snapshot | [machines/devbox.md](machines/devbox.md) | [machines/asus.md](machines/asus.md) |

Everything is validated against BOTH: the ASUS catches slow-hardware
races and GL bugs; the dev box catches aging.

## Where things live

- **Source:** `~/launcher` (repo `maxpoww/launcher`) — crates/daemon is
  the dock/menubox; crates/core the desktop index.
- **Distro integration:** `~/Golem` — `system/waverunner-apply.nix` (the
  privileged install helper), the flake lock pinning waverunner.
- **Install-era findings:** `~/Golem/Installer/preinstall/testing/changes.md`
  (numbered findings) and `~/Golem/Installer/installing/FirstInstall.md`
  (the ASUS dogfood narrative).
- **This dir:**
  - [AUDIT.md](AUDIT.md) — the living full-stack audit: every state
    store, its growth model, corruption story, verdicts.
  - [INVARIANTS.md](INVARIANTS.md) — the testable contract the
    implementation must hold, forever.
  - [FINDINGS.md](FINDINGS.md) — dated findings log for this component
    (cross-referenced with changes.md numbers).
  - [machines/](machines/) — dated state snapshots per machine; append,
    don't overwrite — the time series IS the aging evidence.
  - [harness/state-census.sh](harness/state-census.sh) — harvest any
    machine's dock state (run locally or over ssh); output feeds
    machines/*.md.
  - [harness/aging-check.sh](harness/aging-check.sh) — assert the aging
    invariants on a live machine; run it on anything that's been used a
    while.

## Working method

1. A problem observed on either machine → entry in FINDINGS.md (and
   changes.md if install-related).
2. Root-cause at source in `~/launcher`; fix + test there.
3. Deploy permanently via the seed pipeline (launcher push → Golem lock
   bump → prebuild on dev box → `nix copy` → seed lock → self-rebuild).
   The pipeline is documented in memory (`asus-deploy-loop`) and in
   FirstInstall.md #41.
4. Verify live on the ASUS; update AUDIT.md verdicts.
5. Periodically: run `state-census.sh` on both machines, append to
   machines/*.md, diff against the previous snapshot — growth that the
   AUDIT didn't predict is a new finding.
