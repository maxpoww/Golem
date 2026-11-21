# legacy-names — THE OPTIONS BY THEIR OLD NAME, for machines installed before
# the system was called StandardOS (2026-11-20).
#
# Their own files — hosts/target in an owner's checkout, the build machine's
# /etc/nixos — were written when the options were `golem.…`: `golem.owner`,
# `golem.hardware.gpu`, `golem.lab.door`. Here `golem` is one option that
# takes whatever such a file says and says it again under `standard`, with
# the same priorities and conditions, and that READS as `standard` does (an
# older home layer asks `osConfig.golem.…`). So such a machine keeps
# building, and updating, with its files as they are.
#
# Imported wherever the options are declared (Modular/base/options.nix, and
# the older compositions in flake.nix): a machine of the /etc/nixos layout
# moved there from the old one (golem-relocate) has its configuration.nix
# in the old words too. It is invisible: nothing lists it, nothing new
# should use it. checks.legacy-names composes old-style files both ways.
#
# (One option, not a list of renames: a rename of an option the composition
# does not have is an error even when nobody sets it, and each composition
# has its own set.)
{ config, options, lib, ... }:

{
  options.golem = lib.mkOption {
    type = lib.types.unspecified;
    default = { };
    visible = false;
    apply = _: config.standard;
    description = "The options of `standard`, by their name before 2026-11-20.";
  };

  config.standard = lib.mkAliasDefinitions options.golem;
}
