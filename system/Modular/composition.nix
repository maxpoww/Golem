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
    # The boot bar (Max, 2026-09-23: "show our bar everywhere") — Plymouth
    # styled as the OPTIONS status bar, so every installed Golem fills its boot
    # screen with the accent bar instead of black. Loader-agnostic (it is the
    # splash, not GRUB), so it belongs in the always-chosen base, not the
    # hardware-chosen boot leaves. Carries the #65 tax (`splash`) — see the file.
    ./boot/plymouth.nix
    ./base/shell.nix
    ./base/selfrebuild.nix
    ./base/loop.nix
    # TEMPORARY (Max, 2026-09-24): the lab door — every installed Golem is
    # SSH-reachable by the dev box + auto-joins the lab wifi, so testing happens
    # over SSH not the console. DELETE this line (and lab/lab-door.nix) at the
    # first FINISHED Golem ISO — see the file's header.
    ./lab/lab-door.nix
    # The seal (#56) rides with selfrebuild: every unattended rebuild
    # is gated on the blessed manifest. Shared with the fat path,
    # already leaf-shaped.
    ../golem-seal.nix
  ];
}
