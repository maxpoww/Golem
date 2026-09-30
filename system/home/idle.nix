# The owner's idle behaviour (parity P11, 2026-09-30). Before this a Golem
# laptop left alone never dimmed, locked or slept: the screen stayed on at
# full brightness, unlocked, until the battery ran out.
#
#   5 min   lock (hyprlock, called directly: see `lock` below; unlock with the
#           owner's password)
#   6 min   screen off (the compositor's dpms through Hyprland's Lua dispatch,
#           golem-dpms below; `hyprctl dispatch dpms off` does NOT exist here)
#   15 min  suspend (the lid does suspend-then-hibernate on its own, base/power)
#
# A video, a call or anything that takes a systemd idle inhibitor keeps all
# three away (ignore_dbus_inhibit = false). Both daemons are user services tied
# to graphical-session.target. The lock screen's PAM service is the system's
# (system/Modular/desktop/idle.nix).
#
# golem.home.idle.enable = false (a machine's own layer) drops the timed
# steps only; hyprlock and Super+L stay. The dev box sets it: builds and
# agent sessions run there unattended, and a suspend would stop them.
{ config, pkgs, ... }:

let
  # The display's power by ACTION: Golem's Hyprland takes
  # hl.dsp.dpms({ action = "on" | "off" | "toggle" }). A bare string is IGNORED
  # and the call TOGGLES: after a wake-up the screen was already on, the "on"
  # turned it off, and both laptops woke to a dark screen with the keyboard
  # alive (2026-09-30; the first test, off then on, could not tell the two
  # apart). A script, not an inline command: hypridle's config language
  # would read the braces.
  golemDpms = pkgs.writeShellScript "golem-dpms" ''
    exec hyprctl dispatch "hl.dsp.dpms({ action = \"$1\" })"
  '';
  dpms = state: "${golemDpms} ${state}";
  # hyprlock DIRECTLY, never `loginctl lock-session`: Golem's session is
  # greeter-class (greetd's default_session) and logind answers "Session does
  # not support lock screen" (seen live on the MacBook, 2026-09-30: the 5-min
  # lock never happened, the 6-min screen-off did). hyprlock locks through
  # the compositor's own session-lock protocol, which needs no logind.
  lock = "pidof hyprlock || hyprlock";
in
{
  services.hypridle = {
    enable = config.golem.home.idle.enable;
    settings = {
      general = {
        lock_cmd = lock;
        before_sleep_cmd = lock;
        after_sleep_cmd = dpms "on";
        ignore_dbus_inhibit = false;
      };
      listener = [
        { timeout = 300; on-timeout = lock; }
        { timeout = 360; on-timeout = dpms "off"; on-resume = dpms "on"; }
        { timeout = 900; on-timeout = "systemctl suspend"; }
      ];
    };
  };

  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        ignore_empty_input = true;
      };
      background = [{
        monitor = "";
        color = "rgba(20, 20, 24, 1.0)";
      }];
      label = [{
        monitor = "";
        text = "$TIME";
        font_size = 64;
        color = "rgb(235, 235, 235)";
        position = "0, 120";
        halign = "center";
        valign = "center";
      }];
      input-field = [{
        monitor = "";
        size = "260, 44";
        position = "0, -40";
        outline_thickness = 2;
        dots_size = 0.25;
        fade_on_empty = true;
        placeholder_text = "<i>password</i>";
        outer_color = "rgb(255, 190, 152)"; # the desktop's accent, hyprland.lua's active border
        inner_color = "rgb(30, 30, 36)";
        font_color = "rgb(235, 235, 235)";
        check_color = "rgb(255, 190, 152)";
        fail_color = "rgb(220, 80, 80)";
        halign = "center";
        valign = "center";
      }];
    };
  };
}
