# FRAGMENT (not a chooser target — lives under gpu/nvidia/, the chooser
# never names it). The Turing+ nvidia driver blob, shared by the primary
# leaf (gpu/nvidia-turing.nix) and the offload leaf
# (gpu2/nvidia-offload-turing.nix) so the metal-verified SUSPEND FIX
# cannot drift between them. Ported verbatim from
# system/hardware/gpu-nvidia.nix's turing+ branch (2026-09-10), minus the
# nvidiaGen mkIf — the chooser already decided this is turing+, so the
# leaf carries the config unconditionally. mkDefault priorities kept:
# the user stays sovereign.
{ config, lib, pkgs, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = lib.mkDefault true;
    enable32Bit = lib.mkDefault pkgs.stdenv.hostPlatform.isx86_64;
  };

  hardware.nvidia = {
    modesetting.enable = lib.mkDefault true;
    nvidiaSettings = lib.mkDefault true;

    # Open kernel modules — the supported/required path on Turing+; GSP
    # firmware is mandatory on this generation.
    open = lib.mkDefault true;
    package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.stable;

    powerManagement = {
      # *** THE SUSPEND/RESUME FIX *** NVreg_PreserveVideoMemoryAllocations=1
      # + the nvidia-suspend/resume/hibernate services, so the open GSP
      # module does not assert on resume (kernel_gsp.c:1447 — metal-
      # verified 2026-09-03 on the Slim Pro 9i).
      enable = lib.mkDefault true;
      kernelSuspendNotifier = lib.mkIf
        (config.hardware.nvidia.open == true
         && lib.versionAtLeast config.hardware.nvidia.package.version "595")
        (lib.mkDefault true);
      # Runtime-D3 off by default: a battery win but a resume-instability
      # source; enable per-host only after testing suspend on that model.
      finegrained = lib.mkDefault false;
    };
  };
}
