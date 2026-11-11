# golem-say — Golem's own messages in the owner's language (golem-say.sh says
# how). Every module that posts a notification takes it the same way:
#
#   golemSay = pkgs.callPackage <path to>/system/i18n/golem-say.nix { };
#
# (one derivation whoever asks: the same inputs give the same store path).
{ lib, writeShellApplication, jq, stdenv }:

let
  # Only the catalogues go into the store, not this file or the scripts.
  catalogues = builtins.path {
    name = "golem-say-catalogues";
    path = ./.;
    filter = path: type: type == "regular" && lib.hasSuffix ".json" path;
  };
in
writeShellApplication {
  name = "golem-say";
  runtimeInputs = [ jq ];
  # Syntax only, as the Seam lane does: installs, updates and the greeter all
  # speak through this, and a shellcheck style nit must never fail their
  # rebuild. (Its behaviour is tested by running it: check.sh.)
  checkPhase = ''
    runHook preCheck
    ${stdenv.shellDryRun} "$target"
    runHook postCheck
  '';
  text = ''
    GOLEM_SAY_DIR=''${GOLEM_SAY_DIR:-${catalogues}}
  '' + builtins.readFile ./golem-say.sh;
}
