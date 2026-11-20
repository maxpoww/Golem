{
  description = "This computer. Its own files are beside this one; Golem is in golem/.";

  # No inputs: GOLEM IS THE FOLDER golem/ beside this file. It is root's own
  # copy, a git checkout you may edit, and the versions of everything it is
  # built with (NixOS, the dock…) are pinned in ITS flake.lock. An update
  # merges the new Golem into that folder and keeps what you changed there
  # (golem-update, and the nightly update); nothing else in /etc/nixos is
  # ever rewritten by Golem.
  #
  # The machine is this folder: configuration.nix (yours), modules/ (yours),
  # hardware-configuration.nix (this hardware), machine/ (what Golem's tools
  # recorded: data, never code). This file needs no editing.
  outputs = { self }: import ./golem/machine.nix ./.;
}
