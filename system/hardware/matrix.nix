# The eval matrix — GolemInstall.md §8's first proof leg, and the replay
# harness Installer/PLAN.md promised ("the laptops teach once; the repo
# remembers forever").
#
# Every gated fact permutation is evaluated as a FULL golem-target system
# (the exact composition `nixos-install --flake …#golem-target` builds —
# golemModules + hosts/target + a fake disk), and semantic expectations
# are asserted on the evaluated config: not just "it evaluates" but "the
# no-bluetooth machine really dropped bluez", "the unknown nvidia really
# stayed off the proprietary driver". The committed lab fixtures' facts
# files are permutations too, so a probe or module change that would
# regress a past machine fails CI in seconds, no hardware involved.
#
#   nix build .#checks.x86_64-linux.facts-matrix
#
# Cost note: each row is a complete NixOS+home-manager eval — the matrix
# is minutes of CPU, not seconds. That is the price of evaluating what we
# actually ship; keep rows meaningful (anti-over-gating rule, §5: every
# gate added is a test permutation owed — this file is where the debt is
# paid).
{ lib, pkgs, mkTarget }:

let
  # What nixos-generate-config provides on a real machine — the minimum a
  # bootable system needs so the eval can reach a toplevel.
  fakeDisk = {
    nixpkgs.hostPlatform = "x86_64-linux";
    fileSystems."/" = { device = "/dev/disk/by-label/golem"; fsType = "ext4"; };
    fileSystems."/boot" = { device = "/dev/disk/by-label/ESP"; fsType = "vfat"; };
  };

  # One row: a facts module (an attrset or an imported fixture facts.nix)
  # plus expectations on the evaluated config.
  rows = [
    {
      name = "floor"; # no detection ran: everything at safe defaults
      facts = { };
      expect = cfg: [
        (ex "bluetooth stays on (conservatism)" cfg.services.blueman.enable)
        (ex "no nvidia driver" (!(lib.elem "nvidia" cfg.services.xserver.videoDrivers)))
        (ex "no laptop power stack" (!cfg.services.power-profiles-daemon.enable))
        (ex "historical memory policy (sw 10 / vcp 10)"
          (cfg.boot.kernel.sysctl."vm.swappiness" == 10
           && cfg.boot.kernel.sysctl."vm.vfs_cache_pressure" == 10))
        (ex "no swap → no resume device" (cfg.boot.resumeDevice == ""))
        (ex "fstrim always on" cfg.services.fstrim.enable)
        (ex "fwupd always on" cfg.services.fwupd.enable)
        (ex "no reader → no fprintd" (!cfg.services.fprintd.enable))
        (ex "no hypervisor → no guest tools" (!cfg.services.qemuGuest.enable))
      ];
    }
    {
      name = "fixture-acer-e5-573"; # lab row 1, as detected on the metal
      facts = ../../Installer/fixtures/acer-aspire-e5-573/facts.nix;
      expect = cfg: [
        (ex "Broadwell picks iHD" (cfg.environment.sessionVariables.LIBVA_DRIVER_NAME or "" == "iHD"))
        (ex "4GB tier: zram 150%" (cfg.zramSwap.memoryPercent == 150))
        (ex "4GB tier: zram-first swappiness 180" (cfg.boot.kernel.sysctl."vm.swappiness" == 180))
        (ex "4GB tier: small writeback bursts" (cfg.boot.kernel.sysctl."vm.dirty_ratio" == 5))
        (ex "zram present: page-cluster 0" (cfg.boot.kernel.sysctl."vm.page-cluster" == 0))
        (ex "intel microcode on" cfg.hardware.cpu.intel.updateMicrocode)
        (ex "bluetooth stack on" cfg.services.blueman.enable)
        (ex "laptop power stack on" cfg.services.power-profiles-daemon.enable)
        (ex "intel laptop: thermald on" cfg.services.thermald.enable)
        (ex "4GB tier: one build job" (cfg.nix.settings.max-jobs == 1))
        (ex "102 DPI panel: NO generated scale rule (the 2026-09-02 lesson)"
          (!lib.hasInfix ''output = "eDP-1"''
            cfg.home-manager.users.${cfg.golem.owner}.xdg.configFile."hypr/hyprland.lua".text))
      ];
    }
    {
      name = "fixture-qemu-virtio"; # lab row 0
      facts = ../../Installer/fixtures/qemu-virtio/facts.nix;
      expect = cfg: [
        (ex "confident no-radio drops bluez" (!cfg.services.blueman.enable && !cfg.hardware.bluetooth.enable))
        (ex "unknown chassis: no laptop stack" (!cfg.services.power-profiles-daemon.enable))
        (ex "no nvidia driver" (!(lib.elem "nvidia" cfg.services.xserver.videoDrivers)))
      ];
    }
    {
      name = "intel-legacy"; # the 2013-Air class (Haswell and older)
      facts.golem.hardware = { gpu = "intel"; intelLegacy = true; ramMB = 4096; cores = 4; cpuVendor = "intel"; chassis = "laptop"; };
      expect = cfg: [
        (ex "legacy picks i965" (cfg.environment.sessionVariables.LIBVA_DRIVER_NAME or "" == "i965"))
        (ex "H.264 fallback policy shipped"
          (lib.hasAttr "opt/chrome/policies/managed/golem-legacy-video.json" cfg.environment.etc))
      ];
    }
    {
      name = "amd";
      facts.golem.hardware = { gpu = "amd"; ramMB = 16384; cores = 12; cpuVendor = "amd"; chassis = "desktop"; };
      expect = cfg: [
        (ex "amd microcode on" cfg.hardware.cpu.amd.updateMicrocode)
        (ex "mid tier: zram 50%" (cfg.zramSwap.memoryPercent == 50))
        (ex "mid tier: swappiness 60" (cfg.boot.kernel.sysctl."vm.swappiness" == 60))
        (ex "amd desktop: no thermald" (!cfg.services.thermald.enable))
      ];
    }
    {
      name = "nvidia-hybrid-ada"; # the Slim Pro 9i shape, from detection
      facts = {
        golem.hardware = {
          gpu = "nvidia"; nvidiaGen = "turing+";
          nvidiaBusId = "PCI:1:0:0"; intelBusId = "PCI:0:2:0";
          ramMB = 32768; cores = 20; cpuVendor = "intel"; chassis = "laptop";
        };
        # What the install flow creates on every machine (hibernation is
        # locked): disk swap, sized by lib.golem.swapForHibernationMB.
        swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];
      };
      expect = cfg: [
        (ex "nvidia driver active" (lib.elem "nvidia" cfg.services.xserver.videoDrivers))
        (ex "open kmod on Ada" (cfg.hardware.nvidia.open == true))
        (ex "THE suspend fix present" cfg.hardware.nvidia.powerManagement.enable)
        (ex "PRIME offload with detected ids"
          (cfg.hardware.nvidia.prime.offload.enable
           && cfg.hardware.nvidia.prime.nvidiaBusId == "PCI:1:0:0"))
        (ex "32GB tier: zram 25%" (cfg.zramSwap.memoryPercent == 25))
        (ex "32GB tier: swappiness 10" (cfg.boot.kernel.sysctl."vm.swappiness" == 10))
        (ex "resume wired to the swap device"
          (cfg.boot.resumeDevice == "/dev/disk/by-label/swap"))
        (ex "laptop + swap: lid suspends-then-hibernates"
          (cfg.services.logind.settings.Login.HandleLidSwitch == "suspend-then-hibernate"))
      ];
    }
    {
      name = "nvidia-desktop-ada"; # no iGPU → direct drive, no PRIME
      facts.golem.hardware = { gpu = "nvidia"; nvidiaGen = "turing+"; ramMB = 32768; cores = 16; cpuVendor = "amd"; chassis = "desktop"; };
      expect = cfg: [
        (ex "nvidia driver active" (lib.elem "nvidia" cfg.services.xserver.videoDrivers))
        (ex "no PRIME without both bus ids" (!cfg.hardware.nvidia.prime.offload.enable))
      ];
    }
    {
      name = "nvidia-pre-turing"; # GTX 9xx/10xx: the 580 legacy branch
      facts.golem.hardware = { gpu = "nvidia"; nvidiaGen = "pre-turing"; ramMB = 8192; cores = 8; cpuVendor = "intel"; chassis = "desktop"; };
      expect = cfg: [
        (ex "nvidia driver active" (lib.elem "nvidia" cfg.services.xserver.videoDrivers))
        (ex "proprietary kmod (open is Turing+)" (cfg.hardware.nvidia.open == false))
        (ex "580 legacy branch" (lib.hasPrefix "580." cfg.hardware.nvidia.package.version))
      ];
    }
    {
      name = "nvidia-unknown-gen"; # THE IRON LAW: uncertain → the floor
      facts.golem.hardware = { gpu = "nvidia"; ramMB = 8192; cores = 8; };
      expect = cfg: [
        (ex "unclassified nvidia stays on the floor"
          (!(lib.elem "nvidia" cfg.services.xserver.videoDrivers)))
      ];
    }
    {
      name = "no-bluetooth";
      facts.golem.hardware = { hasBluetooth = false; };
      expect = cfg: [
        (ex "bluez and blueman dropped" (!cfg.services.blueman.enable && !cfg.hardware.bluetooth.enable))
      ];
    }
    {
      # The qemu fixture caught up on 2026-09-04 (regenerated as root from
      # a live MiniGolem boot, which is where vmGuest first got measured
      # rather than assumed). This row stays as the SYNTHETIC guest-tools
      # permutation — round ramMB, no chassis — so the assertions below
      # keep holding even when the lab's VM is retired or re-specced.
      name = "vm-qemu";
      facts.golem.hardware = { gpu = "virtio"; vmGuest = "qemu"; ramMB = 4096; cores = 4; };
      expect = cfg: [
        (ex "qemu guest agent on" cfg.services.qemuGuest.enable)
        (ex "spice agent on" cfg.services.spice-vdagentd.enable)
        (ex "no vmware tools" (!cfg.virtualisation.vmware.guest.enable))
      ];
    }
    {
      name = "fingerprint-reader";
      facts.golem.hardware = { fingerprint = true; chassis = "laptop"; };
      expect = cfg: [
        (ex "fprintd on" cfg.services.fprintd.enable)
      ];
    }
    {
      name = "hidpi-panel"; # 239 = the Slim Pro's probe-measured DPI (34cm/3200px)
      facts.golem.hardware = { gpu = "intel"; panelDpi = 239; chassis = "laptop"; ramMB = 16384; cores = 8; };
      expect = cfg:
        let lua = cfg.home-manager.users.${cfg.golem.owner}.xdg.configFile."hypr/hyprland.lua".text;
        in [
          (ex "generated eDP scale rule at 1.6"
            (lib.hasInfix ''output = "eDP-1", mode = "preferred", position = "auto", scale = 1.6'' lua))
        ];
    }
  ];

  ex = name: ok: { inherit name ok; };

  runRow = row:
    let
      factsModule =
        if builtins.isPath row.facts then import row.facts else row.facts;
      cfg = (mkTarget [ fakeDisk factsModule ]).config;
      failed = builtins.filter (e: !e.ok) (row.expect cfg);
    in
    if failed == [ ] then
      # Discarding the context keeps this EVAL-only: the drv is
      # instantiated (the whole config must be buildable-shaped) but the
      # matrix never builds ten systems.
      "${row.name} ${builtins.unsafeDiscardStringContext cfg.system.build.toplevel.drvPath}"
    else
      throw "facts-matrix row '${row.name}' failed: ${
        lib.concatMapStringsSep "; " (e: e.name) failed}";

  report = map runRow rows;
in
pkgs.runCommand "golem-facts-matrix"
  { passAsFile = [ "report" ]; report = lib.concatStringsSep "\n" report; }
  ''
    cp "$reportPath" $out
    echo "facts-matrix: ${toString (builtins.length rows)} permutations evaluated" >&2
  ''
