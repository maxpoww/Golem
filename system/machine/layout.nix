# machine/layout — THE /etc/nixos LAYOUT (docs/system/Layout.md).
#
# A machine built by mkMachine (./default.nix) lives where NixOS expects a
# machine to live:
#
#   /etc/nixos/                    THE MACHINE: root's. configuration.nix,
#                                  modules/, machine/ (what Standard's tools
#                                  recorded). Never touched by an update.
#   /etc/nixos/standard/              GOLEM: root's own copy, a git checkout that
#                                  root may edit (Max, 2026-11-19: "copia
#                                  editable por root"). An update merges the
#                                  new version into it and keeps the edits.
#   /var/lib/golem/                what the system keeps for itself: secrets,
#                                  the update's state, the checkout's git data
#   ~/.config, ~/.local            the owner's settings and files — nothing the
#                                  system is built from
#
# So there is no checkout in a home directory, and with it goes everything
# that existed to make an owner-writable checkout safe for root to build:
# standard.flakeDir is null here, which switches off the seal, the seed adoption,
# the git pulls as the owner and the copies root made of the checkout
# (base/{seed,first-boot,recover,selfrebuild,autoupdate}.nix, golem-seal.nix,
# waverunner-apply.nix: every one is guarded on it). Root's checkout needs
# none of it: nothing an owner's program can write is in it.
#
#   sudo nixos-rebuild switch      the standard command, and it is enough:
#                                  nixos-rebuild finds /etc/nixos/flake.nix,
#                                  and builds what the folder holds NOW —
#                                  an edit in configuration.nix or in standard/
#   rebuild-golem                  the same behind Standard's one rebuild lock
#   golem-update                   this machine onto the newest Standard
#   golem-recover                  Standard's files back to what built a system
#   golem-status                   what was changed here, against upstream
#
# The nightly update, the dock's installs and the other services of this
# layout are their own leaves beside this file (update.nix, apps.nix…).
{ config, lib, pkgs, ... }:

