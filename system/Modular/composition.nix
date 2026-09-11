# The Modular composition's base — everything ALWAYS chosen at stage 0.
# The hardware leaves arrive beside this via hosts/target/modules.nix
# (the chooser's output); the desktop and program leaves arrive with
# their stages. This file is a plain import list on purpose: the
# composition has no opinions, only membership.
{ ... }:

{
  imports = [
    ./base/options.nix
    ./base/core.nix
    ./base/network.nix
    ./base/ssh.nix
    ./base/nix.nix
    ./base/users.nix
    ./base/locale.nix
    ./base/console.nix
    ./base/zsh.nix
    ./base/selfrebuild.nix
    ./base/loop.nix
    # The seal (#56) rides with selfrebuild: every unattended rebuild
    # is gated on the blessed manifest. Shared with the fat path,
    # already leaf-shaped.
    ../golem-seal.nix
  ];
}
