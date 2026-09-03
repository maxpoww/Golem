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

<!-- Fresh agent 2026-09-03: items marked MAX-GATED or REAL-HW below are NOT
     yours — they need Max's hand or real hardware. Work the actionable ones;
     when they run out, extend per the loop rules (harden, test, profile,
     catalog). Note: launcher is now PUSHED to github and Golem's flake.lock
     pins it — after any launcher commit, an ISO only carries it once pushed
     and re-pinned; that push is MAX's call, never yours (local commits only). -->

- [x] 4e02463 Responsive shell, the LAST half — topbar pills scale on small
      screens. `App::options_bar_h()` (config height × options_scale) is now the
      single source for ALL bar geometry (drawn strip, pill layout, hover hits,
      input region, box anchors, colour-match rows), and `sync_options_zone()`
      re-sets the exclusive zone once the output's logical size is known
      (hooked into new/update/destroy output + the topbar configure). Pill text
      measures AND draws at FONT_PX × scale so widths always fit. The mapping is
      pure + unit-tested (options::pill_scale_for: 1.0 ≥900px, h/900 below,
      0.82 floor). CONFIRMED in golem-vm at 1280x800: Hyprland reports
      `reserved: 0 25 0 0` (28 × 800/900 → 25, re-reserved post-enumeration),
      pixel scan shows the bell pill ~20px in the 25px bar (19.9 expected),
      clock text fits its pill, the notif box opens anchored to the shrunk band
      (wrapped card laid out exactly), and the dynamic OPTION cluster renders at
      the scaled size (screenshots taken; ≥900px screens provably unchanged —
      scale is exactly 1.0 and the zone re-commit is skipped).
- [x] f61ac18 OPTIONS hardening pass E — the surfacing layer (1540fd1) earns
      its tests, and the edges found real bugs: wrapper flags/numbers made
      "nice -n 10 make" NOT-dev (fixed: flags, bare numbers, command/exec all
      skipped; edge-case test incl. gitk/"./git-hooks.sh"/degenerates);
      bystander cap pinned at EVERY activity (primary keeps its cluster,
      bystanders keep their best two in rank order, warnings/info never counted,
      Idle/Unknown cap nothing, fg-media owns the bar even while Coding);
      settle × cap: rank churn keeps the dwell, cap-squeeze restarts it. REAL
      FIX: the mind loop was purely change-driven, so an offer arriving just
      before a quiet spell stayed hidden past its dwell — Settle::next_deadline
      now arms a sleep_until beside the context stream. VM live-confirmed
      (bridge.sock fed as the zsh hook does, foot in a dirty repo):
      last_cmd=btop → Terminal, NO git controls (only the passive dirty
      Warning + branch Info); last_cmd="git status" → Coding, Commit all/Push/
      Pull/Review changes return and the cluster renders on the scaled bar.
      321 workspace tests green, clippy + rustfmt clean.
- [x] 1136e0c Catalog micro-cases — the 3 with real grounding, per the slice
      pattern (catalog §41-43): selection.define (copied single word → "Define
      word" above search; new `define:<word>` tag opens the dict panel seeded —
      CONFIRMED live in the VM end-to-end via options-trigger, screenshot);
      text.find (word processors → universal Ctrl+F through the live-confirmed
      find_in_page tag; by-construction); creative.undo (image/video editors →
      Ctrl+Z, the one universal chord; redo deliberately absent — divergent
      chords; by-construction). Unit tests for all three; 324 green.
      VM tip: the shipped waverunner-ctl predates options-trigger's two-word
      form — pass it as ONE quoted arg (`waverunner-ctl "options-trigger
      <id>"`); and the VM shares the host /nix/store, so a freshly built
      daemon runs in the guest via a systemd user override on its store path
      (no VM rebuild needed).

- [x] 8bfdbd9 Multi-output scale correctness — the scale-owner surface (topbar,
      else dock) tracks its REAL output via wl_surface enter/leave; enter on a
      different panel re-syncs the exclusive zone at that panel's size, leave
      falls back to first-output (enter-before-leave move ordering handled).
      Pure precedence fn (options::preferred_output_height) unit-tested both
      directions + fallbacks. Single-output CONFIRMED live in the VM (new build
      via the store-share override: zone still 25, no daemon errors — only the
      usual MESA vdrm noise); dual-head observation stays REAL-HW.
