# The look of the programs: GTK 3 and 4, the icons, the fonts, what
# libadwaita reads at runtime, and the palette's files. The colours
# themselves are the dock's to write (Controls → Colours); this wires the
# levers the programs honour.
{ config, pkgs, lib, ... }:

let
  # Golem's own icons (tools/icons writes them): folders, files, devices in
  # the dock's cast metal, in two tones — Golem (silver, the light look) and
  # Golem-Dark (graphite, the dark one); the dock's Dark mode switches the
  # apps and itself between them. Every other name falls through to Papirus.
  golemIcons = pkgs.runCommand "golem-icon-theme" { } ''
    mkdir -p $out/share/icons
    cp -r --no-preserve=mode ${./icons/Golem} $out/share/icons/Golem
    cp -r --no-preserve=mode ${./icons/Golem-Dark} $out/share/icons/Golem-Dark
  '';
in
{
  # ── Theming pass (roadmap S5) ─────────────────────────────────────────
  # libadwaita apps cannot be re-skinned the old GTK3 way, so "look at home"
  # means the levers they DO honour, set to what the desktop already is:
  #   colours → THE PALETTE (Controls → Colours, waverunner palette.rs): the
  #             dock writes it for GTK 3/4, foot, hyprlock and Qt into
  #             ~/.local/state/golem/theme, and these configs import it
  #   dark    → the palette's dark variant; the dock flips the look live
  #   fonts   → the ones configuration.nix already ships and defaults to
  #   icons   → Golem-Dark (system/home/icons, built by tools/icons): Golem's
  #             own folders, files and devices, inheriting Papirus-Dark for the
  #             rest; Golem in the light look. waverunner's config.toml names
  #             "Golem" and the dock picks the tone itself
  #   corners → nothing to do: libadwaita's radius isn't configurable, and
  #             Hyprland rounds every window to 12 anyway, which is what
  #             Adwaita draws — they already agree.
  # Aesthetic judgement is still Max's; this only wires the levers.
  gtk = {
    enable = true;
    font = {
      name = "DejaVu Sans";
      size = 11;
    };
    iconTheme = {
      # Golem ships dark; the dock writes the light one when that is chosen.
      name = "Golem-Dark";
      package = golemIcons;
    };
    # No prefer-dark-theme: the look is the dock's to set, live — GTK 3 wears
    # the palette's theme over adw-gtk3 or adw-gtk3-dark by look (waverunner
    # palette.rs), libadwaita follows the portal's colour scheme (and warns
    # about this key, which it ignores). Forced dark here kept GTK 3 apps dark
    # in the light look (2026-10-15).
    # No window buttons in the apps' own header bars: Golem's titlebar
    # already has close/minimize/maximize (red/yellow/green), and GNOME apps
    # showed a second close × beside it (ASUS dogfood, 2026-10-02; Max: "yes
    # hide it, floating is the default anyway"). The libadwaita half is the
    # dconf key below; these cover GTK3/GTK4 apps reading settings.ini.
    gtk3.extraConfig.gtk-decoration-layout = ":";
    gtk4.extraConfig.gtk-decoration-layout = ":";

    # THE PALETTE (Controls → Colours): libadwaita reads
    # ~/.config/gtk-4.0/gtk.css, which only imports what the dock writes —
    # every libadwaita colour variable, both looks (a dark/light switch is
    # live in running apps; a palette or accent change at their next start).
    gtk4.extraCss = ''
      @import url("file://${config.home.homeDirectory}/.local/state/golem/theme/gtk4.css");
    '';
    # GTK 3 has no user stylesheet: its apps wear the palette as a THEME the
    # dock writes over adw-gtk3 (below) and switches by name, which GTK 3
    # reloads live — a user gtk.css is read once and would pin the old one.
  };

  # The rest of what libadwaita reads at runtime. Only keys the gtk module
  # above does NOT already write, so nothing here can conflict with it:
  # accent-color is a named palette (GNOME 47+), so "orange" is the closest
  # NAME to #ffbe98 — the exact colour comes from the CSS above, but apps
  # that ask for the name still get a warm one. Cursor is deliberately
  # absent: hyprland.lua already exports it for every client.
  dconf.settings."org/gnome/desktop/wm/preferences".button-layout = ":";   # see gtk-decoration-layout above
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    accent-color = "orange";
    document-font-name = "DejaVu Sans 11";
    monospace-font-name = "JetBrainsMono Nerd Font 11";
  };

  # The palette's files exist before the dock first writes them (it does at
  # every start): foot and hyprlock report an include that is not there as
  # a config error. Empty is fine — foot's own colours, hyprlock's defaults.
  home.activation.seedPaletteFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dir="$HOME/.local/state/golem/theme"
    $DRY_RUN_CMD mkdir -p "$dir"
    for f in foot.ini hyprlock.conf; do
      [ -e "$dir/$f" ] || $DRY_RUN_CMD touch "$dir/$f"
    done
  '';
}
