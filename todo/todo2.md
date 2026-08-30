# todo2 — S2 The Spine (Brain ↔ Body) — pulled into Arc 1 by Max 2026-08-29

- [x] Read the engine API + the daemon's tokio seam; bridge design written
      (it lives as `brain.rs`'s module doc — the half-page)
- [x] First affordance picked: the topbar window pill (visible, low-risk)
- [x] `options-engine` added to daemon Cargo.toml
- [x] Bridge: "options-brain" thread (current-thread tokio rt) → engine
      `watch` snapshots → calloop channel → `App::on_brain` (`brain.rs`)
- [x] First light achieved + logged: engine streams into the event loop
- [x] Window pill driven from the Brain: title/address/class/fullscreen
      from `ContextState.window` (engine gained `ActiveWindow.address` so
      consumers can act on the window — Close pill needs it)
- [x] Duplicate sensing removed *from the healthy path*: the two blocking
      hyprctl round-trips per hypr event are gone; the poll survives ONLY
      as the degrade path (below)
- [x] Health/degrade: compositor layer dark → pill falls back to direct
      poll; verified live (the ~2s collector warm-up runs on fallback,
      then logs "compositor layer alive — window pill is engine-driven")
- [ ] Max's eyes + a day of daily use: the pill should behave *identically*
      (this was a re-plumbing) — watch for stale titles or fullscreen
      hide/reveal misbehavior
- [ ] Then: mark window-pills "sensed+shown via Brain" in optionsmodules.md
      (full module DoD needs the Mind/OptionSet layer — that's S3's work)

**S2 exit:** one surface engine-driven end to end on the live session —
achieved 2026-08-30 00:45 (pending Max's daily-use confirmation).
Unblocked: W-A (the phone collector now has a bridge to ride).
