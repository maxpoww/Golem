# todo7 — S7 The Golem system flake

<!-- Coarse on purpose — break down on entry. -->

- [ ] New repo (or `golem/` in the site repo?): the distro flake
- [ ] Compose: custom Hyprland 0.55.4 (+ Lua API) as a flake input/output
- [ ] Compose: waverunner + options-notify + dictionaries + waverunner-apply
- [ ] Compose: `golem-apps.nix` (from S5)
- [ ] Golem defaults: theming, fonts, hyprland.lua, session startup
- [ ] Stopgap kit: curated plain GUIs for network/audio/bluetooth (each
      dies when its S4 module ships in Arc 2)
- [ ] Ship chromium (webapp engine fallback — SH F2 resolves it at runtime,
      the flake must make it exist)
- [ ] Pin fonts: the UI font + the Nerd Font the glyphs need (SH F4 —
      renderer loads system fonts only; without them, tofu pills)
- [ ] User/home layer (home-manager module wired in)
- [ ] `nixos-rebuild build-vm` target — one command → Golem VM (this becomes
      the daily test loop for S8/S9)
- [ ] Pin + document every input; the flake IS the distribution
