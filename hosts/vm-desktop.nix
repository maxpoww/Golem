# The MODULAR desktop stage in the VM (2026-09-30): what an installed Standard
# runs (system/Modular/composition + desktop/*), on hosts/vm.nix's machine.
# standard-vm tests the fat tree; this one tests the stage the laptops run —
# the greeter, the session guard, the desktop leaves — before a deploy.
#   nix build .#nixosConfigurations.standard-desktop-vm.config.system.build.vm
{ lib, ... }:
{
  standard.flakeAttr = lib.mkForce "standard-desktop-vm";
  standard.hardware = {
    vmGuest = "qemu";
    chassis = "desktop";
    firmware = "bios";   # qemu-vm boots the kernel directly; no loader
    cpuVendor = "intel";
  };
  # The owner's password in the VM is "golem": hosts/vm.nix's initialPassword.
}
