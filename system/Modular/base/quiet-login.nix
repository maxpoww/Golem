# base/quiet-login — heavy background jobs wait until the owner's desktop is UP.
#
# WHY (ThinkPad on a USB spinning disk, 2026-10-01): the first boot after an
# install showed a black screen with a pointer for ~50 s before the dock and
# the bar appeared. The dock itself needs ~7 s of cold reads there (its
# libraries 6.7 s, fonts 5.4 s, measured on a quiet disk). The rest was
# golem-first-boot's rebuild (30 s after boot) seeking the same disk: with it
# running, the disk gave the login 20 MB/s instead of 55 and LLVM alone took
# 34 s to read instead of 2.7. IOSchedulingClass=idle (honoured, bfq) is not
# enough on a rotating disk: every seek the rebuild wins costs the login one.
# The same applies to nix-gc: a daily Persistent timer with no delay, so a
# laptop that was off at midnight collected garbage right at boot.
#
# The gate (ExecStartPre): wait until the desktop shell (the waverunner dock)
# has been running for 60 s — the login is over and its files are cached —
# or until 5 min after boot with nobody logged in (the machine is idle at the
# greeter; go ahead). A system without the desktop greeter does not wait.
{ config, pkgs, lib, ... }:

let
  hasDesktop = config.services.greetd.enable or false;
  gate = pkgs.writeShellApplication {
    name = "golem-quiet-login";
    runtimeInputs = [ pkgs.procps pkgs.coreutils pkgs.gawk pkgs.getconf ];
    text = ''
      ${lib.optionalString (!hasDesktop) "exit 0"}
      hz=$(getconf CLK_TCK)
      # The dock's age on the MONOTONIC clock: `ps etimes` counts from the
      # wall-clock boot time, and a clock corrected after boot (a dead CMOS
      # battery: the laptop woke in 2020, NTP moved it to today) made every
      # process "6 years old" and opened the gate at once (Acer, 2026-10-03).
      shell_age() {
        local pid st
        pid=$(ps -eo pid=,args= | awk '$2 ~ /\/bin\/waverunner$/ { print $1; exit }')
        [ -n "$pid" ] || return 0
        st=$(cat "/proc/$pid/stat" 2>/dev/null) || return 0
        st=''${st##*) }   # after the command name (which may hold spaces)
        awk -v up="$(cut -d' ' -f1 /proc/uptime)" -v hz="$hz" '{ printf "%d\n", up - $20 / hz }' <<< "$st"
      }
      for _ in $(seq 1 720); do
        shell_age=$(shell_age)
        if [ -n "$shell_age" ] && [ "$shell_age" -ge 60 ]; then
          exit 0
        fi
        up=$(cut -d. -f1 /proc/uptime)
        if [ -z "$shell_age" ] && [ "$up" -ge 300 ]; then
          exit 0
        fi
        sleep 5
      done
      exit 0   # never hold a job forever (1 h cap)
    '';
  };
in
{
  options.golem.quietLogin = lib.mkOption {
    type = lib.types.package;
    internal = true;
    readOnly = true;
    default = gate;
    description = "Waits until the desktop is up (or the machine idles at the greeter) before heavy background work.";
  };

  config = {
    systemd.services.nix-gc.serviceConfig.ExecStartPre = lib.mkBefore [ "${gate}/bin/golem-quiet-login" ];
    systemd.services.nix-gc.serviceConfig.TimeoutStartSec = "infinity";
  };
}
