# FRAGMENT (not a chooser target). Hardware VIDEO DECODE for a PRIMARY nvidia
# GPU — the machine has no Intel/AMD chip to decode on, so without this every
# video (YouTube, calls) decodes on the CPU: hot, battery-hungry, stuttery.
# Imported by the primary leaves only (gpu/nvidia-turing.nix,
# gpu/nvidia-preturing.nix); offload laptops decode on their iGPU (iHD/radeonsi).
#
# nvidia-vaapi-driver translates VA-API (what Firefox/Beam, mpv, … speak) to
# NVDEC. NVD_BACKEND=direct is the backend that works on current drivers (the
# EGL one broke in 525+). Firefox's media sandbox already allows /dev/nvidia*
# (checked in the 156 binary), so it stays ON — no MOZ_DISABLE_RDD_SANDBOX.
#
# Built 2026-09-26 without an nvidia-only machine to test on (Max: "we hope is
# gonna work"). The FALLBACK lives in Beam (golem-chrome.js, "NVIDIA HW DECODE"):
# Firefox drops to software by itself if the driver fails to initialise, and
# Beam turns hardware decode off for that machine if the decoder process keeps
# crashing — retried automatically after a Firefox or driver update. The result
# per machine is in the Beam profile's golem-media.json.
{ lib, pkgs, ... }:

{
  hardware.graphics.extraPackages = [ pkgs.nvidia-vaapi-driver ];

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = lib.mkDefault "nvidia";
    NVD_BACKEND = lib.mkDefault "direct";
  };
}
