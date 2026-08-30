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
- [x] Cold-start test (scratch HOME/XDG, empty everything, live compositor):
      **clean** — default config, first-run recycle-bin created, apps
      indexed + icon caches built from nothing, real GPU adapter, ran 25s
      no crash; Hyprland-IPC fallback engaged exactly as designed. Full
      fresh-machine truth still comes from the S7 build-vm. (Known edge
      found, no fix needed: socket path has no SUN_LEN guard — only
      matters for absurdly long XDG_RUNTIME_DIRs, real ones are short.)
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

- [x] the box opening have a cut on the animation when opening, it gets stuck
      a 1/4 for a few ms. (dock box) → **fixed in b4f28ad, needs restart to
      take effect + your eyes to confirm**. Cause: every dock summon rescans
      the app index; an unchanged result still re-uploaded every icon + wiped
      the text cache = one long frame mid-open (dt motion turns a slow frame
      into a visible leap). Now skipped via fingerprint. Bonus: background
      rescans no longer cancel an in-flight drag.
- [ ] the focus after opening → **need one more line from Max**: focus of
      what, after opening what? (e.g. "typing after opening the box goes to
      the app behind" / "after closing the box the old window doesn't get
      focus back")(dock box) 

the focus after opening 

- [ ] One week daily driving with a notes file; every surprise → a fix or
      a filed line here
- [ ] Exit review: zero known brokenness → open S7
