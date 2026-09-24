{
  # SPDX-License-Identifier: GPL-3.0-or-later
  #
  # Golem OS — a Linux distribution built around OPTIONS.
  # Copyright (C) 2026 Max Power
  #
  # This program is free software: you can redistribute it and/or modify
  # it under the terms of the GNU General Public License as published by
  # the Free Software Foundation, either version 3 of the License, or
  # (at your option) any later version. See LICENSE for the full text.
  #
  # ── ── ──
  #
  # Golem OS — ONE flake = a complete Golem PC (roadmap S7).
  #
  #   nixosConfigurations.golem      Max's machine (Slim Pro 9i, nvidia prime)
  #   nixosConfigurations.golem-vm   hardware-free test system:
  #                                  nixos-rebuild build-vm --flake .#golem-vm
  #   nixosConfigurations.golem-iso  the live medium (S9):
  #                                  nix build .#iso → result/iso/golem-*.iso
  #
  # The flake IS the distribution: everything a Golem machine needs — the
  # compositor, waverunner (dock/launcher/OPTIONS), options-notify,
  # dictionaries, waveview overview plugin, theming, defaults — comes from
  # here. /etc/nixos remains the live channel-based config until Max cuts
  # over; this tree is its faithful, homedir-assumption-free port.

  description = "Golem OS — one flake, one complete Golem PC";

  inputs = {
    # Pinned to the exact rev the live machine's nixos-26.05 channel is on,
    # so the first builds come from the local store, not a world rebuild.
    nixpkgs.url = "github:NixOS/nixpkgs/c5c4a43b0e8056328ec4529f735cabdb8f1942bb";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # waverunner: dock + launcher + OPTIONS surfaces + options-notify +
    # offline dictionaries. Dev loop: point at the local checkout with
    #   nix build --override-input waverunner ~/launcher …
    waverunner = {
      url = "github:maxpoww/launcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # waveview: the 3x3 workspace-overview Hyprland plugin (plain
    # default.nix, packaged below). Same --override-input trick for dev.
    waveview-src = {
      url = "github:maxpoww/waveview";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, waverunner, waveview-src }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      waveview = import "${waveview-src}/default.nix" { inherit pkgs; };

      # Everything common to every Golem machine. Hardware lives in hosts/.
      golemModules = [
        # Every image/system names the source revision it was built from
        # (`nixos-version --configuration-revision`, and os-release
        # VARIANT_ID-adjacent tooling reads it too): a bug report that cannot
        # name its build is not actionable (release-checklist §1.2). A dirty
        # tree is labeled as such rather than lying with the last commit.
        {
          system.configurationRevision =
            self.rev or self.dirtyRev or "unknown";
        }
        ./system/configuration.nix
        home-manager.nixosModules.home-manager
        waverunner.nixosModules.notification-service
        ({ config, ... }: {
          services.options-notify = {
            enable = true;
            enableKdeConnect = true;
          };
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          # The home layer follows the machine's owner (golem.owner) — one
          # knob for the installer, not a name baked into the wiring.
          home-manager.users.${config.golem.owner} = import ./system/home/home.nix;
          home-manager.extraSpecialArgs = { inherit waverunner waveview; };
        })
      ];

      # The installed-Golem composition, as a function of the modules the
      # install flow drops in. ONE definition with three consumers — the
      # eval matrix (CI), the on-medium decision engine (golem-hw-decide),
      # and the install flow itself — so what CI proves, what the stick
      # reports, and what actually gets installed cannot drift apart.
      # Exposed as lib.golem.mkTarget below.
      mkTarget = extra: nixpkgs.lib.nixosSystem {
        inherit system;
        modules = golemModules ++ [ ./hosts/target ] ++ extra;
      };

      # The MODULAR twin of mkTarget (Installing spec): given a facts
      # attrset, compose the base + EXACTLY the leaves the chooser points
      # at + those facts, into an evaluable golem-minimal. The chooser is
      # the single brain here too, so "what the effect matrix proves" and
      # "what golem-install drops into modules.nix" cannot drift. Used by
      # checks.minimal-matrix to assert each chosen leaf's EFFECT on
      # source — build-and-test the hardware modules before any metal.
      mkMinimal = facts: extra: nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
          ./system/Modular/composition.nix
          { golem.hardware = facts; }
        ]
        ++ map (leaf: ./system/Modular + "/${leaf}")
          (import ./system/Modular/choose.nix { inherit facts; }).leaves
        ++ extra;
      };

      # 8e — THE ALL-IN BAKED MATRIX (Max, 2026-09-18, the Omarchy model).
      # Every lab hardware class's minimal toplevel, so the installer ISO can
      # carry the whole matrix and install by LOCAL COPY — no network. Its
      # UNION closure (measured ~6.69 GiB → ~4 GiB compressed ISO) is what
      # system.extraDependencies drags onto the medium. A machine whose exact
      # combo isn't a listed fixture still installs offline: all the heavy
      # driver/kernel/firmware paths are present, so its toplevel assembles
      # from baked components.
      bakedFacts = path: (import path { }).golem.hardware;
      bakedFixtures = [
        { name = "acer";     path = ./Installer/preinstall/fixtures/acer-aspire-e5-573/facts.nix; }
        { name = "asus";     path = ./Installer/preinstall/fixtures/asus/golem-hardware.nix; }
        { name = "comodore"; path = ./Installer/preinstall/fixtures/comodore-gm45/facts.nix; }
        { name = "hp";       path = ./Installer/preinstall/fixtures/hp-pavilion-dm4/facts.nix; }
        { name = "lenovo";   path = ./Installer/preinstall/fixtures/lenovo-slim-pro-9-16irp8/facts.nix; }
        { name = "macbook";  path = ./Installer/preinstall/fixtures/macbook-air-2013/facts.nix; }
        { name = "thinkpad"; path = ./Installer/preinstall/fixtures/thinkpad-e15-gen2/facts.nix; }
        { name = "qemu";     path = ./Installer/preinstall/fixtures/qemu-virtio/facts.nix; }
      ];
      # Placeholder filesystems so each toplevel BUILDS (the bake carries the
      # driver/kernel/firmware closures; the real per-machine toplevel — with
      # its own machine.nix + measured hardware-configuration.nix — assembles
      # from these baked components at install). by-label golem/ESP matches
      # what golem-install actually creates. Same shape effect-matrix uses.
      bakedFakeDisk = fw: {
        # UEFI mounts the ESP at /boot; BIOS/GRUB has NO ESP — /boot lives on the
        # root ext4 GRUB already reads (install.nix's BIOS layout is bios-boot +
        # swap + root, no ESP). A baked BIOS toplevel that carries the ESP /boot
        # mount hangs first boot for 90 s on a by-label/ESP device that never
        # appears, then drops to emergency (BIOS VM gate, 2026-09-24). Firmware-
        # split here matches the synthesized hardware-config in install.nix, which
        # only emits the /boot entry for UEFI.
        fileSystems = {
          "/" = { device = "/dev/disk/by-label/golem"; fsType = "ext4"; };
        } // bakedLib.optionalAttrs (fw == "uefi") {
          "/boot" = { device = "/dev/disk/by-label/ESP"; fsType = "vfat"; };
        };
        # THE FLOOR'S "boots on anything" initrd (8e HOLE C, 2026-09-18): a baked
        # toplevel is installed by DIRECT COPY, so it NEVER runs
        # nixos-generate-config to measure this machine's disk controller. With
        # only nixpkgs' default initrd set (ahci/nvme/sd_mod/xhci) the initrd
        # cannot find root on any other controller — proven fatal on virtio-blk
        # (root device by-label never appears → systemd-initrd emergency). These
        # make the disk reachable on any common machine at gen-1; the first
        # self-rebuild then measures and trims to the real hardware. Additive to
        # includeDefaultModules, so it only ever ADDS bootability.
        boot.initrd.availableKernelModules = [
          # the proven gap — every virtio disk transport
          "virtio_pci" "virtio_mmio" "virtio_blk" "virtio_scsi"
          # SATA/PATA/AHCI
          "ahci" "ata_piix" "ata_generic" "sata_nv" "sata_via" "sata_sis"
          # NVMe + SCSI disk/cdrom
          "nvme" "sd_mod" "sr_mod"
          # USB storage + host controllers
          "usb_storage" "uas" "xhci_pci" "ehci_pci" "ohci_pci" "uhci_hcd"
          # eMMC/SD
          "sdhci_pci" "mmc_block"
          # common SAS/RAID HBAs
          "mptspi" "megaraid_sas" "mpt3sas"
        ];
      };
      bakedLib = nixpkgs.lib;
      bakedFirmwares = [ "bios" "uefi" ];
      # The generic FLOOR (Max's never-fail L3): nothing confidently detected →
      # gpu/auto (boots on any GPU) + tier0 + no microcode/power. Baked per
      # firmware so an UNCLASSIFIABLE machine still resolves to a
      # direct-installable, bootable toplevel — never a from-source build.
      bakedFloorFacts = fw: {
        gpu = "auto"; cpuVendor = "unknown"; ramMB = 0;
        chassis = "unknown"; firmware = fw; vmGuest = "none"; hasBluetooth = false;
      };
      mkBakedEntry = { name, firmware, isFloor, facts }:
        let leaves = (import ./system/Modular/choose.nix { inherit facts; }).leaves; in {
          inherit name firmware isFloor leaves;
          key = bakedLib.concatStringsSep ":" leaves;
          toplevel = (mkMinimal facts [ (bakedFakeDisk firmware) ]).config.system.build.toplevel;
        };
      # COVERAGE: every class in BOTH firmwares (firmware picks grub-bios vs
      # grub-efi → a different leaf-list), plus the floor in both. So any
      # reachable leaf-list has a baked, direct-installable match; anything
      # unmatched falls to the floor for its firmware.
      bakedRaw =
        (bakedLib.concatMap (f:
          map (fw: mkBakedEntry {
            name = "${f.name}-${fw}"; firmware = fw; isFloor = false;
            facts = (bakedFacts f.path) // { firmware = fw; };
          }) bakedFirmwares) bakedFixtures)
        ++ map (fw: mkBakedEntry {
             name = "floor-${fw}"; firmware = fw; isFloor = true;
             facts = bakedFloorFacts fw;
           }) bakedFirmwares;
      # Dedupe by leaf-list KEY for the linkFarm (many collapse — intel-legacy-
      # bios recurs across hp/comodore/etc.); its CLOSURE is what
      # system.extraDependencies bakes onto the medium. The MANIFEST keeps every
      # named entry so golem-install can match exactly OR fall to a floor by
      # firmware — installing by DIRECT COPY (nixos-install --system <baked>),
      # no rebuild, so the eval-mismatch that broke the seed-rebuild can't happen.
      bakedUnique = builtins.attrValues
        (builtins.listToAttrs (map (e: { name = e.key; value = e; }) bakedRaw));
      bakedMatrix = nixpkgs.legacyPackages.${system}.linkFarm "golem-baked-matrix"
        (map (e: { name = e.key; path = e.toplevel; }) bakedUnique);
      bakedManifest = nixpkgs.legacyPackages.${system}.writeText "golem-baked-manifest.json"
        (builtins.toJSON (map (e: {
          inherit (e) name firmware isFloor leaves;
          toplevel = "${e.toplevel}";
        }) bakedRaw));
    in
    {
      packages.${system} = {
        inherit waveview bakedMatrix bakedManifest;

        # The Arc-1 deliverable: one command, one bootable Golem.
        iso = self.nixosConfigurations.golem-iso.config.system.build.isoImage;
      };

      # Policy the install flow consumes as code, not copies (the one
      # rule, spec §2). Hibernation is locked in, so every install carries
      # disk swap sized by THIS rule — the flow asks the flake:
      #   nix eval <src>#lib.golem.swapForHibernationMB --apply "f: f $ram_mb"
      lib.golem = {
        # The hibernation image is capped by RAM, but at hibernate time the
        # disk swap also absorbs what zram held — RAM plus a tenth (2 GiB
        # floor), rounded up to whole GiB, keeps both with room to spare.
        # 4 GB → 6 GiB, 8 GB → 10 GiB, 16 GB → 18 GiB, 32 GB → 36 GiB.
        swapForHibernationMB = ramMB:
          let margin = if ramMB / 10 > 2048 then ramMB / 10 else 2048;
          in ((ramMB + margin + 1023) / 1024) * 1024;

        # The target composition (see the let-binding for why it is shared).
        inherit mkTarget;

        # The decision surface: facts in, "here is exactly what Golem
        # chose" out. The medium's golem-hw-decide calls this with the
        # probe's freshly written golem-hardware.nix, so an audit over SSH
        # and CI's matrix are two questions asked of ONE composition.
        decide = import ./system/hardware/decide.nix {
          lib = nixpkgs.lib;
          inherit mkTarget;
          inherit (self.lib.golem) swapForHibernationMB;
        };

        # The post-install ASK surface (postinstall/postinstall.md): facts
        # in, the list of questions THIS machine triggers out. golem-install
        # calls this once, at install time, and drops the result into
        # hosts/target/postinstall-questions.json — decide answers what
        # Golem chose; this answers what Golem deliberately did NOT choose.
        postinstallQuestions = import ./system/hardware/postinstall.nix {
          lib = nixpkgs.lib;
          inherit mkTarget;
        };

        # The keyboard table (the installer's step 2, as data). One answer
        # in, every setting an installed machine needs out — and the same
        # table CI verifies against kbd + xkeyboard-config, so the surface
        # cannot carry a name the packages do not know:
        #   nix eval .#lib.golem.keyboards.derive --apply 'f: f "colemak"'
        #   nix eval --raw .#lib.golem.keyboards.table
        keyboards = import ./system/hardware/keyboards.nix {
          lib = nixpkgs.lib;
        };

        # The timezone step. The ZONE LIST is not here — tzdata ships it and
        # the medium carries it, so the surface reads it at runtime and
        # there is no second copy to drift. What is here is the default a
        # language implies, which is the only part needing a human.
        timezones = import ./system/timezones.nix {
          lib = nixpkgs.lib;
        };
      };

      # The eval matrix (GolemInstall.md §8): every fact permutation — the
      # committed lab fixtures included — evaluates as a full golem-target
      # system with semantic assertions. `nix flake check`, or directly:
      # `nix build .#checks.x86_64-linux.facts-matrix`.
      checks.${system} = {
        facts-matrix = import ./system/hardware/matrix.nix {
          lib = nixpkgs.lib;
          inherit pkgs mkTarget;
          inherit (self.lib.golem) keyboards;
        };

        # The chooser's chosen-list assertions (Installing constitution
        # rule 4): every lab fixture pinned to its exact pointer list,
        # nvidia machines pinned to their loud refusal until their
        # leaves land. A rule change in Modular/choose.nix that moves a
        # machine's list fails here.
        chooser-matrix = import ./system/Modular/matrix.nix {
          lib = nixpkgs.lib;
          inherit pkgs;
          choose = import ./system/Modular/choose.nix;
        };

        # The EFFECT matrix (Installing, Max 2026-09-10: build & test the
        # hardware modules on source): compose each machine's chosen
        # leaves via mkMinimal and assert the evaluated config. A leaf
        # whose values drift fails here, before metal.
        minimal-matrix = import ./system/Modular/effect-matrix.nix {
          lib = nixpkgs.lib;
          inherit pkgs mkMinimal;
        };

        # The keyboard table's names, against the packages that consume
        # them. facts-matrix proves an evaluated config says what we meant;
        # it cannot prove `console.keyMap = "gb"` is a keymap that exists.
        # This can, and it runs in seconds rather than minutes.
        keyboard-table = import ./system/hardware/keyboard-check.nix {
          lib = nixpkgs.lib;
          inherit pkgs;
          inherit (self.lib.golem) keyboards;
        };

        # Every language's default zone, against tzdata. Europe/Kiev was
        # right for twenty years and is now Europe/Kyiv; only tzdata knows.
        timezone-defaults = import ./system/timezone-check.nix {
          lib = nixpkgs.lib;
          inherit pkgs;
          inherit (self.lib.golem) timezones;
        };
      };

      nixosConfigurations = {
        golem = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = golemModules ++ [
            ./hosts/golem/hardware-configuration.nix
            ./hosts/golem/nvidia.nix
            ./hosts/golem/audio-keepalive.nix
            ./hosts/golem/locale.nix
            { golem.flakeDir = "/home/max/Golem"; }
          ];
        };

        golem-vm = nixpkgs.lib.nixosSystem {
          inherit system;
          # The VM seeds its own flake checkout from the image (hosts/vm.nix)
          # so the installed-machine loop — waverunner-apply, rebuild-golem —
          # works there like it will on an ISO-installed Golem.
          specialArgs = { golemSrc = self; };
          modules = golemModules ++ [ ./hosts/vm.nix ];
        };

        golem-iso = nixpkgs.lib.nixosSystem {
          inherit system;
          # Same source-on-the-medium trick as the VM: the ISO carries the
          # flake it was built from, so the installer (todo9 items 2-3) can
          # instantiate Golem from the stick rather than from the network.
          specialArgs = { golemSrc = self; };
          modules = golemModules ++ [ ./hosts/iso.nix ];
        };
      }
      # The installed-Golem target (spec §6): `nixos-install --flake
      # <seeded-checkout>#golem-target`. The attr appears only once the
      # install flow has dropped hardware-configuration.nix into
      # hosts/target/ — in the repo as published a target with no disk
      # layout cannot evaluate, and `nix flake check` must stay green.
      // nixpkgs.lib.optionalAttrs
        (builtins.pathExists ./hosts/target/hardware-configuration.nix) {
          golem-target = nixpkgs.lib.nixosSystem {
            inherit system;
            modules = golemModules ++ [ ./hosts/target ];
          };

          # The MODULAR stage-0 target (Installing spec, 2026-09-10):
          # base composition + the chooser's pointer list + the same
          # dropped target files — and NOTHING from the fat tree. The
          # home layer here is zsh-only (base/zsh.nix wires it); the
          # desktop/program leaves arrive with their stages by rebuild.
          golem-minimal = nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [
              {
                system.configurationRevision =
                  self.rev or self.dirtyRev or "unknown";
              }
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
              }
              ./system/Modular/composition.nix
              ./hosts/target/golem-hardware.nix
              ./hosts/target/hardware-configuration.nix
              ./hosts/target/machine.nix
            ]
            ++ nixpkgs.lib.optional
              (builtins.pathExists ./hosts/target/modules.nix)
              ./hosts/target/modules.nix;
          };
        };
    };
}
