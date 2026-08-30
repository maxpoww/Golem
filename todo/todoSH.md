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

- [x] the border on the overview are all diferent sizes, the smaller the
      window the smaller (thinner) the border, make them all look like my
      workspace window borders, same color, same tickness, etc.
      → FIXED same day (waveview 8d7f876, in v0.20 live): halos/frames were
      proportional (1.6% of the window, blue) — now constant 3-logical-px
      amber #ffbe98, the desktop's exact border. Note predated the fix; the
      18 verified live-drag rounds all ran with it. Design note: at REST
      minis draw bare (border appears on hover/drag only) — if you want
      every mini to wear a border like desktop windows, that's a new item.

- [ ] overview opens somethimes with no pointer.
      → FIXED in code same day (waveview 92913d3, in v0.20 live): open now
      unhides the cursor and pins the default arrow for the overview's
      lifetime (apps that hide the pointer — terminals while typing, video
      fullscreen — were leaving the overview cursorless). "Sometimes" bug:
      stays open until a week of daily driving shows zero recurrences.

- [x] **Compositor crash during overview drag (2026-08-30 14:41):** SEGV
      inside Hyprland's `CDragStateController::dragEnd()` — it dereferences
      the drag target with no null check (upstream bug, v0.55.4; worth
      reporting). Our release handler called `endDragTarget()` while the
      controller held no live target (window died mid-drag, or the grab was
      silently rejected at begin). Fixed plugin-side: every begin/end drag
      path now checks `dragController()->target()` first, and a
      window-died-mid-drag release folds the grab cleanly. Built; needs a
      plugin reload to take effect (session restarted with the old .so).
      Round 2 (crash 2026-08-30 14:52): same dragEnd SEGV — but timeline
      shows that session started 14:41 with the OLD .so (guards built
      14:49, never loaded there), so this was the known bug's last stand,
      not a guard failure. Two follow-ups anyway: (a) closed a real TOCTOU
      gap — `endRealDrag`/`placeAt` checked target() but then ran
      focus + moveMouse before endDragTarget(); the drop-point motion can
      drop the target after the check, so both now re-check right before
      ending. (b) post-crash restart came up with NO plugin (the config's
      startup `hyprctl plugin load` didn't take) — rebuilt and hot-loaded
      the fixed .so into the live session at 14:57. Watch for a repeat of
      the silent no-plugin start.

- [x] "disappeared app": LocalSend invisible in the grid but found by search.
      → SOLVED, not the fold bug: LocalSend is a MEMBER of the 14-app box
      box-1785375449254-0 (fzf, bluez, brightnessctl, nvidia-settings, lf,
      lsp-plugins, kdeconnect bits, scrcpy-console… — a junk-drawer sweep).
      Grouped apps hide from the loose grid by design and live inside the
      box tile — labeled "fzf +13", so nothing hints LocalSend is there.
      Search ranks grouped apps (also by design) = exactly the mismatch.
      • Fix options: drag it out of the box (yours), or I edit groups.json.
      • Arc-2 UX idea filed: search results should reveal WHERE an app
        lives (open/highlight its box) — "found but invisible" is a trap.
      • Side-find: pins.json holds two pins for boxes that no longer exist
        (group:box-1785368710183-0, group:box-1784838501386-0) — stale,
        harmless, cleanable.

- [x] clipboard: clicking a row's can sometimes copies instead of deleting;
      add a dismiss-all can like the notif box.
      → FIXED + ADDED (fb8e9df, live): the can was DRAWN top-aligned at one
      inset but HIT-TESTED centred at another — on tall rows the visible
      can and its click zone barely overlapped, so the click fell through
      to the row (= copy). One shared rect now defines both, with click
      slack. Footer is now pencil · book · CAN (clear-all, wipes history +
      side files, closes the box) — verified on screen.
- [ ] overview (waveview): moving the mouse in the overview still sends
      input to the workspace underneath.
      → FIXED in code (waveview b095aa7, built): motion is now swallowed
      while the overview is open. The old "cancelling freezes the cursor"
      fear is obsolete — verified in the fork's source that the pointer
      moves BEFORE the hook, so cancelling only stops focus-follows-mouse
      + surface delivery underneath.
- [ ] overview integration (evolved per Max): dock hidden during overview;
      OPTIONS topbar STAYS with its own place, aware of the overview.
      → BUILT both sides, daemon side VERIFIED live:
      • dock hides, edge-reveal strip drops, intellihide gated,
        show/toggle/expand ignored while open (screenshots)
      • topbar stays visible (even over fullscreen), window pill reads
        "Overview" while open, real title returns on close (screenshots)
      • waveview: tiles inset below the bar's 28px reserved strip (one
        shared computeTiles for draw/capture/hit/drop); thumbnails are
        structurally bar-free (captures render workspaces, not layers);
        zoom close still lands exactly full-screen
      ✅ first three verified by Max after his reload.
