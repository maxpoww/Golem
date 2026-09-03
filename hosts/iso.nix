# Golem live ISO — the S7 flake on a USB stick (roadmap S9, todo9 item 1).
#
#   nix build .#iso   →   result/iso/golem.iso
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

  # 1. Wi-fi. There is NOTHING to force here — and forcing it broke wifi on
  #    real hardware (2026-09-02, Acer + QCA9377). The original comment here
  #    claimed installation-device ships a standalone wpa_supplicant that
  #    collides with NetworkManager; that is false — installation-device
  #    enables NetworkManager, not standalone wireless, and nothing in the ISO
  #    base sets `networking.wireless.enable`. Worse, NetworkManager's own
  #    module (networkmanager.nix) sets `networking.wireless.enable = true`
  #    with `dbusControlled = true` — that IS how NM gets its wpa_supplicant
  #    backend. A `mkForce false` here overrode that, so `wpa_supplicant.service`
  #    never existed, and NM reported every wifi (and ethernet) device
  #    `unavailable`: a stranger could not get online, which is the S9 exit
  #    criterion. Let NM manage the supplicant. Do not re-add the override.

  # 2. Bootloader. The ISO boots from its own grub/systemd-boot image built
  #    by iso-image.nix; a live system must never try to *install* one.
  #    Same trap hosts/vm.nix documents: grub's `enable` defaults to
  #    "whatever systemd-boot isn't", so both get forced off by name rather
  #    than trusted to a default.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  #    The live medium sets its own menu timeout (iso-image.nix wants 10);
  #    configuration.nix's 3 is for an installed machine and would collide at
  #    the same priority, so it yields here like the three above.
  boot.loader.timeout = lib.mkForce 10;

  # 3. Garbage collection. Golem core runs a daily gc; the live store is a
  #    read-only squashfs under a tmpfs overlay, where deleting a path from
  #    the lower layer cannot work. Nothing to reclaim, only a failing timer.
  nix.gc.automatic = lib.mkForce false;

  # ── The live session ──────────────────────────────────────────────────

  # greetd (Golem core) autologins the owner (golem.owner, default `max`)
  # into Hyprland — on the ISO that is the *live* user, not a person. The
  # name is ONE option now (release-checklist §2.2): the installer's rename
  # job is setting golem.owner, together with seeding the flake checkout —
  # todo9 item 3, NOT this file.
  #
  # No password: a live medium that asks for one it never showed you is a
  # dead end, and installation-device already gives wheel passwordless sudo.
  users.users.${config.golem.owner}.initialHashedPassword = "";

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

  # ── Lean ──────────────────────────────────────────────────────────────

  # Only what the system needs to work (Max, 2026-09-01: "as debloated as
  # possible"). The full image was 6.33 GiB because the home layer carried
  # the owner's launcher-installed list (android-studio 3.3 GiB, obs' cef
  # 2.0 GiB, three browsers) and a dev toolchain. golem.lean drops those and
  # the non-core CURATE apps; what remains is the shell, foot, the webapp
  # engine, Nautilus/text-editor/Loupe/Papers, the stopgap kit and firmware.
  golem.lean = true;

  # ── The image ─────────────────────────────────────────────────────────

  # Name the artifact after the distro, not after nixos. `image.baseName` is
  # the 25.05 name of `isoImage.isoBaseName` (volumeID was never renamed and
  # keeps its prefix); iso-image.nix bakes edition+label+arch into its own
  # default, so forcing the whole basename means the file is plain golem.iso.
  # Volume IDs are ISO9660: 11 characters, no lowercase.
  image.baseName = lib.mkForce "golem";
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
