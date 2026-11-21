# machine/update — THE NIGHTLY UPDATE of a machine of the /etc/nixos layout.
#
# The twin of base/autoupdate.nix (the checkout-in-a-home layout), and much
# shorter: Standard is root's own copy there (/etc/nixos/standard), so nothing has
# to be vouched for, healed, sealed or done "as the owner". What is the same,
# on purpose, is everything an owner or the desktop can see:
#
#   golem-autoupdate.service/.timer   the same names, the same moment of the
#                                     night per machine, a missed run made up
#                                     at the next start
#   golem-update-now.service          Controls → Updates → Update now
#                                     (desktop/care.nix lets the owner start
#                                     it without a password)
#   /var/lib/golem-notices/update-*   what desktop/update-notice.nix reads to
#                                     say "Standard could not update"
#   exit 75                           the network, not the version: the run
#                                     comes back in an hour, nothing was built
#   `boot`, never `switch`            the new version starts at the next
#                                     restart; a running session is not
#                                     touched
#
# The update itself is `golem-update --nightly` (./layout.nix): this
# machine's wave, the versions held after a crash loop, the merge of the new
# version into root's copy with its edits kept, the build from a root-only
# try, and /etc/nixos moved only when it built.
{ config, lib, pkgs, ... }:

let
  golemWaitOnline = import ../Modular/base/wait-online.nix pkgs;
  golemSay = pkgs.callPackage ../i18n/golem-say.nix { };
  # A system without one (the VMs boot their kernel directly) has no boot
  # entry to check.
  bootMenu = config.boot.loader.grub.enable || config.boot.loader.systemd-boot.enable;
  owner = config.standard.owner;
in
{
  # On the system PATH, as on the other layout: every updater shares one gate.
  environment.systemPackages = [ golemWaitOnline ];

  systemd.services.golem-autoupdate = {
    description = "Golem self-update: gate on the network, merge the new version into root's copy, rebuild boot";
    serviceConfig.Type = "oneshot";
    # Behind the owner (base/autoupdate.nix says why): nice, the idle I/O
    # class, and not during a login.
    serviceConfig.Nice = 19;
    serviceConfig.IOSchedulingClass = "idle";
    serviceConfig.CPUWeight = 20;
    serviceConfig.ExecStartPre = lib.optional (config.standard ? quietLogin) "${config.standard.quietLogin}/bin/golem-quiet-login";
    serviceConfig.RestartForceExitStatus = "75";
    serviceConfig.RestartSec = "1h";
    restartIfChanged = false;   # a switch never waits on it
    path = [ config.standard.machine.updateCommand pkgs.coreutils pkgs.gnugrep pkgs.util-linux ];
    script = ''
      set -euo pipefail   # a failed update marks the service failed (visible), not silent

      # What the owner's desktop reads to say "Standard could not update"
      # (desktop/update-notice.nix): when a run last worked, and when one
      # last failed. These files never leave the machine. Waiting for the
      # wave is a run that worked.
      notes=/var/lib/golem-notices
      finish() {
        local rc=$?
        install -d -m 755 "$notes"
        if [ "$rc" = 0 ]; then
          date +%s > "$notes/update-ok"; rm -f "$notes/update-failed"
        else
          date +%s > "$notes/update-failed"
        fi
        chmod 644 "$notes"/update-* 2>/dev/null || true
      }
      trap finish EXIT

      # The newest system must be what the machine boots next (a rebuild
      # whose boot-menu step failed on a full /boot left the machine looking
      # up to date while every restart booted the old version: audit,
      # 2026-10-29). Write the entry again; a menu that still lacks it fails
      # the run loudly.
      in_boot_menu() {
        local sys
        sys=$(readlink -f /nix/var/nix/profiles/system)
        grep -rqsF "init=$sys/init" /boot/grub/grub.cfg /boot/loader/entries 2>/dev/null
      }
      ensure_boot_entry() {
        ${lib.optionalString (!bootMenu) "return 0   # no boot menu here (a VM booted directly)"}
        in_boot_menu && return 0
        echo "golem-autoupdate: the newest system is not in the boot menu, writing it again" >&2
        /nix/var/nix/profiles/system/bin/switch-to-configuration boot || true
        in_boot_menu && return 0
        df -h /boot >&2 || true
        echo "golem-autoupdate: the boot menu still lacks the newest system (is /boot full?)" >&2
        return 1
      }

      # Real connectivity or a loud give-up that comes back in an hour.
      ${golemWaitOnline}/bin/golem-wait-online || exit 75

      asked_now=0; [ -e /run/golem-update-now ] && asked_now=1
      before=""; [ -f /var/lib/golem/local-edits/latest ] && before=$(cat /var/lib/golem/local-edits/latest)
      rc=0
      golem-update --nightly || rc=$?
      if [ "$rc" = 75 ]; then
        # "Update now" stays asked for the hour's retry (not its wave).
        if [ "$asked_now" = 1 ]; then touch /run/golem-update-now; fi
        exit 75
      fi
      [ "$rc" = 0 ] || exit "$rc"

      # Files of Standard's that root had changed AND the new version changed
      # too were set aside: the owner is told where, in their language.
      after=""; [ -f /var/lib/golem/local-edits/latest ] && after=$(cat /var/lib/golem/local-edits/latest)
      if [ -n "$after" ] && [ "$after" != "$before" ]; then
        home=${lib.escapeShellArg config.users.users.${owner}.home}
        say() { GOLEM_SETTINGS="$home/.config/golem/settings.json" ${golemSay}/bin/golem-say "$@"; }
        uid=$(id -u ${lib.escapeShellArg owner})
        if [ -S "/run/user/$uid/bus" ]; then
          runuser -u ${lib.escapeShellArg owner} -- env DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
            ${pkgs.libnotify}/bin/notify-send -a Golem "$(say "Golem kept your edits aside")" \
            "$(say "Files of Standard's that were changed on this computer were copied to {0} so Golem could update." "$after")" || true
        fi
      fi

      ensure_boot_entry || exit 1
    '';
  };

  # UPDATE NOW (the Controls page's button): one run that skips this
  # machine's wave — the marker the update honours, then the service.
  systemd.services.golem-update-now = {
    description = "Golem self-update now, skipping this machine's wave";
    serviceConfig.Type = "oneshot";
    script = ''
      touch /run/golem-update-now
      ${pkgs.systemd}/bin/systemctl start --no-block golem-autoupdate.service
    '';
  };

  systemd.timers.golem-autoupdate = {
    description = "Daily Standard self-update";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      # Each machine its own moment between midnight and 6:00, the same every
      # night; a machine that was off at its moment runs a few minutes after
      # it is turned on (base/autoupdate.nix has the why of each line).
      RandomizedOffsetSec = "6h";
      Persistent = true;
      RandomizedDelaySec = "10min";
      FixedRandomDelay = true;
    };
  };
}
