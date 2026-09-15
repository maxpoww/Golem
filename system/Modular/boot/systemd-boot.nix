# boot/systemd-boot — RETIRED from the chooser 2026-09-15 (#92, Max:
# "i want Golem to look and feel the same no matter if it is booting on
# grub or Systemd"). systemd-boot cannot be themed AT ALL — font,
# colors, geometry are compiled in — so one look everywhere means one
# menu everywhere: boot/grub-efi.nix now takes firmware=uefi, carrying
# the same theme and quiet patch as the BIOS half. This file is kept
# for the day a machine truly cannot GRUB; nothing points at it.
#
# (Original header: the UEFI bootloader, chosen when the census says
# firmware=uefi. Values lifted verbatim from configuration.nix's uefi
# branch, 2026-09-10.)
{ pkgs, ... }:

{
  boot.loader.timeout = 3;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 15;
    editor = false;
  };

  # Clear a stale one-shot boot pin. LIVES HERE, not in base: bootctl is
  # UEFI-only, and on a BIOS machine it printed "Not booted with UEFI."
  # onto the silent boot on every activation (#68, Max's eyes on the hp).
  # A leaf owns its own bootloader's housekeeping.
  system.activationScripts.clearStaleBootPin.text = ''
    ${pkgs.systemd}/bin/bootctl set-default "" >/dev/null 2>&1 || true
  '';
}
