# machine.nix — a machine's way into Standard.
#
# ⚠ NEVER MOVE OR RENAME THIS FILE: every machine's own flake names it.
#
#   /etc/nixos/flake.nix:   outputs = { self }: import ./standard/machine.nix ./.;
#
# `dir` is the machine's folder (/etc/nixos: configuration.nix, modules/,
# machine/…). Standard is the folder this file is in (/etc/nixos/standard, root's
# own editable copy), evaluated with the pins of its own flake.lock
# (system/machine/from-lock.nix says why not as a flake input). The answer is
# what a flake's outputs are: the machine, under its names.
dir:

let
  standard = import ./system/machine/from-lock.nix { src = ./.; };
in
{
  inherit (standard.lib.standard.machine dir) nixosConfigurations;
}
