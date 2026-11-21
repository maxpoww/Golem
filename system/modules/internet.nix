# modules/internet — Internet: browsers, downloads and torrents, phone and
# devices, cloud storage, file transfer.
#
# No plumbing. PROGRAM SETUP: sharing on the local network only works when
# the others can reach this computer — each program's own port, opened only
# while that program is installed. (Dropbox's LAN sync port is left shut: it
# is a speed-up between two computers of the same account, not something
# Dropbox needs to work.)
{ config, lib, ... }:

let
  m = import ./lib.nix { inherit lib; };
  inherit (m.scope config) has;
in
{
  imports = [
    (m.mkModule {
      id = "internet";
      description = "Internet: browsers, downloads and torrents, phone and devices, cloud storage, file transfer.";
    })
  ];

  config = {
    # KDE Connect (the phone link) finds the phone and talks to it on
    # 1714–1764 — opened only by the old profile until 2026-10-13
    # (system/configuration.nix): an installed Standard with it blocked the
    # phone. The ports alone, not programs.kdeconnect: that module installs a
    # second KDE Connect beside the owner's.
    networking.firewall.allowedTCPPortRanges =
      lib.optional (has "kdeconnect-kde") { from = 1714; to = 1764; };
    networking.firewall.allowedUDPPortRanges =
      lib.optional (has "kdeconnect-kde") { from = 1714; to = 1764; };
    # LocalSend's one port (programs.localsend opens the same and, again,
    # installs a second copy); Syncthing's sync port and local discovery.
    networking.firewall.allowedTCPPorts =
      lib.optional (has "localsend") 53317
      ++ lib.optional (has "syncthing") 22000;
    networking.firewall.allowedUDPPorts =
      lib.optional (has "localsend") 53317
      ++ lib.optionals (has "syncthing") [ 22000 21027 ];
  };
}
