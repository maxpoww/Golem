# gpu/amd — AMD GPU on the open stack. Chosen when the census says
# gpu=amd. mesa's radeonsi VA driver rides the default stack; only the
# VDPAU bridge is added. Lifted from hardware.nix's amd branch.
{ pkgs, ... }:

{
  hardware.graphics.extraPackages = with pkgs; [
    libvdpau-va-gl
  ];
}
