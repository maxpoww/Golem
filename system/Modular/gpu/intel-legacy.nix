# gpu/intel-legacy — pre-Skylake Intel iGPU (Haswell/Ivy and older).
# Chosen when the census says gpu=intel and intelLegacy=true. iHD gives
# these parts NO hardware decode (measured: 2013 HD 5000 CPU-decoding
# VP9 at 95 °C vs 74 °C on i965) — LIBVA pins i965. And because these
# chips decode H.264 only, the enhanced-h264ify Chrome policy makes
# YouTube serve what the silicon can chew. Lifted from hardware.nix's
# intel+intelLegacy branch.
{ pkgs, ... }:

{
  imports = [ ./intel-pmu.nix ]; # the gear's GPU % (the i915 PMU)

  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    intel-vaapi-driver
    libvdpau-va-gl
  ];
  environment.sessionVariables.LIBVA_DRIVER_NAME = "i965";

  # GTK 4 apps draw with OpenGL here, not Vulkan. GTK prefers Vulkan, and
  # Mesa's Vulkan driver for these chips (hasvk: "Haswell Vulkan support is
  # incomplete") takes it: on the 2013 MacBook Air the camera app showed the
  # built-in camera with 130 % of a processor (three worker threads and the
  # main one), the picture visibly not smooth; with the OpenGL renderer the
  # same view costs 10 % (measured 2026-10-10). Every GTK 4 app on such a
  # machine is drawn this way — Files, Text Editor, the viewers.
  environment.sessionVariables.GSK_RENDERER = "ngl";

  # These iGPUs can't afford the compositor's blur: on the 2013 MacBook Air
  # the 3D engine sat at 98% during YouTube and the video stuttered; blur off
  # freed 13-17 points (options.nix, golem.desktop.effects).
  golem.desktop.effects = "light";

  environment.etc."opt/chrome/policies/managed/golem-legacy-video.json".text =
    builtins.toJSON {
      ExtensionInstallForcelist = [
        "omkfmpieigblcllmkgbflkikinpkodlk;https://clients2.google.com/service/update2/crx"
      ];
    };

}