- [ ] overview layout: gaps inconsistent; empty workspaces read bigger than
      full ones; top gap vs OPTIONS should be 3px like window gaps.
      → FIXED (waveview 4a5e0e4, built, brain tests pass): ONE uniform gap
      everywhere (inter-tile = outer margins; the old centering made them
      differ); grid top-anchored exactly 3 logical px below the bar; tiles
      back to true full-monitor aspect (the inset had skewed them); the
      empty-hover/drop outlines now get the same shrink as windows so
      empties can't read bigger.
      Round 2 (0b57205): "too much side/top slack" was geometry —
      aspect-true tiles under a bar force ~57px side margins. Verdict:
      FULL BLEED — tiles give ~3% aspect, grid fills the usable area
      exactly (sides/bottom/inter-tile = one gap, top = bar+3px); the
      window mapper + zoom handle the give invisibly. ✅ verified by Max.
- [ ] empty frames still bigger (windows sit inset by desktop gaps); equal
      all gaps; make the overview scrollable to 18 workspaces (3x6).
      → BUILT (waveview 6f6b517): empty/drop frames now mirror the
      desktop's gaps_out inside the tile (top 3, sides/bottom 10 logical,
      from hyprland.lua) + the window shrink — empties read exactly like
      full workspaces. Grid = 3x6 (18 WSs), wheel scrolls (eased,
      dt-based, hover follows, desktop never scrolls), opening on a deep
      WS pre-scrolls its row into view, digits jump 1-9, clicks reach all
      18. Note: open now captures 18 workspaces (was 9) — if opening
      feels slower, next step is half-res captures.
      Round 3 (4b43763): equality BY CONSTRUCTION — rest-shrink removed
      (windows at true mapped size; gaps = the desktop's own,
      miniaturized) and empty/drop frames = the plain full tile, identical
      to a full workspace's footprint. Wheel now flips PAGES (two 3x3
      pages, one notch = one flip, digits 1-9 select within the current
      page, opening lands on the active page). ALL keys swallowed while
      open (typing was leaking into the focused window). ✅ #2 verified;
      #3 page-flip leftover FIXED (windows clip below the bar strip,
      relaxing with the zoom) — awaits reload.
- [x] clicking an empty workspace jumps but the dock doesn't greet you.
      → FIXED + LIVE (daemon): the workspace-switch event races
      overview-off, so the zone-free reveal was gated and never re-fired;
      overview-off now shows the dock itself when the zone is free.
