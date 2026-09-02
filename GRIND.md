# GRIND.md — the autonomous work loop's queue and rules

This file IS the agent's mandate. A resume message may be as short as
"continue per GRIND.md" — everything needed is here. The repo, not the
agent's transcript, is the memory: knowledge worth keeping goes into
commits, options-catalog.md, or this file.

## The loop (non-negotiable)

1. Take the topmost unfinished item from the QUEUE below.
2. Build it COMPLETELY (for OPTIONS slices: sensed → pill → action performs).
3. Validate: batch 3–4 items per golem-vm session — do NOT boot/tear a VM
   per item. Screenshot surfaced UI. `cargo test --workspace` stays green.
4. Commit (repo-local only), tick the item here with the commit hash,
   update options-catalog.md if it's a slice.
5. IMMEDIATELY take the next item. **Never declare "done". Never stop to
   write a summary.** There is always a next item; if the queue empties,
   ADD items (harden, test, profile, extend the catalog) and continue.
   The ONLY legitimate stop is the token budget dying mid-work.

## Guardrails (non-negotiable)

- Local git commits only. No push, no deploy, nothing leaves this machine.
- NEVER `nixos-rebuild switch/boot/test` on any machine; never touch the
  dev host's running config. VM validation only (unless a test machine is
  explicitly online).
- No destructive auto-actions in OPTIONS offers (reboot/switch stay
  designed-only).
- qemu VMs: `-device virtio-vga-gl -display gtk,gl=on`; keep ONE VM up and
  reuse it across a batch; tear it down when switching tasks; watch host
  `free -m`.
- Verify against real behavior; mark CONFIRMED vs SUSPECTED honestly.
- The topbar renderer is delicate: visual changes there need a screenshot
  diff before commit.

## QUEUE (top = next; tick with `[x] <hash>`)

- [x] dc117ab Hardening+tests pass A: git module (commit/push/pull/diff/remote)
      — matcher unit tests (diff pipeline, open-remote URL, dirty warning),
      edge cases (detached HEAD→silent, no upstream→still commit/push/pull but
      no open-remote), reactive clear outside a repo. Note: a *bare* repo has no
      worktree so the collector reports no branch/dirty → same silent path as
      detached (covered). Also added a focus-churn behavioral-cue test.
- [x] d1de501 Hardening+tests pass B: media. no-MPRIS reactive clear, fmt_time
      + hit_band unit tests, length-0 streams (already covered), two-player
      pick_best (already covered), player-vanishes-mid-drag safe by construction
      (media_drag_commit filters length>0 through the Option, no panic).
- [x] bd28b01 Hardening+tests pass C: selection/clipboard. Bounded classify to
      the SNIPPET_CAP snippet (huge paste no longer scans MBs per change),
      looks_like_path length-guard-first (O(1) on huge), non-UTF8 via
      from_utf8_lossy (tested with U+FFFD), rapid changes coalesce via the watch
      channel by construction. Downloads partial/0-byte/hidden already covered
      (e52737e); ~1000-files is a bounded readdir+stat sweep, correctness fine.
- [x] 13ebcd3 Hardening+tests pass D: bridges. Malformed/unknown/wrong-type
      input rejected (Err→log+ignore, never panics; tested). Daemon-restart
      resilience by construction: server removes stale socket + rebinds; both
      clients (zsh [[ -S ]]||return+zsocket||return; nvim fs_stat+pcall+connect-
      err) silently no-op when the daemon is down and reconnect on next event.
- Batch VM session (2026-09-02): shell.install_missing CONFIRMED end-to-end —
  shell exit-127 `cowsay hi` in a focused foot terminal surfaced the "Install
  cowsay?" pill; triggering it opened the launcher with the nixpkgs search
  pre-filled (cowsay + neo-cowsay/xcowsay/kittysay/…). Live-caught + fixed a real
  bug: pkg_search_for used Expand (no-op from Hidden) → now Toggle (fdcd88c).
  (VM tip: hyprctl over SSH needs HYPRLAND_INSTANCE_SIGNATURE=$(ls -t
  /run/user/1000/hypr/|head -1); this Hyprland fork uses lua dispatch so
  `hyprctl dispatch exec` errors — launch GUI clients directly as wayland
  clients (setsid foot) instead. Never use `read </dev/zero` to sleep — it
  buffers endless nulls and hangs the SSH command.)
