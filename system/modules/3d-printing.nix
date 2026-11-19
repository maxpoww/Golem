# modules/3d-printing — 3D & Printing: modelling, 2D drawing, meshes,
# slicers, laser and CNC.
#
# No plumbing. PROGRAM SETUP: a printer or a laser on a USB cable is a serial
# port (/dev/ttyUSB0, /dev/ttyACM0), and udev gives serial ports to the
# `dialout` group. The slicers and LightBurn talk to it directly, so the
# owner joins that group while one of them is installed. dialout opens
# serial ports and nothing else: it is not root.
# (A printer on the network — Bambu, Prusa Connect, OctoPrint — is reached as
# a client: nothing to open here.)
{ config, lib, ... }:

let
  m = import ./lib.nix { inherit lib; };
  inherit (m.scope config) owner any;

  serial = [ "prusa-slicer" "orca-slicer" "bambu-studio" "lightburn" ];
in
{
  imports = [
    (m.mkModule {
      id = "3d-printing";
      description = "3D & Printing: modelling, 2D drawing, meshes, slicers, laser and CNC.";
    })
  ];

  config = {
    users.users.${owner}.extraGroups = lib.optional (any serial) "dialout";
  };
}
