# base/console — the TTY's keymap and font, data-driven from
# golem.keyboard (the installer's keyboard answer). The XKB sinks
# (X11/XWayland + Hyprland's own input block) arrive with the desktop
# leaf — a tty-only stage 0 has exactly one keyboard consumer, this one.
{ config, lib, ... }:

{
  console.keyMap = lib.mkDefault config.golem.keyboard.consoleKeyMap;
  console.font = lib.mkIf (config.golem.keyboard.consoleFont != null)
    (lib.mkDefault config.golem.keyboard.consoleFont);
}
