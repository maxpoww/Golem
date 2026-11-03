# desktop/idle — the system half of "something happens on idle" (parity P11).
#
# The idle daemon (hypridle) and the lock screen (hyprlock) are the owner's,
# in the home layer (system/home/idle.nix): lock at 5 min, screen off at 6,
# suspend at 15, lock before any sleep. hyprlock authenticates the owner's
# password through PAM, so the system must know it as a PAM service — without
# this entry the lock screen can never be unlocked.
#
# THE POWER KEY (Max, 2026-11-03): a short press is the desktop's — the
# compositor binds it to the banner's power pills (hibernate, sleep, restart;
# system/home/hyprland.lua) — and logind leaves it alone; a long press (logind
# counts five seconds) powers off. logind's own short press was "poweroff": a
# brush of the Lenovo's key, which sits in the keyboard's top row, turned the dev
# box off on 2026-11-03 with nothing said. Where the firmware cuts the power
# itself sooner than five seconds, a long press is still off, only not clean.
#
# Two kernel drivers want the key, and whichever binds first owns it:
#   button             a "Power Button" keyboard: logind and the compositor
#                      above see the key go down and up.
#   tiny_power_button  sends a signal straight to systemd, nobody else sees it.
#                      Its signal was "power off now": on the test VM and the
#                      ASUS (6.18.57: `button` cannot take a fixed-feature button
#                      there, only tiny can) any press turned the machine off.
# So tiny's signal is SIGWINCH instead, which systemd turns into kbrequest.target
# (the console's Alt+↑ does the same), and that asks the owner's banner for the
# same pills. Tiny sees no release, so there a long press is the firmware's own.
{ config, lib, pkgs, ... }:

let
  owner = config.golem.owner;

  # kbrequest.target → the owner's banner shows the power pills. Not while the
  # screen is locked: the lock covers the banner, as the compositor's bind
  # does nothing then either.
  powerKey = pkgs.writeShellApplication {
    name = "golem-power-key";
    runtimeInputs = [ pkgs.procps pkgs.util-linux pkgs.coreutils ];
    text = ''
      uid=$(id -u ${owner}) || exit 0
      [ -S "/run/user/$uid/bus" ] || exit 0
      # (comm is cut at 15: a wrapped hyprlock is ".hyprlock-wrapp".)
      if pgrep -u "$uid" -x 'hyprlock|\.hyprlock-wrapp' >/dev/null; then exit 0; fi
      for ctl in /etc/profiles/per-user/${owner}/bin/waverunner-ctl /home/${owner}/launcher/target/debug/waverunner-ctl; do
        if [ -x "$ctl" ]; then
          exec runuser -u ${owner} -- env XDG_RUNTIME_DIR="/run/user/$uid" "$ctl" power
        fi
      done
    '';
  };
in
{
  security.pam.services.hyprlock = { };

  services.logind.settings.Login = {
    HandlePowerKey = lib.mkDefault "ignore";
    HandlePowerKeyLongPress = lib.mkDefault "poweroff";
  };

  # 28 = SIGWINCH.
  boot.extraModprobeConfig = ''
    options tiny_power_button power_signal=28
  '';
  # Up for as long as its one service runs, so every press starts it again.
  systemd.targets.kbrequest = {
    description = "Golem: the power key, through the kernel's tiny power button driver";
    wants = [ "golem-power-key.service" ];
    unitConfig.StopWhenUnneeded = true;
  };
  systemd.services.golem-power-key = {
    description = "Golem: the power key asks the banner for its pills";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${powerKey}/bin/golem-power-key";
    };
  };
}
