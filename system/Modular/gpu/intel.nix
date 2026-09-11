# gpu/intel — modern Intel iGPU (Broadwell+). Chosen when the census
# says gpu=intel and intelLegacy=false. Both VA-API drivers ship;
# LIBVA_DRIVER_NAME pins iHD (intel-media-driver), the correct engine
# for these generations. Lifted from hardware.nix's intel branch.
{ pkgs, ... }:

{
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    intel-vaapi-driver
    libvdpau-va-gl
  ];
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
}
