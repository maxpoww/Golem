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
  #   nixosConfigurations.golem     Max's machine (Slim Pro 9i, nvidia prime)
  #   nixosConfigurations.golem-vm  hardware-free test system:
  #                                 nixos-rebuild build-vm --flake .#golem-vm
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
    nixpkgs.url = "github:NixOS/nixpkgs/21ea275a7c46aef9d4d6ddc962e6d562e9d94183";

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
        ./system/configuration.nix
        home-manager.nixosModules.home-manager
        waverunner.nixosModules.notification-service
        {
          services.options-notify = {
            enable = true;
            enableKdeConnect = true;
          };
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.max = import ./system/home/home.nix;
          home-manager.extraSpecialArgs = { inherit waverunner waveview; };
        }
      ];
    in
    {
      packages.${system} = {
        inherit waveview;
      };

      nixosConfigurations.golem = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = golemModules ++ [
          ./hosts/golem/hardware-configuration.nix
          ./hosts/golem/nvidia.nix
          { golem.flakeDir = "/home/max/Golem"; }
        ];
      };

      nixosConfigurations.golem-vm = nixpkgs.lib.nixosSystem {
        inherit system;
        # The VM seeds its own flake checkout from the image (hosts/vm.nix)
        # so the installed-machine loop — waverunner-apply, rebuild-golem —
        # works there like it will on an ISO-installed Golem.
        specialArgs = { golemSrc = self; };
        modules = golemModules ++ [ ./hosts/vm.nix ];
      };
    };
}
