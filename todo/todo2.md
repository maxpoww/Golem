# todo2 — S2 The Spine (Brain ↔ Body) — ARC 2 (after the ISO)

- [ ] Read the engine's `Engine::start()` / `subscribe()` API and the
      daemon's existing tokio seam (zbus notif path) — write a half-page
      bridge design before coding
- [ ] Pick the first affordance: topbar pills vs intellihide (recommend
      pills — visible, low-risk)
- [ ] Add `options-engine` to daemon `Cargo.toml`
- [ ] Bridge: engine `watch` snapshots → calloop channel into the event loop
- [ ] First light: log the incoming `ContextState` / `OptionSet`, render
      nothing yet
- [ ] Drive the chosen surface from the `OptionSet`
- [ ] Delete the daemon-side duplicate sensing it replaces
- [ ] Health/degrade path: engine dead → surface falls back gracefully
- [ ] verify-ui + a session of daily use before calling it done
- [ ] Check the module off in `optionsmodules.md` (first one!)
