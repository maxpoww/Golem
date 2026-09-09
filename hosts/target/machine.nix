# The human choices for this machine, written by golem-install.
# Everything else about this system comes from the flake.
{ ... }:
{
  golem.owner = "max";
  networking.hostName = "asus";
  users.users.max.description = "max";

  # The language step's answer. Drives i18n.defaultLocale and
  # which locales get generated — an ungenerated locale falls
  # back to C at first boot without saying so.
  golem.locale.defaultLocale = "en_US.UTF-8";
  golem.locale.timeZone = "America/Denver";
  users.users.max.hashedPassword = "$y$j9T$SyvIDy3hSeegZjrAfL69Z/$abdDCG2Tl0F3sAP/0hzw5czYs86wghDMYYOKs0poeG3";

  # The keyboard step's one answer. Four values, three sinks:
  # console.keyMap, services.xserver.xkb.*, and Hyprland's own
  # input block — wired from these in system/configuration.nix
  # and system/home/home.nix. A comma in layout means a second
  # Latin group so a non-Latin script can still type a URL.
  golem.keyboard = {
    layout = "us";
    variant = "";
    options = "";
    model = "pc104";
    consoleKeyMap = "us";
  };

  # --lab-ssh: this machine is a lab testbed, reachable from the
  # dev box. Golem ships no sshd by default; this is NOT what a
  # stranger's install gets.
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
  users.users.max.openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILn4GLtnQEthtkhvWmcPpl7Y1GtMlBVUyTAJrNcHcX5K golem-vm-loop" ];
  users.users.root.openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILn4GLtnQEthtkhvWmcPpl7Y1GtMlBVUyTAJrNcHcX5K golem-vm-loop" ];
}
