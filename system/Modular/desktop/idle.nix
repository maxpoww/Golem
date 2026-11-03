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
{ lib, ... }:

{
  security.pam.services.hyprlock = { };

  services.logind.settings.Login = {
    HandlePowerKey = lib.mkDefault "ignore";
    HandlePowerKeyLongPress = lib.mkDefault "poweroff";
  };
}
