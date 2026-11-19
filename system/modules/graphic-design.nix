# modules/graphic-design — Graphic Design: vector, paint and retouch, layout,
# UI and web design, pixel art, fonts and colour, tablets.
#
# No plumbing. PROGRAM SETUP: a drawing tablet's driver is a user service
# with its own device rules (and it must keep the kernel's own tablet
# drivers off the device): all of it is the NixOS module's.
{ config, lib, ... }:

let
  m = import ./lib.nix { inherit lib; };
  inherit (m.scope config) any;
in
{
  imports = [
    (m.mkModule {
      id = "graphic-design";
      description = "Graphic Design: vector, paint and retouch, layout, UI and web design, pixel art, fonts and colour, tablets.";
    })
  ];

  config = {
    # (The package calls itself OpenTabletDriver: until 2026-11-19 only the
    # lower-case name was looked for, and the driver never came on.)
    hardware.opentabletdriver.enable = lib.mkIf (any [ "OpenTabletDriver" "opentabletdriver" ]) true;
  };
}
