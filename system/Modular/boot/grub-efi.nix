# boot/grub-efi — the UEFI bootloader. Chosen when the census says
# firmware=uefi. Replaces boot/systemd-boot.nix (#92, Max 2026-09-15:
# "i want Golem to look and feel the same no matter if it is booting on
# grub or Systemd") — systemd-boot has NO theming at all (font, colors,
# geometry all compiled in), so one look everywhere means one menu
# everywhere: GRUB, with the same theme and the same quiet patch as the
# BIOS half. Keep every visual value here in LOCKSTEP with
# grub-bios.nix — the two leaves ARE the same menu on two firmwares.
#
# sd-boot's clearStaleBootPin does not carry over: the one-shot pin was
# a bootctl/EFI-var mechanism only systemd-boot reads; NixOS GRUB
# defaults to a fixed entry, no saved state to go stale.
#
# The macbook (Apple EFI, the boss fight) may need
# efiInstallAsRemovable as a quirk when its turn comes — Apple firmware
# and efibootmgr variables are famously strange. Decide on its metal,
# not here.
{ pkgs, lib, ... }:

{
  # #89 — same quiet grub as grub-bios.nix: no banner (upstream already
  # silences EFI's, the patch makes it universal), cursor hidden at
  # console init. The BIOS-sector hunks simply don't apply on EFI.
  nixpkgs.overlays = [
    (final: prev: {
      grub2 = prev.grub2.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./grub-quiet.patch ];
      });
    })
  ];

  boot.loader.timeout = 3;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
    configurationLimit = 15;

    # THE GOLEM LOOK (#68/#92) — identical numbers to grub-bios.nix.
    theme = pkgs.callPackage ./grub-theme.nix {
      menuWidth = 360;
      menuHeight = 120;
      menuLeft = "50%-180";
      menuTop = "50%-60";
      itemHeight = 24;
    };
    splashImage = null;
    extraConfig = ''
      set timeout_style=menu
    '';
  };
}
