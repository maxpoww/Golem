# base/users — the owner, stage 0. Data-driven from golem.owner (the
# installer's knob); groups here are the stage-0 set — the desktop leaf
# adds its own (adbusers, uinput) beside the subsystems that create
# them. GECOS mkDefault: the installer's machine.nix personalizes it
# (the "conflicting definition values: Max / Max Power" lesson).
{ config, pkgs, lib, ... }:

{
  users.users.${config.golem.owner} = {
    isNormalUser = true;
    description = lib.mkDefault "Max";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "input"
    ];
  };

  # The dev/deploy loop: the owner rebuilds without a password. Build
  # always runs before switch; generations are the net.
  security.sudo.extraRules = [{
    users = [ config.golem.owner ];
    commands = [{
      command = "/run/current-system/sw/bin/nixos-rebuild";
      options = [ "NOPASSWD" ];
    }];
  }];
}
