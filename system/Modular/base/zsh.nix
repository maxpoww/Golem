# base/zsh — Golem at the tty IS this file's doing, stage 0.
# System half lifted verbatim from configuration.nix; the user half is
# the existing home layer's zsh (system/home/zsh.nix — starship, eza,
# bat, fzf, zoxide, the aliases: "zsh as we have it configured on
# Golem", Max 2026-09-10) imported WHOLE, unchanged — the identity
# requirement is that a stage-0 tty feels exactly like the dev box's.
# Data-driven only on golem.owner (whose home it is).
{ config, ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };

  home-manager.users.${config.golem.owner} = {
    imports = [ ../../home/zsh.nix ];
    home.stateVersion = "26.05";
  };
}
