# desktop/bluetooth — stage 1. Ported verbatim from system/bluetooth.nix:
# rides the census (golem.hardware.hasBluetooth) — a machine confidently
# detected with no radio drops bluez + blueman entirely; undetected defaults to
# true (the conservatism rule). blueman is a desktop concern, hence stage 1 (the
# minimal base carries no Bluetooth UI).
{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.golem.hardware.hasBluetooth {
    services.blueman.enable = true;

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

    # A Bluetooth network link (bnep0: sharing this computer's internet with
    # a paired device, or using a phone's) keeps the name the kernel gave it.
    # The radio is a USB device on most laptops, so udev's predictable names
    # renamed bnep0 to enp0s20f0u10 a moment after BlueZ had put it in
    # NetworkManager's shared bridge: the port went "disabled" and the other
    # side never got an address (dev box → MacBook, 2026-10-06).
    systemd.network.links."10-golem-bnep" = {
      matchConfig.OriginalName = "bnep*";
      linkConfig.NamePolicy = "keep kernel";
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
