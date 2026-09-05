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

};
}
