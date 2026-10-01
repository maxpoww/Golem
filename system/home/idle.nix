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
# CAFFEINE (Max, 2026-09-30: "configure a caffeine and toggle it on so they
# stay awake"): `golem-caffeine on|off|status`. On does two things:
#   - hypridle does not run at all (no lock, no screen-off, no idle suspend):
#     its unit only starts while ~/.config/golem/caffeine is absent;
#   - a systemd inhibitor (sleep + the lid switch, block) so logind will not
#     sleep on the lid either.
# The inhibitor alone was the first version and it did NOT keep the screen on:
# hypridle reads Wayland and D-Bus (org.freedesktop.ScreenSaver) inhibits, not
# systemd ones, so both laptops kept locking at 5 min and blanking at 6 with
# caffeine "on" (2026-10-01, ThinkPad: locks at 23:57, 00:17, 00:24).
# Nothing is removed; off brings every step back. The choice is a file
# (~/.config/golem/caffeine), so it survives a reboot, a relogin and a
# home-manager switch (which restarts hypridle: the condition keeps it off).
#
# golem.home.idle.enable = false (a machine's own layer) drops the timed
# steps only; hyprlock and Super+L stay. The dev box sets it: builds and
# agent sessions run there unattended, and a suspend would stop them.
{ config, lib, pkgs, ... }:

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
  # The lock screen is the COMPOSITOR's child, never hypridle's. Started from
  # hypridle it lived in hypridle.service's cgroup, so a home-manager switch
  # that restarted hypridle while the screen was locked killed hyprlock with
  # it; Hyprland keeps a session locked when its lock client dies, so both
  # laptops froze on the lock screen's last frame, clock and all, and no
  # input could unlock them (2026-09-30). Super+L launches it the same way.
  golemLock = pkgs.writeShellScript "golem-lock" ''
    pidof hyprlock >/dev/null && exit 0
    exec hyprctl dispatch 'hl.dsp.exec_cmd("hyprlock")'
  '';
  lock = "${golemLock}";
  # The idle suspend waits for a running install or system update: an app
  # from the dock can take longer than the 15 minutes (DaVinci Resolve, 25
  # min on the ThinkPad), and a suspend in the middle stalls the download or
  # the switch. Only the IDLE suspend: closing the lid still suspends.
  golemIdleSuspend = pkgs.writeShellScript "golem-idle-suspend" ''
    for u in waverunner-apply golem-postinstall-apply golem-autoupdate seam-update golem-first-boot; do
      if systemctl is-active --quiet "$u.service"; then
        echo "golem-idle-suspend: $u is running — not suspending"
        exit 0
      fi
    done
    exec systemctl suspend
  '';
  idleSuspend = "${golemIdleSuspend}";
  golemCaffeine = pkgs.writeShellScriptBin "golem-caffeine" ''
    state="$HOME/.config/golem/caffeine"
    case "''${1:-status}" in
      on)
        mkdir -p "$(dirname "$state")" && touch "$state"
        systemctl --user stop hypridle.service 2>/dev/null
        systemctl --user start golem-caffeine.service
        echo "caffeine ON: no lock, no screen-off, no sleep (lid included). Undo: golem-caffeine off" ;;
      off)
        rm -f "$state"
        systemctl --user stop golem-caffeine.service
        systemctl --user start hypridle.service 2>/dev/null
        echo "caffeine OFF: lock, screen-off and sleep are back" ;;
      status)
        if systemctl --user is-active --quiet golem-caffeine.service; then echo on; else echo off; fi ;;
      *) echo "usage: golem-caffeine on|off|status" >&2; exit 2 ;;
    esac
  '';
in
{
  home.packages = [ golemCaffeine ];
  systemd.user.services.golem-caffeine = {
    Unit = {
      Description = "Golem caffeine: stay awake (golem-caffeine on|off)";
      ConditionPathExists = "%h/.config/golem/caffeine";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service.ExecStart = "${pkgs.systemd}/bin/systemd-inhibit --what=idle:sleep:handle-lid-switch --who=Golem --why=Caffeine --mode=block ${pkgs.coreutils}/bin/sleep infinity";
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Caffeine on: hypridle stays off (see CAFFEINE above).
  systemd.user.services.hypridle.Unit.ConditionPathExists =
    lib.mkIf config.golem.home.idle.enable "!%h/.config/golem/caffeine";

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
        { timeout = 900; on-timeout = idleSuspend; }
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
