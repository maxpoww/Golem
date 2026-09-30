# The MODULAR desktop stage in the VM (2026-09-30): what an installed Golem
# runs (system/Modular/composition + desktop/*), on hosts/vm.nix's machine.
# golem-vm tests the fat tree; this one tests the stage the laptops run —
# the greeter, the session guard, the desktop leaves — before a deploy.
#   nix build .#nixosConfigurations.golem-desktop-vm.config.system.build.vm
{ lib, ... }:
{
  golem.flakeAttr = lib.mkForce "golem-desktop-vm";
  golem.hardware = {
    vmGuest = "qemu";
    chassis = "desktop";
    firmware = "bios";   # qemu-vm boots the kernel directly; no loader
    cpuVendor = "intel";
  };
  # The owner's password in the VM is "golem" (base/users.nix wants a hash;
  # hosts/vm.nix's initialPassword is the fat path's). Never a real one.
  users.users.max.hashedPassword = "$6$OQ6mT9Z2t9.sj/cV$kDNwo.oVUHCpsYMtmjy8y/NPwThO0S2u2B.e7zrPY1A.IWY52WhYrSX3NxUvx7xPcq5mxYzW2xWqDo/.oqeKE.";
}
