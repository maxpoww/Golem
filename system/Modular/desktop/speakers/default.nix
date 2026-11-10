# desktop/speakers — a laptop's built-in speakers, per model.
#
#   • tunings.nix: per-model filter graphs, loaded by WirePlumber into the
#     speaker node itself (see that file for the rules), plus the models whose
#     amp must never be suspended. Matched at runtime on the sound card, so
#     every Golem carries the data and only the matching machine uses it; the
#     graphs are builtin PipeWire filters, nothing is added to the closure.
#   • jack-profile.lua: with a screen on HDMI, the speakers stay in the output
#     list (WirePlumber otherwise picks the headphone profile with nothing in
#     the jack).
{ lib, ... }:

let
  tunings = import ./tunings.nix;
  awake = lib.filter (t: t ? keepAwake) tunings;
in
{
  services.pipewire.wireplumber.extraScripts."golem/jack-profile.lua" =
    builtins.readFile ./jack-profile.lua;

  services.pipewire.wireplumber.extraConfig = {
    "60-golem-jack-profile" = {
      "wireplumber.components" = [{
        name = "golem/jack-profile.lua";
        type = "script/lua";
        provides = "golem.jack-profile";
      }];
      # optional: a script that fails to load must not take the sound down
      "wireplumber.profiles".main."golem.jack-profile" = "optional";
    };

    "60-golem-speaker-tunings" = {
      "node.filter-graph.rules" = map (t: {
        matches = [{
          "node.name" = "~alsa_output.*HiFi__Speaker__sink";
          "alsa.components" = t.components;
        }];
        actions.create-filter-graph = [ (builtins.toJSON t.graph) ];
      }) (lib.filter (t: t ? graph) tunings);
    };

    # Replaces the old "10-no-suspend-tas2781", which matched every output.
    "10-golem-speakers-awake" = lib.mkIf (awake != [ ]) {
      "monitor.alsa.rules" = map (t: {
        matches = [{
          "node.name" = t.keepAwake;
          "alsa.components" = t.components;
        }];
        actions.update-props."session.suspend-timeout-seconds" = 0;
      }) awake;
    };
  };
}
