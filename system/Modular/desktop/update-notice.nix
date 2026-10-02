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
{ pkgs, ... }:

let
  notice = pkgs.writeShellApplication {
    name = "golem-update-notice";
    runtimeInputs = [ pkgs.coreutils pkgs.libnotify ];
    text = ''
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
      now=$(date +%s)
      [ $(( now - made )) -ge $(( 2 * 24 * 3600 )) ] || exit 0

      # At most once a day.
      state="''${XDG_STATE_HOME:-$HOME/.local/state}/golem/update-notice"
      mkdir -p "$(dirname "$state")"
      if [ -f "$state" ] && [ $(( now - $(stat -c %Y "$state") )) -lt $(( 24 * 3600 )) ]; then
        exit 0
      fi
      days=$(( (now - made) / 86400 ))
      notify-send -a Golem "Golem has an update ready" \
        "It has been waiting $days days. Restart when it suits you to start using it."
      touch "$state"
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
