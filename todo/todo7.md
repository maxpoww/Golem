# todo7 — S7 The Golem system flake

<!-- Coarse on purpose — break down on entry. -->

- [x] New repo (or `golem/` in the site repo?): the distro flake
      → Max's call 2026-08-30: the flake lives at the ROOT of ~/Golem (the
      plan repo doubles as the distribution) and pushes to the public
      github.com/maxpoww/Golem. `github:maxpoww/Golem` is directly buildable.
- [x] Compose: custom Hyprland 0.55.4 (+ Lua API) as a flake input/output
      → via the pinned nixpkgs input (exact live channel rev 21ea275a), same
      programs.hyprland the machine runs today; repin deliberately on bumps.
- [x] Compose: waverunner + options-notify + dictionaries + waverunner-apply
      → waverunner flake input: daemon (dictionaries wrapped in) + ctl via
      its homeManagerModules.default (systemd user service replaces the
      hyprland.lua waverunner-dev exec — no more debug builds on PATH);
      options-notify via its nixosModule; waverunner-apply REWRITTEN for the
      flake world (generates system/home/waverunner-packages.nix INSIDE the
      repo + git add — flakes can't see untracked files — and rebuilds with
      --flake; gated on golem.flakeDir, off in the VM; autoUpgrade dropped:
      flake upgrade = input bump, story TBD).
- [ ] Compose: `golem-apps.nix` (from S5)
- [x] Golem defaults: theming, fonts, hyprland.lua, session startup
      → home.nix/zsh/foot/nvim/yazi/webapp icons ported verbatim;
      hyprland.lua's three /home/max assumptions rewritten at build time
      (waveview .so from store path, waverunner via systemd, ctl from PATH).
      CAVEAT until cutover: hyprland.lua now exists in BOTH /etc/nixos and
      the flake — edits must land in both or they drift.
- [ ] Stopgap kit: curated plain GUIs for network/audio/bluetooth (each
      dies when its S4 module ships in Arc 2)
      → started: pavucontrol + networkmanagerapplet in systemPackages,
      blueman already shipped; audit what else a stranger needs (wifi
      first-connect flow!) before ticking.
- [x] Ship chromium (webapp engine fallback — SH F2 resolves it at runtime,
      the flake must make it exist)
      → google-chrome ships via home.nix programs.chromium (unfree on), so
      F2's first-choice browser exists on every Golem machine.
- [x] Pin fonts: the UI font + the Nerd Font the glyphs need (SH F4 —
      renderer loads system fonts only; without them, tofu pills). Also set
      the fontconfig default sans to the chosen font (SH F7: the daemon
      requests generic sans-serif; today that aliases to a missing Noto
      Sans → silent DejaVu fallback, i.e. the UI font is currently
      accidental)
      → flake ships JetBrains Mono + its Nerd Font + dejavu_fonts, and pins
      fontconfig default sans to "DejaVu Sans" — today's accidental look
      made deliberate, zero visual change. Choosing Golem's REAL UI font
      stays open as a design call (Max + mockup, per project law).
- [ ] Ship `~/notification-fix` (Chrome ext: FB/Messenger/IG notifications
      on Wayland — no occlusion tracking) with the webapp profile via
      `--load-extension`; it lives ONLY in Max's homedir today — get it
      into a repo first
- [x] User/home layer (home-manager module wired in)
      → home-manager flake input (release-26.05, follows nixpkgs) as a
      NixOS module, useGlobalPkgs; home-manager.users.max = system/home/.
- [x] `nixos-rebuild build-vm` target — one command → Golem VM (this becomes
      the daily test loop for S8/S9)
      → `nixos-rebuild build-vm --flake .#golem-vm && ./result/bin/run-Golem-vm`
      hosts/vm.nix: no nvidia, virtio-vga-gl, 4G/4 cores, greetd autologs
      max into Hyprland, initialPassword golem. BUILDS clean (2026-08-30);
      first graphical boot still needs eyes.
