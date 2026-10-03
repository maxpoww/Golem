# base/first-boot — the ONE-TIME convergence, stage 0.
#
# WHY THIS EXISTS (2026-09-26 audit, .150/.149/.242). An installed Golem
# boots the DIRECT-COPY baked gen-1: a generic toplevel with the
# "boots-on-anything" broad initrd (~25 modules), hostname always "Golem",
# timezone UTC — because a direct copy never runs nixos-generate-config or
# applies machine.nix. Install-time convergence was pulled (it did a full
# offline rebuild and died on the 2 GB comodore, the exact target build 8e
# exists to avoid). So the convergence moves to FIRST BOOT, where it is ONLINE
# (cache.nixos.org reachable) and non-blocking:
#
#   ONE rebuild of the seed's real golem-minimal — which imports the
#   installer-MEASURED hardware-configuration.nix (real disk → TRIMMED initrd)
#   and machine.nix (real hostname / timezone / keyboard). The result is
#   staged for the next reboot; after it, the machine runs its own hardware,
#   not the generic floor. (base/locale.nix was built convergence-safe — its
#   fixed locale archive hashes identically before and after — for exactly
#   this rebuild.)
#
# `boot`, not `switch`: never restart a live service during the lab phase (a
# switch that restarts sshd would drop the lab door mid-rebuild). The new
# generation goes live on the next natural reboot. Runs ONCE — a stamp in
# /var/lib/golem (the seal's root-owned dir) is written only on SUCCESS, so a
# run that fails (no network, eval error) simply retries next boot rather than
# stranding the machine on gen-1. Guarded on golem.flakeDir like its siblings.
{ config, pkgs, lib, ... }:

let
  stamp = "/var/lib/golem/first-boot.done";
  golemWaitOnline = "${pkgs.writeShellApplication {
    name = "golem-wait-online-fb";
    runtimeInputs = [ pkgs.curl pkgs.coreutils ];
    text = ''
      for _ in $(seq 1 90); do
        curl -fsS --max-time 8 -o /dev/null "https://cache.nixos.org/nix-cache-info" && exit 0
        sleep 10
      done
      echo "first-boot: offline after 15 min — will retry next boot" >&2
      exit 1
    '';
  }}/bin/golem-wait-online-fb";
in
lib.mkIf (config.golem.flakeDir != null) {
  systemd.timers.golem-first-boot = {
    description = "Golem first-boot convergence, shortly after boot";
    wantedBy = [ "timers.target" ];
    timerConfig.OnBootSec = "30s";
  };

  systemd.services.golem-first-boot = {
    description = "Golem first-boot convergence: rebuild onto measured hardware + machine.nix (once)";
    # Started by its TIMER (below), never by a boot target. A oneshot wanted
    # by multi-user.target holds every target after it until it finishes —
    # graphical.target too — so the desktop's session (uwsm waits for
    # graphical.target) sat on a black screen for the whole first rebuild
    # (the 2026-09-26 "can't reach graphical" bug, found again installing the
    # desktop-baked ISO in a VM, 2026-10-01). A timer-started unit is outside
    # the boot transaction: the desktop comes up at once, this converges
    # quietly behind it.
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    # Runs ONCE: skip if the stamp is already there.
    unitConfig.ConditionPathExists = "!${stamp}";
    restartIfChanged = false;   # a switch never waits on it (base/nix.nix, nix-gc)
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = "infinity";   # a full first rebuild on a slow disk/2 GB box
      # The owner is using the machine meanwhile: stay out of the way.
      Nice = 19;
      IOSchedulingClass = "idle";
      # ...and do not start until the desktop is up (base/quiet-login): on a
      # spinning disk this rebuild's seeks made the first login a ~50 s black
      # screen even at idle IO priority (ThinkPad, 2026-10-01).
      ExecStartPre = [ "${config.golem.quietLogin}/bin/golem-quiet-login" ];
    };
    path = [ config.nix.package pkgs.coreutils ];
    script = ''
      set -euo pipefail   # -e: a failed rebuild must NOT reach the stamp below
      dir=${lib.escapeShellArg config.golem.flakeDir}
      attr=${lib.escapeShellArg config.golem.flakeAttr}

      ${golemWaitOnline} || exit 1

      # The seed becomes a checkout of the upstream now that the network is
      # there (base/seed.nix); it re-seals itself, so this comes BEFORE the
      # seal baseline below.
      ${config.golem.seed.adopt}/bin/golem-seed-adopt || true

      # Establish the seal baseline (trust-on-first-use: seals what the
      # installer wrote), then stage the machine's real configuration.
      ${config.golem.seal.check}/bin/golem-seal-check || {
        echo "first-boot: seal check failed — refusing to converge" >&2; exit 1; }

      echo "first-boot: converging onto measured hardware + machine.nix (boot)…"
      ${config.golem.rebuild}/bin/golem-rebuild boot --flake "$dir#$attr"

      mkdir -p "$(dirname ${lib.escapeShellArg stamp})"
      chmod 700 "$(dirname ${lib.escapeShellArg stamp})"
      : > ${lib.escapeShellArg stamp}
      echo "first-boot: converged; the trimmed, personalized generation goes live on the next reboot."
    '';
  };
}
