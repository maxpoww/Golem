# desktop/session — the session plumbing the desktop's apps assume, stage 1.
#
#   gvfs     trash, mounted drives and network shares inside Nautilus and the
#            file chooser (GIO modules; without them Nautilus shows a folder
#            and nothing else)
#   dconf    where GTK/libadwaita settings live — the dark theme, the portal's
#            colour scheme, every gsettings write
#   udisks2  removable drives for the desktop's user (plug in a USB stick)
#   glib     `gsettings` and `gio` on the PATH
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
  environment.systemPackages = [ pkgs.glib ];
}
