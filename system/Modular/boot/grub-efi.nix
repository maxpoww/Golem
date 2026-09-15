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
  # The Golem grub (quiet + item_align), shared with grub-bios.nix so the
  # two firmware halves cannot drift apart. See #89, #92, #94b.
  imports = [ ./grub-patched.nix ];

  boot.loader.timeout = 3;

  # #94 — OWN THE FALLBACK PATH, don't trust firmware NVRAM. The acer
  # (2026-09-15) accepted a named "Golem-boot" entry, put it first in
  # BootOrder, and then DELETED it across one reboot — booting its own
  # "HDD:" entry, which runs \EFI\BOOT\BOOTX64.EFI. A bootloader that
  # lives only in an NVRAM entry is at the mercy of firmware that
  # rewrites its boot order, and old laptops do exactly that. Installing
  # as removable puts GRUB at the fallback path every firmware falls
  # back to, so "it boots" stops depending on NVRAM surviving.
  # mutually exclusive with canTouchEfiVariables (NixOS asserts it):
  # with no NVRAM writes there is no named entry to lose. mkDefault so a
  # machine that needs a named entry can override in its own quirk.
  boot.loader.efi.canTouchEfiVariables = false;

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = lib.mkDefault true;
    device = "nodev";
    configurationLimit = 15;

    # THE GOLEM LOOK (#68/#92) — identical numbers to grub-bios.nix.
    theme = pkgs.callPackage ./grub-theme.nix {
      menuWidth = 226;
      menuHeight = 120;
      menuLeft = "50%-113";
      menuTop = "50%-60";
      itemHeight = 24;
    };
    splashImage = null;
    extraConfig = ''
      set timeout_style=menu
    '';
  };
}
