# modules/productivity — Productivity: notes, tasks, mail and calendar,
# planning, time.
#
# Nothing beyond the programs. Syncthing's ports are the Internet module's
# (internet.nix): a program has its setup in one file, whichever module
# switched it on.
{ lib, ... }:

let
  m = import ./lib.nix { inherit lib; };
in
{
  imports = [
    (m.mkModule {
      id = "productivity";
      description = "Productivity: notes, tasks, mail and calendar, planning, time.";
    })
  ];
}
