# Golem's app set — the CURATE column of `apps.md`, in one place (roadmap S5).
#
# The rule from apps.md: we BUILD only what nobody else can build. Everything
# in this file is an existing app we ship, theme and configure. Picks default
# to GNOME core/Circle so the set stays libadwaita-consistent and
# touch-friendly; a pick only deviates where something fits Golem better.
#
# System-level on purpose: an ISO-installed Golem must come with these for
# *every* user, not just max's home layer.
#
# Deliberately NOT here:
#   • the browser — decision still open (todo5 item 1); the webapp engine
#     ships from `home/home.nix` either way
#   • the stopgap kit (pavucontrol, nm-connection-editor) — those sit in
#     configuration.nix and die when their Arc-2 OPTIONS modules ship
#   • foot, the terminal — session-critical, ships with the compositor
#   • anything in the BUILD column — those are ours, they arrive as OPTIONS
#     surfaces, not packages
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Files. Nautilus is the real file manager (trash, archives, shares);
    # the launcher's own Files listing hands off to it (todo5 item 7).
    nautilus
    file-roller # archive manager, integrates into Nautilus' context menu

    # Everyday desktop
    gnome-text-editor
    gnome-calculator
    gnome-calendar
    gnome-clocks
    gnome-weather
    gnome-contacts # matters once android.md lands
    gnome-maps # nice-to-have tier

    # Media
    loupe # image viewer — fast, touch gestures
    showtime # video player (fall back to celluloid/mpv if codecs fight)
    snapshot # webcam photo/video
    gnome-sound-recorder

    # Music: both ship until todo5 item 6 picks one — Decibels is the
    # play-this-file player, Amberol the library one. The loser gets
    # deleted from this list, not left installed.
    decibels
    amberol

    # Documents & scanning
    papers # PDF viewer + fill & sign
    simple-scan

    # Disks / removable media
    gnome-disk-utility

    # Emoji & characters. The app half of apps.md's "must ALSO be
    # system-wide input"; the input-method half is below.
    gnome-characters
  ];

  # Emoji everywhere, not just in an app (apps.md, todo5 item 8). fcitx5 is
  # the pick apps.md already made; its built-in Unicode addon is the
  # system-wide picker — Ctrl+Alt+Shift+U in any focused text field types
  # the character into that field, which is the part GNOME Characters
  # (copy, then paste) cannot do.
  #
  # waylandFrontend = true because Golem is Hyprland: input goes over
  # text-input-v3 and the candidate popup is a layer surface, instead of
  # every app needing GTK_IM_MODULE set. To back the whole thing out,
  # delete this block — nothing else depends on it.
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = [ pkgs.fcitx5-gtk ];
    };
  };

  # GNOME Disks, and Nautilus mounting USB sticks, both talk to udisks2.
  # (Nix defaults this on; stated here so the dependency is visible when
  # someone trims the app list.)
  services.udisks2.enable = true;

  # Simple Scan finds no scanner at all without the SANE backends.
  hardware.sane.enable = true;

  # Shared calendar/contacts backend. GNOME Calendar and Contacts store
  # everything through evolution-data-server; without it both start empty
  # and cannot keep anything.
  services.gnome.evolution-data-server.enable = true;

  # libadwaita apps read their settings (and the theme preference S5's
  # theming pass will set) from dconf.
  programs.dconf.enable = true;
}
