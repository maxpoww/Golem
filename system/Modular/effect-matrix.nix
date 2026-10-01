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
# of testing what we actually install. Primary-nvidia machines are
# covered by SYNTHETIC fixtures (2026-09-26) until one is captured on metal.
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
        (ex "UEFI → GRUB-EFI on, no systemd-boot (#92)" (c.boot.loader.grub.enable && c.boot.loader.grub.efiSupport && !c.boot.loader.systemd-boot.enable))
        (ex "first-boot never holds a boot target (the desktop must not wait for its rebuild): timer-started, low priority" (c.systemd.services.golem-first-boot.wantedBy == [ ] && c.systemd.timers ? golem-first-boot && c.systemd.services.golem-first-boot.serviceConfig.IOSchedulingClass == "idle"))
        (ex "no passwordless sudo on an install (GolemSecurity)" (!(lib.any (r: lib.any (cmd: lib.elem "NOPASSWD" (cmd.options or [ ])) (r.commands or [ ])) c.security.sudo.extraRules) && !(lib.hasInfix "NOPASSWD" c.security.sudo.extraConfig)))
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
        (ex "bash is the owner's shell (#108: plain bash, not zsh)" (lib.hasPrefix "bash" (c.users.users.${c.golem.owner}.shell.pname or "")))
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
        (ex "UEFI → GRUB-EFI (#92)" (c.boot.loader.grub.enable && c.boot.loader.grub.efiSupport))
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
      name = "hp Pavilion dm4 (FAILING amd Radeon gpu2 — the #33 hold default)";
      facts = (import ../../Installer/preinstall/fixtures/hp-pavilion-dm4/facts.nix { }).golem.hardware;
      expect = c: [
        # No answer yet → the safe HOLD service is on, the destructive OFF is
        # absent entirely (mkIf'd out — `or false` avoids the missing-attr throw).
        (ex "failing gpu2: golem-dgpu-hold service enabled (safe default)" (c.systemd.services.golem-dgpu-hold.enable or false))
        (ex "failing gpu2: golem-dgpu-off ABSENT (needs an explicit answer)" (!(c.systemd.services ? golem-dgpu-off)))
        (ex "BIOS → GRUB" (c.boot.loader.grub.enable && !c.boot.loader.systemd-boot.enable))
        (ex "Arrandale → LIBVA i965" (c.environment.sessionVariables.LIBVA_DRIVER_NAME or "" == "i965"))
        (ex "intel laptop: thermald on" c.services.thermald.enable)
        (ex "tier1 (3718 MB): swappiness 180" (c.boot.kernel.sysctl."vm.swappiness" == 180))
      ];
    }
    {
      name = "macbook air 2013 (Broadcom BCM4360 — the wl quirk, the boss fight)";
      facts = (import ../../Installer/preinstall/fixtures/macbook-air-2013/facts.nix { }).golem.hardware;
      expect = c: [
        (ex "wl kernel module requested" (lib.elem "wl" c.boot.kernelModules))
        (ex "broadcom_sta in extraModulePackages"
          (lib.any (p: (p.pname or "") == "broadcom-sta") c.boot.extraModulePackages))
        (ex "Haswell HD5000 → LIBVA i965" (c.environment.sessionVariables.LIBVA_DRIVER_NAME or "" == "i965"))
        (ex "Apple EFI → GRUB-EFI (#92)" (c.boot.loader.grub.enable && c.boot.loader.grub.efiSupport))
        (ex "intel laptop: thermald on" c.services.thermald.enable)
        (ex "tier1 (3858 MB): swappiness 180" (c.boot.kernel.sysctl."vm.swappiness" == 180))
      ];
    }
    {
      name = "comodore GM45 (BIOS + GMA 4500 — the i965 legacy + grub-bios path)";
      facts = (import ../../Installer/preinstall/fixtures/comodore-gm45/facts.nix { }).golem.hardware;
      expect = c: [
        (ex "BIOS → GRUB on, no systemd-boot" (c.boot.loader.grub.enable && !c.boot.loader.systemd-boot.enable))
        (ex "Gen4 GMA → LIBVA i965 (not iHD)" (c.environment.sessionVariables.LIBVA_DRIVER_NAME or "" == "i965"))
        (ex "legacy h264ify Chrome policy shipped" (c.environment.etc ? "opt/chrome/policies/managed/golem-legacy-video.json"))
        (ex "intel microcode on" c.hardware.cpu.intel.updateMicrocode)
        (ex "tier1 (1931 MB): swappiness 180" (c.boot.kernel.sysctl."vm.swappiness" == 180))
        (ex "tier1: one build job" (c.nix.settings.max-jobs == 1))
        (ex "intel laptop: thermald on" c.services.thermald.enable)
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
        (ex "hibernate image as small as possible (amdgpu -12 on 2026-09-30)"
          (lib.elem "w /sys/power/image_size - - - - 0" c.systemd.tmpfiles.rules))
        (ex "UEFI → GRUB-EFI (#92)" (c.boot.loader.grub.enable && c.boot.loader.grub.efiSupport))
      ];
    }
    {
      name = "SYNTHETIC nvidia-only desktop, turing (primary nvidia — hardware video decode, gpu/nvidia/vaapi.nix)";
      facts = (import ../../Installer/preinstall/fixtures/synthetic-nvidia-desktop-turing/facts.nix { }).golem.hardware;
      expect = c: [
        (ex "nvidia driver on (primary)" (lib.elem "nvidia" c.services.xserver.videoDrivers))
        (ex "turing+: open module package" (c.hardware.nvidia.package == c.boot.kernelPackages.nvidiaPackages.stable))
        (ex "primary: NO PRIME offload" (!c.hardware.nvidia.prime.offload.enable))
        (ex "video decode: nvidia-vaapi-driver shipped"
          (lib.any (p: (p.pname or "") == "nvidia-vaapi-driver") c.hardware.graphics.extraPackages))
        (ex "video decode: LIBVA → nvidia" (c.environment.sessionVariables.LIBVA_DRIVER_NAME or "" == "nvidia"))
        (ex "video decode: NVD_BACKEND direct" (c.environment.sessionVariables.NVD_BACKEND or "" == "direct"))
        (ex "Firefox media sandbox NOT disabled" (!(c.environment.sessionVariables ? MOZ_DISABLE_RDD_SANDBOX)))
      ];
    }
    {
      name = "SYNTHETIC nvidia-only desktop, pre-turing (primary nvidia — hardware video decode, gpu/nvidia/vaapi.nix)";
      facts = (import ../../Installer/preinstall/fixtures/synthetic-nvidia-desktop-pre-turing/facts.nix { }).golem.hardware;
      expect = c: [
        (ex "nvidia driver on (primary)" (lib.elem "nvidia" c.services.xserver.videoDrivers))
        (ex "pre-turing: legacy_580 package" (c.hardware.nvidia.package == c.boot.kernelPackages.nvidiaPackages.legacy_580))
        (ex "primary: NO PRIME offload" (!c.hardware.nvidia.prime.offload.enable))
        (ex "video decode: nvidia-vaapi-driver shipped"
          (lib.any (p: (p.pname or "") == "nvidia-vaapi-driver") c.hardware.graphics.extraPackages))
        (ex "video decode: LIBVA → nvidia" (c.environment.sessionVariables.LIBVA_DRIVER_NAME or "" == "nvidia"))
        (ex "video decode: NVD_BACKEND direct" (c.environment.sessionVariables.NVD_BACKEND or "" == "direct"))
        (ex "Firefox media sandbox NOT disabled" (!(c.environment.sessionVariables ? MOZ_DISABLE_RDD_SANDBOX)))
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
