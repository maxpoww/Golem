# power/laptop — chosen when the census says chassis=laptop. Battery
# on DBus, the profile switch, and hibernation's payoff: a closed lid
# suspends, two hours later the image goes to disk — a laptop
# forgotten in a bag wakes with the session intact. The swapDevices
# guard is mechanism (suspend-then-hibernate's second leg needs the
# disk swap the installer made); tlp deliberately absent (fights
# power-profiles-daemon). Lifted from hardware/power-laptop.nix
# (2026-09-10); thermald is its own leaf (intel-laptop only).
{ config, lib, ... }:

{
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  services.logind.settings.Login.HandleLidSwitch = lib.mkIf
    (config.swapDevices != [ ]) (lib.mkDefault "suspend-then-hibernate");
  systemd.sleep.settings.Sleep.HibernateDelaySec = lib.mkIf
    (config.swapDevices != [ ]) (lib.mkDefault "120min");
}
