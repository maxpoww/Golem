# FINDINGS — dock/menubox findings log

> Dated, append-only. Install-era findings carry their
> `~/Golem/Installer/preinstall/testing/changes.md` number. New findings
> found through THIS project continue the same number line so there is
> one sequence across the lab.

## 2026-09-09 — the install-pipeline day (pre-project, folded in)

- **#37/#40/#41/#42** — stale tile deadlock, GL frame throttle, seed
  permanence, GLES cubemap icons. Fixed + shipped (see FirstInstall.md).
- **#45** — applier read live oneshot builds as dead (`is-active` =
  `activating` → non-zero); foreign-run Done mis-attributed
  (`finished>=since`). False-failed installs at 120 s and reverted the
  list mid-build — the silent xcalc uninstall. Fixed `b2d59f9`.
- **#46** — finished tile stranded "Installing…": apply "done" precedes
  async home-manager activation; the post-fill rescan was one-shot.
  Re-arms every 2 s now. Fixed `bb76739`.
- **#47** — the scan-fingerprint short-circuit returned before
  `resolve_pending_installs`; a scan in the busy/held window froze
  resolution forever (the vlc 13-minute tile; #46's retries armed the
  trap). Fixed `1fa223f`.
- **#48** — installing an already-present app (chromium, the #3 catalog
  overlap) fabricated an icon-less phantom "Command-line tool" tile and
  poisoned `managed.json` gui flags (also brave/darktable/fritzing from
  past sessions). Rescue + heal pass. Fixed `ab44373`; heal verified
  relabeling all four live.
- Post-fix latencies on the ASUS: gimp 1.6 s, signal 1.5 s, spotify
  2.0 s (Done → tile swap).

## 2026-09-09 — project creation audit (the first full-stack pass)

- **#49 (NEW)** — persist reads a corrupt store as empty and the next
  write destroys it. Real-world precedent: the dev box's
  `apps-order.json.bak-20260903-shredded`. Fix: preserve as
  `<name>.corrupt-<date>` + loud log; harden tmp naming. → landing now.
- **#50 (NEW)** — notif history is unbounded by design AND its images
  are never swept (`store_image` writes; nothing deletes). Dev box:
  153 image files after months; year-5 model: thousands of files + a
  startup parse that grows forever. Fix: cap 500 cards + sweep
  unreferenced images on save. → landing now.
- **#51 (CORRECTED after measurement)** — the dictionary hypothesis was
  WRONG: `dict.rs` already lazy-loads on first panel open, and the lean
  image ships NO dictionary files (verified: none on the ASUS). The
  measured RSS story (ASUS, release build, 277 MB / peak 328 MB):
  ~40 MB resident GL driver libs (LLVM+gallium — unavoidable on the GL
  backend, shared pages), ~90–100 MB anon heap. Heap suspects with
  numbers: package index (2.2 MB TSV → per-String structs, est.
  10–20 MB), retained CPU copies of every app icon at multiple sizes
  (needed for GL re-upload after `set_icons` — est. 20–30 MB), glyph
  caches, wgpu staging, and glibc arena retention from the install-churn
  peak. **No lazy-load silver bullet exists; the next step is a real
  profile** (heaptrack/dhat on the ASUS daemon) before touching the
  renderer's icon lifecycle — that is #42-fragile territory. → QUEUED
  as the DockMenu "memory diet" phase, with the profile as its gate.
- **OPEN (queued)** — #3 catalog dedup (don't offer installed apps);
  webapp-chrome disk-cache bound; terminal-emulator assumption of the
  CLI tile path; uninstall-path dogfood; apps-order dead-id policy
  (watch via census).
