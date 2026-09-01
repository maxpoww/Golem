# todo9 — S9 Installer & ISO

<!-- Coarse on purpose — break down on entry. -->

- [x] NixOS ISO module wrapping the S7 flake — live session boots into real
      Golem (dock, OPTIONS, everything)
      → `hosts/iso.nix` + `nixosConfigurations.golem-iso` + `packages.iso`:
      `nix build .#iso`. The live session is the same configuration.nix and
      home layer the installed machine gets; the module is only the seam
      with nixpkgs' installation-cd profile (wpa_supplicant vs
      NetworkManager, no bootloader install, no gc on a read-only store,
      passwordless live `max`, ISO naming), plus /etc/golem/src so the
      installer can instantiate Golem from the stick.
      UNBUILT AND UNBOOTED HERE — this loop's harness has no `nix` (see
      NOTES). First boot is the test; the file's last comment block names
      the two things to suspect if it doesn't (systemd initrd on an overlay
      store; the quiet-boot black screen).
- [?] Decide installer: calamares-nixos vs our own guided surface (friction
      test decides — the installer is Golem's first impression)
- [?] Disk flow: guided partitioning, encryption option, one "install" action
- [ ] Hardware: graphics drivers, wifi firmware, unfree toggle
- [ ] Wifi in the install flow (an ISO that can't get online on another
      PC fails the Arc-1 exit)
- [ ] Verify the stopgap kit (S7) covers post-install life: network,
      audio, bluetooth reachable without terminal
- [ ] S10-lite: download link + honest install notes on golem-os.com
- [ ] Burn to USB, install on real metal, then on a machine that isn't yours
