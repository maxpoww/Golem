# AUDIT — the dock/menubox full-stack audit

> Living document. Every persistent store, cache, and side effect of the
> waverunner daemon, with its growth model over 5 years, its corruption
> story, and a verdict. Facts are code-verified against `~/launcher` at
> the audit date; numbers from the two reference machines (see
> machines/). Update verdicts as fixes land.
>
> First full pass: 2026-09-09 (launcher `ab44373`).

## A. The persistence layer (`crates/daemon/src/persist.rs`)

- **Write path:** temp file + rename, parent dirs created. Atomic against
  crash-mid-write. No fsync — relies on ext4 ordered-mode rename
  heuristics; acceptable (a torn store is recoverable, see below), and
  fsync on every clipboard copy would jank a 5400rpm HDD.
- **Read path:** missing OR **malformed → `None` → store starts empty.**
  ⚠ FOUND 2026-09-09: silent data loss — a corrupt file is *left in
  place* but the next write overwrites it with defaults. The dev box
  carries `apps-order.json.bak-20260903-shredded`: a real corruption
  incident where the grid order was lost and a session hand-rescued a
  backup. **FIXED #49** (launcher `8bb6c72`): the corrupt original is
  preserved as `<name>.corrupt-<epoch>` with a loud warn; the store
  restarts clean and the bytes stay rescuable. A schema break on
  upgrade degrades the same safe way.
- **tmp naming:** `with_extension("tmp")` collapses `foo.json` and a
  hypothetical `foo.rgba` onto one temp name. No live collision today
  (single-threaded writers, distinct stems) — hardened opportunistically
  with #49 (`.tmp` appended, not substituted).

## B. Store-by-store growth audit (5-year model)

