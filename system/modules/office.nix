# modules/office — Office: documents, PDF, mail and calendar, diagrams,
# scanning.
#
# No plumbing: printing and scanning are the desktop's for everyone
# (desktop/printing.nix — CUPS, SANE, driverless), so Simple Scan and
# gscan2pdf find the scanner already. PROGRAM SETUP: Microsoft's core fonts
# are FONTS, not a program — a package among the owner's apps is not where
# fontconfig looks, so they are registered with the system's fonts.
{ config, lib, pkgs, ... }:

let
  m = import ./lib.nix { inherit lib; };
  inherit (m.scope config) has;
in
{
  imports = [
    (m.mkModule {
      id = "office";
      description = "Office: documents, PDF, mail and calendar, diagrams, scanning.";
    })
  ];

  config = {
    # Arial, Times New Roman, Verdana…: what documents written elsewhere ask
    # for by name.
    fonts.packages = lib.optional (has "corefonts") pkgs.corefonts;
  };
}
