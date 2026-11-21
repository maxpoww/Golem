{
  description = "This computer. Its own files are beside this one; StandardOS is in standard/.";

  # No inputs: THE SYSTEM IS THE FOLDER standard/ beside this file. It is
  # root's own copy, a git checkout you may edit, and the versions of
  # everything it is built with (NixOS, the dock…) are pinned in ITS
  # flake.lock. Golem updates it: it merges each new version into that folder
  # and keeps what you changed there (golem-update, and every night); nothing
  # else in /etc/nixos is ever rewritten.
  #
  # The machine is this folder: configuration.nix (yours), modules/ (yours),
  # hardware-configuration.nix (this hardware), machine/ (what Golem recorded
  # about this computer: data, never code). This file needs no editing.
  outputs = { self }: import ./standard/machine.nix ./.;
}