| store | dev box (months) | ASUS (day 1) | growth model | verdict |
|---|---|---|---|---|
| `apps-order.json` | 5.0 KB | 3.7 KB | +1 id per app ever seen; **dead ids never pruned** (proof: `vlc` from the original image survived its uninstall by months) | ACCEPT+WATCH: ~100 B/app, even 500 dead apps ≈ 50 KB. Pruning is risky (an id absent one scan ≠ uninstalled; the slot is the user's layout memory). Census tracks it; prune only if evidence demands. |
| `usage.json` | 2.9 KB | 112 B | +1 key per app ever launched; dead ids kept | ACCEPT+WATCH: trivial size, and dead counts are harmless (sort noise only). |
| `clipboard-history.json` | 132 KB | 1.1 KB | **capped**: `MAX_HISTORY=200` entries, `TEXT_CAP=100k`/entry, images dropped with entries | OK by design. Worst case ~20 MB (200 × 100k) — parse at startup measured trivial. |
| `notif-history.json` | 32 KB | 502 B | "**Grows unbounded by design**" (notif.rs) — stack-collapse dedups per (app,summary), so growth = distinct stacks, but still unbounded | FIXED #50 (`8bb6c72`): capped at 500 cards on save AND load — an old uncapped store shrinks on first use. |
| `notif-images/` | 153 files / 4 MB | 0 | content-hash files written by `store_image`; **nothing ever deletes them** — entries removed from history orphan their images | FIXED #50 (`8bb6c72`): every save sweeps unreferenced images. |
| `clipboard-images/` + `-previews/` | ~100 KB | 0 | side files dropped with their history entries (code-verified) | OK. |
| `webapp-chrome/` | **2.4 GB** | 170 MB | a full Chrome profile for webapps; grows with browsing like any browser profile | ACCEPT (it IS the user's browser data) + QUEUED: pass `--disk-cache-size` to bound the cache portion; census tracks totals. |
| `dictionary.json` + `-es` | 37 MB disk (dev box only) | **absent** (lean image ships none) | static files; already lazy-loaded on first panel open — no cost until used | OK (the #51 hypothesis was corrected by measurement; see C + FINDINGS). |
| `managed.json` | 1.8 KB | 1.8 KB | one record per managed package | OK; the gui-misfile class fixed by #48's heal pass. |
| `pins.json`, `groups.json`, `ui_state.json`, `trash-pinned`, `managed-webapps.json`, `notif-state.json`, `notif-apps.json` | < 1 KB each | < 1 KB | bounded by user structure | OK. |
| `pending-installs.json` + `pending-icon-*.rgba` | absent when idle | absent | removed when nothing in flight; stale icon sidecars swept on save (code-verified) | OK — and the whole lifecycle was hardened today (#45–#47). |
| `apply-status.json` (config dir) | 2.0 KB | 103 B | one record, error tail capped at 4 KB by the helper (`tail -c 4000`) | OK. |

## C. Memory + speed (the "lightweight" ledger)

- **RSS: dev box 300 MB (debug build), ASUS 277 MB (release), ASUS peak
  328 MB.** The biggest polish gap, but NOT the dictionaries: `dict.rs`
  already lazy-loads, and the lean image ships no dictionary files at
  all (ASUS verified). Measured breakdown (pmap, ASUS): ~40 MB resident
  GL driver (LLVM+gallium, shared pages, unavoidable on the GL backend);
  ~90–100 MB anon heap = package index structs (2.2 MB TSV expanded),
  retained CPU icon copies at several sizes (kept for GL re-upload after
  `set_icons` — the #42-fragile area), glyph caches, wgpu staging,
  glibc arena retention from install-churn peaks. **Verdict: QUEUED —
  the "memory diet" phase, gated on a real heap profile
  (heaptrack/dhat on the ASUS)**; no blind refactors in renderer
  territory. (#51 in FINDINGS records the corrected investigation.)
- **Scan cost (ASUS, HDD): 7–19 ms scan + 30–150 ms icons**, ~2 s
  end-to-end retry cadence during installs; summon rescan behind a 30 s
  cooldown. Fine even on the weakest map machine.
- **Startup: "daemon up" < 1 s after exec on the ASUS**; index ready ~2 s.
  The heavy package index (23 673 packages) loads async and doesn't
  block first paint. OK.
- **Frame throttle** on GL/software (#40) keeps the loop responsive on
  old iGPUs — verified under strace on the ASUS.

## D. The install/launch pipeline (state machine)

Audited end-to-end 2026-09-09 across four live installs + one overlap
race + one already-present install; five root fixes landed and are
distro-permanent:

- **#45** applier: oneshot liveness misread (`is-active` = `activating`)
  → false-fail at 120 s → mid-build list revert (silent uninstall);
  foreign-run Done mis-attribution (`finished>=since` vs `started>=since`).
- **#46** stranded tile: apply "done" precedes the async home-manager
  activation that materializes the `.desktop`; the post-fill rescan was
  one-shot. Now re-arms every 2 s while unresolved.
- **#47** the fingerprint short-circuit returned before
  `resolve_pending_installs` — a scan landing in the busy/held window
  froze resolution forever. Now the unchanged path still resolves.
- **#48** installing an already-present app fabricated a phantom
  "Command-line tool" tile + poisoned `managed.json` (`gui:false`).
  Rescue-to-existing-app + a reconcile heal pass (verified relabeling
  brave/darktable/fritzing/chromium live).
- Measured post-fix latencies (ASUS): gimp 1.6 s, signal 1.5 s,
  spotify 2.0 s from Done to tile swap.

**Remaining known gaps (queued):**
- **#3 catalog dedup** — an installed app must not be OFFERED in the
  install section (upstream catalog fix; #48 made its fallout benign).
- **`is_installed` UX for CLI-only packages** — `xorg.xcalc` resolves
  `gui=false` (correct: no desktop file) but the user sees "nothing
  happened"; the CLI tile covers it only if the package is managed.
- **Uninstall path** — not yet dogfooded systematically on the ASUS
  (trash → `apply_uninstall` → revert-on-failure). NEXT dogfood target.

## E. The nix-shell / launch path (audited 2026-09-09 — SOUND)

- **Launch is properly detached**: double-fork + `setsid`, the
  intermediate child reaped immediately — launched apps survive daemon
  restarts, the daemon never accumulates zombies. Webapp launches
  self-heal a stale Chrome profile lock first.
- **Terminal dependency**: `Terminal=true` entries and CLI tiles run
  under the config's `terminal` (Golem ships `foot`, which is part of
  the SYSTEM closure — not uninstallable through the grid — so the
  dependency cannot be pulled out from under the tiles). An
  unresolvable command is warned before exec (`warn_if_unresolvable`).
- **Banner quoting**: every user-influenced string routes through
  `shell_quote` (test-covered); attrs are pre-validated to
  `[A-Za-z0-9._-]` by the applier's charset gate, so no quoting surface
  exists.
- **"Try it"** realizes on its own worker thread — a slow `nix build`
  never blocks an install or the loop.
- Accepted edge (recorded, not fixed): a launch that fails INSIDE the
  detached child (exec 127) dies into /dev/null — the journal warns
  beforehand when resolvable-checking can predict it, but the tile
  gives no visual failure feedback. Queued as UX polish; unreachable on
  a stock Golem (the terminal always exists).

## F. Corruption/crash drill matrix (status)

| scenario | behavior | status |
|---|---|---|
| daemon killed mid-install | restore re-arms; #37 drops if provably installed; wait rejoins or re-trips | VERIFIED live (multiple times, 2026-09-09) |
| machine rebooted mid-apply | stale `building` status detected via corrected liveness; nudge past corpse | VERIFIED (code) after #45; live corpse case seen 16:34 |
| corrupt JSON store | preserved as `.corrupt-<epoch>` + loud warn; store restarts clean | VERIFIED live (drill on the ASUS, 2026-09-09 19:48) |
| helper never triggers (no path unit) | honest fast-fail ("live medium" guard) | code-verified |
| build fails mid-switch (#44 class) | system-changed check treats user-activation-only failure as success; real failures revert list + restore last-good | VERIFIED live (fritzing) |
| disk full during write | write fails → warn + tmp removed; in-memory state intact | code-verified (unexercised) |
