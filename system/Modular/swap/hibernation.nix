# swap/hibernation — resume wiring for the installer's disk swap.
# Hibernation is a LOCKED decision: golem-install creates disk swap
# sized RAM+margin on every machine (partition sizing is engine-side;
# this leaf is the system's half). First swap device = the installer's
# hibernation partition; the guard is mechanism (reading what the
# machine.nix/hardware-configuration declared), not a census fact —
# a swapless host simply gets no resume line. Lifted from
# hardware/memory.nix (2026-09-10).
#
# image_size 0 (2026-10-01, thinkpad metal): the kernel's default
# target (2/5 of RAM) leaves too little headroom on a zram machine.
# It preallocates the snapshot BEFORE devices freeze; amdgpu then
# evicts VRAM into RAM and the image grows past the free pages →
# "Not enough free memory … Error -12 creating image" (the 5%-battery
# hibernate on 2026-09-30, Seam playing video). Reproduced with
# test_resume: default → -12 (need 943k, prealloc 715k); 0 → need
# 637k of 1.26M available. 0 = "as small as possible": ~10 s slower
# in, a few seconds of swap-in after resume — a hibernate that works.
{ config, lib, ... }:

{
  boot.resumeDevice = lib.mkIf (config.swapDevices != [ ])
    (lib.mkDefault (lib.head config.swapDevices).device);

  systemd.tmpfiles.rules = [ "w /sys/power/image_size - - - - 0" ];
}
