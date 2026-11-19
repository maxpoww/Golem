# modules/commerce — Commerce: shops, payments, accounting, product images,
# labels.
#
# Nothing beyond the programs: most of it is web apps.
{ lib, ... }:

let
  m = import ./lib.nix { inherit lib; };
in
{
  imports = [
    (m.mkModule {
      id = "commerce";
      description = "Commerce: shops, payments, accounting, product images, labels.";
    })
  ];
}
