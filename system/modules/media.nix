# modules/media — Media & Entertainment: players, music, streaming sites,
# media centres, podcasts.
#
# Nothing beyond the programs. The codecs come with the players (VLC, mpv);
# the streaming sites are web apps in Seam, which carries Widevine. Kodi,
# Jellyfin and Plex here are the DESKTOP players: a server on this computer
# is another matter and not offered.
{ lib, ... }:

let
  m = import ./lib.nix { inherit lib; };
in
{
  imports = [
    (m.mkModule {
      id = "media";
      description = "Media & Entertainment: players, music, streaming sites, media centres, podcasts.";
    })
  ];
}
