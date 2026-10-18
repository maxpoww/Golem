# base/store-check — every path's contents against its hash, weekly, and
# whatever is damaged fetched again. Moved out of base/nix.nix (2026-10-17)
# so the dev box, whose nix settings are its own (channels), runs the same
# check as every installed Golem (parity P20; Max: "make it work as any
# other Golem machine").
{ config, ... }:

{
  imports = [ ./quiet-login.nix ];

  # A WEEKLY store check: every path's contents against its hash, and
  # whatever is damaged fetched again (--repair). A store can be damaged
  # without anyone noticing — the ASUS's power cut on 2026-10-03 left two
  # paths "modified" that Nix trusted as valid (before fsync-store-paths),
  # and a failing disk does the same. Idle IO, after the desktop is up
  # (base/quiet-login's gate), caught up if the laptop was off; ~15 min on a
  # spinning disk.
  systemd.services.golem-store-check = {
    description = "Golem: check the store's contents and repair what is damaged";
    restartIfChanged = false;   # as nix-gc (store-gc.nix): a switch never starts it
    path = [ config.nix.package ];
    serviceConfig = {
      Type = "oneshot";
      Nice = 19;
      IOSchedulingClass = "idle";
      ExecStartPre = [ "${config.golem.quietLogin}/bin/golem-quiet-login" ];
      TimeoutStartSec = "infinity";
    };
    script = ''
      out=$(nix-store --verify --check-contents --repair 2>&1) || true
      bad=$(printf '%s\n' "$out" | grep -c "was modified" || true)
      echo "golem-store-check: $bad damaged path(s) found and repaired"
      printf '%s\n' "$out" | grep "was modified" || true
    '';
  };
  systemd.timers.golem-store-check = {
    wantedBy = [ "timers.target" ];
    timerConfig = { OnCalendar = "weekly"; Persistent = true; RandomizedDelaySec = "6h"; };
  };
}
