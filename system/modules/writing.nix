# modules/writing — Writing: writing tools, grammar, research, typesetting,
# e-books.
#
# Nothing beyond the programs. An e-reader plugged in for Calibre is a USB
# disk: udisks (desktop/session.nix) already mounts it.
{ lib, ... }:

let
  m = import ./lib.nix { inherit lib; };
in
{
  imports = [
    (m.mkModule {
      id = "writing";
      description = "Writing: writing tools, grammar, research, typesetting, e-books.";
    })
  ];
}
