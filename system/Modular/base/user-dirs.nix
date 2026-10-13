# base/user-dirs — localized XDG user dirs (Descargas, not Downloads).
#
# The language is baked into the installed toplevel (flake.nix bakeLocales), so
# a pt_PT install boots with LANG=pt_PT. This leaf turns that into the folders
# Max asked for: on the owner's first session it runs xdg-user-dirs-update,
# which reads the session LANG and generates ~/.config/user-dirs.dirs with the
# tool's own authoritative translations, creating ~/Transferências / ~/Descargas
# / … instead of English. It respects a user's later renames (no --force), and
# ~/.config is mutable state (like the seeded password/keys) so it persists.
#
# Base, not desktop: stage-0 installs are headless, and the roster test wants
# the localized dirs visible over SSH on first login. The desktop leaf's own
# home layer will layer on top when it ships.
{ config, pkgs, lib, ... }:

let owner = config.golem.owner;
in {
  home-manager.users.${owner} = {
    home.packages = [ pkgs.xdg-user-dirs ];

    # mkDefault: the desktop's home layer (system/home/home.nix) defines this
    # SAME service (After graphical-session instead of default.target). When
    # that layer is wired in (golem-desktop), let ITS version win; this base
    # one applies on the headless minimal, which has no home layer. (2026-09-26)
    systemd.user.services.golem-user-dirs = lib.mkDefault {
      Unit = {
        Description = "Localize XDG user dirs to the session language";
        # Runs once the user manager is up (any login — SSH or console — starts it).
        After = [ "default.target" ];
      };
      Service = {
        Type = "oneshot";
        # Source /etc/locale.conf so LANG is the installed language even before
        # the user manager imports the session environment. gettext needs a
        # non-C LC_MESSAGES, which LANG provides.
        ExecStart = "${pkgs.writeShellScript "golem-user-dirs" ''
          set -a
          # shellcheck disable=SC1091
          [ -r /etc/locale.conf ] && . /etc/locale.conf
          # The owner's own language, when they have one (the control panel's
          # Language, or the installer's seed of it): the folders are named in
          # the language the session speaks, which on a fresh install is not
          # yet the system's (the baked desktop boots in English until its
          # first rebuild).
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
  };
}
