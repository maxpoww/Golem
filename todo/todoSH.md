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

i want to resize windows with supr+arrows

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
      reveals lands THERE. Same rule applied inside open boxes. Try:
      drag to the edge, page flips, drop immediately — no stepping out.

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
