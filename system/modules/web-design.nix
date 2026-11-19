# modules/web-design — Web Design: editors, design tools, browsers to test
# in, build tools, publishing.
#
# Nothing beyond the programs. (Containers and nix-ld are the Development
# module's.)
{ lib, ... }:

let
  m = import ./lib.nix { inherit lib; };
in
{
  imports = [
    (m.mkModule {
      id = "web-design";
      description = "Web Design: editors, design tools, browsers to test in, build tools, publishing.";
    })
  ];
}
