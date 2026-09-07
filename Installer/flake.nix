{
  # The installer medium, minimal cut: a console-only NixOS that boots to a
  # terminal and nothing else. This is the SECOND Golem ISO — the first
  # (../hosts/iso.nix, `nix build ..#iso`) is the full live session; this one
  # is the seed the guided installer will grow in (Max, 2026-09-03: "for now
  # a terminal. simple, minimal").
  #
  # It stays a SEPARATE medium (PLAN.md's separation rule) but is no longer
  # a separate island: the parent flake is an input, so the census, the
  # module library and the target composition on the stick are the same
  # code the installed machine runs — reuse, not mixing.
  description = "Golem installer ISO — minimal console cut";

  inputs = {
    # The distro itself. A relative path input: MiniGolem lives in a
    # subdirectory of the Golem repo and is built from there, so this
    # resolves to the same git tree without hardcoding anyone's $HOME.
    golem.url = "path:../";

    # Every input FOLLOWS the parent's lock. The old copy of the nixpkgs
    # rev in this file said "so the installer medium can never drift from
    # what it installs" — a comment, enforced by nothing. `follows` is
    # that promise made structural: there is exactly one pin now, upstairs.
    #
    # These are declared (rather than reached through `golem`) because the
    # medium needs their STORE PATHS: an offline eval on the stick pins
    # each one with --override-input instead of resolving the lock's
    # github URLs. waverunner's own inputs are here for the same reason —
    # forcing its module set reaches them.
    nixpkgs.follows = "golem/nixpkgs";
    home-manager.follows = "golem/home-manager";
    waverunner.follows = "golem/waverunner";
    waveview-src.follows = "golem/waveview-src";
    waverunner-hm.follows = "golem/waverunner/home-manager";
    waverunner-nid.follows = "golem/waverunner/nix-index-database";
  };

  outputs =
    { self
    , nixpkgs
    , golem
    , home-manager
    , waverunner
    , waveview-src
    , waverunner-hm
    , waverunner-nid
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # The pinning table the on-medium eval runs with. Names are the
      # input names AS THE PARENT FLAKE DECLARES THEM (the eval overrides
      # ../flake.nix's inputs, not this file's), which is why the two
      # waverunner sub-inputs use slash paths.
      inputOverrides = [
        { name = "nixpkgs"; path = nixpkgs; }
        { name = "home-manager"; path = home-manager; }
        { name = "waverunner"; path = waverunner; }
        { name = "waveview-src"; path = waveview-src; }
        { name = "waverunner/home-manager"; path = waverunner-hm; }
        { name = "waverunner/nix-index-database"; path = waverunner-nid; }
      ];

      # One derivation that references every pinned input, so naming it in
      # system.extraDependencies drags them all into the medium's store —
      # without which the --override-input paths above would point at
      # nothing on the stick and the offline eval would die on arrival.
      # It doubles as a browsable /etc/golem/inputs for whoever debugs it.
      offlineSeed = pkgs.linkFarm "golem-offline-seed"
        (map (o: {
          name = nixpkgs.lib.replaceStrings [ "/" ] [ "-" ] o.name;
          path = o.path;
        }) inputOverrides);

      # The pin table as nix CLI arguments. Computed once and shared: both
      # on-medium tools evaluate the SAME flake with the SAME inputs, so
      # "what golem-hw-decide reported" and "what golem-install built"
      # cannot be two different systems.
      overrideArgs = builtins.concatStringsSep " \\\n      "
        (map ({ name, path }: "--override-input ${name} ${path}") inputOverrides);

      # Both are plain { pkgs, ... } modules whose only output is one
      # systemPackages entry; unwrapped here because the boot-time audit
      # needs the DERIVATIONS, not a system profile — a systemd unit gets
      # an explicit PATH and cannot see /run/current-system/sw/bin.
      hw-detect = builtins.head
        ((import ../system/hardware-detect.nix { inherit pkgs; })
          .environment.systemPackages);
      hw-evidence = builtins.head
        ((import ./evidence.nix { inherit pkgs; })
          .environment.systemPackages);

      hw-decide = import ./decide.nix {
        inherit pkgs overrideArgs;
        golemSrc = golem;
      };

      install = import ./install.nix {
        inherit pkgs overrideArgs;
        golemSrc = golem;
      };

      # The surface. Its keyboard table is rendered from the parent's
      # lib.golem — the same data the keyboard-table CI check verifies —
      # so what the stick shows and what CI proves are one source.
      setup = import ./setup.nix {
        inherit pkgs;
        keyboardsTable = golem.lib.golem.keyboards.table;
      };
    in
    {
      nixosConfigurations.golem-installer = nixpkgs.lib.nixosSystem {
        inherit system;
        # The medium carries the distro's source and everything the census
        # needs to evaluate it without a network (see iso.nix).
        specialArgs = { inherit golem hw-decide hw-detect hw-evidence install setup offlineSeed; };
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ./iso.nix
        ];
      };

      packages.${system} = rec {
        iso = self.nixosConfigurations.golem-installer.config.system.build.isoImage;
        default = iso;

        # The lab's fast path (PLAN.md): build a tool alone and `nix copy`
        # it to a live medium over SSH — the census iterates over the wire;
        # the stick is reflashed only for boot-level changes.
        inherit hw-decide hw-detect hw-evidence offlineSeed;
        golem-install = install;
        golem-setup = setup;
      };
    };
}
