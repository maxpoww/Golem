# modules/privacy-security — Privacy & Security: passwords, VPN, private
# browsing, encryption, two-factor codes, the network's watch, backups,
# scanning.
#
# No plumbing. PROGRAM SETUP, keyed on the installed program: a VPN's app, a
# firewall's window and a password manager's browser link are front ends —
# each needs the service or the helper behind it.
# Nothing is needed for: Cryptomator and VeraCrypt (FUSE's fusermount3 is a
# NixOS default — programs.fuse; VeraCrypt mounts through sudo, which asks for
# the owner's password), Tor Browser and Mullvad Browser, KeePassXC,
# Bitwarden, the backup tools.
{ config, lib, pkgs, ... }:

let
  m = import ./lib.nix { inherit lib; };
  inherit (m.scope config) owner has any;
in
{
  imports = [
    (m.mkModule {
      id = "privacy-security";
      description = "Privacy & Security: passwords, VPN, private browsing, encryption, two-factor codes, the network's watch, backups, scanning.";
    })
  ];

  config = {
    # ── VPN ────────────────────────────────────────────────────────────────
    # A VPN's app talks to its daemon; without the daemon it connects to
    # nothing.
    services.mullvad-vpn.enable = lib.mkIf (any [ "mullvad-vpn" "mullvad" ]) true;
    services.tailscale.enable = lib.mkIf (has "tailscale") true;
    # Proton VPN drives NetworkManager's own WireGuard: no daemon. But a
    # tunnel that carries ALL traffic answers from another interface than the
    # one a packet's route says, and the firewall's strict reverse-path check
    # drops those answers (the NixOS manual's WireGuard note; Mullvad's and
    # Tailscale's modules loosen it the same way). mkDefault: a machine's own
    # choice wins.
    networking.firewall.checkReversePath = lib.mkIf (has "proton-vpn") (lib.mkDefault "loose");

    # ── The network's watch ────────────────────────────────────────────────
    # The application firewall's window is a front end to its daemon.
    services.opensnitch.enable = lib.mkIf (has "opensnitch-ui") true;

    # ── Passwords ──────────────────────────────────────────────────────────
    # 1Password unlocks with the system's own authentication and talks to
    # the browser through a helper that must belong to its group: the NixOS
    # module makes both (a polkit policy naming who may use it, the setgid
    # wrapper). The owner, nobody else.
    programs._1password-gui = lib.mkIf (has "1password") {
      enable = true;
      polkitPolicyOwners = [ owner ];
    };

    # ── Encryption ─────────────────────────────────────────────────────────
    # Kleopatra is a window on GnuPG: it needs the agent, and the agent needs
    # a way to ASK for a passphrase. NixOS's default asks on a terminal
    # (curses), which a window never has: Qt's dialog, Kleopatra's own kind.
    programs.gnupg.agent = lib.mkIf (has "kleopatra") {
      enable = true;
      pinentryPackage = lib.mkDefault pkgs.pinentry-qt;
    };

    # ── Scanning ───────────────────────────────────────────────────────────
    # ClamTk scans with ClamAV's signatures: with none it refuses to scan.
    # The updater keeps them (freshclam); no scanning daemon is started.
    services.clamav.updater.enable = lib.mkIf (has "clamtk") true;
  };
}