let
  cfg = config.standard.machine;
  co = "${cfg.dir}/standard";

  # THE FOLDER'S OLD NAME. A machine of this layout installed before the
  # system was called StandardOS (2026-11-20) has its copy of the system in
  # /etc/nixos/golem and a flake.nix that names it there. It is moved once:
  # by the activation of the first system that knows the new name (at the
  # restart an update stages it for), or by the first of Golem's commands to
  # run, whichever comes first — the folder, git's note of where its files
  # are, the one line of flake.nix. Nothing else is touched. (Going back to a
  # system from before that day leaves its commands looking for the old
  # name; the next update puts it right.)
  moveFolder = pkgs.writeShellScript "golem-move-folder" ''
    set -u
    PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.gnused pkgs.gnugrep pkgs.git ]}
    dir=${lib.escapeShellArg cfg.dir}
    new=${lib.escapeShellArg co}
    old="$dir/golem"
    gitdir=${lib.escapeShellArg cfg.gitDir}
    [ -f "$old/flake.nix" ] || exit 0
    [ ! -e "$new" ] || exit 0
    mv -T "$old" "$new" || exit 1
    if [ -d "$gitdir" ]; then
      git --git-dir="$gitdir" config core.worktree "$new" || true
    fi
    if grep -q '\./golem/machine\.nix' "$dir/flake.nix"; then
      sed -e 's#\./golem/machine\.nix#./standard/machine.nix#g' \
          -e 's#Golem is in golem/\.#StandardOS is in standard/.#' \
          "$dir/flake.nix" > "$dir/flake.nix.golem-tmp" \
        && chmod --reference="$dir/flake.nix" "$dir/flake.nix.golem-tmp" \
        && mv -f "$dir/flake.nix.golem-tmp" "$dir/flake.nix"
    fi
    echo "golem: this computer's copy of the system is $new now (it was $old)"
  '';

  # GIT IN ROOT'S CHECKOUT. Its data is in /var/lib/golem (root's alone, out
  # of the folder a rebuild copies into the store); the folder holds a .git
  # FILE that names it, so plain `git status` works there for root. Standard's
  # own commands name both outright and need neither that file nor a setting.
  gitFn = ''
    dir=${lib.escapeShellArg cfg.dir}
    co=${lib.escapeShellArg co}
    gitdir=${lib.escapeShellArg cfg.gitDir}
    branch=${lib.escapeShellArg config.standard.upstream.branch}
    g() { git --git-dir="$gitdir" --work-tree="$co" "$@"; }
    need_checkout() {
      ${moveFolder} || true
      if [ ! -f "$dir/flake.nix" ] || [ ! -f "$co/flake.nix" ] || [ ! -d "$gitdir" ]; then
        echo "$1: this machine has no $co (or no $gitdir) — nothing to do" >&2
        exit 1
      fi
    }
    # The upstream commit the files are made of: what was written beside them
    # (.golem-rev); a checkout made by hand has only git's word. NOTHING when
    # it is not known — the installer lays the files down with no history,
    # and until the first update brings it git cannot say.
    said_rev() {
      local r=""
      [ -f "$co/.golem-rev" ] && r=$(sed 's/-dirty$//' "$co/.golem-rev")
      [[ "$r" =~ ^[0-9a-f]{40}$ ]] && printf '%s\n' "$r"
      return 0
    }
    base_rev() {
      local r; r=$(said_rev)
      if [ -n "$r" ] && g cat-file -e "$r^{commit}" 2>/dev/null; then printf '%s\n' "$r"; return 0; fi
      if [ -z "$r" ] && g rev-parse -q --verify HEAD >/dev/null 2>&1; then
        g merge-base HEAD "refs/remotes/origin/$branch" 2>/dev/null || g rev-parse HEAD
      fi
      return 0
    }
    # The files as they are now, as one git tree (edits, new files and
    # deletions included; what .gitignore names is not).
    local_tree() {
      local idx; idx=$(mktemp -u "$gitdir/golem-index.XXXXXX")
      if [ -n "$1" ]; then GIT_INDEX_FILE="$idx" g read-tree "$1"; else GIT_INDEX_FILE="$idx" g read-tree --empty; fi
      GIT_INDEX_FILE="$idx" g add -A >/dev/null 2>&1
      GIT_INDEX_FILE="$idx" g rm -q --cached --ignore-unmatch .golem-rev >/dev/null 2>&1 || true
      GIT_INDEX_FILE="$idx" g write-tree
      rm -f "$idx"
    }
  '';

  # `rebuild-golem`: what an owner types after editing /etc/nixos. Behind the
  # one rebuild lock (golem-rebuild), always this machine's `default`, so it
  # also works right after a rename (nixos-rebuild asks for the attribute
  # named after the RUNNING hostname).
  rebuildGolem = pkgs.writeShellApplication {
    name = "rebuild-golem";
    runtimeInputs = [ config.standard.rebuild ];
    text = ''
      action=''${1:-switch}; [ $# -gt 0 ] && shift
      if [ "$(id -u)" != 0 ]; then
        exec sudo "$0" "$action" "$@"
      fi
      exec golem-rebuild "$action" --flake ${lib.escapeShellArg "${cfg.dir}#default"} "$@"
    '';
  };

  # `golem-status`: what this machine changed in Standard's files.
  status = pkgs.writeShellApplication {
    name = "golem-status";
    runtimeInputs = [ pkgs.git pkgs.coreutils pkgs.gnused ];
    text = ''
      if [ "$(id -u)" != 0 ]; then exec sudo "$0" "$@"; fi
      ${gitFn}
      need_checkout golem-status
      base=$(base_rev)
      if [ -z "$base" ] || ! g rev-parse -q --verify HEAD >/dev/null 2>&1; then
        said=$(said_rev)
        echo "Standard ''${said:0:12}''${said:+ }(branch $branch), in $co"
        if g rev-parse -q --verify "refs/remotes/origin/$branch" >/dev/null 2>&1; then
          echo "$branch does not know this version (a medium cut from work that was not published): nothing to compare the files with. An update takes the branch's version and sets aside what differs."
        else
          echo "Its history has not arrived yet (it comes with the first update): nothing to compare the files with."
        fi
        exit 0
      fi
      echo "Standard ''${base:0:12} (branch $branch), in $co"
      changed=$(g diff --name-status "$base" -- . ':!.golem-rev' || true)
      new=$(g ls-files --others --exclude-standard || true)
      if [ -z "$changed" ] && [ -z "$new" ]; then
        echo "No file of Standard's was changed on this machine."
      else
        echo "Changed on this machine (kept by an update where it can be):"
        [ -z "$changed" ] || printf '%s\n' "$changed" | sed 's/^/  /'
        [ -z "$new" ] || printf '%s\n' "$new" | sed 's/^/  new  /'
        if grep -q 'seam/sources.json$' <<< "$changed"; then
          echo "(seam/sources.json is the browser updating itself between Standard's versions: the newer one always stays.)"
        fi
        echo "See a change:  sudo git -C $co diff ''${base:0:12} -- <file>"
      fi
    '';
  };

  # `golem-update`: this machine onto the newest Standard of the branch it
  # follows.
  #
  # THE EDITS ARE KEPT. Root may have changed Standard's files here. The update
  # is a three-way merge of the files as they are with the new version, both
  # against the version they started from (git merge-tree, in memory). Where
  # the same lines changed on both sides, Standard's new version wins and the
  # machine's file is set aside (/var/lib/golem/local-edits/<when>/): an edit
  # must never freeze a machine on an old version (the ASUS, 2026-10-02, for
  # a month, when its edited checkout could no longer fast-forward).
  #
  # /etc/nixos MOVES ONLY WHEN THE NEW SYSTEM BUILDS. The merged files are
  # laid out in a root-only copy of the folder and built from there; a
  # version that does not build, or a network that fails, leaves the machine
  # exactly as it was. The new system starts at the next boot (as the
  # nightly update's does), or now with `--now`.
  #
  #   golem-update            the newest version, started at the next boot
  #   golem-update --now      …switched to at once
  #   golem-update --nightly  the nightly run: this machine's wave, the held
  #                           versions, and never a build without the
  #                           version's published pieces (update.nix)
  update = pkgs.writeShellApplication {
    name = "golem-update";
    runtimeInputs = [
      config.standard.rebuild
      config.standard.update.waveCommand
      config.standard.update.publishedCommand
      pkgs.git
      pkgs.rsync
      pkgs.gnutar
      pkgs.coreutils
      pkgs.gnused
      pkgs.gawk
      pkgs.util-linux
    ];
    text = ''
      if [ "$(id -u)" != 0 ]; then exec sudo "$0" "$@"; fi
      action=boot; nightly=0; converge=0
      for a in "$@"; do
        case "$a" in
          --now) action=switch ;;
          --nightly) nightly=1 ;;
          --converge) converge=1 ;;
          *) echo "golem-update: unknown argument: $a" >&2; exit 2 ;;
        esac
      done
      ${gitFn}
      need_checkout golem-update
      state=/var/lib/golem
      install -d -m 700 "$state"

      # One rebuild at a time, held from the fetch to the last file put in
      # place: a dock install never builds a half-updated folder.
      exec 9>>/run/golem-rebuild.lock
      flock -w 7200 9 || { echo "golem-update: another rebuild has been running for 2 h — giving up" >&2; exit 1; }
      export GOLEM_REBUILD_LOCK_HELD=1
      # A try left by a run that was killed (the power went): none is in use,
      # this run holds the lock.
      find "$state" -maxdepth 1 \( -name 'update.*' -o -name 'merge.*' \) -exec rm -rf {} + 2>/dev/null || true

      # 75 = THE NETWORK, not the version (the nightly run comes back in an hour).
      if ! g fetch --quiet --no-tags origin "+refs/heads/$branch:refs/remotes/origin/$branch"; then
        echo "golem-update: $(g remote get-url origin 2>/dev/null || echo upstream) could not be reached" >&2
        exit 75
      fi
      new=$(g rev-parse "refs/remotes/origin/$branch")
      # The files' own commit: in what was just fetched; else asked for by
      # name (a medium cut from a commit that is not on the branch).
      said=$(said_rev)
      if [ -n "$said" ] && ! g cat-file -e "$said^{commit}" 2>/dev/null; then
        g fetch --quiet --no-tags origin "$said" 2>/dev/null || true
      fi
      base=$(base_rev)
      # Files laid down with no history (the installer's): git takes them for
      # what they are now that it has their commit. No file is touched.
      if [ -n "$base" ] && ! g rev-parse -q --verify HEAD >/dev/null 2>&1; then
        g update-ref "refs/heads/$branch" "$base"
        g symbolic-ref HEAD "refs/heads/$branch"
        g read-tree "$base"
      fi
      # NEVER BACKWARDS. A machine can be AHEAD of the branch it follows (a
      # medium cut from work that has not reached it yet): what upstream has
      # is then an older Standard, and "moving to it" would undo the newer one
      # file by file. Upstream counts as new only when it has something this
      # machine does not.
      if [ -n "$base" ] && [ "$new" != "$base" ] && g merge-base --is-ancestor "$new" "$base" 2>/dev/null; then
        echo "golem-update: this machine's Standard (''${base:0:12}) is ahead of $branch (''${new:0:12}) — nothing to take from it"
        new=$base
      fi
      built=$(/nix/var/nix/profiles/system/sw/bin/nixos-version --configuration-revision 2>/dev/null || true)
      built=''${built%-dirty}
      since="$state/update-behind-since"

      # THE FIRST BUILD OF A GOLEM THE BRANCH DOES NOT KNOW (a medium cut
      # from work that was never published): this machine's own system, from
      # the files as they are. The branch's version is not taken on a guess,
      # for which of the two is the newer cannot be told. (A later, ordinary
      # update does take it and sets aside what differs: the way back onto
      # the published line.)
      asis=0
      if [ "$converge" = 1 ] && [ -z "$base" ]; then
        asis=1
        echo "golem-update: the version of the files in $co is not known to $branch — building this machine's own system from them as they are"
      fi

      if [ "$new" = "$base" ] && [ "$built" = "$base" ] && [ "$converge" = 0 ]; then
        rm -f "$since"
        echo "golem-update: already on the newest Standard (''${new:0:12})"
        exit 0
      fi

      # A version that crash-looped this machine's desktop is HELD
      # (desktop/crash-recovery.nix went back from it): the nightly run
      # never builds it again, it waits for the next.
      if [ "$nightly" = 1 ] && [ -s "$state/held-revisions" ] && grep -qx "$new" "$state/held-revisions"; then
        echo "golem-update: upstream is at ''${new:0:12}, which crashed this machine's desktop — holding until a newer version is out."
        exit 0
      fi
      if [ "$nightly" = 1 ] && [ "$new" != "$base" ]; then
        # THE WAVE (updates/client.nix): a new version waits this machine's
        # wave, in days from the run that first found the machine behind —
        # or from the version's publication, when it was out before that.
        # /run/golem-update-now (Controls → Updates → Update now) skips it.
        wave=$(golem-update-wave)
        [ -s "$since" ] || date +%s > "$since"
        from=$(cat "$since")
        published=$(golem-update-published "$new" || true)
        if [[ "$published" =~ ^[0-9]+$ ]] && [ "$published" -lt "$from" ]; then from=$published; fi
        age=$(( $(date +%s) - from ))
        if [ "$age" -lt $(( wave * 86400 )) ] && [ ! -e /run/golem-update-now ]; then
          echo "golem-update: a new version is out; this machine is in wave $wave and takes it in about $(( (wave * 86400 - age + 3599) / 3600 )) h."
          exit 0
        fi
        # The nightly run never compiles a version whose published pieces
        # GitHub could not be asked for (golem-rebuild answers 75).
        export GOLEM_REBUILD_NEED_CACHE=1
      fi

      # THE FILES OF THE NEW VERSION, with this machine's edits.
      # (No base: the files' commit is not known upstream — a medium cut from
      # work that was never published. There is nothing to tell an edit from
      # an old file by, so whatever differs from the new version is set aside.)
      mine=$(local_tree "$base")
      aside=""
      unrelated=()
      if [ -n "$base" ]; then
        base_tree=$(g rev-parse "$base^{tree}")
        parent=(-p "$base")
      elif [ "$asis" = 0 ]; then
        base_tree=""
        parent=()
        unrelated=(--allow-unrelated-histories)
        echo "golem-update: the version of the files in $co is not known upstream — what differs from the new one will be set aside"
      fi
      if [ "$asis" = 1 ]; then
        final=$mine
      elif [ "$mine" = "$base_tree" ] || [ "$mine" = "$(g rev-parse "$new^{tree}")" ]; then
        final=$(g rev-parse "$new^{tree}")
      else
        local_commit=$(g -c user.name=golem -c user.email=golem@localhost commit-tree "$mine" "''${parent[@]}" -m "this machine's changes to Standard")
        # (-z: the tree first, then the files both sides changed, each ended
        # by a NUL — a name is never quoted or cut.)
        mrc=0
        merged=$(mktemp "$state/merge.XXXXXX")
        g merge-tree --write-tree --name-only --no-messages -z "''${unrelated[@]}" "$new" "$local_commit" > "$merged" || mrc=$?
        if [ "$mrc" -gt 1 ]; then
          rm -f "$merged"
          echo "golem-update: the new version could not be merged with this machine's changes (git merge-tree: $mrc)" >&2
          exit 1
        fi
        IFS= read -r -d "" final < "$merged"
        if [ "$mrc" = 1 ]; then
          # Where both sides changed the same lines: Standard's new version, and
          # the machine's file set aside.
          aside="$state/local-edits/$(date +%Y-%m-%d-%H%M%S)"
          idx=$(mktemp -u "$gitdir/golem-index.XXXXXX")
          GIT_INDEX_FILE="$idx" g read-tree "$final"
          first=1
          while IFS= read -r -d "" f; do
            if [ "$first" = 1 ]; then first=0; continue; fi   # the tree
            [ -n "$f" ] || continue
            if g cat-file -e "$local_commit:$f" 2>/dev/null; then
              install -d -m 700 "$aside/$(dirname "$f")"
              g show "$local_commit:$f" > "$aside/$f"
            fi
            GIT_INDEX_FILE="$idx" g update-index --force-remove -- "$f"
            entry=$(g ls-tree "$new" -- "$f" | awk '{ print $1 "," $3 }')
            if [ -n "$entry" ]; then
              GIT_INDEX_FILE="$idx" g update-index --add --cacheinfo "$entry,$f"
            fi
            echo "golem-update: $f — changed here and in the new version: Standard's is taken, this machine's is in $aside/$f"
          done < "$merged"
          final=$(GIT_INDEX_FILE="$idx" g write-tree)
          rm -f "$idx"
        fi
        rm -f "$merged"
      fi

      # THE BROWSER'S PIN (seam/sources.json). Seam's own update lane moves
      # it here between Standard's versions (seam/lane.nix), and Firefox refuses
      # a profile that a NEWER version has used: whichever pin is newer
      # stays, this machine's or the new Standard's. It is the lane's doing,
      # not an owner's edit: it is never set aside.
      pin=seam/sources.json
      pin_version() { { g show "$1:$pin" 2>/dev/null || true; } | sed -n 's/.*"version": *"\([0-9][0-9a-z.]*\)".*/\1/p' | head -n 1; }
      mine_v=$(pin_version "$mine"); final_v=$(pin_version "$final")
      if [ -n "$mine_v" ] && [ -n "$final_v" ] && [ "$mine_v" != "$final_v" ] \
         && [ "$(printf '%s\n%s\n' "$mine_v" "$final_v" | sort -V | tail -n 1)" = "$mine_v" ]; then
        idx=$(mktemp -u "$gitdir/golem-index.XXXXXX")
        GIT_INDEX_FILE="$idx" g read-tree "$final"
        entry=$(g ls-tree "$mine" -- "$pin" | awk '{ print $1 "," $3 }')
        GIT_INDEX_FILE="$idx" g update-index --add --cacheinfo "$entry,$pin"
        final=$(GIT_INDEX_FILE="$idx" g write-tree)
        rm -f "$idx"
        echo "golem-update: this machine's browser is newer ($mine_v) than the new Standard's ($final_v) — its pin stays"
      fi
      if [ -n "$aside" ] && [ -e "$aside/$pin" ]; then
        rm -f "$aside/$pin"
        find "$aside" -depth -type d -empty -delete 2>/dev/null || true
        if [ ! -d "$aside" ]; then
          aside=""
          rmdir "$state/local-edits" 2>/dev/null || true   # nothing was ever set aside here
        fi
      fi

      # A ROOT-ONLY COPY OF THE FOLDER with the new files, and the build.
      # (A run that is stopped, a shutdown in the middle of a build, takes
      # its try away: bash runs no EXIT trap for a signal it was not told
      # about.)
      try=$(mktemp -d "$state/update.XXXXXX")
      trap 'rm -rf "$try"' EXIT
      trap 'exit 143' TERM
      trap 'exit 130' INT
      rsync -a --exclude=/standard "$dir/" "$try/"
      mkdir "$try/standard"
      g archive "$final" | tar -x -C "$try/standard"
      if [ "$asis" = 1 ]; then
        [ ! -f "$co/.golem-rev" ] || cp "$co/.golem-rev" "$try/standard/.golem-rev"
      else
        printf '%s\n' "$new" > "$try/standard/.golem-rev"
      fi

      if [ "$asis" = 1 ]; then
        :   # said above
      elif [ "$new" = "$base" ] && [ "$converge" = 1 ]; then
        echo "golem-update: building this machine's own system from $dir (Standard ''${new:0:12})"
      elif [ "$new" = "$base" ]; then
        echo "golem-update: Standard ''${new:0:12} is in $co but the newest built system is ''${built:-unknown} — building it"
      else
        echo "golem-update: ''${base:0:12}''${base:+ }→ ''${new:0:12}"
      fi
      rrc=0
      golem-rebuild "$action" --flake "path:$try#default" || rrc=$?
      if [ "$rrc" != 0 ]; then
        # Nothing of /etc/nixos was touched. What was set aside was never
        # taken away from the folder either.
        [ -z "$aside" ] || rm -rf "$aside"
        if [ "$asis" = 1 ]; then
          echo "golem-update: the files in $co do not build here — the machine stays as it was" >&2
        elif [ "$rrc" = 75 ]; then
          echo "golem-update: GitHub could not be asked for ''${new:0:12}'s published pieces — nothing compiled, the machine stays as it was" >&2
        else
          echo "golem-update: ''${new:0:12} does not build here — the machine stays as it was" >&2
        fi
        exit "$rrc"
      fi

      # IT BUILT: the files go in place, and git is told what they are made of
      # (the branch at the new commit; the machine's edits show as changes
      # on top of it, uncommitted, exactly as before the update).
      # (No --delete: what git ignores here — a `result` link, an editor's
      # backup — is the machine's and stays. What the new version removed is
      # removed by name.)
      # (--checksum: by content. By size and time, a file changed twice in
      # one second to the same length would be skipped — .golem-rev is one.)
      if [ "$asis" = 1 ]; then
        # Nothing of the folder changed, and git is told nothing: the files
        # are still of a version it does not have.
        said=$(said_rev)
        echo "golem-update: this machine is on its own system$([ "$action" = boot ] && echo ' from its next start') (Standard ''${said:-of a version}''${said:+, a version} $branch does not know: an update takes the branch's when it is asked)"
        exit 0
      fi
      rsync -a --checksum --exclude=/.git "$try/standard/" "$co/"
      while IFS= read -r -d "" f; do
        rm -f -- "$co/$f"
      done < <(g diff-tree -r -z --name-only --diff-filter=D "$mine" "$final")
      g update-ref "refs/heads/$branch" "$new"
      g symbolic-ref HEAD "refs/heads/$branch"
      g read-tree "$new"
      rm -f "$since" /run/golem-update-now
      if [ -n "$aside" ]; then
        echo "golem-update: files this machine had changed were set aside in $aside (golem-status shows what is still changed)"
        printf '%s\n' "$aside" > "$state/local-edits/latest"
      fi
      echo "golem-update: this machine is on Standard ''${new:0:12}$([ "$action" = boot ] && echo ' from its next start')"
    '';
  };

  # `golem-recover [system]`: Standard's files back to what built a given system
  # (the running one by default). Going back a version — after a crash loop,
  # or asked for in Controls → Updates (desktop/crash-recovery.nix) — switches
  # the generation; without this the folder would still hold the version
  # left behind, and the next rebuild would bring it straight back. Every
  # generation keeps the folder it was built from (/etc/golem/machine), Standard
  # with this machine's edits included. Only standard/ is put back:
  # configuration.nix, modules/ and machine/ are the machine's and stay.
  recover = pkgs.writeShellApplication {
    name = "golem-recover";
    runtimeInputs = [ pkgs.git pkgs.rsync pkgs.coreutils pkgs.diffutils pkgs.gnused ];
    text = ''
      sys=$(readlink -f "''${1:-/run/current-system}")
      kept="$sys/etc/golem/machine/standard"
      # (A system built before the folder had its new name keeps it by the old.)
      [ -f "$kept/flake.nix" ] || kept="$sys/etc/golem/machine/golem"
      ${gitFn}
      if [ ! -f "$kept/flake.nix" ]; then
        echo "golem-recover: $(basename "$sys") keeps no copy of Standard — the folder stays as it is" >&2
        exit 1
      fi
      if diff -rq --exclude=.git "$kept" "$co" >/dev/null 2>&1; then
        echo "golem-recover: $co already holds the Standard that built $(basename "$sys")"
        exit 0
      fi
      # (The kept copy is in the store: read-only files. Here they are root's
      # to edit again.)
      rsync -rlp --checksum --delete --exclude=/.git --chmod=u+w "$kept/" "$co/"
      # What those files are made of: said beside them, or (the medium's
      # baked system keeps Standard as the medium carried it, with no such
      # file) by the system itself.
      rev=""
      [ -f "$co/.golem-rev" ] && rev=$(sed 's/-dirty$//' "$co/.golem-rev")
      if [[ ! "$rev" =~ ^[0-9a-f]{40}$ ]]; then
        rev=$("$sys/sw/bin/nixos-version" --configuration-revision 2>/dev/null | sed 's/-dirty$//' || true)
        if [[ "$rev" =~ ^[0-9a-f]{40}$ ]]; then printf '%s\n' "$rev" > "$co/.golem-rev"; else rev=""; fi
      fi
      if [[ "$rev" =~ ^[0-9a-f]{40}$ ]] && [ -d "$gitdir" ] && g cat-file -e "$rev^{commit}" 2>/dev/null; then
        g update-ref "refs/heads/$branch" "$rev"
        g symbolic-ref HEAD "refs/heads/$branch"
        g read-tree "$rev"
      fi
      echo "golem-recover: $co holds the Standard that built $(basename "$sys") again''${rev:+ (''${rev:0:12})}"
    '';
  };

  # The checkout made from nothing (the installer, on the new disk; a repair).
  checkout = pkgs.writeShellScriptBin "golem-machine-checkout" ''
    export PATH=${lib.makeBinPath [ pkgs.git pkgs.coreutils ]}:$PATH
    exec ${pkgs.bash}/bin/bash ${./checkout.sh} "$@"
  '';