- [x] 784810f ctl usage + payload argv — usage renders from a new proto
      USAGE_VERBS table (one entry per Command); Display↔FromStr round-trips
      EVERY variant (exhaustive-match tripwire), and a coverage test makes the
      table and parser police each other, so stale help is a failing test.
      Client space-joins argv, so `options-trigger <id>` works unquoted —
      CONFIRMED live against the VM daemon (exit 0 + trigger logged).
- [x] d197c4b Hardening pass F — the Daemon-tag seam: daemon_tag_known() as a
      pure predicate beside the dispatch (fallback arm debug_asserts the
      inverse), and engine_daemon_tags_are_all_dispatchable drives the real
      `decide` over scenarios firing EVERY tag-emitting provider, asserting
      both directions (all emitted tags dispatchable; all expected tags
      actually emitted — a silenced scenario fails, not hollows). 327 green.

- [~] VM res-switch validation — BLOCKED in this VM: the lua-config Hyprland
      fork rejects `hyprctl keyword monitor` ("non-legacy parsers"), eval'd
      `hl.monitor` rules don't retro-apply to a connected output (tried, incl.
      reload), and wlr-randr isn't installed. What WAS live-confirmed instead:
      the output ADD/REMOVE event path (`hyprctl output create headless` +
      remove) — zone stable at 25 through both events, bar renders cleanly
      after churn (screenshot), zero daemon errors/warns. The mode-switch
      observable moves to REAL-HW (plug an external into the Air).
- [x] ef9a9c4 Scale-change × open-box — a LIVE zone change (not the initial
      sync) now collapses open clip/notif/media boxes via the same close paths
      clicks use (new force_collapse_notif mirrors the empty-box reset); every
      open path re-seeds at the live scale. By-construction (VM can't switch
      modes, see above); real-HW hotplug is the observable.

- [x] VM regression sweep DONE (2026-09-03, FRESH golem-vm rebuilt with
      launcher@ef9a9c4 baked — the old VM's 9p overlay had soured, see
      NOTES.md "golem-vm test-loop mechanics"): zone 25 on the baked build;
      new ctl usage table renders + two-argv options-trigger works from the
      PROFILE binary; selection chain cycles live (word → define above search,
      URL → "Open copied link"); define end-to-end opens the dict panel seeded
      "serendipity" (screenshot); notif box empty-state at scale beside
      bell+clock (screenshot); debug-hover-option clean; ZERO daemon
      errors/panics/unknown-daemon-action over the session's journal.
      (Battery pass G is engine-side unit-tested — no battery in the VM.)
- [x] ecf11a2 Hardening pass G — battery ladder: extracted pure alarm_for()
      (exact rung boundaries 11/10/7/5/0; charging clears EVERY rung incl. the
      lying-gauge "discharging 0% on AC"; no-battery calm) and sleep_decision()
      (BOOT_GRACE blocks suspend AND post-wake hibernate to the ms boundary;
      CRITICAL_STREAK blocks below threshold for both wake states; past the
      guards wake→hibernate always, awake→one suspend per episode via the
      armed latch; sub-Critical never sleeps). One deliberate improvement: a
      battery that VANISHES mid-episode now resets streak + re-arms (the old
      early-return left stale streak). 331 green.
- [x] 64be9ef iso-smoke static check 7 — the pinned waverunner must carry the
      battery boot-grace guards (BOOT_GRACE + CRITICAL_STREAK, via
      builtins.getFlake on the locked input); a repin to pre-92e97e6 fails the
      gate. Verified green against the current pin (7/7).
- [x] Idle re-profile DONE (2026-09-03, fresh VM, ef9a9c4-era build): engine
      aggregate 1.8 updates/sec (baseline 2.1 — no regression from the new
      providers or the settle deadline timer; the timer wakes the mind loop
      only while an offer is pending its 1.2 s dwell, then goes quiet). Daemon
      process CPU over 20 s idle: 30 jiffies = ~1.5% of a core — far below the
      old ~16% figure (that one was measured with a redraw-heavy
      transparent-bar/frost situation; with a matched stable bar the daemon
      only redraws on change). CONFIRMED, no action needed.
