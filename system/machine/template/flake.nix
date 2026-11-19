{
  description = "This computer. Golem is the system; the files beside this one are the machine.";

  # WHICH GOLEM this computer runs. `stable` is the branch every install
  # follows; flake.lock (beside this file) pins the exact version. The update
  # moves the pin (golem-update, and the nightly update); nothing else in
  # this folder is ever rewritten by Golem.
  inputs.golem.url = "github:maxpoww/Golem/stable";

  # The machine is this folder: configuration.nix (yours), modules/ (yours),
  # hardware-configuration.nix (this hardware), machine/ (what Golem's tools
  # recorded: data, never code). Nothing here needs editing.
  outputs = { golem, ... }: {
    inherit (golem.lib.golem.machine ./.) nixosConfigurations;
  };
}
