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

the border on the overview are all diferent sizes, the smaller the window the smaller (thinner) the border, make them all look like my workspace window borders, same color, same tickness, etc. 

overview opens somethimes with no pointer.  

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
