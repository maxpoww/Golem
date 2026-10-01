# Evaluate each package the dock would offer, exactly as an install would
# (Golem's own package set, its config: unfree allowed, nothing insecure or
# broken). Used by refresh.sh; one attribute set of name → "ok:<outPath>" or
# the reason it can never install.
{ flake, names }:
let
  f = builtins.getFlake flake;
  pkgs = f.nixosConfigurations.golem-desktop-vm.pkgs;
  lib = pkgs.lib;
  one = n:
    let
      got = builtins.tryEval (lib.attrByPath (lib.splitString "." n) null pkgs);
      p = got.value;
    in
    if !got.success then "attr-throws"
    else if p == null then "missing"
    else if !(lib.isDerivation p) then "not-a-derivation"
    else
      let d = builtins.tryEval (builtins.seq p.drvPath p.outPath); in
      if d.success then "ok:" + d.value else "eval-fails";
in
builtins.listToAttrs (map (n: { name = n; value = one n; }) names)
