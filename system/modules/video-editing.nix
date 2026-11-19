# modules/video-editing — Video Editing: editors, effects and motion,
# converters, subtitles, recording.
#
# Nothing beyond the programs. OBS Studio's system side (its NVENC wrapper,
# the virtual camera) is the Content Creation module's (content-
# creation.nix): one file per program. DaVinci Resolve needs a graphics card
# with OpenCL or CUDA; the hardware leaves (gpu/*) bring the drivers,
# nothing is added here.
{ lib, ... }:

let
  m = import ./lib.nix { inherit lib; };
in
{
  imports = [
    (m.mkModule {
      id = "video-editing";
      description = "Video Editing: editors, effects and motion, converters, subtitles, recording.";
    })
  ];
}
