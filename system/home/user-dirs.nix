# Documents, Downloads, Pictures…: the owner's folders, named in the
# owner's language.
{ pkgs, ... }:

{
  # XDG User Directories — localized, not hardcoded English.
  #
  # home-manager's xdg.userDirs writes fixed names ("$HOME/Downloads"), which
  # gave a Portuguese install English folders — the thing Max called out. The
  # names must follow the chosen language (Transferências, Documentos, …), and
  # for languages we don't want to hand-maintain a table for. So we DON'T let
  # home-manager own the file (a store symlink would also fight the update);
  # instead xdg-user-dirs-update generates ~/.config/user-dirs.dirs from the
  # session LANG using the tool's own authoritative translations, and creates
  # the folders. It respects a user's later renames (no --force), and on an
  # already-English machine (Max's) leaves the existing folders untouched.
  xdg.userDirs.enable = false;

  systemd.user.services.golem-user-dirs = {
    Unit = {
      Description = "Localize XDG user dirs to the session language";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      # Source /etc/locale.conf so LANG is the system's chosen locale even
      # before the user manager imports the session environment — that is what
      # picks the translation. gettext needs a non-C LC_MESSAGES, which LANG
      # provides.
      ExecStart = "${pkgs.writeShellScript "golem-user-dirs" ''
        set -a
        # shellcheck disable=SC1091
        [ -r /etc/locale.conf ] && . /etc/locale.conf
        # The owner's own language, when they have one (the control panel's
        # Language, or the installer's seed of it — see base/user-dirs.nix):
        # on a fresh install the session speaks it before the system does.
        chosen=$(${pkgs.gnused}/bin/sed -n 's/.*"language"[[:space:]]*:[[:space:]]*"\([A-Za-z_.@0-9-]*\)".*/\1/p' \
          "''${XDG_CONFIG_HOME:-$HOME/.config}/golem/settings.json" 2>/dev/null | ${pkgs.coreutils}/bin/head -n1)
        if [ -n "$chosen" ]; then
          LANG=$chosen
          LC_MESSAGES=$chosen
          unset LC_ALL LANGUAGE
        fi
        set +a
        exec ${pkgs.xdg-user-dirs}/bin/xdg-user-dirs-update
      ''}";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