in
{
  options.standard.machine = {
    dir = lib.mkOption {
      type = lib.types.str;
      default = "/etc/nixos";
      description = "Where this machine's own files live on disk.";
    };
    gitDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/golem/golem.git";
      description = "Git's data for root's checkout of Standard (<dir>/standard), kept out of the folder a rebuild copies.";
    };
    source = lib.mkOption {
      type = lib.types.path;
      internal = true;
      description = "The Standard source this system is built from.";
    };
    updateCommand = lib.mkOption {
      type = lib.types.package;
      internal = true;
      readOnly = true;
      description = "golem-update: this machine onto the newest Standard (the nightly update runs it: ./update.nix).";
    };
    folder = lib.mkOption {
      type = lib.types.path;
      internal = true;
      description = "The machine folder as this build saw it (kept with the generation at /etc/golem/machine).";
    };
    profile = lib.mkOption {
      type = lib.types.enum [ "desktop" "minimal" ];
      default = "desktop";
      description = "The stage this machine runs: the desktop, or the base alone (machine/install.json).";
    };
    leaves = lib.mkOption {
      type = lib.types.listOf (lib.types.attrsOf lib.types.str);
      default = [ ];
      internal = true;
      description = "The hardware leaves the chooser pointed at for this machine's facts, each with its why.";
    };
  };

  config = {
    # No checkout in a home: nothing below base/loop.nix's default applies.
    standard.flakeDir = null;
    standard.flakeAttr = "default";

    # Every generation keeps the folder it was built from: the machine's own
    # files and, when Standard is the folder's standard/ (a machine; not a check's
    # fixture), Standard as it was — this machine's edits included. A generation
    # can always be rebuilt, and a folder edited into a state that no longer
    # builds can be put back from the running system (golem-recover).
    # (The folder is the build's own source, already in the store: this is a
    # link to it, not another copy.)
    environment.etc."golem/machine".source = "${cfg.folder}";

    # What Standard's tools and a curious owner ask the system: which layout,
    # and why this hardware got the modules it got.
    environment.etc."golem/layout.json".text = builtins.toJSON {
      layout = "etc-nixos";
      inherit (cfg) dir profile;
      standard = co;
      leaves = cfg.leaves;
    };

    environment.systemPackages = [ rebuildGolem update recover status checkout ];

    # (The folder's old name, see moveFolder: at the activation of every
    # system, a no-op once moved.)
    system.activationScripts.golemMoveFolder = "${moveFolder} || true";
    standard.machine.updateCommand = update;

    # Going back a version puts Standard's files back with it (see `recover`).
    standard.recover = recover;

    # /var/lib/golem holds the secrets (base/users.nix), the update's
    # root-only tries and the checkout's git data: it exists, root's alone,
    # before anything writes there.
    systemd.tmpfiles.rules = [ "d /var/lib/golem 0700 root root -" ];
  };
}
