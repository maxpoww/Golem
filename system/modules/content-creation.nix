# modules/content-creation — Content Creation: record and stream, sound,
# editing, graphics and thumbnails, the channels' own sites.
#
# No plumbing. PROGRAM SETUP is OBS Studio's:
#   · its NVENC test finds the NVIDIA driver (an overlay on the package);
#   · its Virtual Camera gets a loopback camera of its own.
# Screen capture is the desktop's already (desktop/portals.nix: Hyprland's
# portal + PipeWire); NoiseTorch's capability is in remote-work.nix.
{ config, lib, ... }:

let
  m = import ./lib.nix { inherit lib; };
  inherit (m.scope config) has;
in
{
  imports = [
    (m.mkModule {
      id = "content-creation";
      description = "Content Creation: record and stream, sound, editing, graphics and thumbnails, the channels' own sites.";
    })
  ];

  config = {
    # ── OBS Studio: NVENC ──────────────────────────────────────────────────
    # OBS decides whether NVENC exists by running its own helper,
    # obs-nvenc-test, which dlopens libnvidia-encode.so.1. nixpkgs gives the
    # driver's library directory to OBS's plugins (addDriverRunpath) but not to
    # that helper, so on every NixOS machine with the NVIDIA driver the test
    # fails ("Cannot load libnvidia-encode.so.1"), OBS logs "NVENC not
    # supported" and encodes on the CPU (the dev box, 2026-10-28: an RTX 4050
    # idle while x264 took 2.2 cores). The wrapper hands the running `obs`
    # (and so the helper it spawns) the driver directory, at the END of its
    # library path: OBS's own libraries still come first. No rebuild of OBS —
    # the package is joined, only bin/obs is replaced. Its name stays
    # obs-studio-<version>: the fit and this file look packages up by name.
    # Harmless without NVIDIA (Mesa's libraries live in the same directory),
    # and unconditional: an overlay costs nothing until the package is asked
    # for, and the package must be the same whoever asks (a module's switch,
    # a drag into the grid).
    nixpkgs.overlays = [
      (final: prev: {
        obs-studio = prev.symlinkJoin {
          name = "obs-studio-${prev.obs-studio.version}";
          paths = [ prev.obs-studio ];
          nativeBuildInputs = [ prev.makeWrapper ];
          postBuild = ''
            rm "$out/bin/obs"
            makeWrapper "${prev.obs-studio}/bin/obs" "$out/bin/obs" \
              --suffix LD_LIBRARY_PATH : /run/opengl-driver/lib
          '';
          inherit (prev.obs-studio) version meta passthru;
        };
      })
    ];

    # ── OBS Studio: the Virtual Camera ─────────────────────────────────────
    # "Start Virtual Camera" needs a v4l2loopback device. Standard's desktop has
    # the module loaded for the phone's camera (desktop/phone.nix,
    # /dev/video10), and OBS takes the FIRST loopback device it finds: without
    # one of its own it would feed the phone's ("Android WebCam" in every
    # meeting, and the phone's camera then finds its device busy). So OBS gets
    # its own, at a lower number so it is the one OBS finds: /dev/video9.
    # NOT programs.obs-studio.enableVirtualCamera: that adds a second line of
    # options for the same kernel module (desktop/phone.nix writes the one
    # line, for both). The module reads its options when it loads: the new
    # device is there from the next start of the computer.
    standard.loopbackCameras = lib.optional (has "obs-studio") { nr = 9; label = "OBS Virtual Camera"; };
  };
}
