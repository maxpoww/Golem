# Hardware-free Golem for the S7 test loop:
#   nixos-rebuild build-vm --flake .#golem-vm && ./result/bin/run-Golem-vm
# No nvidia, virtio graphics; greetd autologs max straight into Hyprland.
{ lib, ... }:

{
  nixpkgs.hostPlatform = "x86_64-linux";

  # Dummy root so the config evaluates standalone; the vm builder overrides
  # every filesystem with its own image (mkVMOverride).
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

  # A stranger's first login (greetd autologin makes this rarely needed).
  users.users.max.initialPassword = "golem";

  virtualisation.vmVariant.virtualisation = {
    memorySize = 4096;
    cores = 4;
    qemu.options = [
      "-device virtio-vga-gl"
      "-display gtk,gl=on"
    ];
  };
}
