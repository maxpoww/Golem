# desktop/session — the session plumbing the desktop's apps assume, stage 1.
#
#   gvfs     trash, mounted drives and network shares inside Nautilus and the
#            file chooser (GIO modules; without them Nautilus shows a folder
#            and nothing else)
#   dconf    where GTK/libadwaita settings live — the dark theme, the portal's
#            colour scheme, every gsettings write
#   udisks2  removable drives for the desktop's user (plug in a USB stick)
#   glib     `gsettings` and `gio` on the PATH
#   wsdd     what gvfs spawns for Files' "Network" view (Web Service
#            Discovery): without it the view failed outright — "Failed to
#            spawn the wsdd daemon" (ASUS dogfood, 2026-10-02). The firewall
#            stays closed: auto-discovering Windows hosts would need UDP 3702
#            open on every network the laptop joins; typing smb://host still
#            works.
#
# Ported from the fat system/configuration.nix (gvfs + GIO_EXTRA_MODULES).
# Landed 2026-09-30 (deep debug, parity P9): installs had 0 GIO modules and no
# gsettings.
{ pkgs, lib, ... }:

let
  # THE SESSION BUS (user dbus-broker) must survive running out of file
  # descriptors. Stock dbus-broker exits on EMFILE at accept, or at the pidfd
  # it takes per peer; a dead session bus has uwsm tear the whole session down
  # (dev box, 2026-10-14 06:22:55: three days up, something leaking connections,
  # `sockopt_get_peerpidfd … Too many open files`, greetd closed the session,
  # Max at the greeter). Patched: the pidfd is optional (out of descriptors =
  # "unavailable"), and a connection that cannot be accepted is REFUSED through a
  # spare descriptor the listener keeps for exactly that, with one warning in
  # the journal — the client fails, the bus lives, the session lives.
  dbusBroker = pkgs.dbus-broker.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./dbus-broker-patches/dbus-broker-survive-emfile.patch ];
  });

  # THE BUS GUARD: every five minutes, how full the session bus is. At half its
  # limit the owner is told, with the process holding the most connections; at
  # 80 % the running broker's limit is raised on the spot (prlimit: raising the
  # soft limit up to the hard one needs no privilege). A line a run in
  # ~/.local/state/golem/bus-guard.log, so a leak can be read off later.
  busGuard = pkgs.writeShellScript "golem-bus-guard" ''
    set -u
    PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.gnugrep pkgs.gawk pkgs.procps pkgs.util-linux pkgs.systemd pkgs.libnotify ]}
    export DBUS_SESSION_BUS_ADDRESS="''${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"
    log="''${XDG_STATE_HOME:-$HOME/.local/state}/golem/bus-guard.log"
    mkdir -p "$(dirname "$log")"
    broker=$(pgrep -u "$(id -u)" -x dbus-broker | head -1)
    [ -n "$broker" ] || exit 0
    fds=$(ls /proc/$broker/fd 2>/dev/null | wc -l)
    soft=$(awk '/Max open files/ {print $4}' /proc/$broker/limits)
    hard=$(awk '/Max open files/ {print $5}' /proc/$broker/limits)
    [ "$soft" -gt 0 ] 2>/dev/null || exit 0
    pct=$(( fds * 100 / soft ))
    # Room FIRST: with the bus near full, the questions below and the notice
    # are themselves refused (the Acer, 2026-10-14: raised, but "top:" empty
    # and no notice — the culprit unnamed exactly when it mattered).
    if [ "$pct" -ge 80 ] && [ "$soft" -lt "$hard" ]; then
      prlimit --pid "$broker" --nofile="$hard:$hard" 2>/dev/null && raised=1 || raised=0
    else
      raised=0
    fi
    # The process with the most connections: every unique name on the bus,
    # resolved to its process through the bus itself.
    top=$(for n in $(busctl --user list --no-pager --no-legend --unique 2>/dev/null | awk '{print $1}'); do
            pid=$(busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus GetConnectionUnixProcessID s "$n" 2>/dev/null | awk '{print $2}')
            [ -n "$pid" ] && echo "$pid $(cat /proc/$pid/comm 2>/dev/null || echo '?')"
          done | sort | uniq -c | sort -rn | head -3 | awk '{printf "%s %s(%s) ", $1, $3, $2}')
    echo "$(date '+%F %T') broker=$broker fds=$fds/$soft ($pct%) top: $top" >> "$log"
    if [ "$raised" = 1 ]; then
      echo "$(date '+%F %T') raised the broker's limit to $hard" >> "$log"
      notify-send -u critical "El bus de sesión está al $pct %" "Le subí el tope para que no se caiga. Algo fuga conexiones: $top"
    elif [ "$pct" -ge 50 ]; then
      notify-send -u normal "El bus de sesión está al $pct %" "Algo deja conexiones abiertas: $top"
    fi
  '';
  golemSchemas = pkgs.runCommand "golem-gsettings-schemas" { } ''
    mkdir -p $out/share/glib-2.0/schemas
    cp ${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/*/glib-2.0/schemas/*.xml $out/share/glib-2.0/schemas/
    ${pkgs.glib.dev}/bin/glib-compile-schemas $out/share/glib-2.0/schemas
  '';
in
{
  services.dbus.brokerPackage = dbusBroker;

  systemd.user.services.golem-bus-guard = {
    description = "Golem: how full the session bus is";
    serviceConfig = { Type = "oneshot"; ExecStart = "${busGuard}"; };
  };
  systemd.user.timers.golem-bus-guard = {
    description = "Golem: look at the session bus every five minutes";
    wantedBy = [ "timers.target" ];
    timerConfig = { OnBootSec = "2min"; OnUnitActiveSec = "5min"; AccuracySec = "1min"; };
  };

  services.gvfs.enable = true;
  environment.sessionVariables.GIO_EXTRA_MODULES = [ "${pkgs.gvfs}/lib/gio/modules" ];
  programs.dconf.enable = true;

  # Qt apps wear THE PALETTE too (Controls → Colours): qt5ct/qt6ct as the
  # platform theme, pointed by the dock at the colour scheme it writes
  # (~/.local/state/golem/theme/qt.conf; waverunner palette.rs writes
  # ~/.config/qt{5,6}ct/qt{5,6}ct.conf when nothing else owns them). Without
  # this Qt apps ignored dark mode altogether. The variable reaches apps from
  # the next login.
  qt = {
    enable = true;
    platformTheme = "qt5ct";
  };
  services.udisks2.enable = true;
  environment.systemPackages = [ pkgs.glib pkgs.wsdd golemSchemas ];
  # THE SESSION'S GSETTINGS SCHEMAS. GTK reads the theme, the icon theme and
  # the fonts an app should wear from dconf's org.gnome.desktop.interface —
  # but only where it finds that schema compiled on XDG_DATA_DIRS. nixpkgs
  # keeps every package's schemas inside the package (share/gsettings-schemas/
  # <pkg>/…), reachable only through that package's own wrapper: Thunar and
  # the GNOME apps carry gsettings-desktop-schemas in theirs, Inkscape does
  # not, and `gsettings` itself answered "No schemas installed" in the
  # session (dev box and ASUS, 2026-10-15). So the dock's dconf writes — the
  # look's icon theme, the palette's GTK theme (waverunner palette.rs) —
  # reached some apps and not others. The base schemas go into the system
  # path, compiled, where every app's data dirs already look.
  environment.pathsToLink = [ "/share/glib-2.0" ];
}
