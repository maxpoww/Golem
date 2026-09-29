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
      UPDATE 2026-09-01: it did not even evaluate — `boot.loader.timeout`
      collided with iso-image.nix's own value and the config was dead on
      arrival. Fixed in `7441320`; `.#iso` now resolves to golem.iso.drv.
      The tick above stays, since the module is written; what it was
      silently asserting is split out as its own item below.

- [x] BUILD the ISO: `nix build .#iso` green, and fix whatever falls out
      *(new 2026-09-01 — this is what todo9 item 1's tick was asserting
      without evidence. BUILT GREEN before this run, so the store is warm:
      `/nix/store/kdfj9gvqz0n4i5rc6mjvl910jh21fxd3-golem.iso`. Verified
      structurally — ISO9660 magic, an El Torito boot catalog, volume ID
      GOLEM_ISO. Booting it is NOT in scope: no qemu on this machine and no
      display, so that stays Max's. Two things DID fall out, and they are
      what is left of this item:
      1. `isoImage.isoBaseName`/`volumeID` (`hosts/iso.nix:89-90`) are
         deprecated — eval warns they are renamed to `image.baseName`.
         Rename, rebuild, confirm the warning is gone and volumeID survives.
      2. THE IMAGE IS 6.4 GiB. That is not weak compression — squashfs is
         already at the nixpkgs default `zstd -Xcompression-level 19` — it
         is genuine payload: google-chrome, the whole golem-apps.nix set and
         the full home layer, because "live session boots into REAL Golem"
         is the item. Record the number and what drives it (`nix path-info
         -rS` on the toplevel will rank the closure). Do NOT start cutting
         apps to shrink it — what ships in the live session is a curation
         call and Max's. This is a finding for S10, whose download link this
         blocks, not a licence to trim.)*
      CLOSED 2026-09-01: (1) only `isoBaseName` was ever renamed —
      `image.baseName` since 25.05; `isoImage.volumeID` is still the current
      option in this pin and never warned. Renamed in hosts/iso.nix, rebuilt
      green, no deprecation warning, and the ISO9660 PVD still reads
      GOLEM_ISO (checked at byte offset 32808 of the image). File stays
      plain `golem.iso` (the new upstream default bakes edition+label+arch
      into baseName, so forcing the whole basename drops them — same
      behaviour the alias already had). (2) The number: golem.iso is
      6.33 GiB (6 796 468 224 bytes) from an 18.7 GiB uncompressed closure.
      What drives it, top of `nix path-info -rs` ranked, every one entering
      via the home layer's package set (home-manager-path): android-studio
      3.3 GiB, cef-binary 2.0 GiB (dragged by obs-studio), linux-firmware
      0.78 GiB (enableAllFirmware, expected), chromium-unwrapped 0.70 GiB
      (a SECOND Chrome next to google-chrome 0.43 GiB), openjdk 0.57 GiB,
      llvm-lib 0.54 GiB, firefox 0.38 GiB (a THIRD browser), spotify
      0.37 GiB, gcc 0.26 GiB. Curation calls for S10 — recorded, not cut.
- [?] Decide installer: calamares-nixos vs our own guided surface (friction
      test decides — the installer is Golem's first impression)
- [?] Disk flow: guided partitioning, encryption option, one "install" action
- [x] Hardware: graphics drivers, wifi firmware, unfree toggle
      → wifi firmware was the real hole: NOTHING in this tree enabled
      firmware (`enableRedistributableFirmware` was only ever read, for
      microcode), so wifi would have worked in the live session — the ISO
      profile ships firmware — and died on the first reboot after install.
      `hardware.enableAllFirmware = true` in system/configuration.nix.
      Graphics: nothing to name for the open stack (kernel KMS + the
      firmware above + hardware.graphics from the compositor module);
      nvidia is a HOST choice, so a stranger's nvidia machine lands on
      nouveau — deferred to the generic host in item 3, stated in the
      config. Unfree: already always-on, and the shipped set (google-chrome
      engine, firmware, nvidia) means a "no" would break Golem — so it is a
      baked-in stance, not a toggle. Comments say all three in place.
- [?] Wifi in the install flow (an ISO that can't get online on another
      PC fails the Arc-1 exit)
- [?] Verify the stopgap kit (S7) covers post-install life: network,
      audio, bluetooth reachable without terminal
- [?] S10-lite: download link + honest install notes on golem-os.com
- [?] Burn to USB, install on real metal, then on a machine that isn't yours
