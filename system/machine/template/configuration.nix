# THIS COMPUTER — your file.
#
# Golem is the system. It is in ./golem (read-only: the exact Golem this
# computer runs) and it updates by itself. What is written HERE is this
# computer: its name, its owner, and anything you want different. Golem
# never rewrites this file, and an update never touches it.
#
#   sudo nixos-rebuild switch     apply what you changed (or: rebuild-golem)
#   ./modules/                    drop a .nix file there: it is part of the system
#   ./golem/                      read Golem, copy from it (docs: ./golem/docs)
#   man configuration.nix         every NixOS option
#
# No password or key belongs in this folder: it is copied, readable by
# everyone, into the Nix store at every rebuild.
{ config, lib, pkgs, ... }:

{
  # ── Who and what (the installer's questions) ───────────────────────────
  golem.owner = "@owner@";
  networking.hostName = "@hostname@";
  users.users."@owner@".description = "@fullname@";

  golem.locale.defaultLocale = "@locale@";
  golem.locale.timeZone = "@timezone@";

  golem.keyboard = {
    layout = "@kb_layout@";
    variant = "@kb_variant@";
    options = "@kb_options@";
    model = "@kb_model@";
    consoleKeyMap = "@kb_console@";
  };
@machine_extra@
  # ── Modules: a whole kind of work, its programs and the system they need ─
  # The dock's Modules page switches these on for you (machine/modules.list).
  # By hand it is the same switch:
  #
  #   golem.modules.gaming.enable = true;              # the recommended set
  #   golem.modules.development = {                    # or tool by tool
  #     enable = true;
  #     install = "chosen";
  #     docker.enable = true;
  #     vscode.enable = true;
  #   };

  # ── Your own changes ────────────────────────────────────────────────────
  # environment.systemPackages = [ pkgs.htop ];
  # services.openssh.enable = true;
}
