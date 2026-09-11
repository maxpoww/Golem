# base/network — NetworkManager + the firewall, stage 0.
# App-specific port openings (KDE Connect 1714-1764, LocalSend 53317)
# do NOT live here — they ride the desktop leaf that ships their apps.
# A port without its program is an honest firewall's lie.
{ lib, ... }:

{
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
}