- [x] b5eb8cf Box-open lag, technical half (issues.md "laggy… like a break
      after"): instrumented permanently at debug level — open_clip_box logs
      its synchronous cost, tick_clip/tick_notif log any mid-animation frame
      gap >50 ms. MEASURED in the VM (llvmpipe, the worst case): open cost
      0.5-1.0 ms (incl. the hypr IPC + measure), ZERO frame gaps across 6
      open/close cycles. The open path is technically clean.
      FOR MAX (the feel half, your call): the numbers say the "break after"
      is the CURVE, not a stall — expand uses an exponential ease
      (MORPH_RATE 13/s: 95% of the height in ~230 ms, then a ~300 ms
      sub-pixel crawl to the cutoff), which visually "arrives then crawls".
      The detail/dict panels already use the other pattern (constant-duration
      linear + smoothstep, DETAIL_OPEN_SECS) and don't crawl — switching the
      expand to that pattern is a ~10-line change once you pick a duration.
      To SEE the numbers live: RUST_LOG=waverunner=debug and watch for
      "clip box open"/"frame gap" lines while opening boxes.
<!-- Queue extension 2026-09-03 (actionable items exhausted; per loop rules,
     extended from release-checklist.md + options-catalog.md follow-ups). -->
- [x] (Golem) flake check first-ever run: ALL GREEN; follow-up
      boot.zfs.forceImportRoot=false committed (the 26.11 default — no
      data-loss default left armed; warning gone, checks still pass).
- [x] 2026-09-03 ISO #3 CANDIDATE — built and FULLY gated (static 8/8 at
      build time + real qemu boot: `SMOKE greetd=active hypr=1 wr=1
      supp=active binsh=yes`):
      `/nix/store/fczpi2gdak3758knvxjw2dag16v11l3v-golem.iso`. Cut from a
      CLEAN tree at the "tick pass K" commit; carries this session's Golem
      fixes on top of ISO #2 — count-based rollback gc, the needle guard,
      golem.owner, zfs.forceImportRoot=false, source-rev identity
      (77a8c82-era). Launcher pin UNCHANGED (still 92e97e6) — daemon-side
      work after that stays MAX-GATED on the push+repin. Static check 9
      (owner chain) landed after this cut; it's in the tree for the next.
