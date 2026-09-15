# boot/grub-patched — THE Golem grub, shared by both bootloader leaves:
# the patched package AND the menu's wording.
#
# grub-bios.nix and grub-efi.nix must ship the SAME grub (#92: one look
# on every firmware), and each carrying its own copy of this overlay is
# how they would quietly drift. Both import this instead.
#
# The patches, in the order they were earned on metal:
#  - grub-quiet.patch (#89): no banner, no blinking cursor — silence
#    from the first instruction we own to the themed menu.
#  - grub-item-align.patch (#94b): an item_align property the upstream
#    gfxmenu has no equivalent for; without it the theme cannot centre a
#    label inside its own selection bar.
#
# Cost, stated plainly: a patched grub is not in cache.nixos.org, so it
# compiles once per store. Deliver the closure from the dev box (see
# Installer/installing/tools/deliver-live.sh) and the target's own
# rebuild finds it already built.
{ config, pkgs, ... }:

let
  distro = config.system.nixos.distroName;
in
{
  nixpkgs.overlays = [
    (final: prev: {
      grub2 = prev.grub2.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          ./grub-quiet.patch
          ./grub-item-align.patch
        ];
      });
    })
  ];

  # #95 — THE MENU'S WORDS. NixOS names the submenu
  # "<distro> - All configurations" and each entry "<distro> -
  # Configuration N (date - version)". Both are far wider than a menu
  # box that hugs its labels, so they clipped; and "configurations" is
  # not what someone reads in the moment they need one.
  #
  # Max settled on "Start Golem" / "Previous Versions" (2026-09-15),
  # after weighing snapshots / backups / recover / restore. The words
  # were chosen against two traps:
  #  - "snapshots"/"backups" promise DATA safety a generation does not
  #    give — the files are untouched, not backed up, and that is the
  #    worst thing to misread in the moment you need this menu.
  #  - "restore" promises PERMANENCE it does not give either: verified
  #    on the acer, the entries carry no `savedefault` and default is
  #    pinned to the newest generation, so picking one is a ONE-TIME
  #    boot. Next reboot returns to current. A noun phrase promises
  #    nothing; it just says what the list holds.
  # "Start" also lines the installed menu up with the medium's
  # Start/Install, so a stranger meets the same verb twice.
  #
  # Done by rewriting the generated grub.cfg because the titles are
  # baked into install-grub.pl with no option behind them; the
  # alternative is vendoring the whole grub module (as the ISO vendors
  # iso-image.nix) to change two strings. extraInstallCommands runs
  # right after the generator, every install, so this is idempotent by
  # construction — the patterns only exist before it has run.
  boot.loader.grub.extraInstallCommands = ''
    cfg=/boot/grub/grub.cfg
    if [ -f "$cfg" ]; then
      ${pkgs.gnused}/bin/sed -i \
        -e 's|^menuentry "${distro}"|menuentry "Start ${distro}"|' \
        -e 's|^submenu "${distro} - All configurations"|submenu "Previous Versions"|' \
        -e 's|^\( *\)menuentry "${distro} - Configuration \([0-9]\+\) (\([0-9-]\+\) - [^)]*)"|\1menuentry "Gen \2 - \3"|' \
        "$cfg"
    fi
  '';
}
