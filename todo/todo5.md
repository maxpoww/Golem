# todo5 — S5 The app set (see apps.md)

- [?] Decide default browser: Firefox (default) vs Chromium (webapp engine
      stays regardless) — record the decision in apps.md
- [x] `golem-apps.nix`: one module listing the whole CURATE column
      → `system/golem-apps.nix`, imported by `system/configuration.nix`.
      BUILD CHECK OWED: this session had no nix (harness allows Read/Edit/git
      only), so attribute names are knowledge-checked, not eval-checked —
      run `nixos-rebuild build-vm --flake .#golem-vm` before trusting it.
- [ ] Theming pass: make libadwaita apps look at home (accent, fonts, corners)
- [ ] Default apps / mime wiring: every file type opens in the right pick
- [ ] Per-app touch check (features.md §5 touchscreen)
- [ ] Music pick: try Decibels vs Amberol, keep one
- [ ] Replace launcher's Files section with Nautilus handoff
- [ ] Emoji/characters as system-wide input, not just an app