- [ ] overview DESIGN: too compact, empty frames still read bigger — Max's
      call: design on mockup first, then implement (the project's own law).
      → MOCKUP BUILT: ~/overview-mockup/index.html — live knobs for gap,
      margins, grid fill, radii, backdrop dim, tile backing (frosted
      glass / dim / bare), workspace numbers (empty-only / all / off),
      page dots, wallpaper picker. "copy settings for Claude" exports the
      chosen numbers. Open: chromium --app=file:///home/max/overview-mockup/index.html
      then F11. Design there → I implement the winner.
      → DESIGN CHOSEN + IMPLEMENTED (waveview 3c7a8bd, built): bare
      wallpaper, outer 35 / gap 12 / top-gap 12 (logical), frames r28,
      windows r20, in-tile window gap 1.7% (multi-window only; solo
      full-bleed; melts with the zoom). Design constants in one DSN_*
      block.
      Round 4 (53fb002, from Max's screenshot review — "seam gap ≠ view
      gap; 1-window view reads bigger than 2-window view"): EDGE-AWARE
      SNAP — any window edge near its view bound snaps FLUSH (no
      per-window outer gaps, ever); only seams between windows carry the
      design gap. Solo and multi views share the exact same envelope.
      Lerps with the zoom for the pixel-exact close. Wall mockup fixed
      the same way (outline hugs windows; gap uniform in-view and
      across views).
      Round 5 (7d1f0f3) — THE REAL ROOT CAUSE: windows were mapped against
      the FULL monitor, but no window can occupy the bar's reserved strip,
      so every tile carried a ~2.5% dead band at its top (just past the
      snap threshold — four rounds of seam logic couldn't touch it).
      Windows now map against the USABLE area (monitor minus reserved):
      a maximized window IS the full tile, tops flush. **Awaiting reload**
      (carries strip-clip + round 4 too):
      `! hyprctl plugin unload /home/max/waveview/result/lib/libwaveview.so && hyprctl plugin load /home/max/waveview/result/lib/libwaveview.so`
- [x] "my whole recycle bin is gone." (spotted in Max's clipboard history,
      never filed) → CONFIRMED REAL + FIXED (live): the trash group was
      alive in groups.json but had lost its grid-order slot — and slots
      are only ever created at fold time, so it was invisible forever.
      on_apps_loaded now re-adopts any live box missing a slot; verified:
      "order: re-adopted boxless group:trash". The bin is back at the
      grid's end — drag it where you want it, it sticks now.



- [x] grid pages disappear; messenger moved to a new page came back; apps
      feel missing; fix groups too.
      → ROOT CAUSE FOUND + FIXED (live now): `normalize()` folded any page
      whose members weren't visible *at that instant* — and visibility
      flickers (webapps hop grid↔Install while managed-state settles). Every
      flicker permanently merged your pages; your whole 164-app order had
      collapsed into ONE storage page (that's the "back on original page" +
      "feels like apps are missing" — nothing is actually gone, it all
      reflowed into first-seen order). Now hidden pages are PRESERVED (the
      display already skips them; they reappear intact when members return);
      only truly-empty pages drop.
      • Groups were never affected — same page model, their fold can't
        trigger. If group-internal reorder still FEELS different after this,
        file the specific difference.
      • Honest note: tonight's fix prevents future destruction but can't
        reconstruct the layout already eaten — re-arrange once (make your
        messenger page again); from now on it sticks.
- [x] edge-drag drop needs "move out of the side first" or it lands back on
      the original page.
      → FIXED (live): two causes. (1) holding at the edge CYCLED pages with
      wrap-around — a beat too long walked past the new page back to the
      start ("something clears after a while" was partly this + the fold
      bug); drag paging now STOPS at the ghost page/page 0, wheel paging
      still cycles. (2) the drop resolved its page from the eased scroll,
      which mid-flip still reads as the OLD page — now it resolves against
      the page the flip is headed to, so a drop the instant the new page
      reveals lands THERE. Same rule applied inside open boxes.
      Round 2 (Instagram repro + instrumentation): the REAL culprit — the
      paging band counts positions PAST the grid viewport ("overshoot"),
      but the drop handler treated that zone as "outside the grid" and
      silently no-op'd (the trace showed the drop never even ran). The
      overshoot beside the grid now targets the live page's append slot
      and the drop gate accepts it. Cycle restored per Max (pages → empty
      → around). ✅ **VERIFIED BY MAX** ("works!"); diagnostics removed.

- [ ] floating mode is weird — our custom thing blocks resizing floats;
      get rid of it, let Hyprland handle float/pseudo/fullscreen naturally.
      → CAUSE FOUND: the "Preserve tiled size when toggling floating" Lua
      block in /etc/nixos/hyprland.lua re-fires on window.update_rules and
      snaps every floating window back to its saved tiled size — manual
      resizes get undone. The daemon side is already just clean toggles.
      ✅ FIXED + VERIFIED (Claude, end-to-end): removed the 14-line block
      from /etc/nixos/hyprland.lua (rounding + raise-on-focus kept),
      rebuilt + switched + reloaded; test float resized to 500x400 and
      STAYED through focus/workspace cycles. Backup of old config:
      /tmp/golem-hypr-backup.lua. Your hands: float something (mainMod+Z)
      and drag-resize it.
      (Same session: /etc/nixos made max-writable + NOPASSWD nixos-rebuild
      — declarative, in configuration.nix; memory + GOLEM.md updated.)

- [x] the box opening have a cut on the animation when opening, it gets stuck
      a 1/4 for a few ms. (dock box)
      → FIXED `b4f28ad` (dock summon rescan re-uploaded all icons + wiped the
      text cache on a no-change result = one long frame mid-open). Needs
      restart + your eyes.
- [x] the focus return after closing the openbox is bad; sometimes can't even
      refocus manually; closing on another workspace yanks back to origin;
      want rofi behavior.
      → FIXED `1d1827d`, and you were right that "there is a focus
      implementation there — is no good": the return half literally never ran
      (armed but never fired). That also caused the can't-refocus-manually
      case: the keyboard seat stayed stranded on the dead layer, and
      re-clicking the SAME window is a no-op to the compositor. Now: close on
      the same workspace → origin window gets focus+keyboard back (seat
      re-routed via a neighbor-detour); travelled to another workspace →
      you STAY there, its last window gets the keyboard; closed by clicking
      another window → your click is respected (unchanged).
      Round 2 `7c1f718`: the yank survived round 1 because the settle-force
      lives in frame.rs (the OLD implementation Max remembered — it always
      forced the origin). Now that site is workspace-aware.
      ✅ **VERIFIED BY MAX 2026-08-29** — all three behaviors good (open
      animation, focus return, workspace travel).
- [x] **F6 — not a bug.** The "braille spinner" was Claude Code's own
      terminal spinner inside the focused window's TITLE; the topbar window
      pill re-renders it on its ~1Hz tick (which the clock needs anyway).
      Event/tick-driven, not a stuck animation; frame loop still idles.
- [x] **F7 — explained, folded into todo7.** No code requests 'Noto Sans';
      the daemon asks for generic sans-serif and this system's fontconfig
      aliases that to Noto Sans (absent) → DejaVu fallback. The S7 flake
      must ship the chosen UI font AND set it as the default sans
      (fontconfig), plus the Nerd Font (F4). todo7 note updated.

- [ ] One week daily driving with a notes file; every surprise → a fix or
      a filed line here
- [ ] Exit review: zero known brokenness → open S7

- [x] "i dont like those colored shapes we are using for resizing, it
      should be the actual window changing shape." → the drag ghost's
      frosted plate (built 5c9fc85 same day: plate morphed, window image
      letterboxed inside) — Max overrides that design. Now `6dc84f8`: no
      plate; the window texture itself fills the morphing box, same
      stretch treatment as the sibling halves. Halo border kept. Version
      bumped 0.2→0.3 (identical version strings muddied the morning's
      crash triage). Hot-reloaded live, 0.3 confirmed. Needs your hands:
      drag a window over a sibling and over an empty view.
      (Same .so also carries the dragEnd TOCTOU re-checks from the crash
      round — first time that code is actually loaded.)
      Round 2 ("works, but the window content is really badly rendered
      during the resizing"): the naive stretch mangled pixels mid-morph.
      `880145c` v0.4: COVER-CROP — on any box/capture aspect mismatch the
      source is cropped centrally in UV space (object-fit: cover), so the
      window's pixels keep their aspect and the moving edges cut into
      them, like a real resize. Applies to the ghost AND the gliding
      sibling halves. Plumbing: CTexPassElement can't source-crop, so two
      plugin-side EK_CUSTOM pass elements plant/restore the renderer's
      global UV fields around the draw. Hot-loaded, 0.4 confirmed —
      needs your eyes on the same two drags.
      Round 3 ("still garbage") — crop-vs-stretch changed nothing Max
      saw, so the garbage is the SAMPLING: the morph animates a full-res
      capture through ~3x downscales; single-tap bilinear there = text as
      crawling aliasing (static minis mask the same flaw). `488715d`
      v0.5: mip chain rebuilt on every per-window capture; morph draws
      switch that texture to trilinear and restore bilinear behind them
      (settled minis untouched). Hot-loaded, 0.5 confirmed. If THIS is
      still garbage, the next round needs Max's words or a screenshot —
      what kind of bad: shimmering? blurry? blocky? wrong content?
      Round 4 ("still awful.. i want the life reaction on the workspaces
      too. both on the tiles and the grabbed") → LIVE COMMITS `362db9f`
      v0.6: after a 200ms dwell on a target the window is REALLY inserted
      (actual dwindle split / cross-view move); the tiles show the true
      re-tile springing (recapture boosted to ~20fps for 700ms); hover
      away re-grabs and the next dwell re-commits. Release on the
      committed spot = already done; elsewhere = classic drop; outside
      views / Esc / close = back to the ORIGINAL workspace+spot. The
      synthetic morphs and the shapeshifting ghost are retired (ghost
      keeps its own shape → the bad-render path is never hit). Content
      rendering of morphs = parked; live commits may make it moot.
      Hot-loaded, 0.6 confirmed. Your hands: grab, hover a sibling 200ms
      (watch the REAL split), hover elsewhere, release, and Esc mid-drag.
      Round 5 (Max: "i love it" + three feels: laggy / "doubts, confirms
      twice" / committed = feels dropped, wants to keep trying positions)
      → `f6f5956` v0.7, all four causes found:
      • double bounce = regrab snapshotted the pulled-out intermediate —
        re-commits now capture only the final insert (single bounce);
      • "laggy arrival" = the landing spring started at the -20000 parking
        spot, exposed by live captures — endRealDrag now un-parks to the
        drop point first (short spring, reads as a drop);
      • "feels dropped" = no feedback while committed — the held window
        keeps its halo in-slot; plus own-view empty space no longer
        re-commits (was churning into dwindle's stale-focus slot);
      • dwell 200→120ms; mipmap gen removed from captures (its morph
        consumers are gone) so the 20fps boost captures got cheaper.
      Hot-loaded, 0.7 confirmed. Tune points: DWELL (120ms), boost
      cadence (50ms) — say faster/slower.
      Round 6 ("still gets stuck, not that much but it does") →
      `c949b8d` v0.8: dwell-clock starvation. Every signature change
      restarted the 120ms clock, and the quadrant SIDE wobbles constantly
      (cursor slope + hitboxes drifting ~700ms post-commit while springs
      settle) — the clock could reset forever. Now only a target change
      (tile/under-window) restarts it; side flips commit at once when the
      dwell already elapsed (diagonal crossing = deliberate), guarded by
      a 150ms commit cooldown for on-the-diagonal jitter. Hot-loaded,
      0.8 confirmed.
      Round 7 (Max: "the window lands on each change... before, the
      windows and the ghost reacted to the INTENTION of landing. now the
      grabbed win lands and i loose it") → `5aa559a` v0.9 FREEZE-FRAME
      INTENTIONS: the dwell still lands the window for real, but the
      cycle is land → warp springs → capture ONE settled frame → pull it
      straight back into the hand (uncaptured). Tiles hold the frozen
      landed frame: really-squeezed siblings + a HOLE where it would sit;
      the ghost never leaves the cursor. Periodic captures pause during
      the gesture (they'd reveal the pulled-out reality). Release = real
      drop from the hand; over the hole, the promised split target is
      honored. Bonus fix: release handler reset g_dragWin BEFORE the drop
      logic, so the un-park and restore-original silently no-opped on
      all release paths. Hot-loaded, 0.9 confirmed.
      Round 8 ("its all laggy, flashes all over, the content on the
      windows get all mixed between each other. its a mess") → v0.9's
      freeze-frame was physically wrong: warp() snaps GEOMETRY instantly
      but clients hadn't redrawn, so the frozen capture baked old-size
      buffers stretched into new boxes (the mixing); per-commit sync
      captures + warp storms = the lag/flashes. `9c8af01` v0.10: warpWS
      deleted, back to the v0.8 live-commit engine (captures live while
      springs run, clients re-render truthfully), KEEPING the intention
      visual: dragged window hidden from tiles all gesture (committed
      slot = live HOLE amid really-squeezed siblings), ghost never leaves
      the cursor. Release on the hole reveals in place. Hot-loaded, 0.10
      confirmed.
      LESSON (do not retry): never capture immediately after warping
      window geometry — client buffers lag the layout by 1+ frames.
      Round 9 (Max: "looks good but needs some more work" → wants
      animations half speed to diagnose): SLOW-MOTION DEBUG MODE ON —
      'windows' spring halved SESSION-ONLY via
      `hyprctl eval 'hl.animation({ leaf = "windows", enabled = true,
      speed = 2.4, spring = "easy" })'` (config value stays 4.79; restart
      or reload restores). Plugin `c1bda5a` v0.11: capture boost 700ms →
      BOOST_MS 1400ms to cover the longer springs. REMEMBER to undo both
      (eval speed 4.79 back, BOOST_MS back to ~700) when diagnosis ends.
      Round 10 (slow-mo findings: "jumps on the animations", "traces on
      the other spaces and windows", "blinks", "its not slowed down") →
      `beafdde` v0.12, three causes:
      • not slowed: SPRING curves ignore the speed field (physics only) —
        now bound to easyHalf (stiffness 17.8, damp 7.9; half frequency,
        same damping ratio) via eval. UNDO slow-mo with:
        `hyprctl eval 'hl.animation({ leaf = "windows", enabled = true,
        speed = 4.79, spring = "easy" })'`
      • jumps: tile mapping ran on MID-FLIGHT geometry every 50ms capture
        (minis flipped across snap/seam thresholds between snapshots; slot
        motion sampled at 20fps beside the 165Hz ghost). Mapping now uses
        spring GOALS (moves once per commit); drawn boxes glide at frame
        rate (drawCur); captures refresh CONTENT only.
      • traces/blinks: cross-view arrival fade rendered the window
        half-transparent across snapshots → m_alpha.warp() after every
        moveWindowToWorkspaceSafe (alpha has no client-redraw lag — the
        round-8 lesson is about geometry, not alpha).
      Hot-loaded, 0.12 confirmed.
      Round 11 ("works way better, still some lightnings on other
      workspaces when im moving windows on another") → focus churn: every
      commit focuses the split target (dwindle needs it), and the
      dim_inactive/border-fade/alpha transitions animate across captures
      → bystander tiles glow. `16a9d1b` v0.13: warpFocusFx() snaps dim,
      border fade, alpha, shadow, glow on ALL windows at grab/regrab,
      commit, and drop (compositor-side cosmetics, no client-redraw lag).
      Hot-loaded, 0.13 confirmed. Slow-mo spring still active.
      Round 12 ("after a few movements all gets slowed down, kind of
      stuck") → GL framebuffer churn: captureWindows created a brand-new
      FB per window per capture (hundreds of full-res allocs/sec at the
      20fps boost) — driver degrades progressively. `08b7a35` v0.14: FBs
      pooled across captures (Carry.fb), realloc only on size change,
      vanished windows' FBs released explicitly. Hot-loaded, 0.14
      confirmed. Slow-mo spring still active.
      Round 13 ("a few times i grabed a window and it became floating")
      → the crash guards' cost: grab floats the window out; a dead drag
      target skips endDragTarget() (correct — that deref was the SEGV)
      but nobody undid the float. `8a0841a` v0.15: restoreFloatState()
      after every end attempt (endRealDrag + placeAt) — toggles
      changeFloatingMode() back only when the state differs from gesture
      start, so genuinely-floating windows keep floating. Hot-loaded,
      0.15 confirmed. Slow-mo spring still active.
      Round 14 ("the axis reording is not working well. it was good, now
      its not amazing anymore") → coordinate-frame drift: the user aims
      on the DISPLAYED tiles (committed preview, squeezed halves) but
      dwindle classifies the drop against the pulled-out REAL layout
      (target at full box) — 'below A' on the squeezed half reads as
      'beside A' on the full box. Pre-live-commits both frames were the
      same, hence "it was good". `a0ef359` v0.16: dropPointFor()
      translates the aimed side into a quarter-point inside that side's
      region of the target's real goal geometry (deterministic for any
      aspect); used by commits AND the classic-drop release. Hot-loaded,
      0.16 confirmed. Slow-mo spring still active; "still glitches"
      acknowledged — parked while axis was priority.
      Round 15 ("after a fer movements all gets frozen" AGAIN, + axis
      "little better but not great") → the remaining capture whale: every
      capture re-rendered ALL 18 workspaces full-res (~360 ws renders/s
      at boost, iGPU); a commit touches ≤2. `cfd4abc` v0.17: MASKED
      CAPTURES — dirty tiles accumulated at grab/commit/drop/restore;
      boost ticks refresh only those; the 150ms cadence does the full
      pass + clears. Off-mask tiles keep snapshot, their windows keep
      pooled crops. Backdrop skipped on partial captures.
      + TRACE LOG /tmp/waveview-trace.log (ms-stamped commit/regrab/
      drop/restore + capture mask/duration): next axis round reads the
      recorded aim-vs-result. Hot-loaded, 0.17 confirmed, log cleared.
      Round 16 ("i moved around and one window became floating") → THE
      TRACE PAID OFF IMMEDIATELY: caught `commit tile=7 desk=(-579,-622)`
      — an off-screen drop point. Root cause: the machinery's own
      warpCursorTo calls fire synthetic motion events that re-entered
      updateHoverAt mid-commit and overwrote g_dragCursor. dwindle fed
      garbage coords can't insert → floating window. Also explains
      residual bad reordering (warp-poisoned aims committing into the
      wrong tile/side without going negative). `3e3fde5` v0.18: g_busy
      re-entrancy guard, aim frozen before regrab/commit, commitAt aborts
      on stale tile containment, restoreFloatState nets on grab-reject +
      gesture end. Perf from the trace: masked captures ~10ms vs 130ms
      full — freeze margin confirmed gone. Hot-loaded, 0.18 confirmed.
      Round 17 ("the content of the grabed window and the reacting ones
      get mixed during the animations") → crops are cut from the
      workspace snapshot by each window's CURRENT rect, and mid-spring
      windows genuinely overlap in that snapshot → crops carry neighbour
      slivers. `9bc17b8` v0.19: OVERLAP-GATED CROPS — while a window
      overlaps any same-workspace sibling, its last clean crop is held
      (no realloc; cover-crop bridges size drift), refresh resumes on
      separation; first-ever captures render regardless. Hot-loaded,
      0.19 confirmed. Slow-mo spring still active.
      Round 18 ("its working") → SLOW-MO OFF: spring restored to easy /
      4.79 via eval (matches the .lua so nothing to clean up on restart),
      BOOST_MS back to 700ms. `ca322b3` v0.20 hot-loaded. The live-drag
      overhaul stands: live commits + hole/ghost intention visuals +
      goal mapping + frame-rate glide + masked captures + pooled FBs +
      overlap-gated crops + warp re-entrancy guard + float nets.
      Trace log stays on (/tmp/waveview-trace.log) for future rounds.
      NEXT: Max daily-drives it at full speed; expect fresh feel notes.
      ✅ **VERIFIED BY MAX 2026-08-30, full speed** — "its perfect it my
      side." Live-drag session closed after 18 rounds (v0.2 → v0.20):
      one compositor crash root-caused (upstream dragEnd null deref),
      one interaction model discovered (live commits with hole/ghost
      intention), and seven capture-pipeline root causes fixed. Trace
      log left armed for future rounds.
      Upstream filing (requested, then correctly aborted): the null
      deref is ALREADY FIXED on Hyprland main (`if (!draggingTarget)
      return false;`, post-Aug-11 refactors) but latest release v0.56.2
      (Aug 5) still crashes. Hyprland takes reports via Discussions and
      triages release-only crashes as "reproduce on -git" → would be
      closed as fixed. Nothing filed. Plugin guards stay until a
      post-0.56.2 release lands in nixpkgs (harmless after).

## Overview session (2026-08-30) — CLOSED, all verified by Max live
- Design settled by live iteration (mockups retired for this surface):
  gap 20 / outer 35 / top 12 / frame r28 / window r20 / seam 2.8%.
- Round 5 root cause: bar strip was baked into window mapping (usable-area
  fix) → "the gaps are all the same!" ✓
- Piecewise seam redistribution (uniform seams, aligned columns; twins
  faithful to their true desktop sizes) ✓
- Eased page flip (0.42s in-out cubic) + capture gating (no recapture
  mid-animation) → smooth ✓
- Super+R ladder: open → tour inhabited far page → close ✓ (with the
  key-swallow letting Super-combos through; Esc = direct close, never
  tours) ✓
- Touchpad: 3-up ladder, 3-down Esc, 2-finger paging (accumulated,
  clamped, no loop) ✓
- Super+digit page-relative in overview: Super+R,R,3 → ws12 ✓
