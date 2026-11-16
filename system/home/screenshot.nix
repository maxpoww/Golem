# golem-screenshot — the Print Screen keys' command (golem-screenshot.sh says
# what it does; hyprland.lua binds Print, Shift+Print and Alt+Print to it).
# Before it the key ran `grim | wl-copy` bare: a region on the clipboard, no
# file, no word that anything had happened.
#
# Its tools come with it (runtimeInputs), so the key works whatever the
# session's PATH holds. Two are the session's own and stay there: hyprctl (the
# compositor that is running, not a second build of it) and xdg-open (the
# owner's default image viewer opens a shot).
{ pkgs, ... }:

let
  golemSay = pkgs.callPackage ../i18n/golem-say.nix { };
  golemScreenshot = pkgs.writeShellApplication {
    name = "golem-screenshot";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.grim
      pkgs.slurp
      pkgs.jq
      pkgs.wl-clipboard
      pkgs.libnotify
      pkgs.xdg-user-dirs
      golemSay
    ];
    text = builtins.readFile ./golem-screenshot.sh;
  };
in
{
  home.packages = [ golemScreenshot ];
}
