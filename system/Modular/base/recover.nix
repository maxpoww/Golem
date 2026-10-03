# base/recover — golem-recover: make the source match a system that works.
#
# NixOS can BOOT a previous generation, but the source (~/Golem) stays where
# it was; if the declaration is what broke, the machine can never rebuild
# again (Max, 2026-10-03: "if the error is on your declaration you are done.
# the system wont rebuild anymore … how do we recovery the system so it
# really comes back and rebuild?").
#
# Every generation now names its whole source: its git revision
# (system.configurationRevision) and the machine layer it was built from
# (/etc/golem/machine, flake.nix). `golem-recover [system]` puts the source
# back to exactly that — default: the running system:
#   1. the owner's edits to Golem's own files are kept in
#      ~/Golem-local-edits/<when>/ (never lost);
#   2. git goes to the system's revision (reset --hard on the owner's branch);
#   3. hosts/target comes back from the system's own copy and is staged
#      (a flake only sees tracked or staged files);
#   4. the tree is sealed again.
# Afterwards a rebuild reproduces the system. Used by the crash rollback
# (desktop/crash-recovery.nix), by a failed update (base/autoupdate.nix), and
# by hand: `sudo golem-recover`.
{ config, lib, pkgs, ... }:

let
  owner = config.golem.owner;
  dir = toString config.golem.flakeDir;
  home = config.users.users.${owner}.home;
  recover = pkgs.writeShellApplication {
    name = "golem-recover";
    runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.git pkgs.util-linux pkgs.diffutils pkgs.gnugrep ];
    text = ''
      sys=$(readlink -f "''${1:-/run/current-system}")
      dir=${lib.escapeShellArg dir}
      owner=${lib.escapeShellArg owner}
      asowner() { runuser -u "$owner" -- "$@"; }

      rev=$("$sys/sw/bin/nixos-version" --configuration-revision 2>/dev/null || true)
      rev=''${rev%-dirty}
      snap="$sys/etc/golem/machine"
      if ! [[ "$rev" =~ ^[0-9a-f]{40}$ ]]; then
        echo "golem-recover: $sys does not name its revision — cannot recover from it" >&2
        exit 1
      fi
      if [ ! -d "$dir/.git" ]; then
        echo "golem-recover: $dir is not a checkout yet (golem-seed-adopt makes it one)" >&2
        exit 1
      fi
      cd "$dir"
      ${heal}/bin/golem-git-heal "$dir" || true
      if ! asowner git cat-file -e "$rev^{commit}" 2>/dev/null; then
        asowner git fetch --quiet || true
      fi
      if ! asowner git cat-file -e "$rev^{commit}" 2>/dev/null; then
        echo "golem-recover: revision $rev is not in the checkout's history" >&2
        exit 1
      fi

      # 1. the owner's edits are kept, never lost
      keep="${home}/Golem-local-edits/$(date +%Y-%m-%d-%H%M%S)-recover"
      edited=$(asowner git diff --name-only HEAD 2>/dev/null | grep -v '^hosts/target/' || true)
      if [ -n "$edited" ] || { [ -d "$snap" ] && ! diff -rq "$snap" hosts/target >/dev/null 2>&1; }; then
        asowner mkdir -p "$keep"
        # (if, not `a && b`: under set -e + pipefail a false test as a
        #  loop's last command ended the whole script, silently)
        while IFS= read -r f; do
          if [ -n "$f" ] && [ -e "$f" ]; then
            asowner mkdir -p "$keep/$(dirname "$f")"
            asowner cp -a "$f" "$keep/$f"
          fi
        done <<< "$edited"
        if [ -d hosts/target ]; then
          asowner mkdir -p "$keep/hosts"
          asowner cp -a hosts/target "$keep/hosts/"
        fi
        echo "golem-recover: the current edits are kept in $keep"
      fi

      # 2. the code: exactly the system's revision. `reset --hard` DELETES
      #    files that are staged but not in the commit — every machine file —
      #    so the current ones are held aside first.
      held=$(mktemp -d)
      cp -a hosts/target/. "$held/" 2>/dev/null || true
      asowner git reset --quiet --hard "$rev"

      # 3. the machine layer: the system's own copy (or, from a generation
      #    built before it kept one, the files that were there), staged
      src="$snap"; [ -d "$src" ] || { src="$held"; echo "golem-recover: $(basename "$sys") keeps no machine layer (built before 2026-10-03) — keeping the current one" >&2; }
      # -L: /etc/golem/machine is a symlink into the store, and find does not
      # follow a symlinked starting point by itself (it copied NOTHING once,
      # and reset had already removed the machine files — MacBook, 2026-10-03)
      find -L "$src/" -maxdepth 1 -type f -print0 | while IFS= read -r -d "" f; do
        b=$(basename "$f")
        if [ "$b" = default.nix ]; then continue; fi
        install -m 0644 -o "$owner" -g "$(id -gn "$owner")" "$f" "hosts/target/$b"
        asowner git add -f "hosts/target/$b"
      done
      # Never leave a machine without its machine layer: if the essential
      # files did not come back, put back what was there and say so.
      for need in machine.nix hardware-configuration.nix; do
        if [ ! -f "hosts/target/$need" ]; then
          echo "golem-recover: hosts/target/$need did not come back — restoring the machine layer as it was" >&2
          cp -a "$held/." hosts/target/
          chown -R "$owner": hosts/target
          find hosts/target -maxdepth 1 -type f ! -name default.nix -print0 \
            | while IFS= read -r -d "" f; do asowner git add -f "$f"; done
          rm -rf "$held"
          exit 1
        fi
      done
      rm -rf "$held"

      # 4. sealed again: this tree built a system that works
      ${config.golem.seal.bless}/bin/golem-bless >/dev/null 2>&1 || true
      echo "golem-recover: the source now matches $(basename "$sys") (revision ''${rev:0:8}) — a rebuild reproduces it"
    '';
  };
  # golem-git-heal: what a power cut can do to the owner's checkout, undone.
  #   - a stale lock (.git/index.lock, HEAD.lock, a ref's .lock): every git
  #     command refused, the nightly update failed every night (Acer,
  #     2026-10-03). Removed when certainly an orphan: made before this boot,
  #     or older than 10 minutes with no git running.
  #   - damaged objects: the cut emptied the new HEAD's object file ("bad
  #     object HEAD", MacBook 2026-10-03). Empty objects are deleted and
  #     fetched again from the upstream; if the repository is still broken,
  #     its .git is set aside and golem-seed-adopt makes a fresh checkout,
  #     carrying this machine's own files over.
  # Run first by the nightly update, dock installs and golem-recover.
  heal = pkgs.writeShellApplication {
    name = "golem-git-heal";
    runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.procps pkgs.gawk pkgs.gnused pkgs.git pkgs.util-linux ];
    text = ''
      d="''${1:-${dir}}"; g="$d/.git"
      [ -d "$g" ] || exit 0
      asowner() { runuser -u ${lib.escapeShellArg owner} -- "$@"; }

      boot=$(awk '/^btime/ {print $2}' /proc/stat)
      now=$(date +%s)
      gitrunning=0
      if pgrep -x git >/dev/null; then gitrunning=1; fi
      find "$g" -maxdepth 5 -name '*.lock' -not -path '*/objects/*' -print0 \
        | while IFS= read -r -d "" l; do
            m=$(stat -c %Y "$l")
            # never while git runs: a clock that was AHEAD at boot puts the
            # boot time after a live lock's mtime
            if [ "$gitrunning" = 0 ] && { [ "$m" -lt "$boot" ] || [ $(( now - m )) -gt 600 ]; }; then
              rm -f "$l"
              echo "golem-git-heal: removed a stale lock left by an interrupted git: ''${l#"$g"/}"
            fi
          done

      # Refs git writes for itself and can always do without: a cut left
      # ORIG_HEAD EMPTY and every merge/pull failed on it ("cannot lock ref
      # 'ORIG_HEAD': reference broken" — the ISO VM, 2026-10-03). The same
      # for an empty remote-tracking ref: the next fetch writes it again.
      for r in ORIG_HEAD FETCH_HEAD MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD REBASE_HEAD AUTO_MERGE; do
        if [ -f "$g/$r" ] && ! asowner git -C "$d" rev-parse -q --verify "$r" >/dev/null 2>&1; then
          rm -f "$g/$r"
          echo "golem-git-heal: removed a broken $r left by an interrupted git"
        fi
      done
      if [ -d "$g/refs/remotes" ]; then
        find "$g/refs/remotes" -type f -empty -print -delete | sed 's|^|golem-git-heal: removed empty ref |'
      fi

      # The machine layer, cut to nothing by the same kind of stop
      # (hosts/target/golem-hardware.nix EMPTY on the ISO VM, 2026-10-03:
      # no rebuild could evaluate, so every install failed, and the nightly
      # update saw nothing new to build). An empty file is never the owner's
      # intent: it comes back from the running system's own copy.
      snap=/etc/golem/machine
      if [ -d "$d/hosts/target" ] && [ -d "$snap" ]; then
        for f in "$d"/hosts/target/*; do
          b=$(basename "$f")
          if [ -f "$f" ] && [ ! -s "$f" ] && [ -s "$snap/$b" ]; then
            install -m 0644 -o ${lib.escapeShellArg owner} -g "$(id -gn ${lib.escapeShellArg owner})" "$snap/$b" "$f"
            echo "golem-git-heal: hosts/target/$b was empty — restored from the running system"
          fi
        done
      fi

      healthy() { asowner git -C "$d" rev-parse --verify -q HEAD >/dev/null 2>&1 \
                  && asowner git -C "$d" fsck --connectivity-only --no-dangling >/dev/null 2>&1; }
      healthy && exit 0

      echo "golem-git-heal: the checkout's git data is damaged (an interrupted write?) — repairing"
      find "$g/objects" -type f -empty -print -delete | sed 's|^|golem-git-heal: removed empty object |'
      asowner git -C "$d" fetch --quiet origin 2>/dev/null || true
      if healthy; then
        echo "golem-git-heal: repaired from the upstream"
        exit 0
      fi
      echo "golem-git-heal: still damaged — a fresh checkout of the upstream, keeping this machine's files" >&2
      mv "$g" "$g.damaged-$now"
      ${config.golem.seed.adopt}/bin/golem-seed-adopt || true
      healthy || { echo "golem-git-heal: could not repair the checkout (offline?)" >&2; exit 1; }
    '';
  };
in
{
  options.golem.gitHeal = lib.mkOption {
    type = lib.types.package;
    internal = true;
    readOnly = true;
    default = heal;
    description = "golem-git-heal: undo what an interrupted git leaves in the checkout (stale locks, damaged objects).";
  };
  options.golem.recover = lib.mkOption {
    type = lib.types.package;
    internal = true;
    readOnly = true;
    default = recover;
    description = "golem-recover: put the source back to what built a given system.";
  };
  config = lib.mkIf (config.golem.flakeDir != null) {
    environment.systemPackages = [ recover heal ];
  };
}
