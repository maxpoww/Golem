# modules/music-production — Music Production: studios (DAWs), rhythm and
# live tools, instruments, effects, the tools around them.
# (GolemModules.md §4.9; the first module ever built, 2026-09-08.)
#
# PLUMBING (the module is on): LOW LATENCY. PipeWire's own default
# (1024/48000, ~21 ms) favours battery life; someone playing an instrument
# through a DAW feels every millisecond between the key and the sound. The
# clock below is the range JACK-era studios aimed at: 128 frames by default
# (~2.7 ms), down to 32 when a program asks, up to 2048 so a slower machine
# grows the buffer instead of crackling. If an instrument crackles, the
# maximum is the first number to raise.
#
# What is NOT here, because the desktop has it for everyone already
# (desktop/audio.nix): JACK programs run on PipeWire (services.pipewire.
# jack), and realtime priority for the audio threads comes from rtkit
# (security.rtkit). No realtime kernel: linuxPackages-rt left nixpkgs
# (2026-03-24), and PipeWire with rtkit is what delivers the priority today.
#
# No PROGRAM SETUP: a USB audio interface or a MIDI keyboard is class
# compliant and works the moment it is plugged in (ALSA + PipeWire);
# yabridge carries the Wine it was built with (nixpkgs hard-codes its path),
# so Windows plugins need no Wine installed beside it.
{ config, lib, ... }:

let
  m = import ./lib.nix { inherit lib; };
  inherit (m.scope config) on;
in
{
  imports = [
    (m.mkModule {
      id = "music-production";
      description = "Music Production: studios (DAWs), rhythm and live tools, instruments, effects, and low-latency sound.";
    })
  ];

  config = lib.mkIf (on "music-production") {
    services.pipewire.extraConfig.pipewire."92-golem-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 128;
        "default.clock.min-quantum" = 32;
        "default.clock.max-quantum" = 2048;
      };
    };
  };
}
