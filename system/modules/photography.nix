# modules/photography — Photography: develop RAW, the library, retouching,
# tools.
#
# No plumbing. A camera plugged in needs nothing: systemd's own rules give
# the person at the screen every PTP/MTP device and every camera libgphoto2
# knows (70-uaccess.rules), and gvfs (desktop/session.nix) shows its photos.
# That covers darktable's and Entangle's tethering and Rapid Photo
# Downloader. PROGRAM SETUP: DisplayCAL measures the screen through a
# colorimeter, a USB instrument only root can open until ArgyllCMS's device
# rules are in.
{ config, lib, pkgs, ... }:

let
  m = import ./lib.nix { inherit lib; };
  inherit (m.scope config) has;
in
{
  imports = [
    (m.mkModule {
      id = "photography";
      description = "Photography: develop RAW, the library, retouching, tools.";
    })
  ];

  config = {
    # ArgyllCMS ships the rules for the instruments it drives (i1, Spyder,
    # ColorMunki…): DisplayCAL is a window on it.
    services.udev.packages = lib.optional (has "displaycal") pkgs.argyllcms;
  };
}
