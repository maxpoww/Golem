# FRAGMENT (not a chooser target). The pre-Turing nvidia driver blob
# (Maxwell/Pascal/Volta) — the 580 legacy branch, the last that supports
# these parts; the open kmod is Turing+ only. Shared by the primary leaf
# (gpu/nvidia-preturing.nix) and the offload leaf
# (gpu2/nvidia-offload-preturing.nix). Ported verbatim from
# gpu-nvidia.nix's pre-turing branch (2026-09-10), minus the nvidiaGen
# mkIf. No VRAM-preserve default: the GSP resume assert is an open-module
# problem; the classic branch's suspend path has served these parts for a
# decade (opt in per-host if a model needs it).
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
    open = lib.mkDefault false;
    package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.legacy_580;
  };
}
