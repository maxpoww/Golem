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
    in
    {
      packages.${system} = {
        inherit waveview;

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
      };

      # The eval matrix (GolemInstall.md §8): every fact permutation — the
      # committed lab fixtures included — evaluates as a full golem-target
      # system with semantic assertions. `nix flake check`, or directly:
      # `nix build .#checks.x86_64-linux.facts-matrix`.
      checks.${system}.facts-matrix = import ./system/hardware/matrix.nix {
        lib = nixpkgs.lib;
        inherit pkgs mkTarget;
      };

      nixosConfigurations = {
        golem = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = golemModules ++ [
            ./hosts/golem/hardware-configuration.nix
            ./hosts/golem/nvidia.nix
            ./hosts/golem/audio-keepalive.nix
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
        };
    };
}
