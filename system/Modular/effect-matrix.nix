# The EFFECT matrix (Max, 2026-09-10: "the specific hardware config
# modules should be built and tested on the source"). chooser-matrix.nix
# proves the chosen LIST; this proves each chosen leaf's RESULT: compose
# a machine's leaves via mkMinimal and assert the evaluated config —
# not "it points at intel.nix" but "the composed system really sets
# LIBVA=iHD, swappiness 180, thermald on". A leaf whose values drift
# from what it promised fails HERE, on source, before metal.
#
#   nix build .#checks.x86_64-linux.minimal-matrix
#
# Full nixos+home-manager evals (minutes, like facts-matrix) — the price
# of testing what we actually install. The nvidia machines are absent:
# they REFUSE at choose time (chooser-matrix owns that), so they cannot
# be composed until their leaves land.
{ lib, pkgs, mkMinimal }:

let
  fakeDisk = {
    nixpkgs.hostPlatform = "x86_64-linux";
    fileSystems."/" = { device = "/dev/disk/by-label/golem"; fsType = "ext4"; };
    fileSystems."/boot" = { device = "/dev/disk/by-label/ESP"; fsType = "vfat"; };
  };

  ex = name: ok: { inherit name ok; };

  rows = [
    {
      name = "acer-e5-573 (THE FIRST BLESSED METAL — stage 0, UEFI, HD 5500)";
      facts = (import ../../Installer/preinstall/fixtures/acer-aspire-e5-573/facts.nix { }).golem.hardware;
      expect = c: [
        (ex "UEFI → systemd-boot on, no grub" (c.boot.loader.systemd-boot.enable && !c.boot.loader.grub.enable))
        (ex "Broadwell (not legacy) → LIBVA iHD" (c.environment.sessionVariables.LIBVA_DRIVER_NAME or "" == "iHD"))
        (ex "intel microcode on" c.hardware.cpu.intel.updateMicrocode)
        (ex "tier1: zram 150%" (c.zramSwap.memoryPercent == 150))
        (ex "tier1: swappiness 180" (c.boot.kernel.sysctl."vm.swappiness" == 180))
        (ex "tier1: cache-pressure 50" (c.boot.kernel.sysctl."vm.vfs_cache_pressure" == 50))
        (ex "tier1: dirty 5" (c.boot.kernel.sysctl."vm.dirty_ratio" == 5))
        (ex "tier1: one build job" (c.nix.settings.max-jobs == 1))
        (ex "zram on → page-cluster 0" (c.boot.kernel.sysctl."vm.page-cluster" == 0))
        (ex "laptop: power-profiles-daemon on" c.services.power-profiles-daemon.enable)
        (ex "laptop: upower on" c.services.upower.enable)
        (ex "intel laptop: thermald on" c.services.thermald.enable)
        (ex "disk policy: fstrim on" c.services.fstrim.enable)
        (ex "self-rebuild loop: flakeAttr golem-minimal" (c.golem.flakeAttr == "golem-minimal"))
        (ex "self-rebuild loop: flakeDir set" (c.golem.flakeDir != null))
        (ex "zsh is the owner's shell" (c.users.users.${c.golem.owner}.shell.pname or "" == "zsh"))
        (ex "sshd on, key-only" (c.services.openssh.enable && !c.services.openssh.settings.PasswordAuthentication))
        (ex "NO nvidia driver anywhere" (!lib.elem "nvidia" c.services.xserver.videoDrivers))
        (ex "MINIMAL: no hyprland" (!c.programs.hyprland.enable))
        (ex "MINIMAL: no greetd" (!c.services.greetd.enable))
      ];
    }
    {
      name = "qemu-virtio (VM stage-0 — the proven UEFI install)";
      facts = (import ../../Installer/preinstall/fixtures/qemu-virtio/facts.nix { }).golem.hardware;
      expect = c: [
        (ex "virtio: generic stack, no LIBVA pin" ((c.environment.sessionVariables.LIBVA_DRIVER_NAME or null) == null))
        (ex "qemu guest agent on" c.services.qemuGuest.enable)
        (ex "spice vdagent on" c.services.spice-vdagentd.enable)
        (ex "tier1 (3912 MB): swappiness 180" (c.boot.kernel.sysctl."vm.swappiness" == 180))
        (ex "UEFI → systemd-boot" c.boot.loader.systemd-boot.enable)
        (ex "not a laptop → no power-profiles-daemon" (!c.services.power-profiles-daemon.enable))
      ];
    }
    {
      name = "lenovo (intel primary + nvidia gpu2 working turing+ — the ported nvidia leaves)";
      facts = (import ../../Installer/preinstall/fixtures/lenovo-slim-pro-9-16irp8/facts.nix { }).golem.hardware;
      expect = c: [
        (ex "nvidia driver on (offload)" (lib.elem "nvidia" c.services.xserver.videoDrivers))
        (ex "turing+: open module" (c.hardware.nvidia.open == true))
        (ex "turing+: stable package" (c.hardware.nvidia.package == c.boot.kernelPackages.nvidiaPackages.stable))
        (ex "THE SUSPEND FIX on" c.hardware.nvidia.powerManagement.enable)
        (ex "PRIME offload enabled" c.hardware.nvidia.prime.offload.enable)
        (ex "PRIME intel bus id from facts" (c.hardware.nvidia.prime.intelBusId == "PCI:0:2:0"))
        (ex "PRIME nvidia bus id from facts" (c.hardware.nvidia.prime.nvidiaBusId == "PCI:1:0:0"))
        (ex "intel primary keeps iHD" (c.environment.sessionVariables.LIBVA_DRIVER_NAME or "" == "iHD"))
        (ex "tier3 (31 GB): swappiness 10" (c.boot.kernel.sysctl."vm.swappiness" == 10))
        (ex "tier3: zram 25%" (c.zramSwap.memoryPercent == 25))
      ];
    }
    {
      name = "thinkpad E15 (AMD Ryzen 4700U + Renoir Vega — the amd path)";
      facts = (import ../../Installer/preinstall/fixtures/thinkpad-e15-gen2/facts.nix { }).golem.hardware;
      expect = c: [
        (ex "amd microcode on" c.hardware.cpu.amd.updateMicrocode)
        (ex "NOT intel microcode" (!c.hardware.cpu.intel.updateMicrocode))
        (ex "amd gpu: no LIBVA pin (mesa radeonsi rides default)"
          ((c.environment.sessionVariables.LIBVA_DRIVER_NAME or null) == null))
        (ex "laptop: power-profiles-daemon on" c.services.power-profiles-daemon.enable)
        (ex "AMD laptop: thermald OFF (intel-only daemon)" (!c.services.thermald.enable))
        (ex "tier2 (7159 MB): swappiness 60" (c.boot.kernel.sysctl."vm.swappiness" == 60))
        (ex "UEFI → systemd-boot" c.boot.loader.systemd-boot.enable)
      ];
    }
    {
      name = "asus (gpu=nvidia, unknown gen — the IRON LAW: NO proprietary driver)";
      facts = (import ../../Installer/preinstall/fixtures/asus/golem-hardware.nix { }).golem.hardware;
      expect = c: [
        # Just "no nvidia driver" — deliberately NOT reading
        # hardware.nvidia.open, which evaluates null nvidia internals on
        # the iron-law floor and throws (the #22 crash the ASUS taught us).
        (ex "iron law: NO nvidia driver" (!lib.elem "nvidia" c.services.xserver.videoDrivers))
        (ex "still a laptop: thermald on" c.services.thermald.enable)
        (ex "tier2 (7.8 GB): swappiness 60" (c.boot.kernel.sysctl."vm.swappiness" == 60))
      ];
    }
  ];

  runRow = row:
    let
      c = (mkMinimal row.facts [ fakeDisk ]).config;
      failed = builtins.filter (e: !e.ok) (row.expect c);
    in
    if failed == [ ]
    then "${row.name} ${builtins.unsafeDiscardStringContext c.system.build.toplevel.drvPath}"
    else throw "minimal-matrix row '${row.name}' failed: ${
      lib.concatMapStringsSep "; " (e: e.name) failed}";

  report = map runRow rows;
in
pkgs.runCommand "golem-minimal-matrix"
  { passAsFile = [ "report" ]; report = lib.concatStringsSep "\n" report; }
  ''
    cp "$reportPath" $out
    echo "minimal-matrix: ${toString (builtins.length rows)} composed & asserted" >&2
  ''
