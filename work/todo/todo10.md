# todo10 — S10 Website & release

<!-- Coarse on purpose — break down on entry. Manifesto is live (2026-08-29). -->

- [?] Site structure: manifesto ✔ · screenshots/video of real motion ·
      download · install guide
- [?] Capture real screenshots/screencasts (the motion IS the pitch)
- [?] Headline the Ground superpower: atomic updates + "roll back" button
      (no mainstream OS matches it)
      *(the honest version of this claim is settled in
      `release-checklist.md` §3 — the atomicity is real, the button is not)*
- [x] Alpha release checklist: versioning ("Golem 26 Uprise"), known
      issues, feedback channel
      → `release-checklist.md`. Versioning: "26" is the nixpkgs train
      (26.05), "Uprise" the codename, and `system.stateVersion` is neither
      — today the name lives in one markdown line and every machine still
      says NixOS in os-release and the boot menu, the branding change
      `hosts/iso.nix:87` already assigned to S10, named there with the two
      calls inside it (distroId, label vs tags). Known issues: the first
      single list of what a tester actually hits — five that block the
      Arc-1 exit, four that ship broken on purpose (every user is named
      `max`, and the apply service watches /home/max, so installing an app
      does nothing on any other account; Max's timezone and es_BO locale
      are everyone's), and the uncomfortable group of seven SH items that
      are fixed in code but that no human has looked at. Feedback channel
      is the one part left open — it is Max's pick, and the checklist
      states the two constraints it has to satisfy (one front door for
      three repos; reachable from a machine whose wifi may not work) plus
      a recommendation.
- [?] Publish ISO + instructions on golem-os.com
