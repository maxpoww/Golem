# modules/science-data — Science & Data: notebooks, statistics, math, plots,
# maps, data, lab tools, references.
#
# Nothing beyond the programs. JupyterLab runs as the owner on localhost: no
# service, no port.
{ lib, ... }:

let
  m = import ./lib.nix { inherit lib; };
in
{
  imports = [
    (m.mkModule {
      id = "science-data";
      description = "Science & Data: notebooks, statistics, math, plots, maps, data, lab tools, references.";
    })
  ];
}
