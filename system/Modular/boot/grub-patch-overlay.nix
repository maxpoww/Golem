# boot/grub-patch-overlay — the Golem grub patches as ONE overlay, shared by
# the installed bootloader leaves (grub-patched.nix) and the ISO medium
# (Installer/preinstall/iso.nix).
#
# #92's lockstep worry, one layer down: the medium's UEFI grub and the
# machine's grub must carry the SAME patches or they drift — and they did.
# Until this recut the medium pulled stock `pkgs.grub2_efi`, so it showed the
# old left-aligned, banner-flashing menu while every INSTALLED machine was
# already silent and centred (#89/#95, "the ISO side owed at the recut"). One
# overlay, imported in both places, is how the two cannot drift again.
#
# The patches, in the order they were earned on metal:
#  - grub-quiet.patch (#89): no banner, no blinking cursor — silence from the
#    first instruction we own to the themed menu.
#  - grub-item-align.patch (#95): an item_align property upstream gfxmenu has
#    no equivalent for; without it the theme cannot centre a label inside its
#    own selection bar.
#
# ⚠ Patch ONLY `grub2`, never `grub2_efi` as well. `grub2_efi` is defined as
# `grub2.override { efiSupport = true; }` against the FINAL fixpoint, so it
# already inherits this patched `grub2` — the ISO's `pkgs.grub2_efi` is
# patched through it automatically. Overriding `grub2_efi` on TOP of that
# applies the patch list a second time and the build dies with "Reversed (or
# previously applied) patch detected!" (learned the hard way at this recut).
# The i386-pc/BIOS hunks simply aren't built into the EFI target; the
# banner/cursor/item_align hunks are (#92).
#
# Cost, stated plainly: a patched grub is not in cache.nixos.org, so it
# compiles once per store (see Installer/installing/changes.md #89).
final: prev:
{
  grub2 = prev.grub2.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./grub-quiet.patch
      ./grub-item-align.patch
    ];
  });
}
