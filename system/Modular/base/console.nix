# base/console — the TTY's keymap and font.
#
# On the MINIMAL (installed) path the keymap is SEEDED, not declared: the
# baked toplevel is direct-copied (no rebuild), so golem-install writes a plain
# /etc/vconsole.conf after the copy (install.nix step 5c), exactly as it writes
# the password + SSH key. For that seed to survive activation, NixOS must NOT
# manage /etc/vconsole.conf — otherwise the store symlink is reasserted every
# boot and the seed is lost. So we drop the managed entry here. systemd-vconsole-
# setup still reads whatever /etc/vconsole.conf contains, so the seeded keymap
# applies. (The XKB sinks — X11/XWayland + Hyprland's input block — arrive with
# the desktop leaf; a tty-only stage 0 has exactly one keyboard consumer.)
{ config, lib, ... }:

{
  # console.font stays declarative when a keymap needs a special font — a
  # Latin keymap needs none, and the seeded vconsole.conf carries FONT itself.
  console.font = lib.mkIf (config.golem.keyboard.consoleFont != null)
    (lib.mkDefault config.golem.keyboard.consoleFont);

  # Leave /etc/vconsole.conf to the installer's seed (see header). mkForce so it
  # wins over the console module's own `environment.etc."vconsole.conf"`.
  environment.etc."vconsole.conf".enable = lib.mkForce false;
}
