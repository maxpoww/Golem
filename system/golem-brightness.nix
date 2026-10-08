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
  #     (brightnessctl -e4): 50 % in the dark, +12.5 points per decade of lux,
  #     100 % at 10 000 lx;
  #   - the brightness KEYS still work and TEACH it: a change it did not make is
  #     the owner's, kept as an offset to the curve (state file below), so "a bit
  #     brighter than you think" survives the next cloud and the next boot. The
  #     first run takes the level it finds as right: turning it on moves nothing;
  #   - it moves only for a change worth 3 points, once two readings in a row
  #     agree, in one ramp of a second at most: no flicker under a lamp, nothing
  #     for a hand passing over the sensor;
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

      ${pick}
      case "''${1:-status}" in
        run) ;;
        on)
          rm -f "$off_file"
          systemctl --user start golem-autobrightness.service
          echo "auto brightness ON: the screen follows the room's light; the brightness keys still work and it remembers your correction. Undo: golem-autobrightness off"
          exit 0 ;;
        off)
          mkdir -p "$(dirname "$off_file")" && touch "$off_file"
          systemctl --user stop golem-autobrightness.service
          echo "auto brightness OFF: the screen stays where the keys put it"
          exit 0 ;;
        reset)
          rm -f "$state"
          systemctl --user try-restart golem-autobrightness.service
          echo "auto brightness: your correction is forgotten; the level on screen now is the new reference"
          exit 0 ;;
        status)
          if systemctl --user is-active --quiet golem-autobrightness.service; then echo on; else echo off; fi
          exit 0 ;;
        *) echo "usage: golem-autobrightness on|off|status|reset" >&2; exit 2 ;;
      esac

      # --- the daemon -------------------------------------------------------
      # Both overridable for the test rig (a fake /sys in a temp dir).
      sensor="''${GOLEM_AUTOBRIGHTNESS_SENSOR:-}"
      bl="''${GOLEM_AUTOBRIGHTNESS_BACKLIGHT:-}"
      scale_u=1000000 lux_offset=0

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

      # The curve: tenths of a percent for a smoothed light, plus the owner's
      # offset, kept inside 15–100 %. 376/1000 per lg = 12.5 points per decade.
      target_for() {
        tgt=$(( 500 + 376 * $1 / 1000 + offset ))
        if (( tgt > 1000 )); then tgt=1000; fi
        if (( tgt < 150 )); then tgt=150; fi
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

      # The sensor hub can come up after the session (ISH firmware load).
      tries=0
      until find_sensor; do
        tries=$(( tries + 1 ))
        if (( tries > 5 )); then echo "golem-autobrightness: no ambient light sensor on this machine"; exit 0; fi
        nap 3
      done
      if [ -z "$bl" ]; then
        dev=$(pick) || { echo "golem-autobrightness: no backlight on this machine"; exit 0; }
        bl=/sys/class/backlight/$dev
      fi
      max=""
      read -r max < "$bl/max_brightness" || true
      case "$max" in ""|0|*[!0-9]*) echo "golem-autobrightness: $bl has no usable range"; exit 0 ;; esac
      [ -w "$bl/brightness" ] || { echo "golem-autobrightness: $bl/brightness is not writable (owner not in video?)" >&2; exit 1; }

      offset=""
      [ -r "$state" ] && { read -r offset < "$state" || true; }
      case "$offset" in ""|-|*[!0-9-]*) offset="" ;; esac
      save_offset() {
        mkdir -p "$(dirname "$state")"
        printf '%s\n' "$offset" > "$state.tmp" && mv -f "$state.tmp" "$state"
      }

      echo "golem-autobrightness: sensor $sensor, backlight $bl (max $max)"
      smooth="" prev="" written="" hold=0 last=$EPOCHSECONDS
      while :; do
        now=$EPOCHSECONDS
        # A gap in the ticks = the machine slept: whatever the backlight holds
        # now came from the sleep hooks, not the owner.
        slept=0
        if (( now - last > 15 )); then slept=1; smooth="" prev=""; fi
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
        # The light counts once two readings in a row agree (within a third):
        # a hand over the sensor or a passing shadow moves nothing, and a real
        # change gets ONE ramp 2–4 s later instead of a staircase.
        settled=0
        if [ -z "$smooth" ]; then smooth=$lg; fi
        if [ -n "$prev" ] && (( lg - prev <= 40 && prev - lg <= 40 )); then
          settled=1; smooth=$(( (lg + prev) / 2 ))
        fi
        prev=$lg

        to_p10 "$actual"
        if [ -z "$offset" ]; then
          # First run: the level found is the reference.
          offset=$(( p10 - 500 - 376 * smooth / 1000 ))
          save_offset
          written=$actual
        elif [ -n "$written" ] && (( actual != written )) && (( slept == 0 )); then
          # Not our write: the keys. Learn it, and leave it alone a moment.
          offset=$(( p10 - 500 - 376 * smooth / 1000 ))
          if (( offset > 700 )); then offset=700; fi
          if (( offset < -700 )); then offset=-700; fi
          save_offset
          written=$actual hold=2
          echo "golem-autobrightness: owner set $(( p10 / 10 ))% at $(( mlux / 1000 )) lx (offset $(( offset / 10 )))"
          nap 2; continue
        fi
        written=$actual
        if (( hold > 0 )); then hold=$(( hold - 1 )); nap 2; continue; fi

        target_for "$smooth"
        d=$(( tgt - p10 ))
        # 3 points of dead band, except for the last step up to full in the sun.
        if (( settled == 1 )) && (( d >= 30 || d <= -30 || (tgt == 1000 && d > 0) )); then
          if (( d < 4 )) && (( d > 0 )); then d=4; fi
          steps=$(( (d < 0 ? -d : d) / 4 ))
          if (( steps > 60 )); then steps=60; fi
          i=1
          while (( i <= steps )); do
            to_raw $(( p10 + d * i / steps ))
            if (( rawv != written )); then
              echo "$rawv" > "$bl/brightness" 2>/dev/null || true
              written=$rawv
            fi
            i=$(( i + 1 ))
            nap 0.016
          done
          echo "golem-autobrightness: $(( mlux / 1000 )) lx → $(( tgt / 10 ))%"
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
