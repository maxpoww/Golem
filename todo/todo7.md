# todo7 — S7 The Golem system flake

<!-- Coarse on purpose — break down on entry. -->

- [x] New repo (or `golem/` in the site repo?): the distro flake
      → Max's call 2026-08-30: the flake lives at the ROOT of ~/Golem (the
      plan repo doubles as the distribution) and pushes to the public
      github.com/maxpoww/Golem. `github:maxpoww/Golem` is directly buildable.
- [x] Compose: custom Hyprland 0.55.4 (+ Lua API) as a flake input/output
      → via the pinned nixpkgs input (exact live channel rev 21ea275a), same
      programs.hyprland the machine runs today; repin deliberately on bumps.
- [x] Compose: waverunner + options-notify + dictionaries + waverunner-apply
      → waverunner flake input: daemon (dictionaries wrapped in) + ctl via
      its homeManagerModules.default (systemd user service replaces the
      hyprland.lua waverunner-dev exec — no more debug builds on PATH);
      options-notify via its nixosModule; waverunner-apply REWRITTEN for the
      flake world (generates system/home/waverunner-packages.nix INSIDE the
      repo + git add — flakes can't see untracked files — and rebuilds with
      --flake; gated on golem.flakeDir, off in the VM; autoUpgrade dropped:
      flake upgrade = input bump, story TBD).
- [ ] Compose: `golem-apps.nix` (from S5)
- [x] Golem defaults: theming, fonts, hyprland.lua, session startup
      → home.nix/zsh/foot/nvim/yazi/webapp icons ported verbatim;
      hyprland.lua's three /home/max assumptions rewritten at build time
      (waveview .so from store path, waverunner via systemd, ctl from PATH).
      CAVEAT until cutover: hyprland.lua now exists in BOTH /etc/nixos and
      the flake — edits must land in both or they drift.
- [ ] Stopgap kit: curated plain GUIs for network/audio/bluetooth (each
      dies when its S4 module ships in Arc 2)
      → started: pavucontrol + networkmanagerapplet in systemPackages,
      blueman already shipped; audit what else a stranger needs (wifi
      first-connect flow!) before ticking.
- [x] Ship chromium (webapp engine fallback — SH F2 resolves it at runtime,
      the flake must make it exist)
      → google-chrome ships via home.nix programs.chromium (unfree on), so
      F2's first-choice browser exists on every Golem machine.
- [x] Pin fonts: the UI font + the Nerd Font the glyphs need (SH F4 —
      renderer loads system fonts only; without them, tofu pills). Also set
      the fontconfig default sans to the chosen font (SH F7: the daemon
      requests generic sans-serif; today that aliases to a missing Noto
      Sans → silent DejaVu fallback, i.e. the UI font is currently
      accidental)
      → flake ships JetBrains Mono + its Nerd Font + dejavu_fonts, and pins
      fontconfig default sans to "DejaVu Sans" — today's accidental look
      made deliberate, zero visual change. Choosing Golem's REAL UI font
      stays open as a design call (Max + mockup, per project law).
- [ ] Ship `~/notification-fix` (Chrome ext: FB/Messenger/IG notifications
      on Wayland — no occlusion tracking) with the webapp profile via
      `--load-extension`; it lives ONLY in Max's homedir today — get it
      into a repo first
- [x] User/home layer (home-manager module wired in)
      → home-manager flake input (release-26.05, follows nixpkgs) as a
      NixOS module, useGlobalPkgs; home-manager.users.max = system/home/.
- [x] `nixos-rebuild build-vm` target — one command → Golem VM (this becomes
      the daily test loop for S8/S9)
      → `nixos-rebuild build-vm --flake .#golem-vm && ./result/bin/run-Golem-vm`
      hosts/vm.nix: no nvidia, virtio-vga-gl, 4G/4 cores, greetd autologs
      max into Hyprland, initialPassword golem. BUILDS clean (2026-08-30);
      first graphical boot still needs eyes.
- [ ] Pin + document every input; the flake IS the distribution
      → nixpkgs pinned to the live channel rev; but waverunner + waveview
      inputs are still git+file:///home/max/... — ONLY Max's machine can
      build this flake until both repos are pushed to GitHub and repinned.
      That's the next S7 step.

## Log

- Round 1 (2026-08-30, "lets keep going with the plan" — SH had nothing
  actionable left for Claude, all remaining boxes are Max's hands or the
  daily-driving clock): S7 OPENED. Max decided the flake pushes to the
  empty public github.com/maxpoww/Golem; since local ~/Golem shares the
  name and had no remote, the plan repo IS the distro repo — flake.nix at
  the root. Ported all of /etc/nixos into system/ + hosts/ (nvidia split
  host-side so the VM is hardware-free); /etc/nixos left untouched and
  live until Max cuts over (cutover = `rebuild-golem`, which the flake
  builds as `nixos-rebuild switch --flake $flakeDir#golem`). Both
  nixosConfigurations eval clean; golem-vm BUILT first try (compiled
  waverunner release binaries for the first time ever — the live session
  still runs debug builds from the checkout). Secrets scan of the plan
  docs before the public push: clean. NEXT: Max runs
  ./result/bin/run-Golem-vm and eyeballs the first foreign-hardware boot;
  then push launcher + waveview to GitHub and repin the two local inputs.