- [x] 2e74da9 Catalog slice 45: system.disk_full / system.empty_trash
      (§1.15's disk case) — statvfs sensor (df arithmetic, degenerate-safe),
      trash-non-empty gate, amber warning + Empty-trash Control via new
      daemon tag empty_trash (tested FreeDesktop trash + refilter). Tag in
      daemon_tag_known + pass-F coverage both ways. 363 green.
- [ ] Next VM session: induce/verify disk slice visually if convenient
      (needs a ≥90% disk — maybe a small tmpfs HOME trick), else remains
      by-construction on the proven Daemon-tag path.
- [x] 3bf3a83 Hardening pass K — drag edge-paging dwell clock (shared
      grid/box seam): bands+overshoot, arm-without-paging on entry, fire
      exactly on cooldown then re-arm, disarm on leave, direction-flip
      fires on the elapsed hold. Green.
- [x] waveview build regression check: `nix-build` at HEAD (93fa78c,
      v0.50) builds clean → /nix/store/g0ywiqihna3xmqdnr3fy047xq5hq3d3s.
      Tree clean, no action needed (float-leak watch stays armed, its
      verdict is Max's week of daily driving).
- [x] 508f77d i18n gap — OPTION tooltip titles (engine Strings) were the
      one user-visible text bypassing the tr() table; new tr_dyn routes
      them through (English literal = key, es.json ships them later like
      every daemon string). Tested; green, clippy clean.
- [x] a4a06c6 Hardening pass J — pins/usage persistence: pins.json format
      drift + corruption (object/legacy-array/excluded-ignored/no-pins/
      garbage → never panic, never invented pins), pin_at moves-not-dups +
      clamps, unpin-missing no-op, usage counts. 358 green.
- [x] 68ee698 Hardening pass I — jelly membrane liveness contract: worst
      poke settles <5 s (redraw liveness — is_active drives frames),
      impulses exactly-once across fragmented drains, crossed edge gets
      the main kick, pointer-warp kick clamped, snap PRESERVES pending
      (the contract frame.rs's !has_pending() guard depends on). 353
      green.
- [x] 985318b Needle guard (release-checklist §2.6 silent seam) — a missed
      hyprland.lua rewrite needle now FAILS EVAL (lib.assertMsg names it)
      instead of silently shipping a stranger's desktop without the overview.
      Verified both directions (golem config evals rewritten; a deliberately
      broken needle fails with the message).
- [x] e84839e Rollback retention (release-checklist §2.6 "which bites first")
      — CONFIRMED the 7d age-based gc bit first (deleted all non-current
      system generations on an 8-days-idle machine, leaving 15 dangling boot
      entries); FIXED count-based (nix-env --delete-generations +15 matching
      configurationLimit, then plain store gc; live-ISO-safe via '-' prefix).
      +15 semantics verified on a synthetic 20-gen profile against real
      nix-env. iso-smoke static check 8 gates the class; 8/8 green.
- [x] 0cbb49f Catalog micro-slice: selection.multi_path (§6 documented
      PARTIAL) — multi-file Copy (paths or file:// URIs, one per line) →
      "Open copied files" opens the deepest common parent folder;
      snippet-truncation-safe, component-bounded common dir, percent-decode
      (lossy/literal on bad input). Adjacent fix: a single copied file:///
      URI is now a path (was falling through to web search). Unit-tested
      both sides (catalog §44); LIVE VM confirm queued for the next batch.
      Workspace 336 green, clippy + fmt clean.
- [x] 2de7608 Hardening pass H — install resolution (issues.md P1 "does
      failure leave a cell stuck?" territory): the finished-install→app
      match was inlined 3× and its fuzzy relation had no length floor, so
      short nixpkgs attrs latched onto strangers ('go' ~ 'google-chrome',
      'R' ~ anything) — resolving AND uninstall-mapping the wrong app.
      Extracted pure ids_relate/attr_prefixes_id/resolve_hit (equality
      always; substring/prefix only at normalized length ≥3; claimed ids
      never reused; fuzzy only over newly-appeared apps), all sites share
      them; ring/shine curves bounded+monotonic under test. 348 green.
- [x] bd5468b golem.owner (release-checklist §2.2) — the five baked-in
      maxes (user/greetd/sudo/HM wiring, home layer, apply watch path, ISO
      live password, vm host) all derive from ONE option. Proven both ways:
      extendModules{owner="anna"} → no max user, greetd/sudo/home/ssh/
      flakeDir/apply-watch all anna; default owner attrs unchanged;
      iso-smoke 8/8. Installer rename = set one option.
- [x] VM batch DONE (2026-09-03, FRESH golem-vm baked with launcher@2de7608
      via --override-input, fresh qcow2 in the scratchpad): running daemon
      verified as the new build (binary carries the multi_path strings);
      selection.multi_path CONFIRMED live end-to-end — two copied paths →
      `options: 1 control(s) [selection.multi_path]` → trigger →
      `launching: xdg-open '/home/max/pics'` (the exact common folder), and
      the screenshot shows the folder pill + its "Open copied files" hover
      tooltip + the clip preview beside bell/clock; single file:// URI
      CONFIRMED → selection.open_path → xdg-open takes the URI form as-is;
      journal sweep ZERO warnings/panics/unknown-actions on the pass-H
      build. VM killed, port 2222 freed.
- [ ] MAX-GATED (release-checklist §1.2/§1.3/§3/§4): generation label/tags,
      distroId, the one version string + alpha marker, the rollback headline
      copy, the feedback channel pick. All explicitly reserved as Max's
      DECIDE items (configuration.nix:132-135 comment + checklist wording).
- [ ] MAX-GATED: launcher push + flake.lock re-pin. Golem's pin moved to
      92e97e6 (b052bcf) — everything after (responsive pills 4e02463, passes
      E/F/G, catalog micro-slices 1136e0c, multi-output 8bfdbd9, ctl 784810f,
      open-box collapse ef9a9c4, battery-ladder tests ecf11a2) is LOCAL-ONLY
      and reaches no ISO until Max pushes launcher and the pin moves again.

- [x] 2026-09-02 ISO #2 — `/nix/store/28a2lcqg25f93d75y31xjwa417vfh4w1-golem.iso`
      (`~/Golem/result`, gate green: static 6/6 + SMOKE all-green). Adds, on top
      of ISO #1: the frosted glass restored (blur passes 4 — the perf pass had
      deleted it, caught by Max on his first boot) and the OPTIONS surfacing
      fixes (launcher 1540fd1). Both were live-diagnosed on the 2013 Air.
- [ ] MAX-GATED: OPTIONS surfacing — judge ISO #2 on the Air: btop in ~/Golem must show NO
      git pills; a bar that no longer rewrites itself when the pointer grazes a
      window (follow_mouse = 2 + the new 1.2 s settle); "Review changes" only
      while actually coding. If the 1.2 s dwell feels sluggish for genuinely
      useful offers, that constant is the dial (`mind/settle.rs`).
- [ ] MAX-GATED (his machine): the Air pins its CPU at 799 MHz under full load (verified
      with the performance governor forced, 64 °C, on AC, no throttle events) —
      classic Mac stuck-BD-PROCHOT. An SMC reset is the fix. Any "feels slow"
      report from that machine must be checked against
      `/sys/devices/system/cpu/cpufreq/policy0/cpuinfo_avg_freq` FIRST, before
      blaming the shell.

- [x] 2026-09-02 ISO CUT — built, gated, and shippable:
      `/nix/store/mahw6g2fj21zag0602h4aidphbxa7hw3-golem.iso` (3.01 GiB, also
      at `~/Golem/result`). Max authorised the push, so launcher is public at
      9f23d80 and flake.lock moved 63af71b → 9f23d80 (77 commits): this image
      is the FIRST to carry the daemon-side work (OPTIONS engine, fullscreen
      screencopy pause, renderer/RAM fixes, uniform box scaling, the screencast
      self-suppression). Gate green on the exact image: static 6/6 +
      `SMOKE greetd=active hypr=1 wr=1 supp=active binsh=yes`.
      NOTE for whoever cuts the next one: the ISO carries its own flake source
      (`golemSrc = self`), so editing ANY tracked file changes the ISO hash —
      commit first, then build, then gate, then don't touch the tree.
- [ ] REAL-HW: Confirm the screencast fix on real hardware. The blink was diagnosed on
      the 2013 Air (18 `screencast>>1/0` toggles in 8 s from our own 700 ms
      colour-match) and fixed in 9f23d80, but never seen fixed live: the VM
      can't reproduce it (its colour-match never engages under llvmpipe, so
      there are no captures to suppress). Boot this ISO on the Air and watch
      the bar: the warning pill must never appear on an idle desktop, and must
      still appear for a REAL share.
- [ ] MAX-GATED (design WITH him, do not build): Dynamic OPTION pills appear/disappear with no animation at all
      (`options.rs:770-800` places them at fixed x with no progress value), so
      every engine change is a hard cut and the neighbours jump. Max, 2026-09-02:
      the old animation rules are considered LOST — do not try to reconstruct
      them; treat this as a fresh design decision WITH him before building.

- [x] VM BATCH DONE (2026-09-02, golem-vm at 1280x800 → options_scale 0.889;
      VM built with `--override-input waverunner git+file:///home/max/launcher`
      and the running daemon verified as the build carrying both changes):
      (a) media box uniform scale (654b88d) — CONFIRMED. Box drew 320x114
          (360x128 × 0.889), title/transport/tracks/time all proportionally
          smaller, everything inside the panel, no clipping.
      (b) notif box uniform scale (b4ee500) — CONFIRMED. Box drew ~338 wide
          (380 × 0.889) with three cards; identity tiles ~35px (40 × 0.889),
          the smaller body font wraps inside the card (the 3-line "Ana" card
          laid out exactly), zebra row, right-aligned timestamps and the
          footer ✕ all correct. Bell pill and clock unchanged beside it —
          the pill/box split holds.
      Recipe for the next batch (saves an hour): boot headless with
      `QEMU_OPTS="-display egl-headless"` (no GTK window on Max's session,
      GL still works); ssh -p 2222 max@127.0.0.1; the box-open verbs are
      `waverunner-ctl debug-notif` / `debug-media-box`, and the box
      auto-collapses after ~1.5 s so grim must fire ~0.7 s after the verb.
      No notify-send in the VM — use dbus-send to org.freedesktop.
      Notifications.Notify. No MPRIS from mpv (no mpris script) — VLC
      (`vlc --intf dummy --no-video --repeat <file>`) does publish MPRIS, and
      it needs a REAL finite file (av://lavfi stops instantly, length -1);
      generate one on the host with ffmpeg and scp it in. Never `pkill -f`
      a pattern that also matches the ssh command line — it kills your own
      remote shell.
- [x] 654b88d Responsive shell, media box — the third dropdown box now scales
      uniformly (footprint + pads + transport + tracks + fonts) like the
      clipboard box (ddde8f0). Draw and hit-test share the same geometry fns,
      now free fns taking the scale (seek_track_at/vol_track_at/
      transport_btns_at), so the desync class is closed by construction and
      unit-testable; test asserts offsets/sizes scale by exactly the box factor,
      nothing interactive escapes the panel, and scale 1.0 == the original
      constants. CONFIRMED in the VM — see the VM BATCH item above.
- [x] b4ee500 Responsive shell, notif box — Max's call (2026-09-02) on the
      style question the last pass flagged: UNIFORM EVERYWHERE. The notif box
      no longer scales footprint-only; a `BoxMetrics` struct carries every box
      dimension incl. font/line size, the raw consts are gone from the module
      (so a missed site is a compile error, not shipped overflowing text), and
      each of ~110 sites was classified box (scales) vs topbar pill (does not:
      bell, +N chip, collapsed preview line). The top card lerps between the
      two sizes as it morphs out of the preview band (`TextPx`). All three
      dropdown boxes now scale the same way. CONFIRMED in the VM.
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
- [ ] REAL-HW: FULLSCREEN PERF (b), follow-up: truly hide the topbar (and dock) layers
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
- [~] RAM: profiled post arena+lazy (NOTES.md). CPU icon copy already freed
      after GPU upload (no retention leak). Next block is the GPU icon texture
      array — both levers are tradeoff/risky: lower ICON_SIZE 256→192 (~-26 MB,
      visual-quality tradeoff, deferred per "don't over-invest") or lazy-allocate
      the ~97-layer reserved search tail (~33 MB, needs array realloc+re-upload
      mid-search, unvalidatable in VM llvmpipe). No clean ≥10 MB win this pass.
      Follow-up: the reserved-tail lazy allocation, validated on real hardware.
- [x] ddde8f0 Responsive shell, uniform box scale — DONE for the clipboard box
      (the notif box already scaled). Threaded `scale` through the measure fns
      (clip_text_col_w/row_height_of/clip_row_lines) and push_clip_row's draw in
      lockstep; the desync class is closed because wrap_text is LINEAR in
      font_px — scaling width and font by the same factor yields identical line
      breaks, so measured heights always equal drawn text. ClipState ctor
      measures provisionally at 1.0; open_clip_box re-measures at the live
      scale. CONFIRMED in the VM (800px logical → scale 0.889): box opened at
      box_h=251 with a 4-line wrapped row laid out exactly — no clipping or
      overflow (screenshot); zebra/timestamps/footer intact. Scale 1.0 reduces
      algebraically to the original, so full-size screens provably unchanged.
      Detail/dict panels left unscaled (self-consistent draw+hit geometry —
      no desync possible); scale them later only if they visually dominate.

- [x] iso-smoke — PASSED (2026-09-02, coordinator's fresh ISO
      /nix/store/2dcvbqhk4l5wawnm4z44wkq0lfmqydhj-golem.iso, which DOES carry
      this session's daemon: closure contains waverunner cycnsjq… whose binary
      has install_missing/pkgsearch/reopen_tab/battery_dim/high_mem strings —
      i.e. the fullscreen-fix-era build; my earlier "predates the session" note
      was wrong). Static checks: all 6 green (configs eval, hyprland.lua parses,
      /bin/sh tmpfiles, wpa_supplicant, greetd+oomd, monitor catch-all). Boot
      check (replicated the script's qemu invocation headless against the given
      ISO — the script itself would have rebuilt the ISO since my Golem commits
      changed the flake source, and would have popped a GTK window):
      **SMOKE greetd=active hypr=1 wr=1 supp=active binsh=yes** — all five
      assertions green. Notes: serial socket path must be short (<108 bytes,
      use /run/user/1000); boot needs >150 s before the serial shell responds
      (nixos@Golem autologin appears on ttyS0); with `server,nowait` early boot
      output is dropped, so probe by holding the connection and sending the
      command, reading for ~8 s.
- [x] 2b2a494 Pill tooltips (discoverability): hover a dynamic OPTION pill →
      the offer's title in a small rounded label just below the bar (reuses the
      Label/rect rendering; per-char-estimated background, text shapes exactly at
      render; suppressed while the media box is open). Added a debug-hover-option
      IPC verb (no headless cursor warp on this compositor). CONFIRMED in the
      golem-vm: hovering the screencast pill shows "Screen is being shared". No
      layout regression (renders in the transparent region under the bar).
- [x] c3a3800+5bab023 Catalog expansion — the 3 highest-value unserved cases
      grounded → spec'd → BUILT (plus the earlier batch: reading-title fallback,
      slides.present, downloads/battery-dim/high-mem/reopen-tab/install-missing):
      1. network.down/settings (§1.15 "reconnect wifi") — sysfs operstate sensor
         + nmtui remedy. Unit-tested; live-inducing needs root (documented).
      2. reading.page_next/prev (§1.11) — PageDown/PageUp keystrokes for
         readers. Confirmed-by-construction (send_shortcut path).
      3. window.record/record_stop (§1.10) — wf-recorder pair with a new
         is_recording /proc sensor; wf-recorder added to Golem home pkgs
         (862b173). CONFIRMED live in the VM: pair flips both ways, stop ranks
         first while recording, stays reachable after leaving fullscreen.
      Remaining §1 gaps are micro-cases (image/video-editor internals) or
      bridge-blocked — documented in the catalog.
- [~] iso-smoke (DEFERRED, see below) — run against the current ISO build when the VM
      slot is free; record the result in the commit/catalog.

- [x] Notif box scale — RESOLVED as already-consistent-by-design, no code
      change. Reading notif.rs:814-817: the box deliberately shrinks only its
      FOOTPRINT (EXTENDED_W × options_scale feeds both measure and draw) while
      "the internal pads/icon/font stay full size so text stays legible" — a
      documented legibility decision, internally desync-free. The clipboard box
      (ddde8f0) now scales uniformly (fonts too, 17→15.1px at 0.889 — still
      legible). Two defensible answers to the same question; forcing the notif
      box to (b) against its in-code rationale is churn. FOR MAX: pick one
      style — if uniform wins, apply ddde8f0's pattern to notif (wrap there
      uses a measure closure: scale the measured AND drawn font together).
- [x] Idle-wakeup profile — DONE + documented (NOTES.md), no code change
      warranted. Measured in the golem-vm: engine aggregate = 2.1 updates/sec
      (new `options-engine` example `genrate` measures it via the generation
      counter); the options-brain thread shows a high WAKEUP count (~350/s park/
      unpark from tokio current-thread timers + llvmpipe workers) but only ~6
      jiffies/8s = ~0.75% of one core — the wakeups are cheap, not a CPU cost.
      The daemon's ~16% of-a-core idle in the VM is dominated by the llvmpipe
      RENDER threads re-rasterizing the 700ms screencopy colour-match in
      software — VM-specific (near-free on a real GPU; and already PAUSED during
      fullscreen by 3efd1ee). No cheap coalescing win on the brain; widening the
      idle colour-match poll would trade the safety-net responsiveness the
      screencopy design defends. Real-HW idle profiling is the meaningful
      follow-up (llvmpipe hides the true picture).
- NOTE (2026-09-02): ab8ccaf (reject CPU adapters) verified in the VM: rejects
  llvmpipe via the gpu path, attempts GL (guest exposes no wgpu-usable GL
  surface → "no surface via gl only"), falls back to software with an honest
  log, no crash-loop. The real-GPU win applies on hardware.

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
