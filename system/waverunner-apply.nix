# Privileged apply helper for waverunner's declarative installs — flake port.
#
# SECURITY MODEL (unchanged from the channel version)
# ---------------------------------------------------
# The ONLY user-writable surface is the DATA file
#   ~<user>/.config/waverunner/packages.list   (one nixpkgs attr per line)
# This script (root) PARSES that file as data — it never `import`s it — and
# strictly validates every line against ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ before
# emitting the real Nix. The generated file is root-owned; nothing but this
# service writes it.
#
# FLAKE TWIST: the generated waverunner-packages.nix lives INSIDE the flake
# checkout (system/home/) — flakes can't read outside their tree — and must
# be git-tracked or the build won't see it, so the script `git add`s it.
# Rebuilds run `nixos-rebuild switch --flake <flakeDir>#<golem.flakeAttr>`
# (golem-desktop on an install; `#golem` is the generic systemd-boot config
# and fails on a GRUB machine).
#
# TRIGGER: a systemd.path watches packages.list; writing it runs this once.
# FEEDBACK: result is written to apply-status.json (chowned back to the user).
# ATOMIC: a failed switch never activates; last-good is restored so the tree
# always stays buildable.
#
# (The channel version also carried system.autoUpgrade — dropped here: on a
# flake system "upgrade" = bump flake inputs + rebuild, a deliberate act.
# The Golem upgrade story is an open S7 design item.)

{ config, pkgs, lib, ... }:

