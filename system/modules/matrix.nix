# THE MODULES' effect matrix (2026-11-19) — the twin of desktop-matrix.nix for
# system/modules. Not "the file sets programs.steam" but "the composed
# desktop, with Gaming switched on, really has Steam's system side — and a
# machine that chose nothing has none of it". Evaluation only: nothing is
# built.
#
#   nix build .#checks.x86_64-linux.modules-matrix
{ lib, pkgs, mkMinimal, waverunner }:

let
  fakeDisk = {
    nixpkgs.hostPlatform = "x86_64-linux";
    fileSystems."/" = { device = "/dev/disk/by-label/golem"; fsType = "ext4"; };
    fileSystems."/boot" = { device = "/dev/disk/by-label/ESP"; fsType = "vfat"; };
  };
  desktop = ../Modular/desktop/default.nix;
  fixture = name: (import (../../Installer/preinstall/fixtures + "/${name}/facts.nix") { }).golem.hardware;
  amd = fixture "thinkpad-e15-gen2";
  nvidia = fixture "lenovo-slim-pro-9-16irp8";

  # The dock's own catalog, named outright (these compositions carry no
  # home layer to find it through).
  catalog = { golem.modules.catalog = "${waverunner}/crates/daemon/assets/modules.json"; };
  system = facts: extra: mkMinimal facts ([ fakeDisk desktop catalog ] ++ extra);
  conf = facts: extra: (system facts extra).config;

  ids = builtins.attrNames (import ./lib.nix { inherit lib; }).categories;

  ex = name: ok: { inherit name ok; };
  groups = c: c.users.users.${c.golem.owner}.extraGroups;
  names = c: map lib.getName c.home-manager.users.${c.golem.owner}.home.packages;
  mine = c: lib.filter (w: lib.hasPrefix "golem.modules" w) c.warnings;
  failing = c: lib.filter (a: !a.assertion) c.assertions;
  count = needle: text: builtins.length (lib.filter builtins.isList (builtins.split needle text));
  rootGroups = [ "docker" "libvirtd" "lxd" "incus-admin" "disk" "shadow" "root" "kmem" ];

  clean = conf amd [ ];

  # Gaming as its switch gives it: the catalog's recommended programs.
  gaming = conf amd [ { golem.modules.gaming.enable = true; } ];
  # …one program more, and one of the recommended refused.
  gamingPicked = conf amd [{
    golem.modules.gaming = { enable = true; lutris.enable = true; steam.enable = false; };
  }];
  # Programs one by one, the module itself never switched on.
  byHand = conf amd [{
    golem.modules.development.docker.enable = true;
    golem.modules.development.direnv.enable = true;
    golem.modules.windows-apps.virt-manager.enable = true;
    golem.modules."3d-printing".prusa-slicer.enable = true;
    golem.modules.content-creation.obs-studio.enable = true;
    golem.modules.media.netflix.enable = true;
    golem.modules.media.spotify-web.enable = true;
  }];
  music = conf amd [ { golem.modules.music-production = { enable = true; install = "chosen"; }; } ];

  # EVERYTHING: every module with every program it has.
  everything = system amd [ { golem.modules = lib.genAttrs ids (_: { enable = true; install = "all"; }); } ];
  all = everything.config;

  # The same program DRAGGED into the grid (the owner's app list), no module
  # touched: the system side must come all the same.
  dragged = conf amd [
    ({ config, pkgs, ... }: {
      home-manager.users.${config.golem.owner}.home.packages =
        map lib.lowPrio [ pkgs.steam pkgs.opentabletdriver pkgs.kdePackages.kleopatra pkgs.dolphin-emu pkgs.corefonts ];
    })
  ];

  # Local AI on a machine with an NVIDIA card, and on one without.
  aiNvidiaSys = system nvidia [ { golem.modules.ai.ollama.enable = true; } ];
  aiNvidia = aiNvidiaSys.config;
  aiAmd = conf amd [ { golem.modules.ai = { ollama.enable = true; open-webui.enable = true; }; } ];

  # The selection file, with good lines and hostile ones.
  listed = conf amd [ { golem.modules.listPath = ./test/selection.list; } ];

  # A small catalog of our own: what the real one may one day hold.
  small = conf amd [
    { golem.modules.catalog = lib.mkForce ./test/catalog.json; golem.modules.gaming.enable = true; }
  ];
  typo = conf amd [ { golem.modules.gaming.no-such-game.enable = true; } ];
  noCatalog = conf amd [ { golem.modules.catalog = lib.mkForce null; golem.modules.gaming.enable = true; } ];

  checks = [
    # ── nothing chosen, nothing on ─────────────────────────────────────────
    (ex "clean: no module is on, no web program is handed over"
      (clean.golem.modules.active == [ ] && clean.golem.modules.web == [ ]
        && !(clean.environment.etc ? "golem/modules-web.json")))
    (ex "clean: no Steam, GameMode, 32-bit graphics, Docker, libvirtd, Ollama, Sunshine, 1Password, direnv"
      (!clean.programs.steam.enable && !clean.programs.gamemode.enable && !clean.hardware.graphics.enable32Bit
        && !clean.virtualisation.docker.enable && !clean.virtualisation.docker.rootless.enable
        && !clean.virtualisation.libvirtd.enable && !clean.services.ollama.enable && !clean.services.sunshine.enable
        && !clean.programs._1password-gui.enable && !clean.programs.direnv.enable))
    (ex "clean: no port opened, no group given"
      (!(lib.elem 53317 clean.networking.firewall.allowedTCPPorts)
        && clean.networking.firewall.allowedTCPPortRanges == [ ]
        && !(lib.any (g: lib.elem g (groups clean)) ([ "kvm" "dialout" ] ++ rootGroups))))
    (ex "clean: the one loopback camera is the phone's, as before; no low-latency clock"
      (clean.boot.extraModprobeConfig
          == "options v4l2loopback exclusive_caps=1 card_label=\"Android WebCam\" video_nr=10\n"
        || (count "options v4l2loopback" clean.boot.extraModprobeConfig == 1
            && lib.hasInfix "options v4l2loopback exclusive_caps=1 card_label=\"Android WebCam\" video_nr=10\n" clean.boot.extraModprobeConfig))
      )
    (ex "clean: PipeWire keeps its own clock"
      (!(clean.services.pipewire.extraConfig.pipewire ? "92-golem-low-latency")))
    (ex "clean: every assertion of the system holds" (failing clean == [ ]))

    # ── a module switched on ───────────────────────────────────────────────
    (ex "Gaming on: the recommended programs are installed, the others are not"
      (lib.all (n: lib.elem n (names gaming)) [ "steam" "heroic" "prismlauncher" "gamemode" ]
        && !(lib.elem "lutris" (names gaming)) && !(lib.elem "sunshine" (names gaming))))
    (ex "Gaming on: Steam's system side, 32-bit graphics, GameMode, the controllers' rules"
      (gaming.programs.steam.enable && gaming.programs.steam.remotePlay.openFirewall
        && gaming.hardware.graphics.enable32Bit && gaming.programs.gamemode.enable
        && gaming.hardware.steam-hardware.enable && gaming.golem.modules.active == [ "gaming" ]))
    (ex "Gaming on: nothing of another module comes with it"
      (!gaming.virtualisation.docker.rootless.enable && !gaming.services.ollama.enable
        && !(gaming.services.pipewire.extraConfig.pipewire ? "92-golem-low-latency")))
    (ex "a program said outright wins over the module: Lutris added, Steam refused (and its system side with it)"
      (lib.elem "lutris" (names gamingPicked) && !(lib.elem "steam" (names gamingPicked))
        && !gamingPicked.programs.steam.enable
        # (the module is still on: its plumbing stays)
        && gamingPicked.hardware.graphics.enable32Bit))

    # ── programs one by one ────────────────────────────────────────────────
    (ex "Docker chosen: rootless (the owner's own daemon, DOCKER_HOST), no system daemon, no docker group"
      (byHand.virtualisation.docker.rootless.enable && byHand.virtualisation.docker.rootless.setSocketVariable
        && !byHand.virtualisation.docker.enable && !(lib.elem "docker" (groups byHand))))
    (ex "direnv chosen: hooked into the shells; virt-manager: the owner's own session, kvm, no libvirtd group"
      (byHand.programs.direnv.enable && byHand.virtualisation.libvirtd.enable && byHand.programs.virt-manager.enable
        && lib.elem "kvm" (groups byHand) && !(lib.elem "libvirtd" (groups byHand))
        && lib.hasInfix "qemu:///session" (builtins.toJSON
             byHand.home-manager.users.${byHand.golem.owner}.dconf.settings."org/virt-manager/virt-manager/connections".uris)))
    (ex "a slicer chosen: the serial ports' group, and only then"
      (lib.elem "dialout" (groups byHand) && !(lib.elem "dialout" (groups gaming))))
    (ex "OBS chosen: a loopback camera of its own BESIDE the phone's, in ONE line of options"
      (count "options v4l2loopback" byHand.boot.extraModprobeConfig == 1
        && lib.hasInfix "options v4l2loopback devices=2 exclusive_caps=1,1 card_label=\"OBS Virtual Camera,Android WebCam\" video_nr=9,10\n"
             byHand.boot.extraModprobeConfig
        && !byHand.programs.obs-studio.enableVirtualCamera))
    (ex "web programs install nothing and are handed to the dock as data (the site and the app of one name apart)"
      (map (w: w.id) byHand.golem.modules.web == [ "spotify-web" "netflix" ]
        && lib.all (w: lib.hasPrefix "https://" w.url) byHand.golem.modules.web
        && !(lib.elem "spotify" (names byHand))
        && lib.hasInfix "netflix" byHand.environment.etc."golem/modules-web.json".text))
    (ex "the modules that are on are the ones a program was chosen in"
      (lib.sort (a: b: a < b) byHand.golem.modules.active
        == [ "3d-printing" "content-creation" "development" "media" "windows-apps" ]))
    (ex "Music Production on, nothing chosen: the low-latency clock, and no program"
      ((music.services.pipewire.extraConfig.pipewire."92-golem-low-latency"."context.properties"."default.clock.quantum" or 0) == 128
        && music.services.pipewire.jack.enable && music.security.rtkit.enable
        && names music == names clean))

    # ── dragged in, no module touched ──────────────────────────────────────
    (ex "a program dragged into the grid gets the same system as one switched on in a module"
      (dragged.programs.steam.enable && dragged.hardware.graphics.enable32Bit && dragged.hardware.steam-hardware.enable
        && dragged.golem.modules.active == [ ]))
    (ex "dragged: the tablet driver (by the name its package really has), GnuPG's agent with a window to ask in, Dolphin's rules, the fonts"
      (dragged.hardware.opentabletdriver.enable
        && dragged.programs.gnupg.agent.enable && lib.getName dragged.programs.gnupg.agent.pinentryPackage == "pinentry-qt"
        && lib.any (p: lib.getName p == "dolphin-emu") dragged.services.udev.packages
        && lib.any (p: lib.getName p == "corefonts") dragged.fonts.packages
        && !(lib.any (p: lib.getName p == "corefonts") clean.fonts.packages)))

    # ── local AI by the machine ────────────────────────────────────────────
    (ex "Ollama on an NVIDIA machine too: its service, the plain build (the CUDA one is in no cache: it would compile on the owner's computer)"
      (aiNvidia.services.ollama.enable && lib.getName aiNvidia.services.ollama.package == "ollama"
        && aiNvidia.services.ollama.package.drvPath != aiNvidiaSys.pkgs.ollama-cuda.drvPath))
    (ex "Ollama on any other machine: its service, the plain build; Open WebUI: local only"
      (aiAmd.services.ollama.enable && lib.getName aiAmd.services.ollama.package == "ollama"
        && aiAmd.services.ollama.package.drvPath != aiNvidiaSys.pkgs.ollama-cuda.drvPath
        && aiAmd.services.open-webui.enable && aiAmd.services.open-webui.host == "127.0.0.1"
        && !aiAmd.services.open-webui.openFirewall))

    # ── everything at once ─────────────────────────────────────────────────
    (ex "every module with every program: the system evaluates, every assertion holds"
      (failing all == [ ] && builtins.isString all.system.build.toplevel.drvPath))
    # The security study's road 1 (2026-11-12): the selection is written
    # without a password, so nothing in it may make the owner root.
    (ex "every module with every program: the owner is in no group that is root"
      (!(lib.any (g: lib.elem g (groups all)) rootGroups)))
    (ex "every module with every program: the groups given are the base's, kvm and dialout — nothing else"
      (lib.all (g: lib.elem g (groups clean ++ [ "kvm" "dialout" ])) (groups all)))
    (ex "every module with every program: Docker stays rootless, nobody may talk to the system's libvirtd"
      (all.virtualisation.docker.rootless.enable && !all.virtualisation.docker.enable
        && all.users.groups.libvirtd.members or [ ] == [ ]))
    (ex "every module with every program: what nixpkgs lacks today is said, one warning a program"
      (lib.all (w: lib.hasInfix "skipped" w) (mine all)))
    (ex "every module is on" (lib.sort (a: b: a < b) all.golem.modules.active == ids))

    # ── the selection file ─────────────────────────────────────────────────
    (ex "the list: a module's line switches it on with its recommended programs; a program's line, that program"
      (lib.all (n: lib.elem n (names listed)) [ "steam" "heroic" "gamemode" "docker" "direnv" "1password" ]
        && listed.programs.steam.enable && listed.virtualisation.docker.rootless.enable
        && listed.programs.direnv.enable && listed.programs._1password-gui.enable
        && listed.programs._1password-gui.polkitPolicyOwners == [ listed.golem.owner ]))
    (ex "the list: a line that names nothing is skipped with a warning, each one"
      (lib.any (lib.hasInfix "'gaming.no-such-game' is not a program") (mine listed)
        && lib.any (lib.hasInfix "'not-a-module' is not a module") (mine listed)
        && builtins.length (lib.filter (lib.hasInfix "is not `<module>` or `<module>.<tool>`") (mine listed)) == 2))
    (ex "the list: a line with code in it is never evaluated"
      (!(lib.elem "planted" listed.boot.kernelParams) && listed.users.users.root.password == null
        && failing listed == [ ]))

    # ── the catalog is data ────────────────────────────────────────────────
    (ex "a program nixpkgs lacks is a warning that names it, never a failed system"
      (lib.any (lib.hasInfix "'golem-this-is-not-in-nixpkgs' (Not There)") (mine small)
        && lib.elem "hello" (names small) && failing small == [ ]))
    (ex "\"recommended\" never takes a paid placement"
      (!(lib.elem "cowsay" (names small))))
    (ex "a site and an app of one name are two tools (hello, hello-web)"
      (small.golem.modules.web == [ ] && failing small == [ ]))
    (ex "a program the catalog does not have is an error that names it"
      (lib.any (a: lib.hasInfix "no-such-game" a.message) (failing typo)))
    (ex "without a catalog a module offers no programs, and its plumbing still answers its switch"
      (names noCatalog == names clean && noCatalog.hardware.graphics.enable32Bit && failing noCatalog == [ ]))
  ];

  failed = builtins.filter (e: !e.ok) checks;
  report =
    if failed == [ ]
    then "modules-matrix: ${toString (builtins.length checks)} checks\n"
      + "skipped today (not in nixpkgs, or not evaluating there):\n"
      + lib.concatMapStrings (w: "  ${w}\n") (mine all)
    else throw "modules-matrix failed: ${lib.concatMapStringsSep "; " (e: e.name) failed}";
in
pkgs.runCommand "golem-modules-matrix"
  { passAsFile = [ "report" ]; inherit report; }
  ''
    cp "$reportPath" $out
    echo "modules-matrix: ${toString (builtins.length checks)} checks" >&2
  ''
