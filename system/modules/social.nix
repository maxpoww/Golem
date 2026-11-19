# modules/social — Social: messengers and social networks (Signal, Telegram,
# Discord, Element… and the sites as web apps).
#
# Nothing beyond the programs: a messenger is its package. Calls and screen
# sharing ride what the desktop already has (PipeWire, the portals:
# desktop/audio.nix, desktop/portals.nix).
{ lib, ... }:

let
  m = import ./lib.nix { inherit lib; };
in
{
  imports = [
    (m.mkModule {
      id = "social";
      description = "Social: messengers and social networks (Signal, Telegram, Discord, Element… and the sites as web apps).";
    })
  ];
}
