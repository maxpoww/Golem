# base/users — the owner, stage 0. Data-driven from golem.owner (the
# installer's knob); groups here are the stage-0 set — the desktop leaf
# adds its own (adbusers, uinput) beside the subsystems that create
# them. GECOS mkDefault: the installer's machine.nix personalizes it
# (the "conflicting definition values: Max / Max Power" lesson).
{ config, pkgs, lib, ... }:

{
  users.users.${config.golem.owner} = {
    isNormalUser = true;
    # The password seed: a root-only file, never the system source (below).
    hashedPasswordFile = "/var/lib/golem/secrets/owner-password-hash";
    description = lib.mkDefault "Max";
    shell = pkgs.bashInteractive;
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "input"
    ];
  };

  # The dev/deploy loop: the owner rebuilds without a password. Build
  # always runs before switch; generations are the net.
  # THE OWNER'S PASSWORD NEVER ENTERS THE SYSTEM SOURCE (2026-10-01).
  # machine.nix used to carry `hashedPassword`, and everything in the flake is
  # copied into the world-readable Nix store: the hash sat in every
  # generation's users-groups.json and in every source copy (12 on the
  # ThinkPad), readable by any process — an offline-guessing target that
  # /etc/shadow exists to prevent. Accounts are mutable here (NixOS's default:
  # the declared hash is used only when the account is CREATED, /etc/shadow
  # is the truth after that), so the hash is only a seed for creation: it
  # lives in a root-only file the installer writes, outside the store
  # (`hashedPasswordFile` in the account above).
  # Keep that file equal to the account's real password, before the users
  # step reads it: an existing machine gets the file from /etc/shadow (no
  # hand migration), a later `passwd` is followed, and an account that ever
  # had to be created again would get the CURRENT password, not install day's.
  # A fresh install has no shadow entry yet: the installer's file stands.
  system.activationScripts.golemOwnerSecret = {
    text = ''
      f=/var/lib/golem/secrets/owner-password-hash
      h=$(${pkgs.gnugrep}/bin/grep "^${config.golem.owner}:" /etc/shadow 2>/dev/null | ${pkgs.coreutils}/bin/cut -d: -f2 || true)
      case "$h" in
        \$*)
          if [ ! -f "$f" ] || [ "$(${pkgs.coreutils}/bin/cat "$f")" != "$h" ]; then
            ${pkgs.coreutils}/bin/install -d -m 0700 /var/lib/golem /var/lib/golem/secrets
            ( umask 077; printf '%s\n' "$h" > "$f.tmp" && ${pkgs.coreutils}/bin/mv "$f.tmp" "$f" )
          fi ;;
      esac
    '';
  };
  # (Only the classic users script reads the file at activation; sysusers and
  # userborn define no such script to order against.)
  system.activationScripts.users = lib.mkIf
    (!config.systemd.sysusers.enable && !config.services.userborn.enable)
    { deps = [ "golemOwnerSecret" ]; };

  # A machine file that still declares the hash (written by an installer
  # before 2026-10-01) keeps working and says so; golem-autoupdate removes it.
  warnings = lib.optional (config.users.users.${config.golem.owner}.hashedPassword != null)
    "golem: the owner's password hash is declared in the system source (hosts/target/machine.nix) and is therefore world-readable in the Nix store; remove that line — the account keeps its password (see base/users.nix).";

  # No passwordless sudo on an install (GolemSecurity: "sudo requires a
  # password, no NOPASSWD anywhere in shipped config"). A NOPASSWD rule for
  # nixos-rebuild here was a root escalation for any program running as the
  # owner: `sudo nixos-rebuild switch --flake <its own flake>` (or
  # `nixos-rebuild edit`) — no password, and the seed's seal never asked.
  # Found by golem-deep on the MacBook, 2026-10-01. Unattended rebuilds run
  # as root services (waverunner-apply, golem-autoupdate, seam-update); the
  # owner's own rebuild-golem asks for the password, which is the consent
  # its golem-bless relies on. (The dev box keeps its own NOPASSWD dev loop
  # in system/configuration.nix.)
}
