# boot/systemd-boot — the UEFI bootloader. Chosen when the census says
# firmware=uefi. Values lifted verbatim from configuration.nix's uefi
# branch (2026-09-10).
{ ... }:

{
  boot.loader.timeout = 3;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 15;
    editor = false;
  };
}
