# golem-brightness — the backlight that follows the panel, not a hardcoded name.
#
# Max hit this for years: brightness worked with `intel_backlight`, then a stint
# where he had to use `nvidia_0`, then back — and swapped the name by hand in
# hyprland.lua each time. Root cause (studied on his lenovo, 2026-09-24): on a
# hybrid laptop the internal panel's backlight is owned by whichever GPU is
# DRIVING the panel. `intel_backlight` → `card2-eDP-1` (connected, on the iGPU)
# today; `nvidia_0` → the dGPU (its eDP disconnected now) — which is why it stopped
# working. A fixed device name is wrong by construction, and `brightnessctl`'s own
# auto-pick ignores which connector is live (so the keys can hit a dead backlight
# and look broken "out of the box").
#
# So Golem doesn't store a name — it FINDS the backlight tied to the connected
# internal panel at press time and drives that. Adapts to the mux with zero config,
# on any machine. The brightness keys call `golem-brightness` instead of
# `brightnessctl -d <guess>`. Permissions come from the owner being in `video` +
# brightnessctl's own udev rule (already set) — no setuid, no root.
{ pkgs, ... }:

let
  pick = ''
      # Pick the backlight driving the ACTIVE internal panel: a connected eDP/LVDS
      # connector, then the /sys/class/backlight entry pointing at that connector
      # (or its GPU). Falls back to the first raw-type backlight, then anything.
      pick() {
        for con in /sys/class/drm/card*-eDP-* /sys/class/drm/card*-LVDS-*; do
          [ -e "$con/status" ] || continue
          [ "$(cat "$con/status" 2>/dev/null)" = connected ] || continue
          conpath=$(readlink -f "$con")
          gpu=$(readlink -f "$con/../device")
          for bl in /sys/class/backlight/*; do
            [ -e "$bl" ] || continue
            bld=$(readlink -f "$bl/device")
            case "$bld" in
              "$conpath"|"$gpu"|"$gpu"/*) basename "$bl"; return 0 ;;
            esac
          done
        done
        for bl in /sys/class/backlight/*; do
          [ -e "$bl" ] || continue
          [ "$(cat "$bl/type" 2>/dev/null)" = raw ] && { basename "$bl"; return 0; }
        done
        for bl in /sys/class/backlight/*; do [ -e "$bl" ] && { basename "$bl"; return 0; }; done
        return 1
      }
  '';

  golem-brightness = pkgs.writeShellApplication {
    name = "golem-brightness";
    runtimeInputs = [ pkgs.brightnessctl pkgs.coreutils ];
    # shellcheck: the /sys globs are intentional and guarded.
    text = ''
${pick}
      dev=$(pick) || { echo "golem-brightness: no backlight device found" >&2; exit 1; }
      # -e4 exponential curve, -n2 floor (never fully black) — Max's tuned feel.
      exec brightnessctl -e4 -n2 -d "$dev" "$@"
    '';
  };

  # golem-autobrightness — the panel follows the room's light, where the machine
  # has an ambient light sensor (an iio `in_illuminance_*`: the HID sensor hub of
  # most 2020+ laptops, ACPI ALS). No sensor or no backlight → it exits at start
  # and nothing runs.
  #
  #   - light → level on a log curve, in the same perceptual scale as the keys
  #     (brightnessctl -e4): 40 % in the dark, +7.3 points each time the light
  #     doubles, 100 % from 300 lx. These sensors sit behind the bezel and read
  #     low: a lit room by day is 100–400 lx here. (The first version ran 50 % →
  #     100 % over 10 000 lx: a dark room and daylight were 20 points apart and
  #     nobody could see it work — Max, 2026-10-10.)
  #   - turning it ON moves the screen to the room at once; turning it OFF puts
  #     back the level it had before. The switch must be seen to do something;
  #   - the brightness KEYS still work: the level they set STAYS until the light
  #     itself changes (doubles or halves). What they teach is small: an offset
  #     to the curve of 20 points at most, so one press to 100 % in a dark room
  #     cannot pin the screen at 100 % everywhere (it did);
  #   - brighter follows in ~4 s, dimmer waits ~10 s and fades slower; a change
  #     under 5 points or a single odd reading (a hand, a shadow) moves nothing;
  #   - lid closed, or the backlight at 0 (the hibernate hook holds it there
  #     through the sleep): it waits and learns nothing.
  #
  # `golem-autobrightness off|on|status|reset`: off is a file
  # (~/.config/golem/autobrightness-off, as caffeine), so it survives a reboot.
  # Pure bash arithmetic on /sys, one sensor read every 2 s (the HID hub takes
  # ~0.6 s to answer), no child process in the loop.
  golem-autobrightness = pkgs.writeShellApplication {
    name = "golem-autobrightness";
    runtimeInputs = [ pkgs.coreutils pkgs.systemd ];
    text = ''
      off_file="$HOME/.config/golem/autobrightness-off"
      state="''${XDG_STATE_HOME:-$HOME/.local/state}/golem/autobrightness"
      # The level the owner had when it was switched on, for `off` to put back.
      manual="$state-manual"

      ${pick}
      # Both overridable for the test rig (a fake /sys in a temp dir).
      sensor="''${GOLEM_AUTOBRIGHTNESS_SENSOR:-}"
      bl="''${GOLEM_AUTOBRIGHTNESS_BACKLIGHT:-}"
      max="" actual="" written="" p10=0 rawv=0

      # The backlight and its range; fails where there is none.
      find_backlight() {
        if [ -z "$bl" ]; then
          local dev
          dev=$(pick) || return 1
          bl=/sys/class/backlight/$dev
        fi
        read -r max < "$bl/max_brightness" || true
        case "$max" in ""|0|*[!0-9]*) return 1 ;; esac
        return 0
      }

      # Tenths of a percent ↔ the backlight's own number, on the keys' curve
      # (brightnessctl -e4: value = max * fraction^4), never under 2 (-n2).
      to_raw() {
        local p=$1
        rawv=$(( (max * p * p * p * p + 500000000000) / 1000000000000 ))
        if (( rawv < 2 )); then rawv=2; fi
        if (( rawv > max )); then rawv=max; fi
      }
      to_p10() {
        local want=$1 lo=0 hi=1000 mid
        while (( lo < hi )); do
          mid=$(( (lo + hi + 1) / 2 ))
          if (( (max * mid * mid * mid * mid + 500000000000) / 1000000000000 <= want )); then lo=$mid; else hi=$(( mid - 1 )); fi
        done
        p10=$lo
      }

      read_actual() {
        actual=""
        read -r actual < "$bl/brightness" 2>/dev/null || true
        case "$actual" in ""|*[!0-9]*) return 1 ;; esac
        return 0
      }

      # A timed wait with no child process: read on a pipe nobody writes to.
      exec {idle}<> <(:)
      nap() { read -rt "$1" -u "$idle" _ || true; }

      # Fade from tenths $1 to tenths $2, $3 seconds a step; leaves the last
      # number written in $written.
      fade() {
        local from=$1 to=$2 d steps i=1
        d=$(( to - from ))
        steps=$(( (d < 0 ? -d : d) / 4 ))
        if (( steps > 60 )); then steps=60; fi
        if (( steps < 1 )); then steps=1; fi
        while (( i <= steps )); do
          to_raw $(( from + d * i / steps ))
          if [ "$rawv" != "$written" ]; then
            echo "$rawv" > "$bl/brightness" 2>/dev/null || true
            written=$rawv
          fi
          i=$(( i + 1 ))
          nap "$3"
        done
      }

      case "''${1:-status}" in
        run) ;;
        on)
          # Remember the owner's level, unless it is already ours on screen.
          if ! systemctl --user is-active --quiet golem-autobrightness.service \
             && find_backlight && read_actual && (( actual > 0 )); then
            mkdir -p "$(dirname "$manual")"
            printf '%s\n' "$actual" > "$manual"
          fi
          rm -f "$off_file"
          systemctl --user restart golem-autobrightness.service
          echo "auto brightness ON: the screen follows the room's light; the brightness keys still work. Undo: golem-autobrightness off"
          exit 0 ;;
        off)
          mkdir -p "$(dirname "$off_file")" && touch "$off_file"
          systemctl --user stop golem-autobrightness.service
          # Back to the level it had before it was switched on.
          back=""
          [ -r "$manual" ] && { read -r back < "$manual" || true; }
          case "$back" in ""|0|*[!0-9]*) back="" ;; esac
          if [ -n "$back" ] && find_backlight && read_actual && (( actual > 0 )); then
            to_p10 "$actual"; from=$p10
            to_p10 "$back"
            written=$actual
            fade "$from" "$p10" 0.016
          fi
          echo "auto brightness OFF: the screen stays where the keys put it"
          exit 0 ;;
        reset)
          rm -f "$state"
          systemctl --user try-restart golem-autobrightness.service
          echo "auto brightness: your correction is forgotten"
          exit 0 ;;
        status)
          if systemctl --user is-active --quiet golem-autobrightness.service; then echo on; else echo off; fi
          exit 0 ;;
        *) echo "usage: golem-autobrightness on|off|status|reset" >&2; exit 2 ;;
      esac

      # --- the daemon -------------------------------------------------------
      scale_u=1000000 lux_offset=0 mlux=0 lg=0 tgt=0

      find_sensor() {
        if [ -z "''${GOLEM_AUTOBRIGHTNESS_SENSOR:-}" ]; then
          sensor=
          for f in /sys/bus/iio/devices/iio:device*/in_illuminance_input \
                   /sys/bus/iio/devices/iio:device*/in_illuminance_raw; do
            [ -r "$f" ] && { sensor=$f; break; }
          done
        fi
        [ -n "$sensor" ] && [ -r "$sensor" ] || return 1
        # `_input` is lux already; `_raw` wants (raw + offset) * scale. The
        # scale is a decimal string ("0.001000000"): kept in millionths.
        scale_u=1000000 lux_offset=0
        case "$sensor" in
          *_raw)
            local s="" o="" int frac
            read -r s < "''${sensor%_raw}_scale" || true
            read -r o < "''${sensor%_raw}_offset" || true
            case "$s" in
              ""|*[!0-9.]*) ;;
              *) int=''${s%%.*}; frac=
                 case "$s" in *.*) frac=''${s#*.} ;; esac
                 frac="''${frac}000000"; frac=''${frac:0:6}
                 scale_u=$(( 10#''${int:-0} * 1000000 + 10#$frac )) ;;
            esac
            o=''${o%%.*}
            case "$o" in ""|-|*[!0-9-]*) ;; *) lux_offset=$o ;; esac ;;
        esac
        return 0
      }

      # Millilux now, in $mlux. Fails when the sensor went away (a hub reset).
      read_mlux() {
        local raw=""
        read -r raw < "$sensor" 2>/dev/null || true
        raw=''${raw%%.*}
        case "$raw" in ""|*[!0-9]*) return 1 ;; esac
        mlux=$(( (raw + lux_offset) * scale_u / 1000 ))
        if (( mlux < 0 )); then mlux=0; fi
        return 0
      }

      # 100 * log2(1 + lux), linear between the powers of two → $lg.
      log_light() {
        local l=$(( mlux + 1000 )) n=0
        while (( (l >> (n + 1)) > 0 )); do n=$(( n + 1 )); done
        lg=$(( 100 * n + 100 * (l - (1 << n)) / (1 << n) - 997 ))
        if (( lg < 0 )); then lg=0; fi
      }

      # The curve, in tenths of a percent, for a light $1: 40 % in the dark,
      # 7.3 points per doubling (100 % at 300 lx), plus the owner's offset,
      # kept inside 15–100 %.
      curve() { tgt=$(( 400 + 73 * $1 / 100 )); }
      target_for() {
        curve "$1"
        tgt=$(( tgt + offset ))
        if (( tgt > 1000 )); then tgt=1000; fi
        if (( tgt < 150 )); then tgt=150; fi
      }

      # The sensor hub can come up after the session (ISH firmware load).
      tries=0
      until find_sensor; do
        tries=$(( tries + 1 ))
        if (( tries > 5 )); then echo "golem-autobrightness: no ambient light sensor on this machine"; exit 0; fi
        nap 3
      done
      find_backlight || { echo "golem-autobrightness: no backlight on this machine"; exit 0; }
      [ -w "$bl/brightness" ] || { echo "golem-autobrightness: $bl/brightness is not writable (owner not in video?)" >&2; exit 1; }

      # The owner's offset, 20 points at most either way.
      offset=""
      [ -r "$state" ] && { read -r offset < "$state" || true; }
      case "$offset" in ""|-|*[!0-9-]*) offset=0 ;; esac
      clamp_offset() {
        if (( offset > 200 )); then offset=200; fi
        if (( offset < -200 )); then offset=-200; fi
      }
      clamp_offset
      save_offset() {
        mkdir -p "$(dirname "$state")"
        printf '%s\n' "$offset" > "$state.tmp" && mv -f "$state.tmp" "$state"
      }

      echo "golem-autobrightness: sensor $sensor, backlight $bl (max $max), offset $(( offset / 10 ))"
      # first: the start, where the screen goes to the room without waiting.
      # held: the light (lg) at which the owner set a level with the keys.
      first=1 held="" prev="" lo=0 hi=0 down=0 last=$EPOCHSECONDS
      while :; do
        now=$EPOCHSECONDS
        # A gap in the ticks = the machine slept: whatever the backlight holds
        # now came from the sleep hooks, not the owner.
        slept=0
        if (( now - last > 15 )); then slept=1; prev="" down=0; fi
        last=$now

        lid=""
        for f in /proc/acpi/button/lid/*/state; do
          [ -r "$f" ] && { read -r lid < "$f" || true; }
        done
        if [[ "$lid" == *closed* ]] || ! read_actual || (( actual == 0 )); then
          written=""; nap 2; continue
        fi
        if ! read_mlux; then
          find_sensor || true
          nap 2; continue
        fi
        log_light
        # The last two readings: the darker one decides a move up, the
        # brighter one a move down, so one odd reading (a hand, a lamp swept
        # past) moves nothing either way.
        if [ -z "$prev" ]; then prev=$lg; fi
        if (( lg < prev )); then lo=$lg hi=$prev; else lo=$prev hi=$lg; fi
        light=$(( (lo + hi) / 2 ))
        prev=$lg

        to_p10 "$actual"
        if [ -n "$written" ] && (( actual != written )) && (( slept == 0 )); then
          # Not our write: the keys. It stays until the light itself changes;
          # the curve keeps a bounded part of it.
          curve "$light"
          offset=$(( p10 - tgt ))
          clamp_offset
          save_offset
          written=$actual held=$light down=0
          echo "golem-autobrightness: owner set $(( p10 / 10 ))% at $(( mlux / 1000 )) lx (offset $(( offset / 10 )))"
          nap 2; continue
        fi
        written=$actual
        if [ -n "$held" ]; then
          # Both readings a doubling away from where the keys were used:
          # the light changed, the curve takes over again.
          if (( lo - held >= 100 || held - hi >= 100 )); then held=""
          else nap 2; continue
          fi
        fi

        target_for "$light"
        d=$(( tgt - p10 ))
        if (( first == 1 )); then
          first=0
          if (( d >= 10 || d <= -10 )); then
            fade "$p10" "$tgt" 0.016
            echo "golem-autobrightness: $(( mlux / 1000 )) lx → $(( tgt / 10 ))% (start)"
          fi
          nap 2; continue
        fi
        # 5 points of dead band (the last step up to full in the sun aside).
        # Brighter once two readings agree (~4 s), dimmer after four (~10 s),
        # and with a slower fade.
        target_for "$lo"; du=$(( tgt - p10 )); tu=$tgt
        target_for "$hi"; dd=$(( tgt - p10 )); td=$tgt
        if (( du >= 50 )) || (( tu == 1000 && du > 0 )); then
          fade "$p10" "$tu" 0.016
          down=0
          echo "golem-autobrightness: $(( mlux / 1000 )) lx → $(( tu / 10 ))%"
        elif (( dd <= -50 )); then
          down=$(( down + 1 ))
          if (( down >= 3 )); then
            fade "$p10" "$td" 0.033
            down=0
            echo "golem-autobrightness: $(( mlux / 1000 )) lx → $(( td / 10 ))%"
          fi
        else
          down=0
        fi
        nap 2
      done
    '';
  };
in
{
  environment.systemPackages = [ golem-brightness golem-autobrightness pkgs.brightnessctl ];

  # On by default wherever a sensor exists (the daemon leaves at once without
  # one). Never for the greeter's own session; off = the file, see above.
  systemd.user.services.golem-autobrightness = {
    description = "Golem auto brightness: the panel follows the ambient light sensor";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    unitConfig = {
      ConditionPathExists = "!%h/.config/golem/autobrightness-off";
      ConditionUser = "!@system";
    };
    serviceConfig = {
      ExecStart = "${golem-autobrightness}/bin/golem-autobrightness run";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # brightnessctl's udev rule: the backlight becomes group-`video` writable, and
  # the owner is in `video`. Without it the keys fail with "Operation not
  # permitted": the logind fallback refuses because under uwsm the session's
  # apps belong to the systemd-user MANAGER session, which has no seat
  # (golem-parity, thinkpad 2026-09-29: the helper existed, the write didn't).
  services.udev.packages = [ pkgs.brightnessctl ];
}
