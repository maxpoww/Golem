# base/shell — plain bash, minimal (Max, 2026-09-23: "we don't need the shell
# tweaking on Golem. lets use plain bash, minimal configuration. classic good
# old shell."). Replaces base/zsh.nix, which brought zsh (autosuggestions +
# syntax highlighting) and the home layer's starship / eza / bat / fzf /
# zoxide / aliases.
#
# The owner's shell is set to bash in base/users.nix. This file only gives
# home-manager a (deliberately empty) config for the owner so the stage-0 home
# still evaluates — no prompt theme, no plugins, no aliases: the classic bash
# you get out of the box. Data-driven only on golem.owner (whose home it is).
{ config, ... }:

{
  home-manager.users.${config.golem.owner} = {
    home.stateVersion = "26.05";
  };
}