- [x] Pin + document every input; the flake IS the distribution
      → DONE 2026-08-30 (Max: public): maxpoww/launcher flipped
      public + pushed to head, maxpoww/waveview created public. Both
      inputs repinned github:maxpoww/* (same revs, same narHash — zero
      rebuild); nixpkgs + home-manager were already GitHub pins. The
      flake is now buildable by ANY machine. Dev loop against local
      checkouts: `--override-input waverunner ~/launcher`.

- [x] **Ship a prebuilt package index with the flake** (from Round 2's VM
      crash-loop): waverunner's cold start builds its package index with
      `nix search nixpkgs ^ --json` (~3GB eval) + a `nix shell
      nixpkgs#nix-index` icon sweep — on a 4G machine the OOM killer took
      the whole service cgroup down and systemd respawned it: an INFINITE
      cold-start crash-loop on small hardware (5 daemon starts in 7 min,
      Chrome died as collateral). Invisible on the 32G host; the VM's first
      catch.
      → DONE (launcher `0fdafa7`, Round 5 below): the launcher flake
      builds the index as a derivation from its own pinned nixpkgs
      (nix-env eval → jq → new `waverunner build-index` CLI mode reusing
      the exact parse/filter/save path — 23.9k packages, v5 TSV). HM
      module wires WAVERUNNER_PKG_INDEX; when set it is AUTHORITATIVE
      (no runtime dump ever — a fresh dump could only diverge from the
      pinned system). nix-locate now runs from PATH (nix-index in
      runtimeTools), killing the second 3GB eval; env unset = old dev
      behavior. Icon hints are runtime-lazy (flathub/store fetchers);
      build-time hints via a nix-index-database input = possible later.
      VERIFIED: fresh-disk cold boot loads 23661 packages (prebuilt) in
      ~2s, 0 OOM; the afternoon's 4G repro config re-run — 0 OOM, ONE
      daemon start, desktop in ~1GB. 4G machines run Golem now.
- [ ] VM loop friction: host Hyprland swallows Super before QEMU sees it,
      so Golem binds can't be exercised in the VM from the host desktop.
      Idea: a host "VM mode" (submap that releases all binds + escape key).
- [x] **F9 — "already in package list; treating as installed" is a lie
      while the rebuild runs.** The applier equates list-presence with
      installed; if the entry is mid-apply (status phase "building"),
      the pending install completes instantly, no GUI app exists yet,
      and the resolver falls through to the CLI-tile fallback — brave
      and gimp presented as terminals printing "is ready". Must consult
      apply-status.json (building = still pending). Launcher-repo.
- [x] **F11 — the daemon clobbers packages.list at startup** ("seeding
      declarative package list with 0 attrs"): on start it REWRITES the
      list from its own managed state — on a fresh machine that's empty,
      so (a) any external/manual entries are silently destroyed (the
      apply security model explicitly calls the list "the ONLY
      user-writable surface" — the daemon treats it as a private cache),
      and (b) the rewrite itself triggers a pointless first-boot apply
      run: 8 minutes of input downloads + eval to rebuild an unchanged
      system, with every real install queueing behind it into F10's
      false failures. The list on disk must be the source of truth the
      daemon ADOPTS, not a mirror it overwrites. Launcher-repo.
- [x] **F10 — a queued install is not a failed install.** The applier
      waits 120s for the apply UNIT to start; a long build keeps the
      oneshot busy, the queued path-trigger can't start it, and the
      daemon reports failure + reverts + retries in a loop while the
      first run is still legitimately building (signal-desktop,
      2026-08-30). Watch the status file (phase/mtime), not unit-start.
      Launcher-repo.
- [x] **F13 — startup reconcile sweep.** The daemon's managed state, the
      package list, and the actual profile can drift (boot-revert,
      crashes mid-install, the pre-F11 chaos left a zombie telegram tile
      for a package that wasn't there). On startup: adopt the list,
      compare against the profile, and if a declared attr has no live
      app AND no successful run postdates the list — nudge one apply.
      Would have self-healed both the signal limbo and the telegram
      zombie. Launcher-repo.
      → BUILT (launcher `5704c3a`, Round 10): two sweeps, at most ONE
      reconcile apply per daemon lifetime (a broken package can never
      loop rebuilds). Startup timestamp check: list newer than the last
      successful run → one blocking ensure-apply + rescan. First-scan
      drift sweep: a confirmed GUI attr with no live app under a
      truthful "done ok" status (boot-revert) → one FORCED re-apply
      (list rewrite bumps the mtime past the stale status).
      Verification pending.
- [ ] VM: boot the LATEST generation, not the image's (virtualisation.
      useBootLoader) — direct kernel boot reverts every in-VM switch on
      reboot; a real installed machine keeps what it installed. Needs a
      careful round (bootloader-in-image, likely fresh disk).
- [x] Shell updates restart the daemon mid-session (HM restarts changed
      user units on switch): pending installs must survive a daemon
      restart — persist pending-install state, or hand off gracefully.
      Bit us via the stale-checkout swap; will bite for real on every
      Golem UPDATE that bumps waverunner. Launcher-repo.
      → BUILT (launcher `5704c3a`, Round 10): pending tiles (placement,
      ring clock, icon) + tile-less managed installs persist to
      `pending-installs.json`; on startup they restore in place and
      re-arm through the normal mutation path, whose F9/F10 status-file
      rules make the re-arm exact — a rebuild that landed while the
      daemon was dead fast-completes (full flourish replays), a running
      one is joined, a failed one retries once. Verification pending.
- [ ] VM loop niceness: qemu user-net (slirp) downloads at ~hundreds of
      KB/s — a first brave+gimp closure takes 10-20 min. Fine for
      correctness tests; consider virtio-net or a host-side cache if it
      gets old.
- [x] **F12 — perpetual animations burn the whole machine on a CPU
      renderer.** During an install, the "installing" tile animates every
      frame; on llvmpipe (the VM — but also any GPU-less machine Golem
      ever lands on) that's the daemon at 450% CPU for the length of a
      rebuild, starving every app (foot took 10s to open, 90s+ frozen).
      The daemon KNOWS its adapter (logs device_type: Cpu) — cap
      animation frame rate (or go static) when the renderer is software.
      Launcher-repo. (Live mitigation that proved it: renice 19 on the
      daemon freed the session instantly.)
- [ ] **F8 — renderer init failure = shell silently dead forever.** Seen in
      the Venus experiment: wgpu couldn't create a surface, the daemon
      errored out, systemd's restart limit exhausted in seconds → no dock,
      no bar, no OPTIONS, and nothing tells the user why. The daemon (or
      its unit) needs a real degrade path: retry with backoff, fall back
      to a software adapter, or at minimum leave a visible breadcrumb.
      Launcher-repo work.
- [ ] VM-only: waverunner renders on llvmpipe (virgl gives GL, wgpu wants
      Vulkan) → dock is CPU-drawn, video can stutter with it. Venus
      (vulkan passthrough) tried 2026-08-30 and REVERTED — wgpu got no
      surface at all (F8 is its own finding). Acceptable for the test
      loop; revisit if the VM ever becomes a daily driver. Real hardware
      unaffected.

## Log

- Round 18 (2026-08-31, Max: "the text on options is white, but the
  text inside notifications and clipboard is black"): INK REGIME BUG,
  fixed with numbers rather than guesses. Instrumented the live daemon
  instead of theorising: `matched=None frost=Some([0.13,0.35,0.56])
  ink=[1,1,1]` — with the bar TRANSPARENT it paints the theme's white,
  while both boxes derived ink from the sampled wallpaper frost whose
  luminance (0.32) sits above the 0.179 flip point → they chose BLACK.
  Each was locally "correct"; together they were incoherent. Fix: the
  boxes are the pill grown, so they follow the BAR'S REGIME — matched
  bar → matched colour + the bar's adaptive ink (agree by
  construction); transparent bar → the theme slab TINTED 25% by the
  frost instead of becoming the wallpaper (low because the values are
  LINEAR and the list's resting text sits at LIST_DIM). Keeps the
  wallpaper character, guarantees the theme ink reads. The logic was
  duplicated verbatim in clipboard.rs and notif.rs — the same drift
  that caused it — so it now lives once as `options_box_surface()`.
  Verified live on both boxes. launcher `a3450cc`.
- Round 17 (2026-08-31, Max: "i dont want the pseudo and fullscreen
  button on overview, i dont want the clipboard on overview too. but
  also i dont want to start patching OPTIONS — what should we do?"):
  THE PRESENCE CONTRACT — the first structural answer to "which
  OPTIONS show when". Context first: a survey of the decision machinery
  found the Brain (options-engine, ~4k lines: 8 collectors →
  ContextState+Health → infer_activity → decide_with = providers,
  freshness gate, activity fit, skill calibration with friction,
  suppression + cap) is BUILT and live-verified but NOT consumed — no
  surface reads OptionSet; the daemon only reads ContextState (window
  pill, battery). Meanwhile the live surfaces each decide their own
  visibility ad hoc: ELEVEN `overview_active` conditionals already, and
  Max's three asks would have added four more. Two competing decision
  systems, only the ad-hoc one running.
  The move (agreed): every element declares WHERE it belongs
  (`Presence { desktop, overview }` + a `presence(id)` table) and
  `options_pills` filters ONCE. That list is already the single input
  to draw / hit-test / hover / click, so an absent element can't be
  seen or touched and nothing downstream needs a situation check —
  toggles + clipboard stand down in the overview; title, X, bell,
  clock stay; an open clip drawer collapses on overview open instead
  of lingering invisible with its input region claimed. Deliberately
  the SEAM, not a patch: presence is static today, and the same call
  site later asks the mind for relevance without moving. Verified on
  screen in both situations. launcher `81fb062`, 141 tests.
  Design notes for Arc 2 (S3) recorded in the discussion: the missing
  pieces are a slot/budget allocator (placement + capacity instead of
  a global top-3), hysteresis + minimum lifetime (or affordances will
  flicker at the threshold), and an engagement feedback loop (the
  focus cycle's frecency math is the right shape) so `skill` stops
  being a constant.
- Round 16 (2026-08-31, Max: "lets do the rebuild now"): THE CUTOVER
  ROUND — and the pseudo policy's real bug. The switch had already
  landed (Super+Tab live in the compositor, store config carrying
  everything), so verification could finally run: Golem pseudo
  VERIFIED LIVE on Max's Android Studio window — tag applied, size
  2000x1222 → 1780x1026 (exactly 89%x84%), centered, and the corner
  crop shows rounded corners + the peach active border on a window
  ALONE on its workspace, where smart gaps strip both. Exactly the
  ask.
  Then the bug: toggling twice never turned it OFF. Root cause —
  this fork's Lua `window.tags` reads as an EMPTY TABLE even for a
  tagged window (clients JSON shows the tag fine), and pseudo state
  is exposed nowhere, so the config-side toggle could never tell "on"
  from "off" and re-applied "on" forever. Fix: the policy MOVED TO
  THE DAEMON (hypr::toggle_golem_pseudo) which reads the tag from
  JSON and emits one atomic eval chunk; hyprland.lua keeps only the
  tag-matched frame rule (the half Lua does correctly), and Super+P
  now calls the new `pseudo-toggle` verb so keyboard and pill can
  never drift. Verified both directions. launcher `41cfb01`.
  NOTE: the pill works now; Super+P needs ONE more rebuild (its bind
  still points at the removed Lua function).
  → Max: "the whole options click does not work on overview" — of
  course: the overview swallows EVERY pointer event (info.cancelled)
  so the desktop under it stays inert, which also killed the topbar it
  deliberately keeps alive above the grid (visible but dead — round
  15's X could never have worked). waveview v0.32 passes motion,
  buttons, and scroll over the monitor's reserved top strip (28 logical
  px here) through uncancelled, so the layer surface gets them
  normally; mid-gesture events stay the overview's, so a window drag or
  thumbnail resize that wanders under the bar isn't interrupted, and
  entering the strip clears the grid hover. waveview `fa4152e`.
  Geometry verified (reserved top = 28, bar input region = 28); the
  click itself is Max's to try — no pointer simulation on this
  compositor.
- Round 15 (2026-08-31, Max: "X button by the current task to exit
  overview... current task to show the title of the hovered task and
  also the (size) when im resizing on overview"): THE TOPBAR SERVES
  THE OVERVIEW. All three: (a) the X closes the OVERVIEW while it owns
  the screen (dispatches waveview's Lua toggle via `hyprctl eval` —
  the bar is now its on-screen exit, next to Esc/Super+R); (b) the
  current-task pill follows the POINTER, showing the hovered
  thumbnail's title; (c) resizing a thumbnail streams the live size
  into the same (WxH) suffix round 13 built. waveview v0.31 sends
  overview-hover/overview-resize (throttled 50ms — it rides pointer
  motion); both overrides drop on overview-off, reset centrally in
  notifyWaverunner. Proto gained its first PAYLOAD verbs, so Command
  lost Copy (FromStr parses payload prefixes before the exact-match
  table, keeping titles verbatim). One real bug caught in review, not
  by a crash: sendWaverunner captured a `const char*` in a detached
  thread — fine for the literals it used to carry, a dangling pointer
  the moment a payload temporary was passed; it takes std::string by
  value now. Verified on screen: "Firefox — Golem docs (1240x1000)" →
  size clears → real title back. launcher `8b0b4b1`, waveview
  `9020453`. Testing note: the live desktop kept interleaving (the
  real overview closed mid-test, and a stale daemon binary rejected
  the new verbs — clippy/test don't rebuild the binary, only `cargo
  build` does).
- Round 14 (2026-08-31, Max: "clicking on the current task option to
  circle between the windows... aware of the more used apps... same
  algorithm for supr+tab"): USAGE-AWARE FOCUS CYCLE SHIPPED. Design
  settled through live brainstorm: click = cycle current workspace's
  windows MOST-USED-FIRST; right-click = cycle the OTHER workspaces'
  (cross-workspace bounce). The brain is FRECENCY (focus events earn
  decaying points, half-life 10min — the pair Max bounces between
  stays one click apart even after digressions; new windows fall back
  to compositor focusHistoryID). Two structural insights baked in:
  (1) consecutive clicks walk a FROZEN snapshot — a live re-rank
  would bounce the top two forever and never reach the rest; (2)
  walk-driven hops are suppressed in the stats, only the landing
  earns the point — the mechanism can't pollute its own signal.
  Reusable: ctl verbs focus-next/focus-other, ready for a Super+Tab
  bind in hyprland.lua (one exec_cmd line, deferred until the pending
  config rebuild). Verified live end-to-end (ranked others → home →
  wrap on a 3-window ws) — with Max live-switching workspaces mid-
  test, which briefly made the correct trace look haunted. launcher
  `0836325` (140 tests, 3 new). Frecency is in-memory only for now —
  habits reset with the daemon; persist later if it matters.
  → Max: "its perfect!" — one polish: the focus dispatch warps the
  cursor into the window (warpCursor is unconditional in the fork);
  the cycle now flips cursor.no_warps around its dispatch in one
  atomic `hyprctl eval` Lua chunk (keyword is legacy-parser-only in
  this fork; eval is the dynamic-config door — noted for future use).
  Cursor verified pinned to the pixel through a hop. launcher
  `583b17f`. Super+Tab / Super+Shift+Tab bound to the same verbs, and
  Super+P rerouted through golemPseudoToggle (it was still calling the
  raw toggle, bypassing the Golem pseudo policy) — both hyprland.lua
  copies, Golem `d792544`.
  → v2, INTERACTION-AWARE (Max: cycling through 3 and 4 made them
  count as "used" and broke the 1-2 pair): the model is now HIS —
  interaction commits the cycle, not a timer. Toggle from a settled
  window → the one you last actually WORKED in; toggle again without
  interacting → continue down the frozen list (wrap home); interact →
  commits, next toggle starts fresh. Windows passed through earn
  nothing and never become the partner. waveview v0.30 sends one
  `interacted` per window visit (first key/click/scroll aimed at the
  focused window; Super-chords excluded so Super+Tab can't commit
  itself; pointer events require the cursor inside the window's box so
  pill clicks don't count). Ranking: freshest interaction first, then
  frecency, then compositor history, home last. VERIFIED LIVE on a
  4-window ws (Max's exact scenario): interact → bounce both ways; no
  interaction → four distinct hops and wrap. launcher `fbb2ed8`,
  waveview `3613989`, 141 tests.
- Round 13 (2026-08-31, Max: "see the size of the window live on the
  current task option when im resizing"): LIVE RESIZE READOUT SHIPPED
  + VERIFIED. While the focused window resizes, the window pill swaps
  the title for a live "700 × 800" that tracks the drag, reverting
  0.7s after the size settles; the X stays put beside it. The
  compositor emits NO drag/resize events (checked DragController.cpp —
  nothing), so detection is a size-change poll keyed by window address
  (a focus switch changes address, never false-triggers): 500ms at
  rest → 40ms while moving — same precedent as the intellihide zone
  poll. Verified with scripted pseudo resizes + screenshots (pill
  showed the count, then reverted). Debugging note for the ages: two
  "failed" probes were the BLIND PSEUDO TOGGLE again (round 12's
  lesson, promptly re-learned) — the watcher had been working all
  along. launcher `6114dfb`. Caveat, by design: any same-window size
  change (e.g. a split opening) flashes the readout briefly — honest,
  possibly even nice; revisit if it annoys.
  → v2 same day (Max: "show size as soon as the mouse pointer
  changes"): the readout now appears on BORDER HOVER, before any
  change — the daemon computes the same grab band the compositor uses
  for the resize cursor (border 3 + grab area 10 + 1 slack, from
  activewindow box + cursorpos, rest poll 250ms) and shows the
  CURRENT size the moment the pointer enters it; fullscreen exempt.
  Verified without input-sim by resizing the border TO the idle
  pointer: readout held on band alone 2s past settle, reverted when
  the edge moved away. launcher `68682c1`.
  → v3 (Max: "a individual pill that slides to the left from behind
  the current task one"): the readout is now its OWN display-only
  pill emerging leftward from behind the title pill (same t-driven
  metamorphosis as the toggles; title stays readable; inert to the
  pointer; digits skip the glyph cache). Verified on screen:
  [966 × 1203] [title] [X]. Fun constraint: Max was at the machine
  moving the pointer, so scripted verification raced his hand — the
  border-to-pointer trick needed an atomic read-resize-capture.
  launcher `9a4cd27`.
  → v4 (Max: "same pill"): inline — the size appends to the title,
  "current task (1766x966)", no extra pill. launcher `b5376d5`.
  → v5, the keeper (Max: "involuntary triggers, mostly when im around
  options... i want click on the border"): the hover band was exactly
  the predicted noise (window top borders live under the bar), so the
  trigger is now the real thing — waveview watches the compositor's
  PUBLIC drag-controller state (target + MBIND_RESIZE*, checked on
  mouse events + a 30ms one-shot after button presses) and writes new
  proto verbs resize-drag-on/off to the daemon socket; the daemon
  shows the readout from the CLICK (before any movement) and runs its
  fast sampler only for the drag's duration. ALL rest-state polling
  deleted — back to idle-at-rest. Daemon path verified on screen via
  ctl verbs (suffix on/off); the compositor click needs Max's hand.
  waveview v0.29 hot-reloaded live (unload safe: 0.28 ≥ 0.22, overview
  idle 28min). launcher `338c130`, waveview `999ab71`.
- Round 12 (2026-08-31, Max: "rounded corners and borders when window
  is on pseudo... set this window size as default... it have to keep
  aspect ratio and proportion on all kind of screens"): GOLEM PSEUDO —
  a framed window at a proportional default. Max picked the
  frame-inset look live (three sizes demoed on foot + browsing test on
  chrome): 89% x 84% OF THE TILE, defined as fractions so any screen
  (and any split) reads the same. Design: the pill dispatches
  golemPseudoToggle() (hyprland.lua) → tags "golem-pseudo" + pseudo
  on/off + proportional resize; a tag-matched rule AFTER the no-gaps
  rules (same priority, last set wins — verified in fork source)
  restores rounding 12 + border 3, so smart gaps survive untouched for
  plain tiles. The TAG is the pseudo state — the fork exposes pseudo
  NOWHERE (not clients json, not HL.Window), which cost the round an
  hour of toggle-parity ghosts ("it did not happen"): blind toggles
  canceled in pairs, and clients-json size turned out to report
  mid-ANIMATION values. All learned mechanics (pseudo action on/off,
  resize absolute/relative + pseudo-size semantics, tag dispatch +
  rule matching, dynamic-vs-static rule props on tag flips) written
  into docs/hypr-api.md. hyprland.lua edited in BOTH copies
  (/etc/nixos + flake, verified in sync); launcher `21dd849`; VM
  builds. PENDING: Max runs `sudo nixos-rebuild switch` + `hyprctl
  reload` on the host, then clicks the pseudo pill to verify frame +
  size land together.
- Round 11 (2026-08-31, Max: "change the X to the right and the other
  three buttons to the left"): WINDOW-CLUSTER REWORK + A CORPSE
  UNMASKED. First pass mirrored the old design ([full][float][pseudo]
  [name] [X], all reveal-on-hover); Max: "i dont love it" → final
  design: at REST only [current task] [X] — the close is a permanent
  resting pill, always visible and clickable, right of the name;
  hovering either reveals the toggles — landed (fourth pass, Max's
  calls) as [name] [X] → [pseudo] [fullscreen] emerging rightward from
  behind the X. FLOAT IS CUT from the cluster (Max doesn't use it, no
  Golem story for it: no titlebars to drag, pseudo covers "own size in
  place", video PiP floats itself; hypr::float_active removed). The
  reveal was rebuilt as a symmetric metamorphosis like the bar's other
  elements (copy-link pill / bell peek): one eased progress per button
  (MORPH_RATE 13) drives slide + opacity, so the HIDE tucks each
  button back behind its parent while fading (was: fade-in-place);
  chain emerges inner-first, retracts outermost-first, 60ms stagger,
  and a mid-flight hover flip reverses smoothly. Reveal seen live in a
  screenshot (Max's pointer was parked on the cluster — new order
  confirmed on screen). launcher `eda62a2`+`7ffb7db`. The daemon
  restart for the UX change turned into F13's first LIVE verification —
  and found a real pre-existing hole: apply-status.json on the host was
  a stale "building" CORPSE (a shutdown killed last night's 00:05
  rebuild before any terminal status), and F10's rules honored it as a
  live foreign run — the reconcile (and any install!) would have
  blocked the mutation thread for the full 60-min BUILD_TIMEOUT. Fix:
  wait_for_apply probes `systemctl is-active waverunner-apply.service`
  (throttled, errs on "alive" without systemd) before believing a
  foreign "building"; a corpse counts as idle so the nudge re-trips the
  watch. Verified end-to-end on the host: restart → reconcile armed →
  corpse detected → nudge → real run → 48s no-op switch → status
  truthful, done ok. launcher `c0e6fc9`+`b6a873a`.
- Round 10 (2026-08-31, Max: "lets do F13 and the restart survival
  together"): THE STATE-DRIFT FAMILY CLOSED IN ONE ROUND — they really
  were one theme: the daemon making itself consistent with reality on
  startup instead of trusting the memory it lost. (a) Restart survival:
  in-flight installs persist (`pending-installs.json` + per-attr icon
  sidecars) and re-arm on startup THROUGH the existing F9/F10 machinery
  — no new wait logic; the status file's truth makes the re-arm exact
  (dead-daemon-finished → fast-complete + flourish replay; still
  building → join; failed → one retry). One real bug found en route:
  `adopt_list` would DROP a restored stage whose re-armed list write
  hadn't landed yet (startup adopt racing the mutation thread) — staged
  unconfirmed entries now survive adopt. (b) F13: startup timestamp
  check (list newer than last success → ensure-apply) + first-scan
  drift sweep (confirmed GUI attr, no live app, truthful status →
  forced re-apply), gated to at most one reconcile apply per daemon
  lifetime, skipped entirely when a restored install already armed one
  (its apply proves the whole list on its own), and armed NEVER on an
  empty/missing list (F11 stands: zero first-boot rebuilds). Bonus
  coverage for free: an uninstall whose rebuild failed while the daemon
  was dead now self-heals via the timestamp check. launcher `5704c3a`,
  clippy clean, 137 daemon tests (2 new). TO VERIFY (VM): install
  something slow, restart the daemon mid-build (`systemctl --user
  restart waverunner`), watch the tile survive and the app land at its
  drop slot; and the old zombie repro — a managed GUI attr with its
  package gone — should heal on one startup apply.
- Round 1 (2026-08-30, "lets keep going with the plan" — SH had nothing
  actionable left for Claude, all remaining boxes are Max's hands or the
  daily-driving clock): S7 OPENED. Max decided the flake pushes to the
  empty public github.com/maxpoww/Golem; since local ~/Golem shares the
  name and had no remote, the plan repo IS the distro repo — flake.nix at
  the root. Ported all of /etc/nixos into system/ + hosts/ (nvidia split
  host-side so the VM is hardware-free); /etc/nixos left untouched and
  live until Max cuts over (cutover = `rebuild-golem`, which the flake
  builds as `nixos-rebuild switch --flake $flakeDir#golem`). Both
  nixosConfigurations eval clean; golem-vm BUILT first try (compiled
  waverunner release binaries for the first time ever — the live session
  still runs debug builds from the checkout). Secrets scan of the plan
  docs before the public push: clean. NEXT: Max runs
  ./result/bin/run-Golem-vm and eyeballs the first foreign-hardware boot;
  then push launcher + waveview to GitHub and repin the two local inputs.
- Round 2 (2026-08-30, first VM boot): ✅ Max: dock, OPTIONS, overview —
  "its all there". Then: installed the YouTube webapp, played a video →
  "it crash, the whole thing restart somehow". Diagnosis (sshd + loopback
  :2222 added to the VM, journal read from the crashed boot's persistent
  disk): FOUR OOM-killer events in 6 min, every victim a ~3GB `nix`
  process inside waverunner.service — the cold-start `nix search
  nixpkgs ^` index dump (see the new prebuilt-index item above). Hyprland
  + greetd survived every kill (same pids across all four OOM tables):
  the "session restart" Max saw was the daemon crash-looping + Chrome
  dying (SIGTRAP, core dumped) under memory pressure, not the compositor.
  VM bumped 4G→8G to unblock the loop — the honest minimum-spec question
  is now open. NEXT: Max re-runs YouTube in the 8G VM; watch the index
  build complete (first success takes minutes — nixpkgs eval from cold).
- Round 3 (2026-08-30, Max: "yt works now, video plays fine but there is
  freezing, and also the keyboard looses focus"): 8G verdict — ZERO OOMs,
  index built clean (23779 pkgs, one daemon start). Freeze root-caused:
  waverunner's wgpu picked llvmpipe (device_type: Cpu) — virgl exposes
  GL, wgpu wants Vulkan — so the dock CPU-renders while Chrome
  soft-decodes video on 4 cores. Venus (Vulkan passthrough,
  virtio-vga-gl,venus=on) tried: WORSE — wgpu got no surface, daemon hit
  its restart limit, shell gone ("no bar, no dock, nothing") → REVERTED
  to virgl + cores 4→8; that death mode filed as F8. Keyboard-focus loss
  on the YT search bar still OPEN — no journal culprit; next repro gets a
  live `hyprctl activewindow` over ssh to split guest-focus-bug vs
  QEMU/host grab boundary.
  ✅ verified by Max post-revert: Firefox + Chrome, several sites at
  once — "all worked well no freezing". Focus loss not yet re-seen;
  watch stays armed.
- Round 4 (2026-08-30): INPUTS FREED FROM THE LAPTOP. launcher made
  public (was private + 10 days stale — first push attempt lied
  "Everything up-to-date" while the remote sat at a46cfd1; explicit
  main:main pushed 84efa5a), waveview created public (master pushed as
  main). Flake inputs repinned git+file → github:maxpoww/{launcher,
  waveview}; identical revs/narHashes so the repin cost zero rebuilds;
  VM target verified building from the GitHub-only closure.
  `github:maxpoww/Golem` is now buildable by any machine with nix —
  first time Golem exists independently of Max's laptop.
- Round 9 (2026-08-31, Max: "droping the icons on page 1... land on
  page 2... when i drop it at the end of the grid"): THE END-OF-GRID
  DROP SAGA — three wrong theories, then evidence. (1) First fix
  (same-page reorder clamp) was real but not his path. (2) Host log
  instrumentation showed NO drop handler firing → his gesture was a
  PACKAGE drag from Install, and `installing discord (anchor None)`
  told the story: an anchorless (page-tail) drop was simply never
  placed — resolve only handled `Some(anchor)`, so the app fell to the
  order's default, the LAST page. (3) After fixing the landing
  (PendingInstall.grid_page + move_to_page_end), Max: "nop" — the
  PENDING TILE was the visible half, pushed to the grid's last cell for
  the whole build. Tile now inserts at its target display page's end
  (ghost page = one past last). ✅ Max: "works" — on the host AND the VM. Same round, the
  LIBREOFFICE mystery: it resolved as a CLI terminal tile because its
  desktop files (startcenter/writer/calc) share no substring with the
  attr and the prebuilt index shipped NO hints (round 5's cut corner) —
  the launcher flake now takes nix-index-database as an input and
  package-index bakes desktop stems + icon paths offline in the
  sandbox (libreoffice → base;calc;draw;impress verified in the TSV).
  launcher `ba3ca8d`+`5239e52`.
- Round 8 (2026-08-31, Max: "lets do the F12 fix"): SOFTWARE-RENDERER
  THROTTLE SHIPPED + VERIFIED (launcher `7066585` + `d26d38d`). draw()
  spaces frames to 100ms via a calloop timer when the wgpu adapter is
  device_type Cpu — and after Max's "scrolling feels laggy, no
  smoothness", refined to INPUT-AWARE: the throttle stands down for 2s
  after any pointer/keyboard event, so interactive scrolls/drags run
  full-rate and only ambient streams (the install ring) drop to 10fps.
  Numbers from Max's darktable install: 481% CPU at the click
  (input window, by design) → 39%/87% ambient vs 450% SUSTAINED before;
  system load 2.2 vs 8-9; run landed in 76s with NO daemon freeze
  workaround. En route, TWO more real finds: (a) obsidian's install
  restarted the shell mid-run and ate the completion flourish — the
  VM's seeded checkout pinned a STALE waverunner, so the in-VM switch
  swapped the running daemon; vm.nix now re-syncs the checkout from
  the image on boot (preserving waverunner-packages.nix). (b) Max's
  zombie telegram tile (managed state without a live package, residue
  of the pre-F11 chaos) self-healed when the next install's rebuild
  materialized the whole list — the declarative model repairing its own
  history. Eight installs today, eight gui=true resolutions. Still
  open, filed: F13 startup reconcile sweep (managed vs list vs
  profile), useBootLoader so VM reboots keep the latest generation.
- Round 7 (2026-08-30/31, Max: "lets do the F9/F10/F11 fixes"): APPLIER
  REWORK SHIPPED + ALL THREE VERIFIED LIVE (launcher `985417b`, one
  rule: the status file is the truth). F11: empty first-boot seed
  writes nothing — fresh-disk boot fired ZERO apply runs (no list, no
  status, verified). F9: declared ≠ applied — fast-true only when a
  successful run postdates the list write, else join/re-trigger and
  block; daemon log: "pending install brave resolved as app
  brave-browser (gui=true)" — no CLI-terminal tile, no restart needed.
  F10: busy helper = queued — Max clicked chromium mid-brave-build; it
  waited its turn silently and landed on its own run 2s after brave's
  finished ("resolved as chromium-browser (gui=true)"); the waiter also
  re-trips the watch when a foreign run swallowed its trigger (systemd
  drops path triggers that fire while the oneshot is active — max 3
  nudges, 120s escape only when truly idle). Bonus finding F12 (filed
  above): the install animation on llvmpipe ate 450% CPU, froze foot
  for 90s AND throttled its own download to 200KB/s; SIGSTOP on the
  daemon during the build restored ~7MB/s (chromium run: 112s). 135/135
  tests; VM verified with brave + chromium installed by Max's hands.
- Round 6 (2026-08-30, Max: "i tryed to install brave and alacrity,
  both failed" → hours of VM archaeology): THE INSTALL LOOP NOW WORKS
  END-TO-END on an installed-shape machine — brave + gimp declaratively
  installed inside the VM via packages.list → apply → in-VM flake
  rebuild → clean switch, verified landed (.desktop files + bins), and
  Max: "they healed, and work now" after a daemon restart forced a
  rescan. The road there found SIX distribution bugs, each now fixed in
  the flake: no apply unit without a checkout (VM got the seeded
  installed-machine checkout, golem.flakeAttr for self-rebuild), git +
  nix/libgit2 ownership guards (declarative /etc/gitconfig
  safe.directory), grub assertion (grub re-defaults on when
  systemd-boot is forced off), live-switch topology mismatch (plain
  toplevel stopped nix-store.mount under the running system — POWERED
  OFF THE VM; qemu-vm now imported directly so in-VM switches are
  like-for-like), tmpfs writable store (installs evaporated on reboot,
  ghost paths; now disk-backed), 1G default disk (now 20G sparse).
  Plus three launcher bugs filed (F9 stale "installed" resolution — the
  reason a daemon restart was needed; F10 queued-install false
  failures; F11 startup list clobber + no-op first-boot rebuild).
  NEXT round: the F9/F10/F11 applier rework in the launcher — one
  coherent fix: the on-disk list + apply-status.json are the truth, the
  daemon adopts and watches them, and rescans when a run lands.
- Round 5 (2026-08-30, Max: "lets do the prebuilt index"): the OOM fix,
  see the ticked item above for the design. Notable in the doing: the
  daemon's TSV cache format (v5, header-versioned) made the prebuilt
  path clean — `load_cache` already validates the header, so a future
  format bump silently invalidates stale prebuilts and falls back;
  `nix-env -f <pinned> -qa --json --meta` inside the build sandbox is
  the eval (no flakes/store needed there), jq reshapes it to nix-search
  JSON, and the daemon's own binary converts (`build-index` mode) so
  filter/dedupe can never drift from the runtime path. 135/135 daemon
  tests pass. Golem input bumped; VM disk wiped for a TRUE first boot.
  Both proofs: 8G fresh-disk (prebuilt in ~2s, 0 OOM) and the 4G repro
  (0 OOM, 1 daemon start). The VM currently runs at 4G via QEMU_OPTS —
  vm.nix stays 8G for comfort.
