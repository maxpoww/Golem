# gpu/intel-legacy — pre-Skylake Intel iGPU (Haswell/Ivy and older).
# Chosen when the census says gpu=intel and intelLegacy=true. iHD gives
# these parts NO hardware decode (measured: 2013 HD 5000 CPU-decoding
# VP9 at 95 °C vs 74 °C on i965) — LIBVA pins i965. And because these
# chips decode H.264 only, the enhanced-h264ify Chrome policy makes
# YouTube serve what the silicon can chew. Lifted from hardware.nix's
# intel+intelLegacy branch.
{ pkgs, ... }:

{
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    intel-vaapi-driver
    libvdpau-va-gl
  ];
  environment.sessionVariables.LIBVA_DRIVER_NAME = "i965";

  environment.etc."opt/chrome/policies/managed/golem-legacy-video.json".text =
    builtins.toJSON {
      ExtensionInstallForcelist = [
        "omkfmpieigblcllmkgbflkikinpkodlk;https://clients2.google.com/service/update2/crx"
      ];
    };
}
