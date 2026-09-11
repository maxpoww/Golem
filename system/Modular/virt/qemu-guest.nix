# virt/qemu-guest — chosen when the census says vmGuest=qemu.
# Guest agent + clipboard/resize; idle when the VM has neither.
# Siblings (vmware/virtualbox/hyperv) get their leaves when a machine
# demands them — the growth rule. Lifted from hardware/virt-guest.nix.
{ ... }:

{
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;
}
