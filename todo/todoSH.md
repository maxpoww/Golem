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

- [ ] **F1 — Ship the daemon's own tools.** flake `runtimeTools` only has
      ffmpegthumbnailer + poppler-utils, but the daemon shells out to
      **wl-paste/wl-copy** (clipboard core!), **grim**, **curl**. On a
      foreign machine the clipboard OPTION is silently dead (watch loop
      quietly retries every 3s forever). Fix: add wl-clipboard, grim,
      curl to runtimeTools. Small, high value.
- [ ] **F2 — Webapps hard-require `google-chrome-stable`** (unfree, never
      declared). Fresh machine: clicking any webapp does nothing, silently.
      Fix: resolve browser at runtime (google-chrome-stable → chromium,
      flags are compatible) and ship chromium in the S7 flake; log when
      neither exists.
- [ ] **F3 — Launches fail silently by design** (detached double-fork).
      Missing binary = nothing happens, no feedback. Arc-1 minimum: trace
      it; nicer: surface a notification on spawn failure.
- [ ] **F4 — Glyph font is a foreign-machine risk.** Pill/footer glyphs are
      Nerd-Font private-use codepoints; without the exact font installed
      they render as tofu. Verify which font glyphon resolves and pin it in
      the S7 flake defaults (note for todo7).
- [ ] **F5 — Dictionary both-files-missing state.** Each language degrades
      gracefully (NotFound → language absent), but verify the panel shows
      a friendly message when NO data loads (only reachable if the package
      is misbuilt — low priority, one verify-ui check).

## Max's list (visual / feel)

- (add here, one line each)

- [ ] One week daily driving with a notes file; every surprise → a fix or
      a filed line here
- [ ] Exit review: zero known brokenness → open S7
