# todo6 — S6 Configuration UI

<!-- Coarse on purpose — break down on entry. -->

- [ ] Inventory every existing knob (core::config TOML schema) — what must
      be surfaced vs stay expert-only; cross-check features.md §3 panel list
- [ ] Design the settings surface (mockup first, like every OPTIONS surface)
- [ ] Settings write intent → declarative config (TOML/generated nix), never
      imperative state — same model as packages.list
- [ ] Live-apply where safe (theme, timings); mark what needs restart
- [ ] Theme picker (colors, radius, materials)
- [ ] OPTIONS toggles (link_unfurl, per-module enable/disable)
