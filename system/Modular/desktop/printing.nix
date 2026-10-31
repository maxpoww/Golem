# desktop/printing — plug a printer or a scanner in, and it works.
#
# Max, 2026-10-21: "hacé que funcione enchufar e imprimir en la mayoría de
# impresoras y scanners posible". Until now Golem had no printing at all: a
# plugged-in printer was a /dev/usb/lp0 nobody used, and every print dialog was
# empty.
#
# What makes "most printers" work, from the most to the least common:
#   - DRIVERLESS printing (IPP Everywhere / AirPrint / Mopria): nearly every
#     printer made since ~2013 on the network, and the USB ones that speak IPP
#     over USB (`ipp-usb` turns those into network printers on this machine).
#     CUPS + cups-filters do it with no driver; Avahi finds them by name.
#   - a DRIVER, for USB printers that do not speak IPP (this machine's HP
#     DeskJet 1200 is one): HP (hplip, its free part — no binary plug-in),
#     Gutenprint (hundreds of Canon, Epson, Brother, Lexmark…), Epson's own
#     escpr/escpr2, Brother's mono lasers (brlaser), Samsung/Xerox SPL (splix),
#     the ZjStream/HBPL lasers (foo2zjs). Free and in the binary cache only: an
#     unfree driver (Canon's cnijfilter2, Brother's per-model ones) is built on
#     every machine, the weak ones included, and gutenprint and driverless
#     cover those printers.
#   - the QUEUE made by itself: CUPS adds no USB printer on its own.
#     system-config-printer's udev rule does, choosing the best driver for the
#     printer's own device ID (what Fedora and Ubuntu do).
#   - scanners: SANE (sane-backends' own drivers), sane-airscan (driverless
#     eSCL/WSD — nearly every networked or IPP-over-USB all-in-one) and HP's.
#
# Golem's own part (`golem-printers`): the first printer becomes the default
# (Files' Print, `lp`, and any app that asks for "the" printer find it), and the
# owner is told when one is ready, in the desktop's own notifications.
{ config, lib, pkgs, ... }:

