# boot/grub-bios — the BIOS/legacy bootloader. Chosen when the census
# says firmware=bios. GRUB (not systemd-boot, UEFI-only) is also what
# chainloads other OSes; the disk is GPT + a BIOS-boot partition on
# both firmware paths so dual-boot has room to grow. device mkDefault:
# golem-install overrides it in machine.nix with the real target disk.
# Values lifted verbatim from configuration.nix's bios branch.
{ pkgs, lib, ... }:

{
  # The Golem grub (quiet + item_align), shared with grub-efi.nix so the
  # two firmware halves cannot drift apart. See #89, #92, #94b.
  imports = [ ./grub-patched.nix ];

  boot.loader.timeout = 3;
  boot.loader.grub = {
    enable = true;
    efiSupport = false;
    device = lib.mkDefault "/dev/sda";
    configurationLimit = 15;

    # THE GOLEM LOOK ON BIOS (#68 — Max, on the hp's stock menu: "grub
    # looks like shit… all golem should look the same").
    #
    # Text mode was tried and is WORSE (photographed on the hp): GRUB's
    # text menu draws its own "GNU GRUB version 2.12" header and a
    # full-screen frame, and it leaves GRUB's core chatter ("GRUB
    # loading. Welcome to GRUB!") on the screen because nothing ever
    # clears it. A GRAPHICAL theme fixes all three at once — gfxterm
    # clears the display and paints only the theme.
    #
    # So: the medium's own theme (grub-theme.nix — black field, #cccccc
    # items, #eeeeee selection bar, DejaVu), sized like a systemd-boot
    # list rather than the first attempt's half-screen slab: a narrow
    # centred box, one modest highlight bar per row.
    # Width HUGS the widest label in the whole tree. After #95's
    # rewording that is a recovery row, "Gen 15 - 2026-09-15" = 210px in
    # DejaVu Sans 20 (measured), + a space either side = a 222px bar in
    # a 226px box, centred at 50%-113. The top level ("Golem" 67px,
    # "Recover" 82px) rides the same bar — one width for every row is
    # GRUB's rule as much as syslinux's. Lockstep with grub-efi.nix.
    theme = pkgs.callPackage ./grub-theme.nix {
      menuWidth = 226;
      menuHeight = 120;
      menuLeft = "50%-113";
      menuTop = "50%-60";
      itemHeight = 24;
    };
    # NixOS ships a default splash (the blue NixOS wallpaper) and draws
    # it even with a theme set — that is the "grub nixos background"
    # still behind the menu. Kill it; the theme owns the screen.
    splashImage = null;
    extraConfig = ''
      set timeout_style=menu
    '';

    # #93 — the kernel's real-mode stub prints "No EFI environment
    # detected." on every BIOS boot, straight into VGA text memory —
    # before printk exists, so quiet/loglevel can't touch it. NixOS
    # hands over in TEXT mode on BIOS (gfxpayload=text), which is what
    # makes the write visible (and what causes the menu→boot mode-switch
    # flash). Hand over in graphics like the EFI path always has: the
    # menu's framebuffer survives into KMS, the stub's text lands in
    # invisible memory, the flash is gone. Tradeoff, accepted: a stub-
    # LEVEL panic (rare: corrupt image, decompression failure) is a
    # silent black hang instead of a printed error — the record knows.
    gfxpayloadBios = "keep";
  };
}
