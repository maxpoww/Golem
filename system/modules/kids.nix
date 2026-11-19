# modules/kids — Kids: learn and play, games, creating, parental controls.
#
# No plumbing. PROGRAM SETUP: parental controls are not programs a child's
# account could simply close — each is a system service.
#   · Timekpr-nExT: its daemon counts the time and ends the session. Nobody
#     is put in its admin group: changing a limit asks for the
#     administrator's password.
#   · Parental Controls (malcontent): the accounts service's extension that
#     the app filters and age ratings are kept in.
{ config, lib, ... }:

let
  m = import ./lib.nix { inherit lib; };
  inherit (m.scope config) has;
in
{
  imports = [
    (m.mkModule {
      id = "kids";
      description = "Kids: learn and play, games, creating, parental controls.";
    })
  ];

  config = {
    services.timekpr.enable = lib.mkIf (has "timekpr") true;
    services.malcontent.enable = lib.mkIf (has "malcontent") true;
  };
}
