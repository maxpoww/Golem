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
{ config, lib, pkgs, ... }:

{
  # Two tiers (golem.lean, 2026-09-01). "Core" is what the system needs to
  # WORK — open a folder, a text file, an image, a PDF, a zip. Everything
  # else is the full CURATE experience an installed machine gets.
  environment.systemPackages = with pkgs; [
    # Files. Nautilus is the real file manager (trash, archives, shares);
    # the launcher's own Files listing hands off to it (todo5 item 7).
    nautilus
    file-roller # archive manager, integrates into Nautilus' context menu

    gnome-text-editor
    loupe # image viewer — fast, touch gestures
    papers # PDF viewer + fill & sign
  ];
  # The rest of the CURATE tier (calculator, calendar, clocks, weather,
  # contacts, maps, showtime, snapshot, sound recorder, decibels, amberol,
  # simple-scan, disks, characters) left 2026-09-29 — the debloat: "i only
  # want seam on it … all rest on the menubox is bloat". What stays above is
  # what opening a file needs.

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
  i18n.inputMethod = lib.mkIf (!config.golem.lean) {
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
  hardware.sane.enable = !config.golem.lean;

  # Shared calendar/contacts backend. GNOME Calendar and Contacts store
  # everything through evolution-data-server; without it both start empty
  # and cannot keep anything.
  services.gnome.evolution-data-server.enable = !config.golem.lean;

  # libadwaita apps read their settings — including the dark/accent
  # preference home.nix's theming pass writes — from dconf.
  programs.dconf.enable = true;
}
