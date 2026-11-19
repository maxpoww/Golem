# modules/gaming — Gaming: stores and launchers, performance tools, game
# streaming, emulators, free games.
#
# PLUMBING (the module is on): what every game on this computer assumes,
# whichever store it came from.
#   · 32-bit graphics: Windows games and older Linux ones are 32-bit
#     (GolemModules.md §4.1; the NixOS manual, "Steam").
#   · The controllers' and VR headsets' device rules (hardware.steam-hardware:
#     Valve's udev rules — a DualSense, a Switch Pro pad, a Steam Controller
#     reach the session through hidraw). An Xbox pad on a cable or Bluetooth
#     works with the kernel's own driver; the out-of-tree xone/xpadneo drivers
#     are for the wireless dongle and for rumble quirks, need nothing here to
#     play, and are left out.
#   · GameMode's daemon and its polkit rules (GolemModules.md §4.1).
#
# PROGRAM SETUP is keyed on the installed program, so a game store dragged
# into the grid gets the same system as one switched on here.
{ config, lib, pkgs, ... }:

let
  m = import ./lib.nix { inherit lib; };
  inherit (m.scope config) has any on;

  # (Names as lib.getName gives them: RetroArch with its cores is its own,
  # PPSSPP is its SDL build.)
  stores = [ "steam" "lutris" "heroic" "bottles" ];
  emulators = [ "retroarch" "retroarch-with-cores" "dolphin-emu" "pcsx2" "rpcs3" "cemu" "ppsspp-sdl" ];
in
{
  imports = [
    (m.mkModule {
      id = "gaming";
      description = "Gaming: stores and launchers, performance tools, game streaming, emulators, free games.";
    })
  ];

  config = lib.mkMerge [
    (lib.mkIf (on "gaming") {
      hardware.graphics.enable32Bit = true;
      hardware.steam-hardware.enable = true;
      programs.gamemode.enable = true;
    })

    {
      # Steam is a system program on NixOS: its 32-bit runtime, its udev rules
      # and (for Remote Play / local transfers) its ports come with the module.
      programs.steam = lib.mkIf (has "steam") {
        enable = true;
        remotePlay.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
      };
      # Controllers and VR headsets are let through to the session — for the
      # emulators too, which read the same pads (a DualSense through hidraw).
      hardware.steam-hardware.enable = lib.mkIf (any (stores ++ emulators)) true;
      # Windows games and old Linux ones are 32-bit: they need 32-bit graphics.
      hardware.graphics.enable32Bit = lib.mkIf (any stores) true;
      # GameMode's daemon needs its polkit rules to be allowed to do anything.
      programs.gamemode.enable = lib.mkIf (any (stores ++ [ "gamemode" ])) true;
      # Gamescope, system-wide (the launch option `gamescope -- %command%`
      # finds it from any store). WITHOUT its nice capability on purpose:
      # programs.gamescope.capSysNice makes a setcap wrapper, and a wrapper
      # with capabilities cannot start inside Steam's own sandbox — the one
      # place most people run it.
      programs.gamescope.enable = lib.mkIf (has "gamescope") true;
      # Sunshine captures the screen and makes input devices: both privileged.
      # (Moonlight, the other end, is only its program.)
      services.sunshine = lib.mkIf (has "sunshine") {
        enable = true;
        capSysAdmin = true;
        openFirewall = true;
      };
      # Dolphin's own device rules (its package ships them): the GameCube
      # controller adapter and Wii remotes on USB, opened without root.
      services.udev.packages = lib.optional (has "dolphin-emu") pkgs.dolphin-emu;
    }
  ];
}
