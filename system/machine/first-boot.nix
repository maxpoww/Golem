# machine/first-boot — THE ONE-TIME CONVERGENCE of a machine of the
# /etc/nixos layout. (The twin of base/first-boot.nix, which says at length
# why it exists.)
#
# An installed Golem boots a system that was BAKED on the medium and copied
# as it is: generic — the broad "boots on anything" initrd, the medium's own
# account, hostname and language — because nothing is ever built on the
# target during the install (a 2 GB machine cannot). The machine's own
# answers and measured hardware are already in /etc/nixos; this builds them,
# once, online and behind the owner's first session:
#
#   golem-update --converge     the newest Golem of the branch, merged into
#                               root's copy (/etc/nixos/golem), and this
#                               machine's own system built from the folder —
#                               even when there is no newer version
#
# `boot`, not `switch`: the new system starts at the next restart (the
# account is renamed to the owner's then, base/users.nix).
#
# Only where the INSTALLER asked for it: it leaves
# /var/lib/golem/first-boot.pending, and the run that succeeds removes it. A
# machine built any other way (a rebuild from its folder) has no such file
# and never runs this. A run that fails (no network yet) leaves the file:
# the network gives another try in an hour, anything else at the next start.
{ config, lib, pkgs, ... }:

let
  pending = "/var/lib/golem/first-boot.pending";
  golemWaitOnline = import ../Modular/base/wait-online.nix pkgs;
in
{
  systemd.timers.golem-first-boot = {
    description = "Golem first boot, shortly after the start";
    wantedBy = [ "timers.target" ];
    timerConfig.OnBootSec = "30s";
  };

  systemd.services.golem-first-boot = {
    description = "Golem first boot: build this machine's own system from /etc/nixos (once)";
    # Started by its TIMER, never by a boot target: a oneshot wanted by
    # multi-user.target holds every target after it, graphical.target too,
    # and the first session sat on a black screen for the whole rebuild
    # (2026-09-26, and again 2026-10-01).
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    unitConfig.ConditionPathExists = pending;
    restartIfChanged = false;
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = "infinity";   # a whole first build on a slow disk
      # The owner is using the machine meanwhile: stay out of the way, and
      # do not start until the desktop is up (base/quiet-login).
      Nice = 19;
      IOSchedulingClass = "idle";
      ExecStartPre = lib.optional (config.golem ? quietLogin) "${config.golem.quietLogin}/bin/golem-quiet-login";
      # 75 = the network, not the build: again in an hour.
      RestartForceExitStatus = "75";
      RestartSec = "1h";
    };
    path = [ config.golem.machine.updateCommand pkgs.coreutils ];
    script = ''
      set -euo pipefail   # a failed build must not reach the last line
      ${golemWaitOnline}/bin/golem-wait-online || exit 75
      echo "first-boot: building this machine's own system (its answers, its measured hardware)…"
      golem-update --converge
      rm -f ${lib.escapeShellArg pending}
      echo "first-boot: done; this machine's own system starts at the next restart."
    '';
  };
}
