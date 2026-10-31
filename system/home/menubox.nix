# The MENUBOX shows Seam and nothing else (Max, 2026-09-29: "i only want seam
# on it (Golem browser) all rest on the menubox is bloat").
#
# Everything hidden here stays INSTALLED — the terminal behind Super+E, yazi,
# the editor, the player, the system plumbing. It just isn't something you
# pick from the grid. The launcher's indexer (waverunner core/src/index.rs)
# skips NoDisplay entries, and an entry in ~/.local/share/applications
# overrides a system one with the same ID — so hiding is an override here,
# never a patch to the package.
#
# Hiding is for what comes WITH Golem. What the owner installed from the dock is
# theirs to see, and to open: btop ships in every Golem (base/core.nix), so its stub
# outlived an install of it, and the dock took the app for a command-line tool with no
# entry: a shell saying "btop is ready" where the dev box opens btop (the ASUS,
# 2026-10-31). The same went for mpv, Neovim, yazi, lf, foot, xterm and Blueman.
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

  # What the dock installed: the lowPrio home packages (hosts/target/apps.nix, made
  # by waverunner-apply). Nothing else in the home layer is lowPrio.
  picked = map lib.getName
    (lib.filter (p: ((p.meta or { }).priority or 5) > 5) config.home.packages);
  # These entries, unless the owner installed one of these packages.
  unlessPicked = packages: entries:
    lib.optionals (!lib.any (p: builtins.elem p picked) packages) entries;
in
{
  # golem.home.menubox.hidePlumbing (./options.nix): on for every install;
  # the dev box keeps its hand-arranged grid (parity P1).
  xdg.dataFile = lib.mkIf config.golem.home.menubox.hidePlumbing (lib.listToAttrs (
    unlessPicked [ "foot" ] (
      [ (hideCopy "foot" config.programs.foot.package) ]
      ++ map hideStub [ "footclient" "foot-server" ]
    )
    ++ unlessPicked [ "neovim" ] [ (hideCopy "nvim" config.programs.neovim.finalPackage) ]
    ++ unlessPicked [ "yazi" ] [ (hideCopy "yazi" config.programs.yazi.package) ]
    # lf is a folder handler: a stub without Exec made "open folder" dead (P9).
    ++ unlessPicked [ "lf" ] [ (hideCopy "lf" pkgs.lf) ]
    ++ unlessPicked [ "mpv" "mpv-with-scripts" ] [
      (hideCopy "mpv" pkgs.mpv)
      (hideCopy "umpv" pkgs.mpv)
    ]
    ++ unlessPicked [ "btop" ] [ (hideStub "btop") ]
    ++ unlessPicked [ "xterm" ] [ (hideStub "xterm") ]
    ++ unlessPicked [ "blueman" ] (map hideStub [ "blueman-adapters" "blueman-manager" ])
    ++ map hideStub [
      "nixos-manual"
      "uuctl"
      "org.freedesktop.Xwayland"
      "xdg-desktop-portal-gtk"
    ]
  ));
}
