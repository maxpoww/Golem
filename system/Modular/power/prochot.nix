# power/prochot — a CPU held at its slowest by the PLATFORM, not by heat.
#
# Max, 2026-10-20: "make golem unlock all macbooks, or any other pc with
# this kind of shit". The lab MacBook Air had run at 800 MHz — a third of
# its speed, for everything, for weeks — because its battery is dead. With
# no battery to soften a power spike, Apple's SMC holds the CPU's PROCHOT
# line ("processor hot") and the CPU sits at its lowest clock. Nothing was
# hot (51 °C, no thermal throttle ever counted): the CPU's own register said
# the line was held from OUTSIDE. Dells and Lenovos do the same with a dead
# battery or a charger their firmware does not recognise.
#
# WHAT THIS DOES — on an Intel CPU, when the platform holds PROCHOT while
#   - the CPU itself is cool (20 °C or more under its throttle point),
#   - the machine runs on the charger (or has no battery at all), and
#   - both are still true five seconds later,
# it clears BD PROCHOT (MSR 0x1FC bit 0): the CPU stops obeying the outside
# line. The CPU's OWN thermal protection is untouched — a CPU that really
# heats up still slows itself down.
#
# WHEN — at boot, after every wake (the firmware sets the bit again) and on
# every power-supply event (a charger in or out, a battery report). No
# polling. Off the charger the bit goes back on at once: on battery the
# platform's brake may be protecting the battery, and it is never ours to
# take there. A new battery or the right charger stops the line being held
# and this finds nothing to do.
#
# THE PRICE — with no working battery nothing absorbs a sudden spike, so a
# heavy load could cut the power: keep the charger in. Not for AMD (no such
# switch) nor a virtual machine; there it does nothing.
#
# Proven on the MacBook Air 6,2 (i5-4250U): 800 → 2300 MHz under load.
{ pkgs, lib, ... }:

let
  sleeps = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" "suspend-then-hibernate.target" ];

  release = pkgs.writeShellApplication {
    name = "golem-prochot";
    runtimeInputs = [ pkgs.msr-tools pkgs.kmod pkgs.coreutils ];
    text = ''
      marker=/run/golem-prochot.released

      # The first CPU's register, as 0x…; fails where there is none (AMD, a VM).
      msr() { rdmsr -p 0 -c "$1" 2>/dev/null; }

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

      battery() {
        local ps
        for ps in /sys/class/power_supply/*; do
          [ "$(cat "$ps/type" 2>/dev/null)" = Battery ] || continue
          echo "$(cat "$ps/capacity" 2>/dev/null || echo ?) %, $(cat "$ps/status" 2>/dev/null || echo ?)"
          return
        done
        echo "none"
      }

      # 0 = the platform holds PROCHOT on a cool CPU that runs on the charger
      # (sets $temp, °C, for the log); 2 = the same but the CPU is hot — it
      # may cool (a pinned CPU does, fast); 1 = nothing to do.
      held() {
        local ctl therm margin target tj=100
        on_mains || return 1
        ctl=$(msr 0x1fc) || return 1
        (( ctl & 1 )) || return 1               # already released
        therm=$(msr 0x19c) || return 1
        (( therm >> 2 & 1 )) || return 1        # nobody outside holds the line
        (( therm >> 31 & 1 )) || return 1       # no valid reading: hands off
        (( therm & 1 )) && return 2             # at its own throttle point
        margin=$(( therm >> 16 & 0x7f ))        # degrees under the throttle point
        (( margin >= 20 )) || return 2
        target=$(msr 0x1a2) && tj=$(( target >> 16 & 0xff ))
        temp=$(( tj - margin ))
      }

      # Bit 0 of 0x1FC on every CPU: 0 = released, 1 = the platform's say.
      set_bit() {
        local ctl
        ctl=$(msr 0x1fc) || return 1
        wrmsr -a 0x1fc $(( $1 ? ctl | 1 : ctl & ~1 ))
      }

      modprobe msr 2>/dev/null || true
      msr 0x1fc >/dev/null || exit 0           # no such switch here

      if [ -e "$marker" ] && ! on_mains; then
        set_bit 1 && rm -f "$marker" \
          && echo "golem-prochot: off the charger — the platform's PROCHOT is obeyed again (battery: $(battery))"
        exit 0
      fi

      # Held twice, five seconds apart. Too hot: look again every 10 s for up
      # to 3 minutes — an event that came while the CPU was warm is not lost.
      temp=
      for _ in $(seq 18); do
        state=0; held || state=$?
        if (( state == 0 )); then
          sleep 5
          state=0; held || state=$?
          (( state == 0 )) && break
        fi
        (( state == 2 )) || exit 0
        sleep 10
      done
      (( state == 0 )) || exit 0
      if set_bit 0 && ! (( $(msr 0x1fc) & 1 )); then
        touch "$marker"
        echo "golem-prochot: the platform held the CPU at its slowest (PROCHOT) while it was cool (''${temp} °C) and on mains power — released (battery: $(battery))"
      else
        echo "golem-prochot: PROCHOT is held but the CPU refused the write (locked down?) — left as it is"
      fi
    '';
  };
in
{
  boot.kernelModules = [ "msr" ];

  systemd.services.golem-prochot = {
    description = "Release a CPU the platform holds at its slowest while it is cool and on the charger (BD PROCHOT)";
    wantedBy = [ "multi-user.target" ] ++ sleeps;
    after = sleeps;
    unitConfig = {
      ConditionVirtualization = "no";
      StartLimitIntervalSec = 0;   # power-supply events come in bursts
    };
    # Simple, not oneshot: the boot (and a wake) never waits on its five-second
    # look or its three cool-down minutes; a start while it runs is a no-op.
    serviceConfig = {
      Type = "simple";
      ExecStart = lib.getExe release;
    };
  };

  # A charger in or out, a battery report: look again.
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ACTION=="change", RUN+="${pkgs.systemd}/bin/systemctl --no-block start golem-prochot.service"
  '';
}
