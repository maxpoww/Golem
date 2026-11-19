# modules/remote-work — Remote Work: meetings, team chat, remote desktop,
# sound and camera, the office suites online.
#
# No plumbing: meetings ride what the desktop has (PipeWire for sound and the
# camera, the portals for sharing a screen). PROGRAM SETUP:
#   · Zoom is built with Hyprland's screen-sharing portal inside its sandbox;
#   · TeamViewer's daemon; NoiseTorch's capability.
# AnyDesk and RustDesk, as the side that CONNECTS, are only their programs.
{ config, lib, ... }:

let
  m = import ./lib.nix { inherit lib; };
  inherit (m.scope config) has any;
in
{
  imports = [
    (m.mkModule {
      id = "remote-work";
      description = "Remote Work: meetings, team chat, remote desktop, sound and camera, the office suites online.";
    })
  ];

  config = {
    # Zoom runs in a sandbox of its own (an FHS environment) and shares the
    # screen through the desktop portal it finds INSIDE it; nixpkgs builds
    # none in unless told which desktop this is (its programs.zoom-us module
    # does exactly this, by overriding the package). An overlay and not that
    # module: the module installs a second Zoom beside the owner's, and the
    # owner's own comes first on the path. Unconditional, as OBS's: it costs
    # nothing until Zoom is asked for.
    nixpkgs.overlays = [
      (final: prev: {
        zoom-us = prev.zoom-us.override { hyprlandXdgDesktopPortalSupport = true; };
      })
    ];

    # TeamViewer's window is a front end to its daemon: without it, it never
    # connects.
    services.teamviewer.enable = lib.mkIf (has "teamviewer") true;

    # NoiseTorch makes its virtual microphone with a capability its wrapper
    # carries; the bare program cannot.
    programs.noisetorch.enable = lib.mkIf (any [ "noisetorch" "NoiseTorch" ]) true;
  };
}
