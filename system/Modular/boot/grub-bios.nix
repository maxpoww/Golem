# boot/grub-bios — the BIOS/legacy bootloader. Chosen when the census
# says firmware=bios. GRUB (not systemd-boot, UEFI-only) is also what
# chainloads other OSes; the disk is GPT + a BIOS-boot partition on
# both firmware paths so dual-boot has room to grow. device mkDefault:
# golem-install overrides it in machine.nix with the real target disk.
# Values lifted verbatim from configuration.nix's bios branch.
{ lib, ... }:

{
  boot.loader.timeout = 3;
  boot.loader.grub = {
    enable = true;
    efiSupport = false;
    device = lib.mkDefault "/dev/sda";
    configurationLimit = 15;
  };
}
