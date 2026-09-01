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

- [ ] BUILD the ISO: `nix build .#iso` green, and fix whatever falls out
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