- [~] 3efd1ee FULLSCREEN PERF (partial — screencopy pause DONE+CONFIRMED; layer
      unmap deferred). (a) PAUSE the topbar screencopy colour-match during
      fullscreen — DONE. CONFIRMED in golem-vm: directScanoutBlockedBy loses
      "RECORD" on fullscreen-enter, regains it on exit, across clean cycles;
      topbar stays mapped + renders correctly before/after. This removes the
      dominant per-frame waverunner cost (the 700ms wlr-screencopy GPU readback
      + colour histogram). (b) UNMAP the topbar layer to also clear the solitary
      "OVERLAYS" blocker — NOT done: intractable with the wgpu-backed surface. A
      null-buffer commit doesn't cleanly remap via wgpu present (bar stays blank
      after exit); destroying the LayerSurface wedges the wayland/brain event
      flow (brain updates stop, bar never returns). The dock layer also blocks
      solitary regardless. Direct-scanout can't even engage in the VM (inherent
      "SW"/llvmpipe blocker), so (b) needs real-hardware work. See follow-up.
- [ ] FULLSCREEN PERF (b), follow-up: truly hide the topbar (and dock) layers
      during fullscreen so Hyprland grants solitary/direct-scanout. Needs a
      wgpu-compatible unmap: likely drop+recreate BOTH the LayerSurface AND its
      wgpu Renderer together (the event-loop wedge came from dropping the layer
      while the renderer/handlers still referenced its surface), or a
      set_size(0,0)/exclusive-zone approach, or render the bar into the DOCK's
      surface instead of a separate overlay. Validate on real hardware (Intel
      GPU, no SW blocker): hyprctl monitors solitary must engage, waverunner CPU
      ~0% during fullscreen video. Reversible: abandon if it regresses the bar.
- [x] 521998e Browser bridge — assessed + BLOCKED under guardrails (extension
      needs a store upload / can't reach --app webapps; CDP needs a security-
      exposing debug port; video-tab already covered by MPRIS). Documented in
      options-catalog.md. Built the pragmatic fallback: infer Reading from the
      browser window title (docs markers) → reading offers, no bridge. A real
      active-tab-URL signal waits on a packaged extension (out of scope here).
- [ ] RAM: continue profiling in the VM (post arena-cap + lazy-index);
      identify next-biggest resident block (icon/texture buffers?);
      take any win ≥ 10 MB with before→after VmRSS in the commit.
- [ ] Responsive shell, uniform box scale: notif + clipboard boxes scale
      font AND chrome together via options_scale() (see memory of the
      2026-09-02 attempt: measure/draw must use the same scaled values —
      thread scale through clip_text_col_w/row_height_of AND the draw
      path together). Screenshot-verify at 1366x768 in the VM.
- [ ] Pill tooltips (discoverability): hover shows the offer's title.
      Delicate renderer — screenshot before/after; abandon cleanly if it
      regresses layout rather than forcing it.
- [ ] Catalog expansion: pick the 3 highest-value unserved use-cases from
      options-catalog.md §gaps, ground → spec → build if sensable.
- [ ] iso-smoke `--boot` run against the current ISO build when the VM
      slot is free; record the result in the commit/catalog.

## Done (this file's history is the progress log)

- Session 2026-09-02 (before GRIND.md existed), all local commits in launcher
  unless noted:
  - RAM: glibc arena cap + lazy-loaded pkg index (gated on launcher-open).
    Idle VmRSS 420→326 MB, anon 170→97 MB, CONFIRMED in golem-vm. Finding +
    RSS breakdown in NOTES.md (Golem): the residual Golem-vs-GNOME gap is
    session daemons (easyeffects ~135 MB etc.), not waverunner core.
  - Slices: downloads.open + downloads.extract (new collector; CONFIRMED live
    in VM — dropped a .zip, both pills surfaced), system.battery_dim (laptop
    critical-battery remedy), system.high_mem (monitor), browser.reopen_tab,
    shell.install_missing (fb35a00 — command-not-found → open Install search
    pre-filled via new pkgsearch:<name> daemon action). Downloads 0-byte
    edge-case hardening (e52737e).
