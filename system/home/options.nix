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
        Lua appended to hyprland.lua, last, so it wins: this machine's own
        deltas (a look it keeps, a panel). Keep it short; anything more than
        one machine would want belongs in hyprland.lua itself.
      '';
    };
  };
}
