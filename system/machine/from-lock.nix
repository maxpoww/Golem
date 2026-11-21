# GOLEM, EVALUATED FROM ITS OWN LOCK — with no flake around it.
#
#   standard = import ./from-lock.nix { src = /etc/nixos/standard; };
#   standard.lib.standard.machine /etc/nixos   # …the same outputs the flake has
#
# On a machine Standard is a folder its owner can edit as root
# (/etc/nixos/standard: docs/system/Layout.md). Named as a flake INPUT of the
# machine's flake it would be locked twice: Nix copies the input's pins into
# the machine's own flake.lock and never looks at the input's again, so the
# day Standard's flake.lock moved (an update, a pull by hand) the machine went
# on building the new Standard with the old nixpkgs and the old dock (measured
# 2026-11-19 with a relative `path:` input, Nix 2.34: the sub-flake's code is
# read fresh, its lock is not).
#
# So the machine's flake has no inputs at all, and Standard's flake.nix is
# called here with the inputs ITS OWN flake.lock names: one pin file, the one
# an update moves. Each input is fetched by what the lock holds (a revision
# and its hash: `builtins.fetchTree` of a locked reference is as pure as a
# flake input, and gives the same store path), and wired as Nix wires them:
# an input is a node of the lock, a `follows` is a path from the root.
#
# What the result does NOT have is a git revision of its own (self.rev): the
# folder is not asked for one. flake.nix reads .golem-rev there instead, the
# revision the update wrote beside the files.
{ src }:

let
  lock = builtins.fromJSON (builtins.readFile (src + "/flake.lock"));
  inherit (lock) nodes root;

  # An input of a node: the name of another node, or a path from the root
  # (`inputs.nixpkgs.follows = "nixpkgs"` is [ "nixpkgs" ]).
  resolve = spec: if builtins.isList spec then walk root spec else spec;
  walk = node: path:
    if path == [ ] then node
    else walk (resolve nodes.${node}.inputs.${builtins.head path}) (builtins.tail path);

  tree = name:
    if name == root then { outPath = src; }
    else builtins.fetchTree nodes.${name}.locked;

  flakes = builtins.mapAttrs
    (name: node:
      let
        source = tree name;
        inputs = builtins.mapAttrs (_: spec: flakes.${resolve spec}) (node.inputs or { });
        outputs = (import (source.outPath + "/flake.nix")).outputs (inputs // { self = result; });
        # What Nix hands a flake as `self` and as an input: its outputs, what
        # is known of its source (revision, date), and itself.
        result = outputs // source // {
          inherit inputs outputs;
          sourceInfo = source;
          _type = "flake";
        };
      in
      if node.flake or true then result else source)
    nodes;
in
flakes.${root}
