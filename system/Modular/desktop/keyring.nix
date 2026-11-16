# desktop/keyring — where apps keep their passwords (2026-10-28, plan F3.13).
#
# The Secret Service (org.freedesktop.secrets): GTK apps, Chrome and every
# Electron app (VS Code, Discord, Slack…), Wi-Fi tools, anything on libsecret
# store their passwords and sign-ins there. Without one they cannot save a
# login — some ask again every time, some refuse to start. Seam keeps its own
# store and needs none of this.
#
# GNOME Keyring, with its own prompt (gcr).
# Its "login" keyring is locked with the owner's password, and the place that
# password is typed is THE LOGIN: greetd starts the desktop with none typed
# (desktop/greeter.nix) and the lock screen is the desktop's first screen
# (golem-lock-screen --login, home/idle.nix). So:
#   - hyprlock's PAM starts the daemon WITH the password (auto_start), or
#     unlocks the one already running; the first time it makes the login
#     keyring with it. Only a password the system ACCEPTED gets there: in
#     NixOS's order the keyring sees every attempt before pam_unix judges it,
#     and a typo at the first login made the keyring with the typo — the
#     right password a second later could no longer open it (the VM,
#     2026-10-28). So the password is checked first and a wrong one ends the
#     attempt (requisite);
#   - golem-lock-screen, once the lock is gone, completes the daemon's start
#     (`--start`: its Secret Service on the bus, its certificates). A daemon
#     started this way waits two minutes for that, then exits.
# Nothing may start the daemon BEFORE that password (the VM, 2026-10-28):
#   - greetd's PAM leaves it alone: with no password typed it could only start
#     one with the login keyring locked, and the first app to ask for a secret
#     hung on a prompt behind the lock screen;
#   - the package's two autostart entries (pkcs11, secrets) are hidden: they
#     started a daemon with no password at the session's start, and a login
#     keyring the lock screen then made in it was never on the bus — the
#     default alias named a collection that did not exist, and an app storing
#     a password hung. (Golem's session runs every XDG autostart entry;
#     /etc/xdg comes first in XDG_CONFIG_DIRS, so these win.)
#   - the portal's Secret backend is not routed to it (desktop/portals): the
#     portal service asked for it as the session started.
# Every later lock (idle, sleep, Super+L) unlocks the running daemon again.
{ lib, ... }:

let
  hidden = name: ''
    [Desktop Entry]
    Type=Application
    Name=${name}
    Hidden=true
  '';
in
{
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.hyprlock = {
    enableGnomeKeyring = true;
    rules.auth = {
      unix-early.enable = lib.mkForce false;     # (it only fetched the password for the keyring)
      unix = { control = lib.mkForce "requisite"; order = lib.mkForce 12100; };
      gnome_keyring.settings.auto_start = true;  # (12200: after the check)
      deny.enable = false;                       # (the requisite check is the verdict)
    };
  };
  security.pam.services.greetd.enableGnomeKeyring = false;
  # Not its SSH agent (NixOS turns gcr's on with the keyring): it would put
  # SSH_AUTH_SOCK in the session and answer every ssh — a change of its own,
  # not part of keeping passwords.
  services.gnome.gcr-ssh-agent.enable = false;
  environment.etc = lib.genAttrs
    [ "xdg/autostart/gnome-keyring-pkcs11.desktop" "xdg/autostart/gnome-keyring-secrets.desktop" ]
    (f: { text = hidden "GNOME Keyring (started by golem-lock-screen)"; });
}
