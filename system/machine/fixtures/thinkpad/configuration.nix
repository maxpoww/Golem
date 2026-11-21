# THIS COMPUTER — your file.
#
# Standard is the system. It is in ./standard (read-only: the exact Standard this
# computer runs) and it updates by itself. What is written HERE is this
# computer: its name, its owner, and anything you want different. Standard
# never rewrites this file, and an update never touches it.
#
#   sudo nixos-rebuild switch     apply what you changed (or: rebuild-golem)
#   ./modules/                    drop a .nix file there: it is part of the system
#   ./standard/                      read Standard, copy from it (docs: ./standard/docs)
#   man configuration.nix         every NixOS option
#
# No password or key belongs in this folder: it is copied, readable by
# everyone, into the Nix store at every rebuild.
{ config, lib, pkgs, ... }:

{
  # ── Who and what (the installer's questions) ───────────────────────────
  standard.owner = "ana";
  networking.hostName = "thinkpad-ana";
  users.users."ana".description = "Test Owner";

  standard.locale.defaultLocale = "es_AR.UTF-8";
  standard.locale.timeZone = "America/Argentina/Buenos_Aires";

  standard.keyboard = {
    layout = "latam";
    variant = "";
    options = "";
    model = "pc105";
    consoleKeyMap = "la-latin1";
  };

  # ── Modules: a whole kind of work, its programs and the system they need ─
  # The dock's Modules page switches these on for you (machine/modules.list).
  # By hand it is the same switch:
  #
  #   standard.modules.gaming.enable = true;              # the recommended set
  #   standard.modules.development = {                    # or tool by tool
  #     enable = true;
  #     install = "chosen";
  #     docker.enable = true;
  #     vscode.enable = true;
  #   };

  # ── Your own changes ────────────────────────────────────────────────────
  # environment.systemPackages = [ pkgs.htop ];
  # services.openssh.enable = true;
}
