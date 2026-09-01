# todo11 — S11 Everyone-hardening (cross-cutting)

<!-- Runs alongside S8–S10, closes last. -->

- [x] i18n pass: shell strings extractable, Spanish first (dictionary
      already leads the way)
      *(UNPARKED 2026-09-01: "the shell" is waverunner's Rust and ~/launcher
      is now in scope. Do the FIRST half only — pick an extraction mechanism
      and wrap the user-visible strings in it. That is a refactor, not a new
      surface, so the freeze allows it. Do NOT translate: `es_BO` is pinned
      onto every machine at `system/configuration.nix:98-110` and changing
      that is the installer's question and Max's daily driver, so it stays
      his. Keep `nix develop -c cargo test --workspace` green.)*
      *(DONE 2026-09-01, launcher 7ae5112: new `crates/daemon/src/i18n.rs`
      — gettext-style `tr()`, English literal = key + fallback, table is a
      flat JSON map at `<data-dir>/i18n/<tag>.json` (or `$WAVERUNNER_I18N`),
      tag from `LC_ALL`→`LC_MESSAGES`→`LANG`, `es_BO` tried before `es`.
      Zero new deps (serde_json, same shape as dict.rs). 36 strings + 12
      month keys wrapped across 8 files; extraction is
      `grep -rhoE 'i18n::tr\("[^"]+"\)'`. Recycle Bin translates at display
      keyed off TRASH_ID so persisted state stays English. To ship Spanish
      later: drop `es.json` in the data dir — no code change. clippy clean,
      249 tests green (4 new).)*
- [x] Keyboard-only audit: every gesture reachable without a pointer
      *(DONE 2026-09-01 → `keyboard-audit.md`. Read from the input code of
      both trees (launcher 7ae5112, waveview e49da53), every row cited.
      Verdict: navigation is covered — popup search/arrows/Enter/Escape is
      a real keyboard model, waveview has digits/Esc/tour — but curation
      is not: every model-editing drag (pin, reorder, box, install,
      uninstall, trash) has no keyboard path, both topbar boxes are
      pointer-only end to end (notifications = the sharpest edge), and
      fullscreen has no bind at all. `follow_mouse = 2` is NOT a fight:
      hover moves cursor focus only, keyboard focus moves on click — the
      §5 worry is retired, one live check added to research §7. Audit
      only, per the freeze: no code changed, nothing invented.)*
      *(UNPARKED 2026-09-01: the compositor half is already collected in
      `accessibility-research.md` §5 — every window/workspace/launcher/
      overview action has a bind in `system/home/hyprland.lua:263-329`. The
      missing half was the surfaces, and ~/launcher and ~/waveview are both
      in scope now. This is an audit that produces a document, not a code
      change: read the input handling in both trees and fill in the rows —
      dock, pills, boxes, the drag-to-install gesture, the overview's drags.
      Write "no keyboard path" where that is the finding; do not invent one.
      One thing to check while in there: `input.follow_mouse = 2`
      (`hyprland.lua:250`) lets the pointer move focus, which may fight
      keyboard-only navigation.)*
- [x] Accessibility research: what a11y means for a layer-shell/wgpu surface
      (hard problem — investigate early, don't leave for last; features.md §9)
      → `accessibility-research.md`. The finding that reorders the work:
      Golem has three renderers with three different stories, and **the
      parts that are ours are the inaccessible ones** — every GTK app we
      ship is one Nix option from being screen-reader usable (no
      `at-spi2-core`, no `orca`, no accessibility bus anywhere in this
      tree), while the shell publishes no tree at all. wgpu is not the
      blocker it looks like: AT-SPI is D-Bus, not Wayland, so a GPU client
      can be accessible — via AccessKit — it just has to build the tree by
      hand. Two things the item's framing missed: (a) **six of the nine
      §9 rows are compositor work**, not shell work, and three of those
      (magnifier — the fork already animates a `zoomFactor` leaf, colour/
      contrast output shader, on-screen keyboard) are roughly a day each;
      (b) a perfect tree still leaves Orca **undrivable**, because Wayland
      grants no global key grabs and only GNOME has the plumbing — Golem
      forks the compositor, so that route is ours to build and no plan
      works without it. §6 orders the cheap true steps, §7 is the checklist
      for a session with a machine, §8 answers the last item in this file.
- [x] Reduce-motion / reduce-transparency modes (our glass needs an off switch)
      *(DONE 2026-09-01, launcher d47951c — the engine step the unpark
      scoped. New `[accessibility]` config.toml section: `reduce_motion`
      snaps every animation primitive (ease_toward / Follower / Spring /
      Timed, plus the three steppers outside them: box open/close, launch
      bounce, click ripple+box wave) — install rings and the battery alarm
      still animate, information not ornament. `reduce_transparency`
      rewrites the theme background opaque at startup, lifts the OPTIONS
      boxes' panel/zebra to alpha 1.0, and draws the bar as the boxes'
      opaque slab. Both default off — resting look byte-identical. 252
      tests green (3 new), clippy -D warnings clean; not seen live (no
      display this run). Ordering now unblocked: the three repo-side
      consumers (`hyprland.lua:172`, `:139-156`, dconf enable-animations)
      wait only on the ONE intent that writes all four — that writer is
      S6's settings surface, frozen until Arc 2.)*
      *(UNPARKED 2026-09-01: NOTES recorded this as blocked "only on
      ordering" — the engine must read the flag before the other three
      consumers are flipped, and the engine was out of reach. ~/launcher is
      in scope now, so do the engine step: waverunner reads a reduce-motion /
      reduce-transparency intent from `xdg.configFile."waverunner/config.toml"`
      (`home.nix:316-326`) and honours it in its own motion and glass.
      Design is settled in `accessibility-research.md` §4: ONE intent, four
      consumers, never a per-layer toggle. Do NOT flip the compositor
      one-liners (`hyprland.lua:172`, `:139-156`) until the engine lands —
      that produces the worst result, windows still and the dock still
      flying. Keep the workspace tests green.)*
- [?] Non-expert testing rounds: watch real people, fix what confuses them
- [?] The final check: is the word "everyone" on the website true?
      *(the honest answer, with citations, is `accessibility-research.md`
      §8 — today it's an intention, not a description)*
