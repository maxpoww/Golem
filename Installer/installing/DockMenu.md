# DockMenu — the dock/menubox goes distro-grade

> 2026-09-09, Max: "take this machine and the ASUS as a map… GIVE ME THE
> MOST POLISHED DOCK/APPMENUBOX POSSIBLE — bullet-proof in every install
> and after 5 years of intense usage." The permanent project now lives at
> **`~/GolemOne/DockMenu/`** — this file records its creation and what
> the first full-stack pass found, because all of it is installer
> experience.

## Why this matters to the installer

The dock/menubox (waverunner) is the first thing an installed Golem user
touches and the ONLY interface to installing software. Every install
round from here on inherits: (a) the #45–#48 pipeline fixes proven today
on the ASUS, and (b) a written reliability contract with a harness that
any lab machine can be checked against in seconds.

## What was created

- `~/GolemOne/DockMenu/README.md` — charter + the two-machine map
  (dev box = months-of-usage aging dataset; ASUS = fresh-install
  dataset) + the working method (find → fix at source → seed pipeline →
  verify live → census).
- `AUDIT.md` — every persistent store with its 5-year growth model and
  verdict (code-verified). Headlines: persist is atomic but a corrupt
  store was silently destroyed on next write (the dev box's real
  `apps-order.json.bak-20260903-shredded` incident) → #49; notif history
  is unbounded by design AND its images are never swept → #50; 37 MB of
  dictionaries resident in RAM for one panel ≈ the biggest chunk of the
  dock's ~300 MB RSS → #51.
- `INVARIANTS.md` — the testable contract (state atomicity, bounded
  growth, install-pipeline guarantees I1–I7, perf budgets, self-
  maintenance rules).
- `FINDINGS.md` — the numbered findings log, continuing the changes.md
  number line (#49/#50/#51 opened today).
- `machines/devbox.md`, `machines/asus.md` — first census snapshots
  (day-1 vs months: 170 MB vs 2.4 GB state, both dominated by the
  webapp Chrome profile; JSON stores all healthy).
- `harness/state-census.sh` — harvest any machine's dock state (works
  over ssh); the appended series is the aging record.
- `harness/aging-check.sh` — asserts the machine-checkable invariants;
  **both map machines pass clean today**. Run it on any lab laptop that
  has been used a while; a FAIL is a finding, always.

## Numbers worth keeping (2026-09-09 baseline)

- Fresh install day-1 state: 170 MB total (168 MB = one webapp's Chrome
  profile; JSON stores < 10 KB combined).
- Months-of-usage state: 2.4 GB (again ~all Chrome profile), JSON stores
  < 180 KB combined — the store design is fundamentally sound; the gaps
  are the three findings above.
- Install→tile latency after the fixes: 1.5–2 s from apply Done
  (gimp/signal/spotify, measured on the 5400rpm ASUS).
- Daemon RSS ~280–300 MB on both machines — the #51 target.

## For the installing rounds

When the acer/dell/hp/comodore installs happen, run
`harness/aging-check.sh` on each as part of first-boot verification, and
`state-census.sh` before AND after the install session — the deltas are
free dogfood data for DockMenu.
