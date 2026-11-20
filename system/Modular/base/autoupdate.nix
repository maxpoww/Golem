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
#    current generation and let them drive rebuild-golem + bless. After the
#    fast-forward, golem-seal-heal checks every changed file against root's
#    OWN fetch of upstream and re-seals only upstream's code; a tree with
#    anything else in it is not built (2026-11-12: until then this re-sealed
#    whatever was there, so any program running as the owner could commit to
#    ~/Golem and have root build it — the security study's road 2).
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
  ownerPut = import ../../owner-put.nix pkgs;
  golemSay = pkgs.callPackage ../../i18n/golem-say.nix { };

  # THE CONNECTIVITY GATE (./wait-online.nix, shared with the /etc/nixos
  # layout's nightly update).
  golemWaitOnline = import ./wait-online.nix pkgs;
  # A system without one (the VMs boot their kernel directly) has no boot
  # entry to check.
  bootMenu = config.boot.loader.grub.enable || config.boot.loader.systemd-boot.enable;
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
    # Behind the owner: the pull, the eval and the bless at Nice 19 in the
    # idle I/O class (the nix daemon's own builds carry their own weights,
    # updates/client.nix), and not during a login — the quiet-login gate,
    # which on a weak machine also waits for a calm minute. On the 2013
    # MacBook Air the morning's update rebuilt the system an hour after
    # boot, 5 min of both cores while its owner worked (2026-10-29).
    serviceConfig.Nice = 19;
    serviceConfig.IOSchedulingClass = "idle";
    serviceConfig.CPUWeight = 20;
    serviceConfig.ExecStartPre = lib.optional (config.golem ? quietLogin) "${config.golem.quietLogin}/bin/golem-quiet-login";
    # Exit 75 = THE NETWORK, not the version: no connection after 15 min, or
    # GitHub could not be asked for the version's published pieces. Nothing
    # was built; the run comes back in an hour instead of tomorrow night
    # (2026-11-19: the ASUS lost a whole night to a bad network, and until
    # then such a night also set it compiling the whole system).
    serviceConfig.RestartForceExitStatus = "75";
    serviceConfig.RestartSec = "1h";
    restartIfChanged = false;   # a switch never waits on it (base/nix.nix, nix-gc)
    # git (+ ssh/https transports), nix for the rebuild, coreutils for the flow.
    path = [ pkgs.git pkgs.openssh config.nix.package pkgs.coreutils pkgs.util-linux ];
    script = ''
      set -euo pipefail   # -e: a failed rebuild marks the service failed (visible), not silent
      dir=${lib.escapeShellArg config.golem.flakeDir}
      attr=${lib.escapeShellArg config.golem.flakeAttr}
      owner=${lib.escapeShellArg config.golem.owner}

      # What the owner's desktop reads to say "Golem could not update"
      # (desktop/update-notice.nix): when a run last worked, and when one last
      # failed. Nobody else could ever know (no telemetry); these files never
      # leave the machine. Waiting for the wave is a run that worked.
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

      # The newest system must be what the machine boots next. A rebuild whose
      # boot-menu step failed (a full /boot) leaves the profile on the new
      # system and the menu on the old one: the machine then looked up to date
      # while every restart booted the old version, forever (audit,
      # 2026-10-29: the ESP held 4 of the 15 entries GRUB wanted). Write the
      # entry again; a menu that still lacks it fails the run loudly.
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

      # 1) real connectivity or a loud give-up (never a stale-cache no-op);
      #    the give-up comes back in an hour (75, RestartForceExitStatus).
      ${golemWaitOnline}/bin/golem-wait-online || exit 75

      # A seed still in its installed form (a plain copy) becomes a checkout of
      # the upstream first (base/seed.nix; a no-op once it is one).
      ${config.golem.seed.adopt}/bin/golem-seed-adopt || true

      cd "$dir" || { echo "golem-autoupdate: seed $dir is gone — nothing to update" >&2; exit 1; }
      ${config.golem.gitHeal}/bin/golem-git-heal "$dir" || true

      # 2) is there a trusted upstream to pull from?
      # (Every git command here runs AS THE OWNER: root never runs git inside
      # their repository, whose config could name commands git would run.)
      if [ -z "$(runuser -u "$owner" -- git -C "$dir" remote 2>/dev/null)" ] \
         || ! runuser -u "$owner" -- git -C "$dir" rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
        echo "golem-autoupdate: the seed is not a checkout of an upstream yet (offline at every try so far?) — nothing to pull." >&2
        exit 0
      fi

      # Installs follow golem.upstream.branch: "stable", where the update lane
      # puts only versions it built, tested and cached (updates/README.md). A
      # seed cloned when installs followed main moves over once that branch
      # exists upstream; until the lane's first publish it doesn't, and the
      # seed stays where it is.
      want=${lib.escapeShellArg config.golem.upstream.branch}
      cur=$(runuser -u "$owner" -- git -C "$dir" rev-parse --abbrev-ref '@{u}' 2>/dev/null || true)
      if [ "$cur" != "origin/$want" ] \
         && runuser -u "$owner" -- git -C "$dir" fetch --quiet origin "+refs/heads/$want:refs/remotes/origin/$want" 2>/dev/null; then
        runuser -u "$owner" -- git -C "$dir" branch --quiet --set-upstream-to="origin/$want"
        echo "golem-autoupdate: now following $want (was ''${cur:-nothing})."
      fi

      # A machine file from an installer before 2026-10-01 declares the owner's
      # password hash, which puts it in the world-readable store (base/users.nix).
      # Remove the line: the account is mutable and keeps its password, and the
      # activation step has already mirrored it into the root-only secret file.
      # Root edits a root-only copy, seals that one change (golem-seal-adopt:
      # only if the file was the blessed one), then writes it into the owner's
      # file — never sealing whatever else is in the tree.
      migrated=0
      mf="$dir/hosts/target/machine.nix"
      if [ -f "$mf" ] && [ -s /var/lib/golem/secrets/owner-password-hash ] \
         && grep -q '\.hashedPassword = ' "$mf"; then
        mold=$(mktemp); mnew=$(mktemp)
        runuser -u "$owner" -- cat -- "$mf" > "$mold"   # read as the owner (18-Nov)
        sed '/users\.users\.[^ ]*\.hashedPassword = /d' "$mold" > "$mnew"
        if ${config.golem.seal.adopt}/bin/golem-seal-adopt hosts/target/machine.nix "$mnew" "$mold"; then
          runuser -u "$owner" -- ${ownerPut} "$mf" < "$mnew"   # written as the owner (18-Nov)
          runuser -u "$owner" -- git -C "$dir" add -f hosts/target/machine.nix || true
          migrated=1
          echo "golem-autoupdate: removed the owner's password hash from the system source (it stays in /etc/shadow)."
        else
          echo "golem-autoupdate: the password-hash line stays until the change to machine.nix is approved" >&2
        fi
        rm -f "$mold" "$mnew"
      fi

      # Seam's update lane pins a newer browser IN the checkout between our
      # pulls (seam/sources.json). Left there, the fast-forward below refuses
      # the dirty tree the day upstream moves the pin too, and the machine
      # stops updating for good. Set it aside, pull, and put it back only if
      # it is still the newer one (never step the browser down: Firefox
      # refuses a profile a newer version has used).
      # The pin is read and written back AS THE OWNER (18-Nov): the pull in
      # between runs as the owner, with their git config, so whatever they
      # run can swap the file for a link, and root writing it back by name
      # then wrote the owner's bytes into any file on the machine.
      pin=seam/sources.json; heldpin=""
      if ! runuser -u "$owner" -- git -C "$dir" diff --quiet HEAD -- "$pin" 2>/dev/null; then
        heldpin=$(mktemp)
        if runuser -u "$owner" -- cat -- "$dir/$pin" > "$heldpin"; then
          runuser -u "$owner" -- git -C "$dir" checkout -q HEAD -- "$pin"
        else
          rm -f "$heldpin"; heldpin=""
        fi
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
        # In the owner's language (root: their settings, named).
        say() { GOLEM_SETTINGS="$home/.config/golem/settings.json" ${golemSay}/bin/golem-say "$@"; }
        if [ "$n" = 1 ]; then
          body=$(say "A file you changed in ~/Golem was copied to {0} so Golem could update." "$keep")
        else
          body=$(say "{0} files you changed in ~/Golem were copied to {1} so Golem could update." "$n" "$keep")
        fi
        uid=$(id -u "$owner")
        if [ -S "/run/user/$uid/bus" ]; then
          runuser -u "$owner" -- env DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
            ${pkgs.libnotify}/bin/notify-send -a Golem "$(say "Golem kept your edits aside")" "$body" || true
        fi
      fi

      # A revision that crash-looped the desktop is HELD (desktop/
      # crash-recovery.nix rolled the machine back from it): never pull to it
      # or build it — wait for upstream's next one.
      heldfile=/var/lib/golem/held-revisions
      if [ -s "$heldfile" ]; then
        runuser -u "$owner" -- git -C "$dir" fetch --quiet || true
        upstream=$(runuser -u "$owner" -- git -C "$dir" rev-parse '@{u}' 2>/dev/null || true)
        if [ -n "$upstream" ] && grep -qx "$upstream" "$heldfile"; then
          echo "golem-autoupdate: upstream is at $upstream, which crashed this machine's desktop — holding until a newer version is out."
          exit 0
        fi
      fi

      # THE WAVE (updates/client.nix): a new version waits this machine's
      # wave, in days from the run that first found the machine behind, so
      # the machines spread over the week and the lab (wave 0) meets every
      # version first. Counting from "first behind", not from each version,
      # means a machine late in the week still updates when versions come
      # faster than its wave. Only pulling waits: a version already pulled
      # but never built is finished below. /run/golem-update-now skips it.
      # The clock is cleared when the machine is current, or after a
      # successful rebuild of what it pulled.
      # A version that was out before the machine first saw it counts from
      # its publication (when the lane uploaded its cache): a machine
      # installed from an older ISO, or back after weeks off, meets a
      # version the other machines have run for days, and waiting its whole
      # wave again only kept it behind (audit, 2026-10-29).
      wave=$(${config.golem.update.waveCommand}/bin/golem-update-wave)
      since=/var/lib/golem/update-behind-since
      [ -d /var/lib/golem ] || install -d -m 700 /var/lib/golem
      pull=1
      asked_now=0; [ -e /run/golem-update-now ] && asked_now=1
      runuser -u "$owner" -- git -C "$dir" fetch --quiet || true
      upstream=$(runuser -u "$owner" -- git -C "$dir" rev-parse '@{u}' 2>/dev/null || true)
      if [ -z "$upstream" ] || runuser -u "$owner" -- git -C "$dir" merge-base --is-ancestor "$upstream" HEAD 2>/dev/null; then
        rm -f "$since"
      else
        [ -s "$since" ] || date +%s > "$since"
        from=$(cat "$since")
        published=$(${config.golem.update.publishedCommand}/bin/golem-update-published "$upstream" || true)
        if [[ "$published" =~ ^[0-9]+$ ]] && [ "$published" -lt "$from" ]; then from=$published; fi
        age=$(( $(date +%s) - from ))
        if [ "$age" -lt $(( wave * 86400 )) ] && [ ! -e /run/golem-update-now ]; then
          echo "golem-autoupdate: a new version is out; this machine is in wave $wave and takes it in about $(( (wave * 86400 - age + 3599) / 3600 )) h."
          pull=0
        fi
        rm -f /run/golem-update-now
      fi

      # From the pull to the end (build, or recover), the source is in
      # flux: hold the rebuild lock for all of it, so a dock install never
      # reads a pulled-but-unbuilt (maybe broken) tree (MacBook, 2026-10-03:
      # an install during a failing update built the broken source).
      exec 8>>/run/golem-rebuild.lock
      flock -w 7200 8 || { echo "golem-autoupdate: another rebuild has held the lock for 2 h — trying again tomorrow" >&2; exit 1; }
      export GOLEM_REBUILD_LOCK_HELD=1

      before=$(runuser -u "$owner" -- git -C "$dir" rev-parse HEAD)
      # The checkout is the OWNER's: every git write runs as them, or root
      # leaves FETCH_HEAD/objects behind that the owner can no longer touch
      # (seen on the first real pull, 2026-09-30).
      if [ "$pull" = 1 ]; then
        if ! runuser -u "$owner" -- git -C "$dir" pull --ff-only --quiet; then
          echo "golem-autoupdate: seed cannot fast-forward (local commits?) — leaving the current generation; run rebuild-golem yourself." >&2
          if [ -n "$heldpin" ]; then   # leave the tree exactly as we found it
            runuser -u "$owner" -- ${ownerPut} "$dir/$pin" < "$heldpin" || true
            runuser -u "$owner" -- git -C "$dir" add "$pin" || true; rm -f "$heldpin"
          fi
          # FAILED, not success: a machine that can no longer update must show
          # up in systemctl --failed and every probe, not look healthy forever.
          exit 1
        fi
      fi
      after=$(runuser -u "$owner" -- git -C "$dir" rev-parse HEAD)
      if [ -n "$heldpin" ]; then
        held=$(sed -n 's/.*"version": *"\([0-9.]*\)".*/\1/p' "$heldpin")
        up=$(runuser -u "$owner" -- sed -n 's/.*"version": *"\([0-9.]*\)".*/\1/p' "$dir/$pin")
        if [ "$(printf '%s\n%s\n' "$held" "$up" | sort -V | tail -1)" = "$held" ] && [ "$held" != "$up" ]; then
          runuser -u "$owner" -- ${ownerPut} "$dir/$pin" < "$heldpin"   # as the owner: theirs either way
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
        if [ "$pull" = 0 ]; then
          echo "golem-autoupdate: running $after; the newer version waits for this machine's wave."
        else
          echo "golem-autoupdate: already up to date ($after)."
        fi
        ensure_boot_entry || exit 1
        exit 0
      fi
      if [ "$before" = "$after" ] && [ "$built" != "$after" ]; then
        echo "golem-autoupdate: the checkout is at $after but the newest built system is ''${built:-unknown} — finishing that build."
      fi

      # 3) Root builds only a tree it can vouch for: the one last blessed, or
      #    that one moved by upstream's own code (golem-seal-heal checks each
      #    changed file, byte for byte, against root's own fetch of upstream —
      #    never the owner's .git, whose remote and objects are theirs to
      #    change). Until 2026-11-12 this re-sealed unconditionally: a program
      #    running as the owner could commit to ~/Golem, start
      #    golem-update-now (no password) and have root build its commit — the
      #    security study's road 2. A change nobody approved stays the
      #    owner's: rebuild-golem builds it with their password.
      if ! ${config.golem.seal.check}/bin/golem-seal-check >/dev/null 2>&1 \
         && ! ${config.golem.seal.heal}/bin/golem-seal-heal; then
        echo "golem-autoupdate: $dir holds changes nobody approved — not building them as root. Approve them with rebuild-golem (it asks for the password), or put Golem's files back." >&2
        exit 1
      fi
      # Then stage the new generation for the next reboot — built from root's
      # own copy of exactly what was just vouched for, never from ~/Golem
      # itself: a file swapped in after the check would otherwise be what
      # Nix read (golem-seal.nix, golem-seal-copy).
      if ! src=$(${config.golem.seal.copy}/bin/golem-seal-copy); then
        echo "golem-autoupdate: root could not make its copy of the approved files — not building." >&2
        exit 1
      fi
      echo "golem-autoupdate: $before -> $after, rebuilding (boot)…"
      # NEED_CACHE: when GitHub cannot be asked whether this version's
      # published pieces exist, golem-rebuild builds nothing and says 75
      # (updates/client.nix). Compiling blind cost the ASUS a night (19-Nov):
      # hours of compiling on a network that then failed the build anyway.
      rrc=0
      GOLEM_REBUILD_NEED_CACHE=1 ${config.golem.rebuild}/bin/golem-rebuild boot --flake "path:$src#$attr" || rrc=$?
      rm -rf "$src"
      if [ "$rrc" = 75 ]; then
        # Nothing was built. The source goes back like a failed build's, so
        # no other rebuild (a dock install) builds the new version without
        # its pieces meanwhile; the next run pulls it again.
        echo "golem-autoupdate: GitHub could not be reached for $after's published pieces — nothing compiled, trying again in an hour" >&2
        ${config.golem.recover}/bin/golem-recover /nix/var/nix/profiles/system || true
        # "Update now" stays asked for the hour's retry (not its wave).
        if [ "$asked_now" = 1 ]; then touch /run/golem-update-now; fi
        exit 75
      fi
      if [ "$rrc" != 0 ]; then
        # The pulled source does not build. Leave it there and every later
        # rebuild — dock installs included — fails too: put the source back to
        # what built the newest system (base/recover.nix). The next run tries
        # upstream again (a download that broke is not a broken version).
        echo "golem-autoupdate: $after does not build — putting the source back to what built this machine's newest system" >&2
        ${config.golem.recover}/bin/golem-recover /nix/var/nix/profiles/system || true
        exit 1
      fi
      # The wave's clock stops only once the new version is built: a build
      # that failed (a download that broke) is tried again the next night,
      # not a whole wave later.
      if [ "$pull" = 1 ]; then rm -f "$since"; fi
      ensure_boot_entry || exit 1
      echo "golem-autoupdate: new generation staged; it goes live on the next reboot."
    '';
  };

  # UPDATE NOW (the Controls page's button, 2026-11-06): one run that skips
  # this machine's wave — the marker the service honours, then the service.
  # The owner may start it without a password (desktop/care.nix lists it);
  # the marker goes with the run, so the next nightly run waits its turn
  # again.
  systemd.services.golem-update-now = {
    description = "Golem self-update now, skipping this machine's wave";
    serviceConfig.Type = "oneshot";
    script = ''
      touch /run/golem-update-now
      ${pkgs.systemd}/bin/systemctl start --no-block golem-autoupdate.service
    '';
  };

  systemd.timers.golem-autoupdate = {
    description = "Daily Golem self-update";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      # Each machine its own moment between midnight and 6:00, the same every
      # night: systemd derives it from this machine's machine-id and the
      # timer's name, on the machine, so the machines never all ask at once.
      RandomizedOffsetSec = "6h";
      # A machine that was off at its moment (most are, at night) runs a few
      # minutes after it is turned on; one that slept, as it wakes.
      Persistent = true;
      RandomizedDelaySec = "10min";
      FixedRandomDelay = true;
      # Not RandomizedDelaySec=6h for the moment, as until 2026-10-28: systemd
      # counts a missed run's delay from the BOOT (timer.c, "rebase after boot
      # time"), so a machine turned on in the morning waited its 0-6 h again,
      # and one used for less than that a day never updated at all. Proven on
      # systemd 260 with real timers.
    };
  };
}
