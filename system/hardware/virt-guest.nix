# Hypervisor guest tools — the `vmGuest` fact's consumer (spec §4).
# Each hypervisor gets exactly its own integration: clipboard/resize/
# time-sync stop being "Linux in a VM is janky" and the census's DMI
# read is all it costs. "none" (physical hardware, or a hypervisor we
# could not classify) adds nothing — the conservatism law.
{ config, lib, ... }:

let
  guest = config.golem.hardware.vmGuest;
in
{
  config = lib.mkMerge [
    (lib.mkIf (guest == "qemu") {
      services.qemuGuest.enable = lib.mkDefault true;
      # Clipboard + display resize on qemu/KVM desktops (spice/virtio);
      # idle when the VM has neither.
      services.spice-vdagentd.enable = lib.mkDefault true;
    })
    (lib.mkIf (guest == "vmware") {
      virtualisation.vmware.guest.enable = lib.mkDefault true;
    })
    (lib.mkIf (guest == "virtualbox") {
      virtualisation.virtualbox.guest.enable = lib.mkDefault true;
    })
    (lib.mkIf (guest == "hyperv") {
      virtualisation.hypervGuest.enable = lib.mkDefault true;
    })
  ];
}
