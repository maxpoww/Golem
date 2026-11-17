# power/gpu-floor — on the charger, Intel graphics may not idle at its
# slowest clock: the desktop then misses every other refresh of a fast screen.
#
# Max, 2026-11-15: "what i want is the screens to be able to get as much fps
# as posible (if a user have a 240hz monitor … they want their 240 or similar)
# or they go to another distro". Measured that night on the dev box (Iris Xe,
# 3200x2000 at 165 Hz, gears under a see-through terminal, 11 s a setting):
#
#   performance mode                               162 to 164 frames a second
#   balanced mode, the chip free to idle (100 MHz)  81, 83, 96
#   balanced, its clock at 600 MHz least            122, 160, 88
#   balanced, at 900 MHz least                      161, 142, 160
#   balanced, at 1200 MHz least                     161, 161, 161
#   balanced, at 1500 MHz least                     162, 163, 163
#
# (Three passes each, one scene; the CPU mostly at its slow balanced clock,
# about 900 MHz.) The driver picks the chip's clock from
# how busy it is, and a desktop that draws one small frame every 6 ms never
# looks busy: it sat at 300 to 1100 of 1500 MHz while each frame came a little
# too late for its refresh, so the screen showed every other one. A floor
# under the clock is all it takes.
#
# WHAT THIS DOES — on the charger (or with no battery at all), with a FAST
# SCREEN connected (one whose EDID names a rate over 75 Hz), the lowest clock
# Intel graphics may use is set to 80 % of its highest (1200 of 1500 MHz
# there: the lowest value that held the full rate in every pass). Off the
# charger, or with only 60 Hz screens, it is the hardware's own lowest: on the
# battery it matters more and Golem's screens go to 60 Hz anyway, and a 60 Hz
# screen gives a frame 16 ms — the lab's Haswell laptops (200 to 1000 MHz,
# 60 Hz panels) are left exactly as they were. The floor only counts while
# the chip is awake: asleep (RC6), it draws what it always did.
#
# A screen's top rate is read from its whole EDID (edid-top-hz.awk): the
# first block's range of rates and timings, and every extension's — CTA-861
# timings and video codes, DisplayID timings and ranges. The dev box's own
# panel flags 3200x2000@60 and lists 165 only in a DisplayID block; the first
# block alone found it there only through its range of rates.
#
# WHEN — at boot, after every wake, on every power-supply event and when a
# screen is plugged in or out. No polling. Other graphics (AMD, NVIDIA, a
# virtual machine) have no such file and nothing is done.
{ pkgs, lib, ... }:

let
  sleeps = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" "suspend-then-hibernate.target" ];

  floor = pkgs.writeShellApplication {
    name = "golem-gpu-floor";
    runtimeInputs = [ pkgs.coreutils pkgs.gawk ];
    text = ''
      # On the charger — or no battery at all (a desktop, a battery taken out).
      on_mains() {
        local ps battery=no
        for ps in /sys/class/power_supply/*; do
          [ -r "$ps/type" ] || continue
          case "$(cat "$ps/type")" in
            Mains|USB|USB_C|USB_PD)
              [ "$(cat "$ps/online" 2>/dev/null)" = 1 ] && return 0 ;;
            Battery) battery=yes ;;
          esac
        done
        [ "$battery" = no ]
      }

      # The highest refresh rate a panel's EDID names anywhere, in Hz; 0 when
      # it cannot be read.
      edid_top_hz() {
        od -An -v -tu1 -w1 "$1" 2>/dev/null | awk -f ${./edid-top-hz.awk}
      }

      # A connected screen that can show more than 75 frames a second.
      fast_screen() {
        local out
        for out in /sys/class/drm/card[0-9]*-*; do
          [ "$(cat "$out/status" 2>/dev/null)" = connected ] || continue
          [ "$(edid_top_hz "$out/edid")" -gt 75 ] && return 0
        done
        return 1
      }

      # One chip: its lowest allowed clock (file $1) between the hardware's
      # own lowest ($2) and highest ($3), all in MHz.
      set_floor() {
        local min=$1 lowest highest want now
        lowest=$(cat "$2" 2>/dev/null) || return 0
        highest=$(cat "$3" 2>/dev/null) || return 0
        [ "$highest" -gt "$lowest" ] 2>/dev/null || return 0
        if [ "$fast" = yes ]; then
          want=$(( highest * 80 / 100 ))
          [ "$want" -lt "$lowest" ] && want=$lowest
        else
          want=$lowest
        fi
        now=$(cat "$min" 2>/dev/null) || return 0
        [ "$now" = "$want" ] && return 0
        if echo "$want" > "$min" 2>/dev/null; then
          echo "golem-gpu-floor: $(dirname "$min"): lowest clock $now -> $want MHz (of $highest)"
        fi
      }

      shopt -s nullglob
      fast=no
      if on_mains && fast_screen; then fast=yes; fi
      # i915.
      for card in /sys/class/drm/card[0-9]*; do
        [ -w "$card/gt_min_freq_mhz" ] || continue
        set_floor "$card/gt_min_freq_mhz" "$card/gt_RPn_freq_mhz" "$card/gt_RP0_freq_mhz"
      done
      # xe (the newer driver): one folder a graphics engine.
      for gt in /sys/class/drm/card[0-9]*/device/tile*/gt*/freq0; do
        [ -w "$gt/min_freq" ] || continue
        set_floor "$gt/min_freq" "$gt/rpn_freq" "$gt/rp0_freq"
      done
    '';
  };
in
{
  systemd.services.golem-gpu-floor = {
    description = "On the charger, Intel graphics keeps a clock fast enough for every refresh of the screen";
    wantedBy = [ "multi-user.target" ] ++ sleeps;
    after = sleeps;
    unitConfig = {
      ConditionVirtualization = "no";
      StartLimitIntervalSec = 0;   # power-supply events come in bursts
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe floor;
    };
  };

  # A charger in or out, a screen plugged in or out: set it again.
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ACTION=="change", RUN+="${pkgs.systemd}/bin/systemctl --no-block start golem-gpu-floor.service"
    SUBSYSTEM=="drm", ACTION=="change", RUN+="${pkgs.systemd}/bin/systemctl --no-block start golem-gpu-floor.service"
  '';
}
