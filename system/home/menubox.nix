# The MENUBOX shows Seam and nothing else (Max, 2026-09-29: "i only want seam
# on it (Golem browser) all rest on the menubox is bloat").
#
# Everything hidden here stays INSTALLED — the terminal behind Super+E, yazi,
# the editor, the player, the system plumbing. It just isn't something you
# pick from the grid. The launcher's indexer (waverunner core/src/index.rs)
# skips NoDisplay entries, and an entry in ~/.local/share/applications
# overrides a system one with the same ID — so hiding is an override here,
# never a patch to the package.
{ config, lib, pkgs, ... }:

let
  # Entries that are ALSO handlers (terminal, text, folders, video): keep the
  # real entry and only add NoDisplay, so xdg-open and "open with" still find
  # them. Built as a derivation (no import-from-derivation at eval time).
  hideCopy = id: pkg: {
    name = "applications/${id}.desktop";
    value.source = pkgs.runCommand "${id}-nodisplay.desktop" { } ''
      src=${pkg}/share/applications/${id}.desktop
      test -e "$src" || { echo "menubox.nix: $src is missing" >&2; exit 1; }
      sed '0,/^\[Desktop Entry\]$/s//[Desktop Entry]\nNoDisplay=true/' "$src" > $out
    '';
  };

  # Pure plumbing with no handler role: a stub that claims the ID is enough.
  # A stub for an ID the machine doesn't have is harmless.
  hideStub = id: {
    name = "applications/${id}.desktop";
    value.text = "[Desktop Entry]\nType=Application\nName=${id}\nNoDisplay=true\n";
  };
in
{
  # golem.home.menubox.hidePlumbing (./options.nix): on for every install;
  # the dev box keeps its hand-arranged grid (parity P1).
  xdg.dataFile = lib.mkIf config.golem.home.menubox.hidePlumbing (lib.listToAttrs (
    [
      (hideCopy "foot" config.programs.foot.package)
      (hideCopy "nvim" config.programs.neovim.finalPackage)
      (hideCopy "yazi" config.programs.yazi.package)
      (hideCopy "lf" pkgs.lf)   # a folder handler: a stub without Exec made "open folder" dead (P9)
      (hideCopy "mpv" pkgs.mpv)
      (hideCopy "umpv" pkgs.mpv)
    ]
    ++ map hideStub [
      "footclient"
      "foot-server"
      "btop"
      "waypaper"
      "xterm"
      "nixos-manual"
      "uuctl"
      "org.freedesktop.Xwayland"
      "xdg-desktop-portal-gtk"
      "blueman-adapters"
      "blueman-manager"
    ]
  ));
}
