# desktop/portals — the desktop portal, said out loud (plan F3.17).
#
# The portal is how an app asks the desktop for what it may not take: a file
# chosen by the owner (every Flatpak, Electron and Chromium "Open…" and
# "Save as…", the dock's own "send a file"), a screen to share (the picker in
# a video call), the light or dark look (libadwaita apps follow it live), a
# link opened in the browser.
#
# It worked before this file, by rebound: programs.hyprland brings the
# Hyprland backend and its portals.conf, something else brought GTK's. A
# change upstream in either would have taken the file chooser or the screen
# share away with nothing here to say what was meant. This says it:
#
#   screen sharing, screenshots for apps, global shortcuts  → Hyprland's
#   everything else (file chooser, look, notifications…)    → GTK's
#   the Secret portal                                        → nobody
#
# Nobody for Secret on purpose (desktop/keyring.nix): the portal asked the
# keyring for it as the session started, before the owner's password had
# opened it, and the first app to store a password hung behind the lock
# screen. Apps reach the keyring through the Secret Service itself.
{ pkgs, ... }:

{
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    # Read as hyprland-portals.conf: the session's XDG_CURRENT_DESKTOP is
    # Hyprland. /etc/xdg comes before the packages' own files.
    config.hyprland = {
      default = [ "hyprland" "gtk" ];
      "org.freedesktop.impl.portal.Secret" = [ "none" ];
    };
  };
}
