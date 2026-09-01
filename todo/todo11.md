# todo11 — S11 Everyone-hardening (cross-cutting)

<!-- Runs alongside S8–S10, closes last. -->

- [?] i18n pass: shell strings extractable, Spanish first (dictionary
      already leads the way)
- [?] Keyboard-only audit: every gesture reachable without a pointer
      *(the compositor half of the answer is already collected:
      `accessibility-research.md` §5 — every window/workspace/launcher/
      overview action has a bind in `system/home/hyprland.lua:263-329`.
      The gap is the surfaces, which is the half this session can't see.)*
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
- [?] Reduce-motion / reduce-transparency modes (our glass needs an off switch)
      *(design settled from here — `accessibility-research.md` §4: one
      intent, four consumers (compositor animations `hyprland.lua:172`,
      compositor transparency `:139-156`, the shell via `config.toml`
      `home.nix:316-326`, the apps via dconf `home.nix:102-107`). The
      engine has to read the flag first or the other three are pointless.)*
- [?] Non-expert testing rounds: watch real people, fix what confuses them
- [?] The final check: is the word "everyone" on the website true?
      *(the honest answer, with citations, is `accessibility-research.md`
      §8 — today it's an intention, not a description)*
