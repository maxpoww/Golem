# Golem live ISO — the S7 flake on a USB stick (roadmap S9, todo9 item 1).
#
#   nix build .#iso   →   result/iso/golem-<label>-x86_64-linux.iso
#
# The live session IS Golem, not a themed installer shell: same
# system/configuration.nix, same home layer, same compositor, dock and
# OPTIONS an installed machine gets. Everything below is only the seam
# between that config and nixpkgs' installation-cd profile — every setting
# here exists because the two disagree about something, or because the
# medium is read-only.
#
# What this module deliberately is NOT: an installer. Which surface does the
# guided install (calamares vs ours) is todo9 item 2, and the disk flow is
# item 3. Until then the live session boots into Golem and `nixos-install`
# from the base profile is the (terminal) way out — the Arc-1 exit needs
# item 2, not this file.
{ config, lib, pkgs, golemSrc, modulesPath, ... }:

{
  # installation-cd-base pulls in three profiles: iso-image (the squashfs +
  # bootable image), base (a usable rescue toolbox) and installation-device
  # (autologin getty, passwordless wheel, nixos user, all-hardware firmware).
  # The graphical variant is deliberately NOT used — its display-manager
  # session would compete with greetd for tty1.
  imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-base.nix") ];

  # ── The collisions ────────────────────────────────────────────────────

  # 1. Wi-fi. installation-device turns on wpa_supplicant (the minimal ISO
  #    has no NetworkManager); Golem core turns on NetworkManager. Both at
  #    once is not just two daemons on one interface — networkmanager.nix
  #    asserts on it unless every interface is listed unmanaged. Golem's
  #    answer to "get online on a strange machine" is NetworkManager (the
  #    stopgap nm-connection-editor is already in systemPackages), so
  #    wpa_supplicant is the one that goes.
  networking.wireless.enable = lib.mkForce false;

  # 2. Bootloader. The ISO boots from its own grub/systemd-boot image built
  #    by iso-image.nix; a live system must never try to *install* one.
  #    Same trap hosts/vm.nix documents: grub's `enable` defaults to
  #    "whatever systemd-boot isn't", so both get forced off by name rather
  #    than trusted to a default.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

  # 3. Garbage collection. Golem core runs a daily gc; the live store is a
  #    read-only squashfs under a tmpfs overlay, where deleting a path from
  #    the lower layer cannot work. Nothing to reclaim, only a failing timer.
  nix.gc.automatic = lib.mkForce false;

  # ── The live session ──────────────────────────────────────────────────

  # greetd (Golem core) autologins `max` into Hyprland — on the ISO that is
  # the *live* user, not a person: the whole tree hardcodes the name in four
  # places, one with teeth (system/waverunner-apply.nix:31 watches
  # /home/max/…, so on any other account installing an app does nothing).
  # Renaming the user is the installer's job, together with seeding the
  # flake checkout — todo9 item 3, NOT this file.
  #
  # No password: a live medium that asks for one it never showed you is a
  # dead end, and installation-device already gives wheel passwordless sudo.
  users.users.max.initialHashedPassword = "";

  # No flake checkout on the live medium (golem.flakeDir stays null), so
  # waverunner-apply and rebuild-golem are absent by design: a nixos-rebuild
  # into a tmpfs overlay would fill RAM and vanish on reboot. The visible
  # consequence, and it is the right one to know before a demo: dragging an
  # app into the Install section in the LIVE session does nothing. Installed
  # Golem gets the checkout (hosts/vm.nix:21 is the shape).

  # The source the installer will instantiate, carried on the medium itself
  # (/etc/golem/src → a store path in the ISO's own store). Item 3 will
  # point `nixos-install --flake` at this instead of at the network.
  # Caveat for whoever writes that: having the *source* on the ISO is not
  # yet an offline install — evaluating it still wants the flake inputs
  # (nixpkgs, waverunner, waveview) fetched, so the installer either
  # prefetches them into the image or installs a prebuilt toplevel.
  environment.etc."golem/src".source = golemSrc;

  # ── The image ─────────────────────────────────────────────────────────

  # Name the artifact after the distro, not after nixos. Volume IDs are
  # ISO9660: 11 characters, no lowercase.
  isoImage.isoBaseName = lib.mkForce "golem";
  isoImage.volumeID = lib.mkForce "GOLEM_ISO";
  # (Full branding — os-release, the boot menu title, system.nixos.distroName
  # — is S10's, and it belongs to the installed system too, not just here.)

  # ── If it does not boot ───────────────────────────────────────────────
  #
  # First suspect: Golem core runs a systemd initrd
  # (system/configuration.nix:54) while nixpkgs' own installer ISOs still
  # boot the scripted one, so the overlay-store mounts in iso-image.nix are
  # the least-travelled path in this whole config. Parity with the installed
  # system is why it is left alone here; if stage 1 hangs or drops to an
  # emergency shell, prove it by adding
  #
  #     boot.initrd.systemd.enable = lib.mkForce false;
  #
  # Second suspect: a black screen with no message is the *expected* look of
  # a failed session — Golem core boots quiet (loglevel=0, kernel.printk all
  # zeroes, fbcon=map:1). tty2 still has a getty from installation-device;
  # Ctrl+Alt+F2 is the way in.
}
