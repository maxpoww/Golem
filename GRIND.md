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
- [ ] Hardening+tests pass B: media (pill, box, sliders, MPRIS edge cases:
      player vanishes mid-drag, two players, no MPRIS).
- [ ] Hardening+tests pass C: selection/clipboard slices (huge clipboard,
      non-UTF8, rapid changes) + downloads watcher (partial files, ~1000
      files in ~/Downloads).
- [ ] Hardening+tests pass D: bridges (zsh + nvim) — daemon restarts while
      bridge connected, malformed bridge input never panics the daemon.
- [ ] Browser bridge (the last big collector): a minimal extension or CDP
      probe reporting active-tab URL + video-playing to the Brain; wire one
      new offer off it. If infeasible without a store upload, document why
      in options-catalog.md and build the best CDP fallback.
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
