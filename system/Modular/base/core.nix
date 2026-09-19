# base/core — every Golem machine's identity and plumbing, stage 0.
# Lifted verbatim from system/configuration.nix (2026-09-10); the WHY
# comments travel with their lines. No facts read here — this is what
# is true of EVERY Golem, or it doesn't belong in this file.
{ config, pkgs, lib, ... }:

{
  # mkDefault so the installer's machine.nix can name the machine
  # without a conflicting-definition death (the GECOS lesson).
  networking.hostName = lib.mkDefault "Golem";
  system.nixos.distroName = "Golem";
  system.stateVersion = "26.05";

  # Golem ships unfree and does not ask (webapp engine, firmware,
  # nvidia): an install-time "unfree?" question whose "no" breaks the
  # app set is not a question.
  nixpkgs.config.allowUnfree = true;

  # A system monitor on EVERY Golem, minimal included (Max, 2026-09-18).
  environment.systemPackages = [ pkgs.btop ];

  # /bin/sh and /usr/bin/env on FRESH roots — nixos-init makes the
  # classic activation a no-op, and greetd's worker execve's a
  # hardcoded /bin/sh. Belt-and-suspenders tmpfiles: harmless where the
  # links exist, load-bearing on every fresh root.
  systemd.tmpfiles.rules = [
    "L+ /bin/sh - - - - ${config.environment.binsh}"
    "L+ /usr/bin/env - - - - ${config.environment.usrbinenv}"
  ];

  # Force-importing ZFS pools at boot risks data loss; Golem ships no
  # ZFS root — this only protects a tester who plugs in pools.
  boot.zfs.forceImportRoot = false;

  # fq+BBR as distro policy (Max, 2026-09-04): BBR models the path
  # instead of backing off on every loss; fq provides the pacing BBR
  # expects. Hardware-independent — no fact, no gate.
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "kernel.printk" = "0 0 0 0";
  };

  # The quiet boot — Golem's console is silent until Golem speaks. But
  # QUIET, not BLANK: a stage-0 machine has no compositor, so fbcon IS
  # its only display. The two params that HIDE the framebuffer console —
  # `fbcon=map:1` (maps the console to framebuffer 1) and `splash` — are
  # desktop-boot cosmetics: on the fat path greetd→Hyprland takes the
  # screen through KMS and fbcon never matters, so a mapped-away console
  # was invisible-and-harmless. On minimal it is invisible-and-FATAL:
  # the acer (first metal, #65) has only fb0, `fbcon=map:1` pointed the
  # tty at a fb1 that does not exist, and the installed system booted
  # perfectly to a DEAD SCREEN — getty active, SSH fine, nothing drawn.
  # So base keeps the log-QUIETING (harmless, still a visible console)
  # and drops the two display-TAKEOVER params; the desktop stage re-adds
  # its own clean-boot handoff (and should reconsider whether fbcon=map
  # is even the right mechanism on a single-framebuffer machine).
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
  boot.initrd.systemd.enable = true;
  boot.kernelParams = [
    "quiet"
    "loglevel=0"
    "rd.systemd.show_status=false"
    "rd.systemd.log_level=0"
    "systemd.show_status=false"
    "systemd.log_level=0"
    "rd.udev.log_level=0"
    "udev.log_level=0"
    "vt.global_cursor_default=0"
    "vt.default_red=0"
    "vt.default_green=0"
    "vt.default_blue=0"
  ];

  # Read every disk a stranger might plug in.
  boot.supportedFilesystems = {
    ntfs = true;
    exfat = true;
    vfat = true;
    btrfs = true;
    xfs = true;
    f2fs = true;
  };

  # (The stale-boot-pin cleanup moved to boot/systemd-boot.nix — it is
  # bootctl, i.e. UEFI-only, and running it on a BIOS machine printed
  # "Not booted with UEFI." onto Golem's silent boot every time. #68.)

  # Run-anything conveniences — tiny, and part of "feels like Golem".
  programs.nix-ld.enable = true;
  services.envfs.enable = true;

  # Firmware for foreign hardware, and keep it current via LVFS.
  hardware.enableAllFirmware = true;
  services.fwupd.enable = lib.mkDefault true;
}
