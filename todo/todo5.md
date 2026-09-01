# todo5 — S5 The app set (see apps.md)

- [?] Decide default browser: Firefox (default) vs Chromium (webapp engine
      stays regardless) — record the decision in apps.md
- [x] `golem-apps.nix`: one module listing the whole CURATE column
      → `system/golem-apps.nix`, imported by `system/configuration.nix`.
      BUILD CHECK OWED: this session had no nix (harness allows Read/Edit/git
      only), so attribute names are knowledge-checked, not eval-checked —
      run `nixos-rebuild build-vm --flake .#golem-vm` before trusting it.
- [x] Theming pass: make libadwaita apps look at home (accent, fonts, corners)
      → `system/home/home.nix`: gtk module (DejaVu Sans 11, Papirus-Dark,
      prefer-dark for GTK3/4) + gtk4 CSS overriding accent to the desktop's
      #ffbe98 + dconf color-scheme/accent-color/document+monospace fonts.
      Corners needed nothing: libadwaita's radius isn't configurable and
      Hyprland already rounds to 12, which is what Adwaita draws.
      Same BUILD CHECK OWED as above — and the aesthetic verdict is Max's
      eyes, this only wires the levers to values the desktop already uses.
- [x] Default apps / mime wiring: every file type opens in the right pick
      → `xdg.mimeApps` in `system/home/home.nix`: directories→Nautilus,
      text/code→Text Editor, images→Loupe, video→Showtime, audio→Decibels,
      pdf/epub→Papers, archives→File Roller, plus ISO/calendar/vcard/geo.
      text/html + http(s) left OUT on purpose — those ARE item 1, and
      wiring them would settle the browser by the back door.
      Same BUILD CHECK OWED. Also: a machine with a hand-written
      ~/.config/mimeapps.list will need it moved aside on first rebuild.
- [ ] Per-app touch check (features.md §5 touchscreen)
- [ ] Music pick: try Decibels vs Amberol, keep one
- [ ] Replace launcher's Files section with Nautilus handoff
- [ ] Emoji/characters as system-wide input, not just an app