let
  owner = config.golem.owner;

  # Root: whenever CUPS' printer list changes. The first printer becomes the
  # default when there is none; the list is written where the owner's side
  # can read it (printers.conf itself is root's alone).
  printersSeen = pkgs.writeShellApplication {
    name = "golem-printers";
    runtimeInputs = [ pkgs.cups pkgs.coreutils pkgs.gnugrep pkgs.gawk ];
    text = ''
      mkdir -p /run/golem
      queues=$(lpstat -e 2>/dev/null || true)
      if [ -n "$queues" ] && ! lpstat -d 2>/dev/null | grep -q ': '; then
        first=$(printf '%s\n' "$queues" | head -n 1)
        lpadmin -d "$first" || true
      fi
      # One line a printer: its queue, then what it is ("HP DeskJet 1200").
      tmp=/run/golem/printers.tmp
      : > "$tmp"
      for q in $queues; do
        what=$(lpstat -l -p "$q" 2>/dev/null | awk -F'Description: ' '/Description: /{print $2; exit}')
        printf '%s\t%s\n' "$q" "''${what:-$q}" >> "$tmp"
      done
      chmod 0644 "$tmp"
      mv -f "$tmp" /run/golem/printers
    '';
  };

  # Root, after system-config-printer has looked at a printer plugged in (or
  # turned on): its queue, paused when it went away, takes up again. s-c-p
  # does that itself only while the queue's message is still its own
  # "Unplugged or turned off" — and a print cut by the unplug writes its error
  # over it, so the queue stayed paused for good (Max's DeskJet, 2026-10-21:
  # turned off with paper out mid-print, back on, nothing printed).
  printerBack = pkgs.writeShellApplication {
    name = "golem-printer-back";
    runtimeInputs = [ pkgs.cups pkgs.coreutils pkgs.gnugrep pkgs.gnused ];
    text = ''
      export LC_ALL=C
      # usb-BBB-DDD: the device that came (configure-printer@'s instance).
      case "''${1:-}" in usb-*-*) ;; *) exit 0 ;; esac
      inst=''${1#usb-}
      bus=$((10#''${inst%-*}))
      dev=$((10#''${inst#*-}))
      serial=
      for d in /sys/bus/usb/devices/*; do
        if [ "$(cat "$d/busnum" 2>/dev/null)" = "$bus" ] && [ "$(cat "$d/devnum" 2>/dev/null)" = "$dev" ]; then
          serial=$(cat "$d/serial" 2>/dev/null || true)
        fi
      done
      [ -n "$serial" ] || exit 0
      # "device for <queue>: <uri>" — the queues of this very printer.
      lpstat -v 2>/dev/null | while read -r _ _ queue uri; do
        queue=''${queue%:}
        printf '%s' "$uri" | grep -qiF "serial=$serial" || continue
        state=$(lpstat -p "$queue" 2>/dev/null) || continue
        case "$state" in *disabled*) ;; *) continue ;; esac
        # Paused by the unplug (whatever the cut print wrote over it: nothing,
        # a filter's last line, the backend's error), or by CUPS when the print
        # failed with the printer off. Not by hand: a plain `cupsdisable`
        # says "Paused", and that one stays.
        why=$(printf '%s\n' "$state" | sed -n 2p | sed 's/^[[:space:]]*//')
        if [ "$why" != "Paused" ]; then
          cupsenable "$queue" && echo "golem-printer-back: $queue takes up again"
        fi
      done
    '';
  };

  # The ink of a printer that does not tell CUPS (most HP inkjets over USB),
  # for the Printers page: HPLIP's own device code, without the tray icon and
  # the update check its hp-levels starts (printer-ink.py).
  printerInk = pkgs.writeShellApplication {
    name = "golem-printer-ink";
    text = ''
      export GOLEM_HPLIP=${pkgs.hplip} GOLEM_SITE=${pkgs.python3.sitePackages}
      exec ${pkgs.python3}/bin/python3 -I ${./printer-ink.py} "$@"
    '';
  };

  # The owner's side: a printer that was not there before is announced once.
  printerNotice = pkgs.writeShellApplication {
    name = "golem-printer-notice";
    runtimeInputs = [ pkgs.coreutils pkgs.libnotify pkgs.gnugrep ];
    text = ''
      list=/run/golem/printers
      [ -f "$list" ] || exit 0
      state="''${XDG_STATE_HOME:-$HOME/.local/state}/golem/printers-seen"
      mkdir -p "$(dirname "$state")"
      # The first time, what is there is what was always there: nothing said.
      if [ ! -f "$state" ]; then
        cut -f1 "$list" > "$state"
        exit 0
      fi
      case "''${LANG:-}" in
        es*) title="Impresora lista"; body="se puede imprimir desde cualquier app." ;;
        *) title="Printer ready"; body="you can print from any app." ;;
      esac
      while IFS="$(printf '\t')" read -r queue what; do
        [ -n "$queue" ] || continue
        if ! grep -qxF "$queue" "$state"; then
          notify-send -a Golem -i printer "$title" "$what: $body" || true
        fi
      done < "$list"
      cut -f1 "$list" > "$state"
    '';
  };
in
{
  config = lib.mkIf (!config.golem.lean) {
    environment.systemPackages = [ printerInk ];

    services.printing = {
      enable = true;
      # cups starts on first use (its socket), not at boot: 1.2 s of a weak
      # machine's login, and Golem's own part below runs three minutes in.
      startWhenNeeded = true;
      drivers = with pkgs; [
        hplip
        gutenprint
        epson-escpr
        epson-escpr2
        brlaser
        splix
        foo2zjs
      ];
      # (A printer added is written to printers.conf at once, not up to 30 s
      # later: that file is what Golem's own part follows.)
      extraConf = "DirtyCleanInterval 0";
    };

    # Printers and scanners on the network, found by name (and the
    # "printer.local" names they give themselves).
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    # A daemon that died leaves its PID file, owned by its own user, in a place
    # systemd keeps: the next start (the socket's, at the first client) reads it,
    # says "Failed to create PID file: File exists" and the service stays failed
    # for the rest of the boot, printers and scanners undiscovered (ASUS,
    # 2026-10-31). Clear it first, and come back by itself.
    systemd.services.avahi-daemon.serviceConfig = {
      ExecStartPre = "-${pkgs.coreutils}/bin/rm -f /run/avahi-daemon/pid";
      Restart = "on-failure";
      RestartSec = "2s";
    };

    # USB printers and scanners that speak IPP over USB: on this machine they
    # become network devices, used with no driver.
    services.ipp-usb.enable = true;

    # A USB printer plugged in gets its queue, with the best driver for it.
    services.system-config-printer.enable = true;

    hardware.sane = {
      enable = true;
      extraBackends = [ pkgs.sane-airscan pkgs.hplip ];
      # A webcam is not a scanner: SANE's v4l backend lists every camera as
      # one (a scanning app offering "Integrated Camera"), and every scanner
      # look would open each camera — the MacBook's FaceTime HD must have no
      # reader but PipeWire (quirks/facetimehd.nix).
      disabledDefaultBackends = [ "v4l" ];
    };
    services.udev.packages = [ pkgs.sane-airscan ];

    users.users.${owner}.extraGroups = [ "lp" "scanner" ];

    # A printer back: its paused queue takes up again (`printerBack`).
    systemd.services."configure-printer@".serviceConfig.ExecStartPost =
      "${printerBack}/bin/golem-printer-back %i";

    systemd.timers.golem-printers = {
      wantedBy = [ "timers.target" ];
      timerConfig = { OnBootSec = "3min"; AccuracySec = "30s"; };
    };
    # The network printer discovery (cups-browsed, on with avahi) starts
    # ninety seconds after boot, not at it: it is what woke cupsd at every
    # boot once cups went on its socket (1.1 s of the Air's login, a
    # resident scheduler; 2026-10-30). A printer found by name is listed a
    # minute and a half after boot.
    systemd.services.cups-browsed.wantedBy = lib.mkForce [ ];
    systemd.timers.cups-browsed = {
      wantedBy = [ "timers.target" ];
      timerConfig = { OnBootSec = "90s"; AccuracySec = "10s"; };
    };
    systemd.services.golem-printers = {
      description = "Golem: a default printer, and the list the desktop reads";
      after = [ "cups.service" ];
      wants = [ "cups.service" ];
      wantedBy = [ ];   # its timer, three minutes in
      serviceConfig = { Type = "oneshot"; ExecStart = "${printersSeen}/bin/golem-printers"; };
    };
    systemd.paths.golem-printers = {
      description = "Golem: follow CUPS' printer list";
      wantedBy = [ "paths.target" ];
      pathConfig.PathChanged = "/etc/cups/printers.conf";
    };

    systemd.user.services.golem-printer-notice = {
      description = "Golem: say when a printer is ready";
      serviceConfig = { Type = "oneshot"; ExecStart = "${printerNotice}/bin/golem-printer-notice"; };
    };
    systemd.user.paths.golem-printer-notice = {
      description = "Golem: follow the printers the system has";
      wantedBy = [ "paths.target" ];
      pathConfig.PathChanged = "/run/golem/printers";
    };
  };
}
