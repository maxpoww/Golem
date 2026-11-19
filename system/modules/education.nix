# modules/education — Education: study, math and science, geography,
# languages, reading, online classes.
#
# Nothing beyond the programs.
{ lib, ... }:

let
  m = import ./lib.nix { inherit lib; };
in
{
  imports = [
    (m.mkModule {
      id = "education";
      description = "Education: study, math and science, geography, languages, reading, online classes.";
    })
  ];
}
