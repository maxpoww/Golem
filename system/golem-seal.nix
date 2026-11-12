# The seed blessing gate — Golem #56 ("this one can't be Golem's backdoor").
#
# THE HOLE THIS CLOSES
# --------------------
# The seed flake lives in the owner's HOME, owned by the owner — that is
# Golem's philosophy (your system is yours to hack). But the root apply
# helpers rebuild the SYSTEM from it on every app install, so any code
# running as the user could edit the system configuration and get root
# silently: no sudo prompt, ever. The two sanctioned user→system channels
# (waverunner's packages.list, the postinstall answers) are safe — the
# helpers parse them as DATA and generate the Nix themselves — the hole
# was everything else in the tree.
#
# THE GATE
# --------
# Root keeps a manifest (sha256 per file) of the seed OUTSIDE the seed, in
# /var/lib/golem (root-owned, 0700). Before any unattended rebuild, the
# helpers verify the seed against it, EXCLUDING only the two generated
# data channels. A mismatch refuses the rebuild with a clear message:
#
#     sudo golem-bless
#
# `golem-bless` shows what changed and re-seals. Running it as root IS the
# consent — the one password prompt this design ever costs, and only when
# the system configuration itself was edited. App installs, postinstall
# answers, daily use: never prompted.
#
# First run (fresh install / first boot) is trust-on-first-use: no
# manifest yet → the helper seals what the installer wrote and proceeds.
#
# Residual, accepted + documented: an attacker who already has ROOT can
# rewrite the manifest — the gate guards the user→root ESCALATION, not a
# lost root. And the owner's own edits cost one bless, which is the point.

{ config, pkgs, lib, ... }:

let
  flakeDir = config.golem.flakeDir;
  manifestDir = "/var/lib/golem";
  manifest = "${manifestDir}/seed.manifest";
  # A root-only copy of the files as they were last blessed. An app install
  # never waits on an unapproved edit: it builds from this copy instead
  # (waverunner-apply), and the edit applies once its owner approves it.
  snapshotDir = "${manifestDir}/blessed";
  # Root's own mirror of upstream, fetched from the configured URL — never
  # from anything in the owner's .git — to tell upstream code from local edits.
  mirrorDir = "${manifestDir}/upstream.git";
  upstreamUrl = lib.attrByPath [ "golem" "upstream" "url" ] "https://github.com/maxpoww/Golem" config;
  upstreamBranch = lib.attrByPath [ "golem" "upstream" "branch" ] "main" config;

  # The generated data channels (root-written from validated user data) —
  # exempt from the seal because their content never reaches eval as code.
  exempt = [
    "./system/home/waverunner-packages.nix"
    "./system/home/waverunner-packages.nix.last-good"
    "./hosts/target/apps.nix"            # the same channel on the Modular desktop
    "./hosts/target/apps.nix.last-good"
    "./system/postinstall-generated.nix"
    "./system/postinstall-generated.nix.last-good"
  ];
  exemptArgs = lib.concatMapStringsSep " " (p: "! -path ${lib.escapeShellArg p}") exempt;
  # The channels a build needs (their .last-good copies are the helpers' own).
  channels = lib.concatMapStringsSep " " (p: lib.escapeShellArg (lib.removePrefix "./" p))
    (lib.filter (p: !(lib.hasSuffix ".last-good" p)) exempt);

  # Shared manifest computation: "sha256  ./path" lines, NUL-walked, sorted.
  # compute_in DIR for any copy of the tree; compute for the checkout itself.
  computeFn = ''
    compute_in() {
      (cd "$1" && \
        find . -type f \
          ! -path './.git/*' \
          ! -name '*.tmp' \
          ! -name 'result' ! -name 'result-*' \
          ${exemptArgs} \
          -print0 | sort -z | xargs -0 -r sha256sum)
    }
    compute() { compute_in ${lib.escapeShellArg flakeDir}; }
  '';

  # The commit the checkout is at, read from the files themselves (git run
  # inside the owner's repository would obey its config, as root).
  headFn = ''
    read_head() {
      local seed=${lib.escapeShellArg flakeDir} headref ref
      headref=$(cat "$seed/.git/HEAD" 2>/dev/null || true)
      if [[ "$headref" == ref:\ * ]]; then
        ref=''${headref#ref: }
        cat "$seed/.git/$ref" 2>/dev/null || awk -v r="$ref" '$2 == r { print $1 }' "$seed/.git/packed-refs" 2>/dev/null || true
      else
        printf '%s\n' "$headref"
      fi
    }
  '';

  # ROOT BUILDS ITS OWN COPY (2026-11-12, the security study's next step
  # after the three roads). A check of ~/Golem followed by a build of
  # ~/Golem leaves a moment between the two: a program running as the owner
  # could watch root read the files and swap one in before Nix copied the
  # tree. So every root build now reads a root-only copy, made from the
  # snapshot and checked against the manifest file by file; the checkout is
  # only ever compared, never built from.
  #   copy_files SRC DEST LIST  the files LIST names ("<sum>  ./path"), SRC → DEST
  #   data_channels SRC DEST    the generated data files (outside the seal: the
  #                             helpers write them from validated data), as they
  #                             are now; anything but a plain file is left out
  #   write_rev DEST            .golem-rev: the commit, for the flake's
  #                             system.configurationRevision (a copy has no git)
  copyFn = ''
    copy_files() {
      (cd "$1" && cut -c67- "$3" | tr '\n' '\0' | tar --null --no-recursion -T - -cf - 2>/dev/null) \
        | tar -xf - -C "$2" 2>/dev/null || true
    }
    data_channels() {
      local have=() p
      for p in ${channels}; do
        if [[ -e "$1/$p" || -L "$1/$p" ]]; then have+=("$p"); fi
      done
      (( ''${#have[@]} )) || return 0
      (cd "$1" && tar --no-recursion -cf - -- "''${have[@]}" 2>/dev/null) | tar -xf - -C "$2" 2>/dev/null || true
      for p in "''${have[@]}"; do
        if [[ -L "$2/$p" || ! -f "$2/$p" ]]; then rm -rf "''${2:?}/$p"; echo "golem-seal: left out $p (not a plain file)" >&2; fi
      done
    }
    write_rev() {
      local head
      head=$(read_head)
      if [[ "$head" =~ ^[0-9a-f]{40}$ ]]; then printf '%s-dirty\n' "$head" > "$1/.golem-rev"; fi
    }
    new_build_dir() {
      # Copies a crashed run left behind; a running build's is never a day old.
      find ${lib.escapeShellArg manifestDir} -maxdepth 1 -name 'build.*' -mmin +1440 -exec rm -rf {} + 2>/dev/null || true
      mktemp -d ${lib.escapeShellArg manifestDir}/build.XXXXXX
    }
  '';

  # ONE rebuild at a time, for every rebuilder Golem has: the dock's app
  # installs, post-install answers, first boot, the nightly update, Seam's
  # update lane and the owner's rebuild-golem. switch-to-configuration takes
  # its own lock WITHOUT waiting ("Could not acquire lock"), and by then
  # nixos-rebuild has already made the new generation the boot default — so
  # an app install that met the nightly update failed in the dock while the
  # next reboot quietly brought the app in. Here the second rebuilder waits
  # its turn instead. The lock file is Seam's lane's, which already took it.
  rebuild = pkgs.writeShellApplication {
    name = "golem-rebuild";
    runtimeInputs = [ pkgs.util-linux config.system.build.nixos-rebuild ];
    text = ''
      # A caller that holds the lock around MORE than the rebuild (the nightly
      # update: pull → build → recover; a dock install: read → generate →
      # build) says so, and is not made to wait for itself.
      if [ "''${GOLEM_REBUILD_LOCK_HELD:-}" != 1 ]; then
        exec 9>>/run/golem-rebuild.lock
        if ! flock -n 9; then
          echo "golem-rebuild: another system rebuild is running — waiting for it…" >&2
          flock -w 7200 9 || { echo "golem-rebuild: still busy after 2 h — giving up" >&2; exit 1; }
        fi
      fi
      # The version's published cache (updates/client.nix): what the update
      # lane already built is downloaded, not compiled. None published → none.
      extra=()
      ${lib.optionalString (config.golem ? update) ''
        flake=""; prev=""
        for a in "$@"; do
          case "$a" in --flake=*) flake=''${a#--flake=} ;; esac
          if [ "$prev" = --flake ]; then flake=$a; fi
          prev=$a
        done
        if [ -n "$flake" ]; then
          mapfile -t extra < <(${config.golem.update.cacheArgs}/bin/golem-cache-args "''${flake%%#*}" || true)
        fi
      ''}
      nixos-rebuild "$@" "''${extra[@]}"
    '';
  };
  # The root-only snapshot of the blessed files (the seal's own file set,
  # data channels included). stage copies the checkout to $staged, beside
  # it; the seal is then computed FROM that copy, and commit_stage makes the
  # same copy the snapshot. Hashing the checkout and copying it separately
  # left a moment where the two could differ (a file swapped in between):
  # the manifest said one thing and the snapshot, which root builds, held
  # another. Anything but plain files and directories is dropped from the
  # copy (the checkout is the owner's: a swapped-in link is not followed).
  snapshotFn = ''
    stage() {
      staged=${lib.escapeShellArg snapshotDir}.new
      rm -rf "$staged"; mkdir -p "$staged"; chmod 700 "$staged"
      (cd ${lib.escapeShellArg flakeDir} && \
        find . -type f ! -path './.git/*' ! -name '*.tmp' ! -name 'result' ! -name 'result-*' -print0 \
        | tar --null --no-recursion -T - -cf - 2>/dev/null) | tar -xf - -C "$staged" 2>/dev/null || true
      find "$staged" ! -type f ! -type d -delete
    }
    commit_stage() {
      rm -rf ${lib.escapeShellArg snapshotDir}.old
      if [[ -d ${lib.escapeShellArg snapshotDir} ]]; then mv ${lib.escapeShellArg snapshotDir} ${lib.escapeShellArg snapshotDir}.old; fi
      mv "$staged" ${lib.escapeShellArg snapshotDir}
      rm -rf ${lib.escapeShellArg snapshotDir}.old
    }

  '';

  # golem-seal-heal: the checkout changed since the last bless, but maybe
  # only by UPSTREAM's code (a pull nobody re-blessed: a manual deploy, an
  # interrupted update). Root fetches upstream itself and checks every
  # changed file against the commit the checkout says it is at; if each one
  # is byte-for-byte upstream's, that change is trusted exactly like the
  # nightly update's pull, and it re-blesses. Any other change is a local
  # edit and stays the owner's to approve (exit 1, listed).
  #
  # Nothing here runs git INSIDE the owner's repository (its config could
  # name commands git would run as root): HEAD is read from the files, the
  # contents are hashed outside any repository, and the mirror is root's.
  heal = pkgs.writeShellApplication {
    name = "golem-seal-heal";
    runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.gawk pkgs.git pkgs.gnutar pkgs.gnugrep pkgs.diffutils ];
    text = ''
      manifest=${lib.escapeShellArg manifest}
      seed=${lib.escapeShellArg flakeDir}
      mirror=${lib.escapeShellArg mirrorDir}
      ${computeFn}
      ${headFn}
      ${snapshotFn}
      [[ -f "$manifest" ]] || { echo "golem-seal-heal: nothing blessed yet" >&2; exit 1; }
      [[ "$(compute)" == "$(cat "$manifest")" ]] && exit 0

      # The commit the checkout is at, from the files themselves.
      head=$(read_head)
      [[ "$head" =~ ^[0-9a-f]{40}$ ]] || { echo "golem-seal-heal: cannot read the checkout's commit" >&2; exit 1; }

      if [[ ! -d "$mirror" ]]; then git init -q --bare "$mirror"; chmod 700 "$mirror"; fi
      git -C "$mirror" fetch -q --no-tags ${lib.escapeShellArg upstreamUrl} "+refs/heads/${upstreamBranch}:refs/heads/up" \
        || { echo "golem-seal-heal: cannot reach ${upstreamUrl}" >&2; exit 1; }
      if ! git -C "$mirror" cat-file -e "$head^{commit}" 2>/dev/null \
         || ! git -C "$mirror" merge-base --is-ancestor "$head" up; then
        echo "golem-seal-heal: the checkout is at $head, which is not upstream's — a local commit" >&2
        exit 1
      fi

      # Everything below reads root's own copy, never the checkout again:
      # what is checked against upstream is what gets sealed, and the copy
      # becomes the snapshot root builds from.
      stage
      trap 'rm -rf "$staged"' EXIT
      current=$(compute_in "$staged")
      if [[ "$current" == "$(cat "$manifest")" ]]; then commit_stage; trap - EXIT; exit 0; fi

      path_of() { cut -c67-; }   # "<64 hex>  ./path"
      cur_paths=$(printf '%s\n' "$current" | path_of | sort)
      changed=$(comm -23 <(printf '%s\n' "$current" | sort) <(sort "$manifest") | path_of | sort -u)
      removed=$(comm -13 <(printf '%s\n' "$cur_paths") <(path_of < "$manifest" | sort))
      local_edits=()
      # A caller that just put back the machine layer from a system's OWN copy
      # (golem-recover: /etc/golem/machine, in the store) names that copy: a
      # machine file equal to it is the system's, not an edit. Nothing else
      # can vouch for a file that is not upstream's.
      trusted=''${GOLEM_SEAL_TRUSTED_MACHINE:-}
      while IFS= read -r p; do
        [[ -n "$p" ]] || continue
        if [[ -n "$trusted" && "$p" == ./hosts/target/* && "$p" != ./hosts/target/*/* ]] \
           && [[ -f "$trusted/''${p#./hosts/target/}" ]] \
           && cmp -s -- "$trusted/''${p#./hosts/target/}" "$staged/''${p#./}"; then
          continue
        fi
        want=$(git -C "$mirror" rev-parse -q --verify "$head:''${p#./}" 2>/dev/null) || { local_edits+=("$p"); continue; }
        got=$(cd / && git hash-object --no-filters -- "$staged/''${p#./}")
        [[ "$got" == "$want" ]] || local_edits+=("$p")
      done <<< "$changed"
      while IFS= read -r p; do
        [[ -n "$p" ]] || continue
        git -C "$mirror" cat-file -e "$head:''${p#./}" 2>/dev/null && local_edits+=("$p (deleted)")
      done <<< "$removed"

      if (( ''${#local_edits[@]} )); then
        echo "golem-seal-heal: local edits not yet approved (sudo golem-bless):" >&2
        printf '  %s\n' "''${local_edits[@]}" >&2
        exit 1
      fi
      printf '%s\n' "$current" > "$manifest"; chmod 600 "$manifest"
      commit_stage; trap - EXIT
      echo "golem-seal-heal: the checkout is upstream's ''${head:0:7} — re-blessed"
    '';
  };

  # golem-seal-adopt RELPATH NEW [OLD]: a root service changed ONE file of
  # the checkout itself (Seam's lane: the browser pin it took from Mozilla;
  # the nightly update: a migration) — seal that one change and nothing
  # else. A full golem-bless here would also seal whatever else the owner's
  # programs had changed meanwhile (the security study, 2026-11-12). NEW is
  # root's own copy of what it wrote (never re-read from the owner's tree);
  # with OLD, the file must have been the blessed one before the change.
  # The path must already be in the seal.
  adopt = pkgs.writeShellApplication {
    name = "golem-seal-adopt";
    runtimeInputs = [ pkgs.coreutils pkgs.gawk ];
    text = ''
      if [[ "$(id -u)" != 0 ]]; then echo "golem-seal-adopt: root only" >&2; exit 1; fi
      manifest=${lib.escapeShellArg manifest}
      snap=${lib.escapeShellArg snapshotDir}
      rel=''${1:?relpath}; new=''${2:?file}; old=''${3:-}
      case "$rel" in /*|*..*) echo "golem-seal-adopt: bad path $rel" >&2; exit 1 ;; esac
      [[ -f "$manifest" ]] || { echo "golem-seal-adopt: nothing blessed yet" >&2; exit 1; }
      key="./$rel"
      was=$(awk -v k="$key" 'substr($0, 67) == k { print substr($0, 1, 64) }' "$manifest")
      [[ -n "$was" ]] || { echo "golem-seal-adopt: $rel is not in the seal" >&2; exit 1; }
      if [[ -n "$old" ]] && [[ "$(sha256sum < "$old" | cut -c1-64)" != "$was" ]]; then
        echo "golem-seal-adopt: $rel was not the blessed one before the change — not sealing it" >&2
        exit 1
      fi
      sum=$(sha256sum < "$new" | cut -c1-64)
      awk -v k="$key" -v s="$sum" 'substr($0, 67) == k { $0 = s substr($0, 65) } { print }' "$manifest" > "$manifest.new"
      chmod 600 "$manifest.new"; mv "$manifest.new" "$manifest"
      if [[ -d "$snap" ]]; then
        mkdir -p "$snap/$(dirname "$rel")"
        install -m 644 "$new" "$snap/$rel.new" && mv "$snap/$rel.new" "$snap/$rel"
      fi
      echo "golem-seal-adopt: sealed $rel"
    '';
  };

  sealCheck = pkgs.writeShellApplication {
    name = "golem-seal-check";
    runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.diffutils pkgs.gawk pkgs.gnutar ];
    text = ''
      manifest=${lib.escapeShellArg manifest}
      ${computeFn}
      ${snapshotFn}
      if [[ ! -f "$manifest" ]]; then
        # Trust on first use: seal what the installer wrote.
        mkdir -p ${lib.escapeShellArg manifestDir}
        chmod 700 ${lib.escapeShellArg manifestDir}
        stage
        current=$(compute_in "$staged")
        printf '%s\n' "$current" > "$manifest"
        chmod 600 "$manifest"
        commit_stage
        echo "golem-seal: first run — seed sealed ($(printf '%s\n' "$current" | wc -l) files)"
        exit 0
      fi
      current=$(compute)
      # A plain string comparison: `diff -q` stopped reading early and the
      # writer died of SIGPIPE ("printf: write error: Broken pipe"), noise
      # that ended up in the error the dock reports.
      if [[ "$current" == "$(cat "$manifest")" ]]; then
        # Sealed machines from before the snapshot existed get theirs now,
        # from a copy that matches the seal.
        if [[ ! -d ${lib.escapeShellArg snapshotDir} ]]; then
          stage
          if [[ "$(compute_in "$staged")" == "$(cat "$manifest")" ]]; then commit_stage; else rm -rf "$staged"; fi
        fi
        exit 0
      fi
      echo "golem-seal: the system configuration changed since the last blessing." >&2
      echo "golem-seal: changed paths:" >&2
      # < current-only (new/modified), > manifest-only (old/removed).
      diff <(printf '%s\n' "$current") "$manifest" | grep -E '^[<>]' \
        | awk '{print "  " $1 " " $3}' | sort -u -k2 >&2 || true
      echo "golem-seal: review the change, then: sudo golem-bless" >&2
      exit 1
    '';
  };

  bless = pkgs.writeShellApplication {
    name = "golem-bless";
    runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.diffutils pkgs.gawk pkgs.gnutar ];
    text = ''
      if [[ "$(id -u)" != 0 ]]; then
        echo "golem-bless: run with sudo — blessing is the explicit root consent." >&2
        exit 1
      fi
      manifest=${lib.escapeShellArg manifest}
      ${computeFn}
      ${snapshotFn}
      # What is blessed is root's copy, and that copy becomes the snapshot.
      stage
      trap 'rm -rf "$staged"' EXIT
      current=$(compute_in "$staged")
      if [[ -f "$manifest" ]]; then
        if [[ "$current" == "$(cat "$manifest")" ]]; then
          # The snapshot refreshed from the same files (and made, on machines
          # sealed before it existed).
          commit_stage; trap - EXIT
          echo "golem-bless: nothing changed — the seed is already blessed."
          exit 0
        fi
        echo "golem-bless: blessing these changes:"
        diff <(printf '%s\n' "$current") "$manifest" | grep -E '^[<>]' \
          | awk '{print "  " $1 " " $3}' | sort -u -k2 || true
      else
        echo "golem-bless: no previous seal — sealing the seed for the first time."
      fi
      mkdir -p ${lib.escapeShellArg manifestDir}
      chmod 700 ${lib.escapeShellArg manifestDir}
      printf '%s\n' "$current" > "$manifest"
      chmod 600 "$manifest"
      commit_stage; trap - EXIT
      echo "golem-bless: sealed ($(printf '%s\n' "$current" | wc -l) files)."
    '';
  };

  # golem-seal-copy: what every unattended root build builds (the nightly
  # update, Seam's lane, the dock's installs, first boot). Prints a fresh
  # root-only directory holding exactly the sealed files, checked against the
  # manifest, plus the data channels as they are now and .golem-rev. The
  # caller builds `path:<dir>#<attr>` and removes the directory afterwards.
  # A snapshot that does not match the seal is made again from the checkout,
  # but only when the checkout itself matches the seal.
  copy = pkgs.writeShellApplication {
    name = "golem-seal-copy";
    runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.gawk pkgs.gnutar ];
    text = ''
      if [[ "$(id -u)" != 0 ]]; then echo "golem-seal-copy: root only" >&2; exit 1; fi
      manifest=${lib.escapeShellArg manifest}
      snap=${lib.escapeShellArg snapshotDir}
      seed=${lib.escapeShellArg flakeDir}
      ${computeFn}
      ${headFn}
      ${snapshotFn}
      ${copyFn}
      [[ -f "$manifest" ]] || { echo "golem-seal-copy: nothing blessed yet" >&2; exit 1; }
      dest=$(new_build_dir)
      trap 'rm -rf "$dest"' EXIT
      fill() { find "$dest" -mindepth 1 -delete; copy_files "$1" "$dest" "$manifest"; }
      if [[ -d "$snap" ]]; then fill "$snap"; fi
      if [[ ! -d "$snap" || "$(compute_in "$dest")" != "$(cat "$manifest")" ]]; then
        stage
        if [[ "$(compute_in "$staged")" == "$(cat "$manifest")" ]]; then
          commit_stage
          echo "golem-seal-copy: the approved copy was made again from the checkout" >&2
          fill "$snap"
        else
          rm -rf "$staged"
        fi
        if [[ "$(compute_in "$dest")" != "$(cat "$manifest")" ]]; then
          echo "golem-seal-copy: root's copy of the approved files does not match the seal, and neither does $seed — not building" >&2
          exit 1
        fi
      fi
      data_channels "$seed" "$dest"
      write_rev "$dest"
      trap - EXIT
      printf '%s\n' "$dest"
    '';
  };

  # golem-seal-approve ACTION [ARGS]: rebuild-golem, the owner's own build
  # with their password. It used to build ~/Golem and then bless whatever
  # ~/Golem held by the end — a file changed during the build was approved
  # without being built. Now root copies the checkout once, builds that
  # copy, and on success seals that same copy: what is approved is exactly
  # what was built.
  approve = pkgs.writeShellApplication {
    name = "golem-seal-approve";
    runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.diffutils pkgs.gawk pkgs.gnutar ];
    text = ''
      if [[ "$(id -u)" != 0 ]]; then echo "golem-seal-approve: run with sudo" >&2; exit 1; fi
      manifest=${lib.escapeShellArg manifest}
      seed=${lib.escapeShellArg flakeDir}
      ${computeFn}
      ${headFn}
      ${snapshotFn}
      ${copyFn}
      action=''${1:?action (switch, boot)}; shift
      stage
      dest=$(new_build_dir)
      list=$(mktemp)
      trap 'rm -rf "$staged" "$dest" "$list"' EXIT
      current=$(compute_in "$staged")
      printf '%s\n' "$current" > "$list"
      if [[ -f "$manifest" && "$current" != "$(cat "$manifest")" ]]; then
        echo "golem-seal-approve: building and approving these changes:"
        diff <(printf '%s\n' "$current") "$manifest" | grep -E '^[<>]' \
          | awk '{print "  " $1 " " $3}' | sort -u -k2 || true
      fi
      copy_files "$staged" "$dest" "$list"
      data_channels "$staged" "$dest"
      write_rev "$dest"
      ${rebuild}/bin/golem-rebuild "$action" --flake "path:$dest#${config.golem.flakeAttr}" "$@"
      mkdir -p ${lib.escapeShellArg manifestDir}
      chmod 700 ${lib.escapeShellArg manifestDir}
      printf '%s\n' "$current" > "$manifest"
      chmod 600 "$manifest"
      commit_stage
      echo "golem-seal-approve: built and approved ($(printf '%s\n' "$current" | wc -l) files)."
    '';
  };
in
{
  options.golem.seal.check = lib.mkOption {
    type = lib.types.package;
    description = "The seed seal-check tool the root apply helpers gate on.";
  };
  # The re-seal tool, exposed so a TRUSTED unattended channel can re-baseline
  # the manifest without a human bless. Only auto-update uses it, and only
  # after a clean fast-forward pull from upstream (the trust root) — never on
  # a local edit. The interactive `golem-bless` on $PATH is unchanged; this is
  # the same package, referenced by store path.
  options.golem.seal.bless = lib.mkOption {
    type = lib.types.package;
    description = "The seed re-seal tool (golem-bless), for trusted unattended re-baselining.";
  };

  options.golem.seal.heal = lib.mkOption {
    type = lib.types.package;
    description = "golem-seal-heal: re-bless when every change since the last bless is upstream's own code.";
  };
  options.golem.seal.adopt = lib.mkOption {
    type = lib.types.package;
    description = "golem-seal-adopt: seal one file a root service wrote itself, nothing else.";
  };
  options.golem.seal.copy = lib.mkOption {
    type = lib.types.package;
    description = "golem-seal-copy: a root-only copy of exactly the sealed files, for root to build from.";
  };
  options.golem.seal.approve = lib.mkOption {
    type = lib.types.package;
    description = "golem-seal-approve: the owner's rebuild — build a copy of the checkout, then seal that same copy.";
  };
  options.golem.seal.snapshot = lib.mkOption {
    type = lib.types.str;
    default = snapshotDir;
    readOnly = true;
    description = "Root-only copy of the last blessed checkout (installs build from it when local edits are unapproved).";
  };
  options.golem.rebuild = lib.mkOption {
    type = lib.types.package;
    description = "golem-rebuild: nixos-rebuild behind Golem's one rebuild lock (every rebuilder uses it).";
  };

  config = lib.mkMerge [
    { golem.rebuild = rebuild; }
    (lib.mkIf (flakeDir != null) {
      golem.seal.check = sealCheck;
      golem.seal.bless = bless;
      golem.seal.heal = heal;
      golem.seal.adopt = adopt;
      golem.seal.copy = copy;
      golem.seal.approve = approve;
      environment.systemPackages = [ bless approve rebuild ];
    })
  ];
}