let
  flakeDir = config.golem.flakeDir;
  flakeAttr = config.golem.flakeAttr;
  user = config.golem.owner;
  userHome = "/home/${user}";
  listFile = "${userHome}/.config/waverunner/packages.list";
  statusFile = "${userHome}/.config/waverunner/apply-status.json";
  appsFile = config.golem.appsFile;
  generated = "${flakeDir}/${appsFile}";

  applyScript = pkgs.writeShellApplication {
    name = "waverunner-apply";
    # This script does its own error handling (it must always write a status
    # and restore the last-good file on a failed rebuild), so drop the
    # default `errexit` — keep nounset + pipefail.
    bashOptions = [ "nounset" "pipefail" ];
    runtimeInputs = [
      config.system.build.nixos-rebuild
      config.nix.package
      config.golem.seal.check
      config.golem.seal.heal
      config.golem.rebuild
      pkgs.gnugrep
      pkgs.gnutar
      pkgs.glibc.bin # getent: the connectivity wait
      pkgs.git
      pkgs.util-linux # runuser: git writes into the owner's checkout run as the owner
      pkgs.jq
      pkgs.coreutils
      pkgs.systemd # for the #61 reset-failed; a bare systemctl under a
                   # writeShellApplication's clean PATH would break silently.
    ];
    text = ''
      list=${lib.escapeShellArg listFile}
      status=${lib.escapeShellArg statusFile}
      gen=${lib.escapeShellArg generated}
      flakedir=${lib.escapeShellArg flakeDir}
      lastgood="$gen.last-good"
      started=$(date +%s.%N)

      # The whole install under the rebuild lock: never read or write the
      # source while a nightly update has it in flux (golem-seal.nix,
      # base/autoupdate.nix; MacBook 2026-10-03).
      exec 8>>/run/golem-rebuild.lock
      flock -w 7200 8 || true
      export GOLEM_REBUILD_LOCK_HELD=1

      write_status() {
        # $1 phase ("building"|"done")   $2 ok (true|false|null)   $3 error (json string or null)
        tmp=$(mktemp)
        printf '{"phase":"%s","ok":%s,"started":%s,"finished":%s,"error":%s}\n' \
          "$1" "$2" "$started" "$(date +%s.%N)" "$3" > "$tmp"
        mv "$tmp" "$status"
        chown ${user}:users "$status" 2>/dev/null || true
        chmod 644 "$status" 2>/dev/null || true
      }

      write_status "building" null null

      # 4. The list changed while this pass ran (another install queued, an
      #    edit): run again from the top, so nothing waits for a trigger that
      #    systemd dropped. Bounded, so a list rewritten in a loop can't keep
      #    the machine rebuilding forever.
      again_if_list_changed() {
        local pass="''${GOLEM_APPLY_PASS:-1}"
        if [[ "$(sha256sum < "$list" 2>/dev/null || echo none)" != "$listsum" && "$pass" -lt 5 ]]; then
          echo "waverunner-apply: the list changed during the rebuild — applying again (pass $((pass + 1)))" >&2
          GOLEM_APPLY_PASS=$((pass + 1)) exec "$0"
        fi
      }

      # 0. The seed blessing gate (#56, golem-seal.nix): an unattended
      #    root rebuild only proceeds when the seed matches its blessed
      #    manifest. The list this script exists to apply is exempt (it's
      #    validated DATA, below) — the gate guards everything else in the
      #    tree from being edited into a silent root rebuild.
      #
      #    An install must not fail on it, though (Max, 2026-10-01: "it cant
      #    fail.. it have to install"). So: when every change is upstream's
      #    own code (a pull nobody re-blessed), golem-seal-heal re-blesses it.
      #    When the owner has edits not yet approved, the install builds from
      #    the root-only copy of the last approved state (+ this list): the
      #    app installs, and the edit waits for its owner's `sudo golem-bless`.
      buildfrom="$flakedir"
      if ! sealmsg=$(golem-seal-check 2>&1); then
        if healmsg=$(golem-seal-heal 2>&1); then
          echo "$healmsg" >&2
        elif [[ -d ${lib.escapeShellArg config.golem.seal.snapshot} ]]; then
          echo "$healmsg" >&2
          echo "waverunner-apply: building from the last approved state; the local edits above wait for: sudo golem-bless" >&2
          buildfrom=/var/lib/golem/build
        else
          errjson=$(printf '%s\n%s' "$sealmsg" "$healmsg" | tail -c 2000 | jq -Rs .)
          write_status "done" false "$errjson"
          echo "$sealmsg" >&2
          exit 1
        fi
      fi

      # What this pass applies. A change to the list while it runs is NOT
      # seen by systemd (the path watch drops triggers while the service is
      # running — measured on the ThinkPad, 2026-10-01: four edits, one run),
      # so the end of a successful pass looks again (step 4).
      listsum=$(sha256sum < "$list" 2>/dev/null || echo none)

      # 1. Validate: keep only strict nixpkgs attr tokens; anything else is
      #    dropped (never interpreted).
      attrs=()
      if [[ -f "$list" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
          line="''${line%%#*}"
          line="$(printf '%s' "$line" | tr -d '[:space:]')"
          if [[ -z "$line" ]]; then
            continue
          fi
          if [[ "$line" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]]; then
            attrs+=("$line")
          else
            echo "waverunner-apply: rejected invalid entry: $line" >&2
          fi
        done < "$list"
      fi

      # 2. Generate the root-owned Nix from the validated tokens, and make
      #    sure the flake can see it (tracked file; dirty is fine).
      {
        echo "# Generated by waverunner-apply from packages.list. Do not edit by hand."
        # lowPrio: an app the owner adds must never fail the whole batch by
        # shipping a file Golem already ships. mpv (2026-09-29, thinkpad): the
        # owner's mpv collided with Golem's mpv-with-scripts on bin/umpv and
        # took kdenlive, gimp and thunderbird down with it. Golem's copy wins
        # the shared paths; everything else of the app is installed.
        # Each name is LOOKED UP, not referenced: a name nixpkgs does not have
        # — a bad entry, or an app a nixpkgs update renamed or removed — is
        # skipped with a warning instead of failing the evaluation of the whole
        # system. Referenced bare (`with pkgs; [ name ]`), one such name made
        # every later install fail AND every rebuild, the nightly update
        # included (ASUS dogfood, 2026-10-02).
        echo "{ pkgs, lib, ... }:"
        echo "let"
        echo "  wanted = ["
        for a in ''${attrs[@]+"''${attrs[@]}"}; do
          echo "    \"$a\""
        done
        echo "  ];"
        echo "  find = n: lib.attrByPath (lib.splitString \".\" n) null pkgs;"
        echo "  missing = builtins.filter (n: find n == null) wanted;"
        echo "in"
        echo "{"
        echo "  warnings = map (n: \"waverunner: '\''${n}' is not in nixpkgs (renamed or removed?) — skipped\") missing;"
        echo "  home.packages = map lib.lowPrio (builtins.filter (p: p != null) (map find wanted));"
        echo "}"
      } > "$gen.new"
      mv "$gen.new" "$gen"
      # Root inside the user's checkout: /etc/gitconfig carries the
      # safe.directory entry (configuration.nix) for git AND nix's libgit2.
      # It MUST be tracked: a flake only sees tracked files, and on a fresh
      # machine the very first install creates the file — if `git add` lost
      # a race with another git command (index.lock), the rebuild "succeeded"
      # without the app and the dock waited for an app that never came.
      staged=false
      for _ in 1 2 3 4 5 6 7 8 9 10; do
        runuser -u ${user} -- git -C "$flakedir" add ${lib.escapeShellArg appsFile} 2>/dev/null || true  # the checkout is the owner\'s: git writes run as them
        if runuser -u ${user} -- git -C "$flakedir" ls-files --error-unmatch ${lib.escapeShellArg appsFile} >/dev/null 2>&1; then
          staged=true; break
        fi
        sleep 1
      done
      if [[ "$staged" != true ]]; then
        msg="Golem could not add its app list to the system checkout (git is busy in $flakedir?). Try again in a moment."
        write_status "done" false "$(printf '%s' "$msg" | jq -Rs .)"
        echo "$msg" >&2
        exit 1
      fi

      # 3. Rebuild. On success snapshot last-good; on failure restore it so
      #    the next rebuild is never poisoned by a bad add.
      #
      # A switch that BUILT AND ACTIVATED the system but hit a per-user
      # activation error still exits non-zero (switch-to-configuration-ng
      # sets exit_code=4 if ANY user's reload fails, AFTER the system is
      # already switched). Run as root from this service there is no root
      # `systemd --user` manager, so root's per-user activation always fails
      # ("Failed to remove jobs token" / "Connection is closed") — which
      # wrongly failed every install and left tiles stuck "Installing…"
      # (Golem #44/#43; the package was actually installed). So on a non-zero
      # exit we check whether the SYSTEM generation actually changed: if it
      # did, the package IS installed — a user-activation warning is not an
      # install failure. Only a switch that did NOT change the system is a
      # real failure to revert.
      # #61: a daemon (or helper) killed mid-switch orphans the transient
      # `nixos-rebuild-switch-to-configuration` unit in a failed state, and
      # systemd-run then refuses the name ("already loaded") — every later
      # install fails at switch though the build succeeded (seen on both
      # map machines, 2026-09-10). We are root: clear any corpse first.
      # A RUNNING unit is not "failed", so this never touches a live switch.
      systemctl reset-failed nixos-rebuild-switch-to-configuration.service 2>/dev/null || true
      # The approved copy + this list, when building from it (see the gate).
      if [[ "$buildfrom" != "$flakedir" ]]; then
        rm -rf "$buildfrom"; mkdir -p "$buildfrom"; chmod 700 "$buildfrom"
        (cd ${lib.escapeShellArg config.golem.seal.snapshot} && tar -cf - .) | tar -xf - -C "$buildfrom"
        install -D -m644 "$gen" "$buildfrom/${appsFile}"
        flakeref="path:$buildfrom#${flakeAttr}"
      else
        flakeref="$flakedir#${flakeAttr}"
      fi

      # Transient failures are retried, never reported: the network went
      # away (a download, the binary cache), the disk filled up (the store is
      # collected, then again), something held a lock. The dock keeps showing
      # the install as running meanwhile. Only a failure that comes back the
      # same after the retries is a real one.
      transient() {
        grep -qiE 'unable to download|Could not resolve|resolve host|Connection (reset|refused|timed out)|timed out|Network is unreachable|Failure when receiving|Operation too slow|HTTP error (5[0-9][0-9]|429)|error: download|curl error|SSL|TLS|cannot connect|Could not acquire lock|No space left on device|unexpected end of file|Temporary failure'
      }
      wait_online() {
        for _ in $(seq 1 60); do getent ahosts cache.nixos.org >/dev/null 2>&1 && return 0; sleep 5; done
        return 1
      }
      attempt=1; backoff=20
      while :; do
        before=$(readlink -f /run/current-system 2>/dev/null || echo none)
        if err=$(golem-rebuild switch --flake "$flakeref" 2>&1); then
          ok=yes
        elif after=$(readlink -f /run/current-system 2>/dev/null); [[ -n "$after" && "$after" != "$before" ]]; then
          # System switched; only user activation (root, no user manager here)
          # warned. The package is installed (#44).
          echo "$err" | grep -qi "user activation" \
            && echo "waverunner-apply: system switched; a user-activation warning was ignored (#44)" >&2
          ok=yes
        else
          ok=no
        fi
        [[ "$ok" == yes ]] && break
        if (( attempt < 6 )) && printf '%s' "$err" | transient; then
          echo "waverunner-apply: attempt $attempt hit a passing problem — retrying in ''${backoff}s:" >&2
          printf '%s\n' "$err" | tail -n 3 >&2
          if printf '%s' "$err" | grep -qi 'No space left on device'; then
            echo "waverunner-apply: the disk is full — collecting the store (old generations kept)" >&2
            nix-store --gc >/dev/null 2>&1 || true
          fi
          sleep "$backoff"; wait_online || true
          attempt=$((attempt + 1)); backoff=$((backoff * 2))
          continue
        fi
        break
      done

      if [[ "$ok" == yes ]]; then
        cp -f "$gen" "$lastgood"
        again_if_list_changed
        write_status "done" true null
      else
        if [[ -f "$lastgood" ]]; then
          cp -f "$lastgood" "$gen"
          runuser -u ${user} -- git -C "$flakedir" add ${lib.escapeShellArg appsFile} || true  # the checkout is the owner\'s: git writes run as them
        fi
        errjson=$(printf '%s' "$err" | tail -c 4000 | jq -Rs .)
        write_status "done" false "$errjson"
        echo "$err" >&2
        exit 1
      fi
    '';
  };
in
{
  # Where the generated list lives, relative to the checkout. The fat profile
  # keeps its historical path; the Modular desktop puts it in hosts/target/
  # beside the machine's other per-machine files (one machine's state, never
  # the distro's), and golem-desktop imports it from there.
  options.golem.appsFile = lib.mkOption {
    type = lib.types.str;
    default = "system/home/waverunner-packages.nix";
    description = "Path (relative to golem.flakeDir) of the Nix file waverunner-apply generates from packages.list.";
  };

  config = lib.mkIf (flakeDir != null) {
    systemd.services.waverunner-apply = {
      description = "Apply waverunner's declarative package list (nixos-rebuild switch --flake)";
      # NEVER restart-on-change: this unit DRIVES the switch, so a seed
      # change that alters its own definition made switch-to-configuration
      # stop the running instance — killing the in-flight switch with it
      # (seen on the ASUS 2026-09-09: two half-activated generations, the
      # #58 self-kill). A oneshot picks up the new definition on its next
      # run anyway.
      restartIfChanged = false;
      # No start limit: the dock retries a failed install at once, and three
      # quick failures (systemd's default is 5 starts in 10 s, counted with
      # the path unit's own triggers) put the unit AND its path watch into
      # "start-limit-hit" — the next install was then never picked up at all
      # and the dock gave up after its nudges (ThinkPad, DaVinci Resolve,
      # 2026-10-01: three seal refusals, then a silent fourth failure). Each
      # run is a whole rebuild; there is no storm to guard against.
      startLimitIntervalSec = 0;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${applyScript}/bin/waverunner-apply";
      };
    };

    systemd.paths.waverunner-apply = {
      description = "Watch waverunner's packages.list for changes";
      wantedBy = [ "multi-user.target" ];
      unitConfig.StartLimitIntervalSec = 0;
      pathConfig = {
        PathChanged = listFile;
        Unit = "waverunner-apply.service";
      };
    };
  };
}
