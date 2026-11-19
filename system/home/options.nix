# The home layer's per-machine knobs (parity P1, 2026-09-30).
#
# Golem's home layer is ONE set of files for every machine: the installed
# Golems AND the dev box. Two copies of the desktop (the dev box's
# /etc/nixos/{home.nix,hyprland.lua} and this directory) drifted for months:
# click-to-focus, STAGE mode, shadows and motion changed on one and never
# reached the other. What legitimately differs per machine is declared here
# and set by that machine's own layer (on the dev box, /etc/nixos/home.nix);
# everything else is shared, so a fix made on one machine lands on all.
{ lib, ... }:

{
  options.golem.home = {
    devCheckout = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        The shell runs from live checkouts: the dock from ~/launcher
        (waverunner-dev, the debug waverunner-ctl) and the overview from
        ~/waveview/result: the dev box's edit, build, restart loop. Off (every
        install): the flake's store paths and the waverunner systemd unit.
      '';
    };

    idle.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Lock at 5 min, screen off at 6, suspend at 15 (hypridle). The lock
        screen itself (hyprlock, Super+L) is there either way.
      '';
    };

    loginLock.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        The lock screen is the desktop's first screen at every start: the
        login (greetd starts the desktop with no password typed). The
        owner's password opens the desktop and the keyring. Off: the
        desktop opens at once and the keyring at the first unlock.
      '';
    };

    menubox.hidePlumbing = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Hide the terminal, editor, file manager, player and system plumbing
        from the menubox (./menubox.nix), so it shows the apps a person
        picks (Seam first). Off keeps every installed entry on the grid, as
        the dev box has it (its grid and groups were arranged by hand).
      '';
    };

    hyprlandExtra = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        This machine's own Lua for Hyprland, loaded after everything Golem
        declares, so it wins (golem/extra.lua in the tree): a look it keeps, a
        panel. Keep it short; anything more than one machine would want
        belongs in a module of system/home/hypr/golem.
      '';
    };

    hyprlandModules = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "gaming" ];
      description = ''
        More app modules whose own Lua the Hyprland configuration loads
        (golem/modules/<name>.lua: the window rules and keys a module
        of programs brings with it), beside the ones that are switched on
        (golem.modules.active, read by hyprland.nix). A name with no file
        is fine.
      '';
    };

    # The two below are SET by hyprland.nix and only read: by the checks
    # (the matrices assert on the facts by evaluation, with nothing built;
    # the flake's hypr-config runs the built tree) and by a rig.
    hyprFacts = lib.mkOption {
      type = lib.types.str;
      internal = true;
      readOnly = true;
      description = ''
        The text of this machine's generated facts for Hyprland
        (golem/machine.lua in the tree): what differs from one machine to
        the next, as a Lua table the modules read.
      '';
    };

    hyprTree = lib.mkOption {
      type = lib.types.package;
      internal = true;
      readOnly = true;
      description = ''
        This build's Hyprland configuration, one folder in the store: the
        tree's entry (hyprland.lua), Golem's modules (golem/), the facts
        (golem/machine.lua) and the machine's own tail when set
        (golem/extra.lua). ~/.config/hypr/hyprland.lua, the one link in the
        home, points Hyprland at it.
      '';
    };
  };
}
