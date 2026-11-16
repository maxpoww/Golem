# desktop/whats-new — what each update changed, written by hand (Max,
# 2026-11-16: "qué cambió lo escribimos a mano").
#
# system/whats-new.json is the list: one short sentence a change and a
# language, newest FIRST, each with an `id` that never changes once
# published. Every system carries the list as it stood when it was built
# (/etc/golem/whats-new.json), so Controls → Updates tells what a kept
# version changed by comparing its list with the one of the version before
# it: nothing has to know which update made which system.
#
# Writing one: a sentence a person who never saw the code understands, about
# 70 letters at most (it is one line on a page that does not scroll), in
# English and in es, pt, fr, de, it; es_ES and pt_PT only where they would
# differ. Add it at the TOP, in the same commit as the change it tells or in
# the one that publishes the update. Old entries may be dropped once no kept
# system can lack them (months later); never edit an id.
{ lib, ... }:

let
  file = ../../whats-new.json;
  entries = builtins.fromJSON (builtins.readFile file);
  needed = [ "id" "en" "es" "pt" "fr" "de" "it" ];
  lacking = lib.concatMap (e: map (k: "${e.id or "?"}: ${k}") (lib.filter (k: (e.${k} or "") == "") needed)) entries;
  ids = map (e: e.id or "") entries;
in
{
  assertions = [
    {
      assertion = lacking == [ ];
      message = "system/whats-new.json: entries lack words: ${lib.concatStringsSep ", " lacking}";
    }
    {
      assertion = lib.unique ids == ids;
      message = "system/whats-new.json: an id is there twice";
    }
  ];

  environment.etc."golem/whats-new.json".source = file;
}
