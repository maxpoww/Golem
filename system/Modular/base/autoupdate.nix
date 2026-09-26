# base/autoupdate — Golem keeps itself current, stage 0's maintenance spine.
# The garbage side already lives in base/nix.nix (nix.gc daily, keep 15
# generations, auto-optimise-store). This is the OTHER half Max named: an
# installed Golem must not freeze at its install-date revision. Ported from
# the proven rice design (2026-09-07 / -09-19), adapted from channels to the
# flake seed and from `switch` to `boot`.
#
# THREE DECISIONS, on purpose:
#
# 1. REBUILD `boot`, NOT `switch`. Unattended, at any hour: staging the new
#    generation for the next reboot never tears down a running kernel or a
#    live session. That sidesteps the whole 2026-09-07 session-kill class
#    (a channel bump restarting the uwsm skeleton) WITHOUT needing the
#    X-RestartIfChanged session guard here — that guard is a desktop-stage
#    concern; the minimal has no session to protect. `allowReboot` is never
#    set: Golem stages, it does not reboot the owner's machine out from under
#    them. The new generation goes live on the next natural reboot.
#
# 2. TRUST THE UPSTREAM SEED, guard the LOCAL tree. The update source is the
#    flake seed's own git upstream (a distro updates by pulling trusted
#    commits, whose committed flake.lock IS the tested nixpkgs pin — we never
#    mutate the lock in place, which would fight the seal). We rebuild ONLY
#    after a clean `git pull --ff-only`; a tree that cannot fast-forward
#    (local commits or a dirty checkout) is the OWNER's — we leave it on its
#    current generation and let them drive rebuild-golem + bless. After a
#    trusted fast-forward we re-seal (golem.seal.bless) so the dev-loop seal's
#    baseline tracks upstream; we NEVER re-seal a local edit. The seal (#56)
#    thus keeps guarding user→root escalation exactly as before.
#
# 3. GATE ON REAL CONNECTIVITY, fail LOUD. golem-wait-online (shared with the
#    rice) waits for the channel/cache hosts before touching anything, so a
#    run that fires before Wi-Fi is back (wake-from-sleep DNS race) does not
#    quietly rebuild against stale state — it waits, or gives up loudly.
#
# HONEST LIMITATION, today: an installed Golem's seed has no upstream remote
# yet (it is a local checkout the installer dropped). Until Golem publishes an
# upstream repo/channel, this leaf is a correct, network-gated NO-OP — the
# machinery is in place and the day the seed gains a remote, updates flow. Its
# absence is the real gap, not this leaf. Guarded on golem.flakeDir like
# selfrebuild/seal: a machine with no checkout gets nothing.
{ config, pkgs, lib, ... }:

let
  # THE CONNECTIVITY GATE — verbatim from the rice (waverunner-apply.nix), so
  # the two systems share one behaviour. 90 x 10s = 15 min ceiling, then a
  # loud non-zero exit rather than a silent cache no-op.
  golemWaitOnline = pkgs.writeShellApplication {
    name = "golem-wait-online";
    runtimeInputs = [ pkgs.curl pkgs.coreutils ];
    text = ''
      hosts=( "https://channels.nixos.org/" "https://cache.nixos.org/nix-cache-info" )
      tries=90   # 90 x 10s = 15 min ceiling
      for i in $(seq 1 "$tries"); do
        for u in "''${hosts[@]}"; do
          if curl -fsS --max-time 8 -o /dev/null "$u"; then
            if [ "$i" -gt 1 ]; then
              echo "golem-wait-online: reachable after ~$(( (i - 1) * 10 ))s"
            fi
            exit 0
          fi
        done
        sleep 10
      done
      echo "golem-wait-online: still offline after $(( tries * 10 / 60 )) min — giving up" >&2
      exit 1
    '';
  };
in
lib.mkIf (config.golem.flakeDir != null) {
  # golem-wait-online on the system PATH: this root service and any future
  # user-lane updater share ONE gate (same code, same retry), exactly as the
  # rice shares it between nixos-upgrade and `ups autoupdate`.
  environment.systemPackages = [ golemWaitOnline ];

  systemd.services.golem-autoupdate = {
    description = "Golem self-update: gate on network, fast-forward the trusted seed, rebuild boot";
    # No wantedBy — the timer drives it. Serialized by Type=oneshot.
    serviceConfig.Type = "oneshot";
    # git (+ ssh/https transports), nix for the rebuild, coreutils for the flow.
    path = [ pkgs.git pkgs.openssh config.nix.package pkgs.coreutils ];
    script = ''
      set -euo pipefail   # -e: a failed rebuild marks the service failed (visible), not silent
      dir=${lib.escapeShellArg config.golem.flakeDir}
      attr=${lib.escapeShellArg config.golem.flakeAttr}

      # 1) real connectivity or a loud give-up (never a stale-cache no-op).
      ${golemWaitOnline}/bin/golem-wait-online || exit 1

      cd "$dir" || { echo "golem-autoupdate: seed $dir is gone — nothing to update" >&2; exit 1; }

      # 2) is there a trusted upstream to pull from?
      if [ -z "$(git remote 2>/dev/null)" ] || ! git rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
        echo "golem-autoupdate: seed has no upstream branch — nothing to pull (correct no-op until Golem has an upstream)."
        exit 0
      fi

      before=$(git rev-parse HEAD)
      if ! git pull --ff-only --quiet; then
        echo "golem-autoupdate: seed cannot fast-forward (local commits or a dirty tree) — leaving the current generation; run rebuild-golem yourself." >&2
        exit 0
      fi
      after=$(git rev-parse HEAD)
      if [ "$before" = "$after" ]; then
        echo "golem-autoupdate: already up to date ($after)."
        exit 0
      fi

      # 3) the fast-forwarded tree is upstream-trusted → re-baseline the seal,
      #    then stage the new generation for the next reboot.
      ${config.golem.seal.bless}/bin/golem-bless || true
      echo "golem-autoupdate: $before -> $after, rebuilding (boot)…"
      /run/current-system/sw/bin/nixos-rebuild boot --flake "$dir#$attr"
      echo "golem-autoupdate: new generation staged; it goes live on the next reboot."
    '';
  };

  systemd.timers.golem-autoupdate = {
    description = "Daily Golem self-update";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;        # catch up a missed run (laptop asleep at the hour)
      RandomizedDelaySec = "45min";
    };
  };
}
