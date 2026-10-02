# desktop/session — the session plumbing the desktop's apps assume, stage 1.
#
#   gvfs     trash, mounted drives and network shares inside Nautilus and the
#            file chooser (GIO modules; without them Nautilus shows a folder
#            and nothing else)
#   dconf    where GTK/libadwaita settings live — the dark theme, the portal's
#            colour scheme, every gsettings write
#   udisks2  removable drives for the desktop's user (plug in a USB stick)
#   glib     `gsettings` and `gio` on the PATH
#   wsdd     what gvfs spawns for Files' "Network" view (Web Service
#            Discovery): without it the view failed outright — "Failed to
#            spawn the wsdd daemon" (ASUS dogfood, 2026-10-02). The firewall
#            stays closed: auto-discovering Windows hosts would need UDP 3702
#            open on every network the laptop joins; typing smb://host still
#            works.
#
# Ported from the fat system/configuration.nix (gvfs + GIO_EXTRA_MODULES).
# Landed 2026-09-30 (deep debug, parity P9): installs had 0 GIO modules and no
# gsettings.
{ pkgs, ... }:

{
  services.gvfs.enable = true;
  environment.sessionVariables.GIO_EXTRA_MODULES = [ "${pkgs.gvfs}/lib/gio/modules" ];
  programs.dconf.enable = true;
  services.udisks2.enable = true;
  environment.systemPackages = [ pkgs.glib pkgs.wsdd ];
}
