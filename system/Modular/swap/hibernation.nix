# swap/hibernation — resume wiring for the installer's disk swap.
# Hibernation is a LOCKED decision: golem-install creates disk swap
# sized RAM+margin on every machine (partition sizing is engine-side;
# this leaf is the system's half). First swap device = the installer's
# hibernation partition; the guard is mechanism (reading what the
# machine.nix/hardware-configuration declared), not a census fact —
# a swapless host simply gets no resume line. Lifted from
# hardware/memory.nix (2026-09-10).
{ config, lib, ... }:

{
  boot.resumeDevice = lib.mkIf (config.swapDevices != [ ])
    (lib.mkDefault (lib.head config.swapDevices).device);
}
