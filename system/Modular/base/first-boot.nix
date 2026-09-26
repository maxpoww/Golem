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
  systemd.services.golem-first-boot = {
    description = "Golem first-boot convergence: rebuild onto measured hardware + machine.nix (once)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    # Runs ONCE: skip if the stamp is already there. Nothing Requires this
    # unit, so a slow rebuild never blocks getty/login — it converges quietly.
    unitConfig.ConditionPathExists = "!${stamp}";
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = "infinity";   # a full first rebuild on a slow disk/2 GB box
    };
    path = [ config.nix.package pkgs.coreutils ];
    script = ''
      set -euo pipefail   # -e: a failed rebuild must NOT reach the stamp below
      dir=${lib.escapeShellArg config.golem.flakeDir}
      attr=${lib.escapeShellArg config.golem.flakeAttr}

      ${golemWaitOnline} || exit 1

      # Establish the seal baseline (trust-on-first-use: seals what the
      # installer wrote), then stage the machine's real configuration.
      ${config.golem.seal.check}/bin/golem-seal-check || {
        echo "first-boot: seal check failed — refusing to converge" >&2; exit 1; }

      echo "first-boot: converging onto measured hardware + machine.nix (boot)…"
      /run/current-system/sw/bin/nixos-rebuild boot --flake "$dir#$attr"

      mkdir -p "$(dirname ${lib.escapeShellArg stamp})"
      chmod 700 "$(dirname ${lib.escapeShellArg stamp})"
      : > ${lib.escapeShellArg stamp}
      echo "first-boot: converged; the trimmed, personalized generation goes live on the next reboot."
    '';
  };
}
