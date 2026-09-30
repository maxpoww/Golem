{ config, lib, pkgs, ... }:

{
# The whole stack rides the census: a machine whose detection confidently
# says "no radio" (golem.hardware.hasBluetooth = false) drops bluez +
# blueman entirely; undetected machines default to true and keep this
# always-on behavior (the conservatism rule, GolemInstall.md §4).
config = lib.mkIf config.golem.hardware.hasBluetooth {

services.blueman.enable        = true;

hardware.bluetooth = {
  enable = true;
  powerOnBoot = true;
  settings = {
    General = {
      Enable = "Source,Sink,Media,Socket";
      Experimental = true;
      FastConnectable = true;
    };
    Policy = {
      AutoEnable = true;
    };
  };
};

    # After a HIBERNATE (not a plain suspend) BlueZ comes back with its
    # trusted devices disconnected, and speakers and headphones stay silent
    # until reconnected by hand. The lid does suspend-then-hibernate on a
    # Golem laptop, so this is every long lid-close. Waits for the adapter
    # to power up, then reconnects each trusted device (4 tries). Ported
    # from the dev box on 2026-09-30 (found by the P1 diff: it only ever
    # lived there).
    systemd.services.bluetooth-reconnect-after-hibernate = {
      description = "Reconnect trusted Bluetooth devices after resume from hibernation";
      after = [ "hibernate.target" "suspend-then-hibernate.target" "bluetooth.service" ];
      wantedBy = [ "hibernate.target" "suspend-then-hibernate.target" ];
      path = [ pkgs.bluez ];
      serviceConfig = {
        Type = "oneshot";
        TimeoutStartSec = "90s";
      };
      script = ''
        for _ in $(seq 20); do
          bluetoothctl show | grep -q "Powered: yes" && break
          sleep 1
        done
        bluetoothctl devices Trusted | while read -r _ mac _; do
          for _ in $(seq 4); do
            bluetoothctl info "$mac" | grep -q "Connected: yes" && break
            bluetoothctl connect "$mac" && break
            sleep 4
          done
        done
        exit 0
      '';
    };

};
}
