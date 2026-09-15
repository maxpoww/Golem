# hosts/target/modules.nix — written by golem-hw-choose. THE MACHINE:
# every import below is a leaf the census pointed at, each with its
# why. Change it by re-choosing (or by an owner's deliberate edit) —
# the eval matrix pins the lab machines' lists, so drift is visible.
{ ... }:
{
  imports = [
    # firmware=bios
    ../../system/Modular/boot/grub-bios.nix
    # cpuVendor=intel
    ../../system/Modular/cpu/intel-microcode.nix
    # gpu=intel, intelLegacy (pre-Skylake → i965)
    ../../system/Modular/gpu/intel-legacy.nix
    # ramMB=1931 < 6144
    ../../system/Modular/memory/zram-tier1.nix
    # hibernation is a locked decision
    ../../system/Modular/swap/hibernation.nix
    # runtime per-device rule — the one always-leaf
    ../../system/Modular/disk/policy.nix
    # chassis=laptop
    ../../system/Modular/power/laptop.nix
    # chassis=laptop + cpuVendor=intel
    ../../system/Modular/power/thermald.nix
    # OWNER EDIT (#90, 2026-09-15): the lid switch reports "closed"
    # with the lid open — power/laptop's lid rule slept the machine 30 s
    # after every wake. No census fact chooses this yet.
    ../../system/Modular/quirks/lid-switch-broken.nix
  ];
  # not chosen: gpu2 (gpu2=none — single-GPU machine) · virt (vmGuest=none — physical machine) · quirks (lid-switch-broken added by owner edit above, not by the chooser)
}