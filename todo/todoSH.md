# todoSH — SH Harden what exists (Arc 1, current section)

<!-- The "working perfectly" pass. Freeze rule: fix, don't grow. -->

## Audits

- [ ] Max's bug inventory (visual/feel eye): every glitch/annoyance in the
      live surfaces, one line each, below under "Max's list"
- [x] Foreign-hardware audit — clean: no /home/max outside tests, no
      hardcoded monitors/resolutions/scales in the daemon, hostname read
      dynamically; unwrap/expect discipline holds (6 non-test uses, all
      justified thread-spawn/invariants)
- [x] Graceful-degradation sweep — nothing crashes when deps are absent,
      but see findings F1/F2: "graceful" sometimes means "silently dead"
- [x] Error-path audit — launch/watch/unfurl/dict all fail soft; install
      worker failure UX (5s "Failed" flash) was verified back in P4.6
- [ ] Cold-start test on a truly fresh user → defer to the S7 build-vm
      (the VM *is* the clean machine; persist.rs auto-creates its dirs,
      so expectations are good)
- [ ] Multi-resolution/scale check (1080p scale 1, HiDPI scale 2) — needs
      eyes + hardware; pairs with Max's visual pass

## Findings → fixes (Claude's queue)

- [x] **F1 — Ship the daemon's own tools.** ✅ fixed (commit 4519663):
      wl-clipboard/grim/curl added to flake runtimeTools; first clipboard
      watch failure now warns instead of debug-logging.
- [x] **F2 — Webapp browser fallback.** ✅ fixed (4519663): browser resolved
      at runtime google-chrome-stable → chromium → chromium-browser, warns
      when none. S7 still must SHIP chromium (noted in todo7).
- [x] **F3 — Silent launch failures.** ✅ fixed (4519663): a launch whose
      first token isn't on PATH warns before the double-fork swallows the
      127. (Notification-on-failure = Arc-2 polish, parked.)
- [x] **F4 — Glyph font risk verified real:** renderer uses
      `FontSystem::new()` = system fonts only; a machine without the Nerd
      Font shows tofu pills. Fix belongs in the S7 flake (font pinning) —
      task added to todo7.
- [x] **F5 — Dictionary no-data state exists in code** ("Dictionary data
      not installed." + loading state). Resolved by inspection.

## Max's list (visual / feel)

- (add here, one line each)

- [ ] One week daily driving with a notes file; every surprise → a fix or
      a filed line here
- [ ] Exit review: zero known brokenness → open S7
