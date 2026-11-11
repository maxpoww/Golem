# desktop/equalizer — the owner's equalizer, one per output.
#
# The dock's pages (the gear box's Equalizer row, Controls' Equalizer page)
# change the sound live and keep each output's choice in WirePlumber's state
# file golem-eq; eq.lua puts it back inside the output's own node whenever
# the output appears (filter graph 1, on top of the model's speaker tuning,
# which is graph 0). Builtin PipeWire filters only: nothing added to the
# closure, and an output left flat loads nothing.
{ ... }:

{
  services.pipewire.wireplumber.extraScripts."golem/eq.lua" = builtins.readFile ./eq.lua;

  services.pipewire.wireplumber.extraConfig."61-golem-eq" = {
    "wireplumber.components" = [{
      name = "golem/eq.lua";
      type = "script/lua";
      provides = "golem.eq";
    }];
    # "required": an "optional" component nothing wants never loads (0.5.14)
    "wireplumber.profiles".main."golem.eq" = "required";
  };
}
