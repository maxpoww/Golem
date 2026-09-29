# todo6 — S6 Configuration UI

<!-- Coarse on purpose — break down on entry. -->

<!-- Whole section parked 2026-09-01: every item is Rust in the waverunner
     tree (out of reach from ~/Golem), and S6 is Arc 2 — under the Arc-1
     freeze a settings surface is exactly the "new OPTIONS surface" the
     roadmap forbids. See NOTES.md. -->

- [?] Inventory every existing knob (core::config TOML schema) — what must
      be surfaced vs stay expert-only; cross-check features.md §3 panel list
- [?] Design the settings surface (mockup first, like every OPTIONS surface)
- [?] Settings write intent → declarative config (TOML/generated nix), never
      imperative state — same model as packages.list
      — the model to copy is `system/waverunner-apply.nix` (data file →
      validated → generated nix → rebuild → status json), which is here
- [?] Live-apply where safe (theme, timings); mark what needs restart
- [?] Theme picker (colors, radius, materials)
- [?] OPTIONS toggles (link_unfurl, per-module enable/disable)
      — today's defaults are seeded in `system/home/home.nix`
      (`xdg.configFile."waverunner/config.toml"`): theme.icon_theme,
      options.link_unfurl. That file is the write target the toggles need.
