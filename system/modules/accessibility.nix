# modules/accessibility — Accessibility: hearing the screen, seeing, typing
# and pointing, reading.
#
# No plumbing. PROGRAM SETUP: the screen reader needs the accessibility bus
# and a speech service. The magnifier, the on-screen keyboard and the
# high-contrast themes are only their programs.
{ config, lib, ... }:

let
  m = import ./lib.nix { inherit lib; };
  inherit (m.scope config) has any;
in
{
  imports = [
    (m.mkModule {
      id = "accessibility";
      description = "Accessibility: hearing the screen, seeing, typing and pointing, reading.";
    })
  ];

  config = {
    services.orca.enable = lib.mkIf (has "orca") true;
    services.speechd.enable = lib.mkIf (any [ "orca" "speechd" "speech-dispatcher" ]) true;
  };
}
