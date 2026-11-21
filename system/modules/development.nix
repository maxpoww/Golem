# modules/development — Development: editors and IDEs, git, containers,
# databases, API tools, languages, game engines, terminals.
#
# No plumbing: a language or an editor is its package. PROGRAM SETUP, keyed on
# the installed program:
#   · Docker runs ROOTLESS, Podman serves Distrobox and Podman Desktop;
#   · nix-ld gives programs built for other Linux systems their loader;
#   · direnv is hooked into the shells (without the hook it does nothing);
#   · Android Studio's emulator needs /dev/kvm.
# `adb` needs nothing here: systemd gives the session the phone's USB device
# (its uaccess rules; NixOS removed programs.adb for that reason), and Standard's
# desktop already has the phone tools (desktop/phone.nix).
{ config, lib, ... }:

let
  m = import ./lib.nix { inherit lib; };
  inherit (m.scope config) owner has any;
in
{
  imports = [
    (m.mkModule {
      id = "development";
      description = "Development: editors and IDEs, git, containers, databases, API tools, languages, game engines, terminals.";
    })
  ];

  config = {
    # ── Containers ─────────────────────────────────────────────────────────
    # NO GROUP HERE IS ROOT (2026-11-12, the security study's road 1). The
    # owner's selection is written without a password, so anything it
    # switches on must give the owner nothing they did not have: the `docker`
    # group IS root (a container with / mounted). Any program running as the
    # owner could ask for "docker" and become root at the next install.
    #
    # Docker runs ROOTLESS instead: the daemon is the owner's own (a user
    # service), `docker` finds it through DOCKER_HOST, and `docker run` works
    # as before without any group.
    virtualisation.docker.rootless = lib.mkIf (has "docker") {
      enable = true;
      setSocketVariable = true;
    };
    # Distrobox and Podman Desktop need a container engine; Podman when there
    # is no Docker to use.
    virtualisation.podman.enable = lib.mkIf (any [ "podman-desktop" "distrobox" ] && !has "docker") true;

    # Programs built for other Linux systems (an editor's downloaded language
    # server, a vendor's binary) find their loader.
    programs.nix-ld.enable = lib.mkIf (has "nix-ld") true;

    # direnv's whole job is the shell hook (and nix-direnv, which the NixOS
    # module turns on with it): the bare program never runs by itself.
    programs.direnv.enable = lib.mkIf (has "direnv") true;

    # The Android emulator is a virtual machine. /dev/kvm is not root (it
    # runs machines, nothing else).
    users.users.${owner}.extraGroups = lib.optional (has "android-studio") "kvm";
  };
}
