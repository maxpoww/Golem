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
    path = [ pkgs.git pkgs.openssh config.nix.package pkgs.coreutils pkgs.util-linux ];
    script = ''
      set -euo pipefail   # -e: a failed rebuild marks the service failed (visible), not silent
      dir=${lib.escapeShellArg config.golem.flakeDir}
      attr=${lib.escapeShellArg config.golem.flakeAttr}
      owner=${lib.escapeShellArg config.golem.owner}

      # 1) real connectivity or a loud give-up (never a stale-cache no-op).
      ${golemWaitOnline}/bin/golem-wait-online || exit 1

      # A seed still in its installed form (a plain copy) becomes a checkout of
      # the upstream first (base/seed.nix; a no-op once it is one).
      ${config.golem.seed.adopt}/bin/golem-seed-adopt || true

      cd "$dir" || { echo "golem-autoupdate: seed $dir is gone — nothing to update" >&2; exit 1; }

      # 2) is there a trusted upstream to pull from?
      if [ -z "$(git remote 2>/dev/null)" ] || ! git rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
        echo "golem-autoupdate: the seed is not a checkout of an upstream yet (offline at every try so far?) — nothing to pull." >&2
        exit 0
      fi

      # A machine file from an installer before 2026-10-01 declares the owner's
      # password hash, which puts it in the world-readable store (base/users.nix).
      # Remove the line: the account is mutable and keeps its password, and the
      # activation step has already mirrored it into the root-only secret file.
      migrated=0
      mf="$dir/hosts/target/machine.nix"
      if [ -f "$mf" ] && [ -s /var/lib/golem/secrets/owner-password-hash ] \
         && grep -q '\.hashedPassword = ' "$mf"; then
        runuser -u "$owner" -- sed -i '/users\.users\.[^ ]*\.hashedPassword = /d' "$mf"
        runuser -u "$owner" -- git -C "$dir" add -f hosts/target/machine.nix || true
        migrated=1
        echo "golem-autoupdate: removed the owner's password hash from the system source (it stays in /etc/shadow)."
      fi

      # Seam's update lane pins a newer browser IN the checkout between our
      # pulls (seam/sources.json). Left there, the fast-forward below refuses
      # the dirty tree the day upstream moves the pin too, and the machine
      # stops updating for good. Set it aside, pull, and put it back only if
      # it is still the newer one (never step the browser down: Firefox
      # refuses a profile a newer version has used).
      pin=seam/sources.json; heldpin=""
      if ! runuser -u "$owner" -- git -C "$dir" diff --quiet HEAD -- "$pin" 2>/dev/null; then
        heldpin=$(mktemp); cp "$dir/$pin" "$heldpin"
        runuser -u "$owner" -- git -C "$dir" checkout -q HEAD -- "$pin"
      fi

      # The owner's edits to Golem's OWN files must not freeze the machine.
      # ~/Golem sits in their home (Files shows it); one edited file that
      # upstream later changes made `pull --ff-only` refuse, and the machine
      # never updated again — while this unit reported success (ASUS,
      # 2026-10-02). The machine's own layer is theirs and stays put:
      # hosts/target/ (installer + dock), seam/sources.json (set aside above),
      # the post-install answers. Anything else edited is copied to
      # ~/Golem-local-edits/<when>/ and restored to Golem's version; the owner
      # is told where their copy went.
      home=${lib.escapeShellArg config.users.users.${config.golem.owner}.home}
      edited=$(runuser -u "$owner" -- git -C "$dir" diff --name-only HEAD 2>/dev/null \
        | grep -vE '^(hosts/target/|seam/sources\.json$|system/postinstall-generated\.nix)' || true)
      if [ -n "$edited" ]; then
        keep="$home/Golem-local-edits/$(date +%Y-%m-%d-%H%M%S)"
        runuser -u "$owner" -- mkdir -p "$keep"
        printf '%s\n' "$edited" | while IFS= read -r f; do
          if [ -e "$dir/$f" ]; then
            runuser -u "$owner" -- mkdir -p "$keep/$(dirname "$f")"
            runuser -u "$owner" -- cp -a "$dir/$f" "$keep/$f"
          fi
          runuser -u "$owner" -- git -C "$dir" checkout -q HEAD -- "$f" 2>/dev/null \
            || runuser -u "$owner" -- git -C "$dir" reset -q HEAD -- "$f"
        done
        n=$(printf '%s\n' "$edited" | wc -l)
        echo "golem-autoupdate: $n edited Golem file(s) set aside in $keep and restored, so the update can go on:"
        printf '  %s\n' $edited
        uid=$(id -u "$owner")
        if [ -S "/run/user/$uid/bus" ]; then
          runuser -u "$owner" -- env DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
            ${pkgs.libnotify}/bin/notify-send -a Golem "Golem kept your edits aside" \
            "$n file(s) you changed in ~/Golem were copied to $keep so Golem could update." || true
        fi
      fi

      before=$(git rev-parse HEAD)
      # The checkout is the OWNER's: every git write runs as them, or root
      # leaves FETCH_HEAD/objects behind that the owner can no longer touch
      # (seen on the first real pull, 2026-09-30).
      if ! runuser -u "$owner" -- git -C "$dir" pull --ff-only --quiet; then
        echo "golem-autoupdate: seed cannot fast-forward (local commits?) — leaving the current generation; run rebuild-golem yourself." >&2
        if [ -n "$heldpin" ]; then   # leave the tree exactly as we found it
          cat "$heldpin" > "$dir/$pin"; runuser -u "$owner" -- git -C "$dir" add "$pin" || true; rm -f "$heldpin"
        fi
        # FAILED, not success: a machine that can no longer update must show
        # up in systemctl --failed and every probe, not look healthy forever.
        exit 1
      fi
      after=$(git rev-parse HEAD)
      if [ -n "$heldpin" ]; then
        held=$(sed -n 's/.*"version": *"\([0-9.]*\)".*/\1/p' "$heldpin")
        up=$(sed -n 's/.*"version": *"\([0-9.]*\)".*/\1/p' "$dir/$pin")
        if [ "$(printf '%s\n%s\n' "$held" "$up" | sort -V | tail -1)" = "$held" ] && [ "$held" != "$up" ]; then
          cat "$heldpin" > "$dir/$pin"   # into the owner's existing file: keeps its owner
          runuser -u "$owner" -- git -C "$dir" add "$pin"
          echo "golem-autoupdate: kept this machine's newer Seam pin ($held over upstream's $up)."
        else
          migrated=1   # the pin moved to upstream's: the tree changed, re-seal and rebuild below
        fi
        rm -f "$heldpin"
      fi
      # Up to date only if the NEWEST BUILT system is this revision too. A run
      # that pulled and then died in the rebuild (lid closed, power cut, a
      # download that broke) left HEAD new and the system old; comparing only
      # before/after, every later run said "already up to date" and the
      # machine waited for upstream's next commit to build what it had
      # (ASUS dogfood, 2026-10-02). The built system carries its revision.
      built=$(/nix/var/nix/profiles/system/sw/bin/nixos-version --configuration-revision 2>/dev/null || true)
      built=''${built%-dirty}
      if [ "$before" = "$after" ] && [ "$migrated" = 0 ] && [ "$built" = "$after" ]; then
        echo "golem-autoupdate: already up to date ($after)."
        exit 0
      fi
      if [ "$before" = "$after" ] && [ "$built" != "$after" ]; then
        echo "golem-autoupdate: the checkout is at $after but the newest built system is ''${built:-unknown} — finishing that build."
      fi

      # 3) the fast-forwarded tree is upstream-trusted → re-baseline the seal,
      #    then stage the new generation for the next reboot.
      ${config.golem.seal.bless}/bin/golem-bless || true
      echo "golem-autoupdate: $before -> $after, rebuilding (boot)…"
      ${config.golem.rebuild}/bin/golem-rebuild boot --flake "$dir#$attr"
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
