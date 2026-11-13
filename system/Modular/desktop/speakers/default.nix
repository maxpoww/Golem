# desktop/speakers — a laptop's built-in speakers, per model.
#
#   • tunings.nix: per-model filter graphs, loaded by WirePlumber into the
#     speaker node itself (see that file for the rules). Matched at runtime on
#     the sound card, so every Golem carries the data and only the matching
#     machine uses it; the graphs are builtin PipeWire filters, nothing is
#     added to the closure.
#   • tas2781.nix: TAS2781 amps reload their program at every sound start, so
#     the card can sleep without the speakers coming back thin and harsh.
#   • jack-profile.lua: with a screen on HDMI, the speakers stay in the output
#     list (WirePlumber otherwise picks the headphone profile with nothing in
#     the jack).
{ lib, ... }:

let
  tunings = import ./tunings.nix;
in
{
  imports = [ ./tas2781.nix ];

  # The same list for the shell: the dock's Equalizer draws an output's factory
  # tuning under the owner's curve (`eq.rs::factory_for`, matched by the card's
  # components and the speaker node).
  environment.etc."golem/speaker-tunings.json".text = builtins.toJSON (map (t: {
    inherit (t) name components graph;
    node = "HiFi__Speaker__sink";
  }) (lib.filter (t: t ? graph) tunings));

  services.pipewire.wireplumber.extraScripts."golem/jack-profile.lua" =
    builtins.readFile ./jack-profile.lua;

  services.pipewire.wireplumber.extraConfig = {
    "60-golem-jack-profile" = {
      "wireplumber.components" = [{
        name = "golem/jack-profile.lua";
        type = "script/lua";
        provides = "golem.jack-profile";
      }];
      # "required": WirePlumber 0.5 does not load an "optional" component that
      # nothing else wants (measured: the hook never registered, 2026-11-11).
      # A load error would stop WirePlumber, so the script stays plain Lua
      # with no dependency beyond common-utils (tests: jack-profile hooks
      # registered in an isolated WirePlumber 0.5.14).
      "wireplumber.profiles".main."golem.jack-profile" = "required";
    };

    "60-golem-speaker-tunings" = {
      "node.filter-graph.rules" = map (t: {
        matches = [{
          "node.name" = "~alsa_output.*HiFi__Speaker__sink";
          "alsa.components" = "~.*${t.components}.*";
        }];
        actions.create-filter-graph = [ (builtins.toJSON t.graph) ];
      }) (lib.filter (t: t ? graph) tunings);
    };
  };
}
