# machine.nix — a machine's way into Golem.
#
# ⚠ NEVER MOVE OR RENAME THIS FILE: every machine's own flake names it.
#
#   /etc/nixos/flake.nix:   outputs = { self }: import ./golem/machine.nix ./.;
#
# `dir` is the machine's folder (/etc/nixos: configuration.nix, modules/,
# machine/…). Golem is the folder this file is in (/etc/nixos/golem, root's
# own editable copy), evaluated with the pins of its own flake.lock
# (system/machine/from-lock.nix says why not as a flake input). The answer is
# what a flake's outputs are: the machine, under its names.
dir:

let
  golem = import ./system/machine/from-lock.nix { src = ./.; };
in
{
  inherit (golem.lib.golem.machine dir) nixosConfigurations;
}
