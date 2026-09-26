# desktop/greeter — the login, stage 1. greetd launches the owner's Hyprland
# session through uwsm (the same unit programs.hyprland.withUWSM installs, in
# hyprland.nix). Ported verbatim from the fat system/configuration.nix.
#
# This is Golem's current single-user behaviour: the session starts as the owner
# without a password gate at the greeter. A real multi-user greeter is a
# separate future decision; this leaf reproduces what the fat path does today.
{ config, ... }:

{
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "uwsm start hyprland-uwsm.desktop";
      user = config.golem.owner;
    };
  };
}
