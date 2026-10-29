# desktop/update-notice — tell the owner when an update has waited for a restart.
#
# WHY (ASUS dogfood, 2026-10-02): golem-autoupdate stages every update for the
# NEXT BOOT (a live switch once killed the session — autoupgrade-session-kill),
# and a laptop that only sleeps and hibernates never boots. The dock's
# deploy-health sensor saw the drift (stale_generation) but nothing showed it,
# so a machine could run an old system for months, security fixes included,
# without the owner ever knowing. Max: "do the notification".
#
# The rule: an update is READY when the running system is not the newest one
# built, or the newest one changes the kernel/initrd the machine booted with (a
# live switch alone needs no restart). Once it has waited 2 days, a
# notification says so — at most once a day, checked after login and every
# few hours.
#
# And when Golem CANNOT update (audit, 2026-10-29): the nightly update failing
# night after night was visible only in `systemctl --failed`, and with no
# telemetry nobody else can ever see it. base/autoupdate.nix marks when a run
# last worked and when one last failed; after 7 days without one that worked,
# and a failure since, the owner is told, at most once a day. A machine just
# turned on after weeks away says nothing until a run has really tried.
{ pkgs, ... }:

let
  notice = pkgs.writeShellApplication {
    name = "golem-update-notice";
    runtimeInputs = [ pkgs.coreutils pkgs.libnotify ];
    text = ''
      now=$(date +%s)
      state="''${XDG_STATE_HOME:-$HOME/.local/state}/golem"
      mkdir -p "$state"
      once_a_day() {   # once_a_day <name>: true at most once every 24 h
        if [ -f "$state/$1" ] && [ $(( now - $(stat -c %Y "$state/$1") )) -lt $(( 24 * 3600 )) ]; then
          return 1
        fi
        touch "$state/$1"
      }

      # Golem cannot update. Counted from the last run that worked, or from
      # the newest system when no run has worked since this check exists.
      notes=/var/lib/golem-notices
      if [ -f "$notes/update-failed" ]; then
        ok=$(cat "$notes/update-ok" 2>/dev/null || echo 0)
        newest=$(stat -c %Y "/nix/var/nix/profiles/$(readlink /nix/var/nix/profiles/system)" 2>/dev/null || echo 0)
        [ "$newest" -gt "$ok" ] && ok=$newest
        failed=$(cat "$notes/update-failed")
        if [ "$failed" -gt "$ok" ] && [ $(( now - ok )) -ge $(( 7 * 24 * 3600 )) ] && once_a_day update-stuck; then
          notify-send -a Golem "Golem could not update for $(( (now - ok) / 86400 )) days" \
            "It tries again every day and needs nothing from you but an internet connection. If this keeps coming back, restart the computer."
        fi
      fi

      latest=$(readlink -f /nix/var/nix/profiles/system) || exit 0
      current=$(readlink -f /run/current-system) || exit 0
      booted=$(readlink -f /run/booted-system) || exit 0
      ready=0
      [ "$current" != "$latest" ] && ready=1
      for f in kernel initrd; do
        [ "$(readlink -f "$booted/$f")" != "$(readlink -f "$latest/$f")" ] && ready=1
      done
      [ "$ready" = 1 ] || exit 0

      # How long it has waited: when the newest generation was made.
      # (the profile points at system-N-link; that link's own mtime is when
      # generation N was made)
      made=$(stat -c %Y "/nix/var/nix/profiles/$(readlink /nix/var/nix/profiles/system)") || exit 0
      [ $(( now - made )) -ge $(( 2 * 24 * 3600 )) ] || exit 0
      once_a_day update-notice || exit 0
      days=$(( (now - made) / 86400 ))
      notify-send -a Golem "Golem has an update ready" \
        "It has been waiting $days days. Restart when it suits you to start using it."
    '';
  };
in
{
  systemd.user.services.golem-update-notice = {
    description = "Golem: say when an update has waited for a restart";
    serviceConfig = { Type = "oneshot"; ExecStart = "${notice}/bin/golem-update-notice"; };
  };
  systemd.user.timers.golem-update-notice = {
    description = "Golem: check for an update waiting for a restart";
    wantedBy = [ "timers.target" ];
    timerConfig = { OnStartupSec = "10min"; OnUnitActiveSec = "4h"; };
  };
}
