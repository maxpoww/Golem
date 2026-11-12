# base/network — NetworkManager + the firewall, stage 0.
# App-specific port openings (KDE Connect 1714-1764, LocalSend 53317)
# do NOT live here — they ride the desktop leaf that ships their apps.
# A port without its program is an honest firewall's lie.
{ lib, ... }:

{
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  # A private Wi-Fi address (the privacy study, 2026-11-12): each network sees
  # its own address for this machine, the same one every time it comes back —
  # so captive portals and the router still know it, but no two networks can
  # tell they met the same laptop. (Scans already use random addresses.) The
  # lab door keeps the real one: the lab finds its machines by it.
  networking.networkmanager.wifi.macAddress = lib.mkDefault "stable";
}
