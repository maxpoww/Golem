# desktop/bluetooth — stage 1. Ported verbatim from system/bluetooth.nix:
# rides the census (golem.hardware.hasBluetooth) — a machine confidently
# detected with no radio drops bluez + blueman entirely; undetected defaults to
# true (the conservatism rule). blueman is a desktop concern, hence stage 1 (the
# minimal base carries no Bluetooth UI).
{ config, lib, ... }:

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
  };
}
