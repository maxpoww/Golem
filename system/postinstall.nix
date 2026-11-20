# The post-install ASK framework (postinstall/postinstall.md, changes.md
# #33's home). Some decisions cannot be made honestly before there is a
# desktop; Golem leaves the machine in a safe holding state (see the
# consuming module, e.g. hardware/gpu-second.nix) and asks exactly once,
# the first time the owner is actually in a position to judge it.
#
# THE ANSWER STORE is one generic id → chosen-option-id map, not one typed
# option per question — the next question this framework grows costs
# NOTHING here (changes.md #33: "a small framework, not a one-off"). A
# consuming module just reads
#   config.golem.postinstall.answers.<id> or <its own safe default>
# — see gpu-second.nix for the one question that exists today.
#
# THE LOOP, four parts, mirroring waverunner-apply.nix's exact machinery
# (user data → validated → git-tracked generated nix → nixos-rebuild
# switch → atomic rollback → status.json) rather than inventing a second
# one, per the spec's own instruction:
#
#   1. golem-install drops hosts/target/postinstall-questions.json — the
#      questions THIS machine triggered (system/hardware/postinstall.nix),
#      computed once, at install time, from the facts this install ran on.
#   2. golem-postinstall-ask (a per-user systemd service, fired on every
#      graphical session start) reads that file, skips anything already
#      SHOWN (~/.config/golem/postinstall-shown.json — "asked once", not a
#      recurring nag, even if never answered), and for anything new pops a
#      small foot terminal and asks. An answer is written to
#      ~/.config/golem/postinstall-answers.json.
#   3. a systemd.path watches that file and fires golem-postinstall-apply
#      (root, oneshot): validate each (id, chosen option) pair against the
#      SHIPPED question set (never trust the answers file's shape — same
#      rule waverunner-apply's packages.list lives by), regenerate
#      system/postinstall-generated.nix, git add it, `nixos-rebuild
#      switch` from root's own copy of the approved files (golem-seal-copy),
#      rollback to last-good on failure.
#   4. the consuming module (gpu-second.nix) reads the newly-set
#      golem.postinstall.answers.<id> on the next eval that rebuild
#      performs, and the machine is now running the owner's actual choice.
#      The generated file is READ AS DATA there, never imported: it sits in
#      the owner's checkout, outside the seal (see parseAnswers below).
{ config, pkgs, lib, ... }:

let
  cfg = config.golem;
  flakeDir = cfg.flakeDir;
  flakeAttr = cfg.flakeAttr;
  user = cfg.owner;
  userHome = "/home/${user}";
  configDir = "${userHome}/.config/golem";
  answersFile = "${configDir}/postinstall-answers.json";
  shownFile = "${configDir}/postinstall-shown.json";
  statusFile = "${configDir}/postinstall-apply-status.json";
  # Where the installer left this machine's questions: in the checkout's
  # machine layer here; a machine of the /etc/nixos layout says its own
  # (system/machine/answers.nix).
  questionsFile = cfg.postinstall.questionsFile;
  generated = "${flakeDir}/system/postinstall-generated.nix";

  askScript = pkgs.writeShellApplication {
    name = "golem-postinstall-ask";
    bashOptions = [ "nounset" "pipefail" ];
    runtimeInputs = [ pkgs.jq pkgs.coreutils pkgs.foot ];
    text = ''
      questions=${lib.escapeShellArg questionsFile}
      answers=${lib.escapeShellArg answersFile}
      shown=${lib.escapeShellArg shownFile}
      mkdir -p "$(dirname "$answers")"

      read_json() { # $1 file  $2 default-json — never fail on missing/empty
        if [[ -s "$1" ]]; then cat "$1"; else printf '%s' "$2"; fi
      }

      # Question ids the shipped set names that this owner has not been
      # shown yet. Cheap and headless — this runs on EVERY graphical
      # session start, so the common case (nothing pending, or everything
      # already shown) must cost nothing visible.
      pending_ids() {
        jq -r --argjson seen "$(read_json "$shown" '[]')" \
          '([.[].id] // []) - $seen | .[]' \
          <(read_json "$questions" '[]') 2>/dev/null || true
      }

      if [[ "''${1:-}" != "--interactive" ]]; then
        ids=$(pending_ids)
        if [[ -z "$ids" ]]; then
          exit 0
        fi
        # Only now — something is actually pending — does a window exist
        # to see. exec, not a subshell: the systemd service tracks THIS
        # process either way.
        exec ${pkgs.foot}/bin/foot --app-id golem-postinstall -e "$0" --interactive
      fi

      mapfile -t ids < <(pending_ids)
      if [[ "''${#ids[@]}" -eq 0 ]]; then
        exit 0
      fi

      for id in "''${ids[@]}"; do
        q=$(jq -c --arg id "$id" '.[] | select(.id == $id)' "$questions")
        title=$(jq -r '.title' <<<"$q")
        body=$(jq -r '.body' <<<"$q")
        mapfile -t optIds < <(jq -r '.options[].id' <<<"$q")
        mapfile -t optLabels < <(jq -r '.options[].label' <<<"$q")

        clear
        printf '%s\n\n%s\n\n' "$title" "$body"
        for i in "''${!optIds[@]}"; do
          printf '  %d) %s\n' "$((i + 1))" "''${optLabels[$i]}"
        done
        printf '\n'

        choice=""
        while [[ -z "$choice" ]]; do
          read -rp "> " ans || exit 0
          if [[ "$ans" =~ ^[0-9]+$ ]] && (( ans >= 1 && ans <= ''${#optIds[@]} )); then
            choice="''${optIds[$((ans - 1))]}"
          else
            echo "please type a number 1-''${#optIds[@]}"
          fi
        done

        # Record SHOWN before the answer: a crash right here must not make
        # this question askable-forever, only answerable-late (the owner
        # can still change it by hand in postinstall-generated.nix).
        jq --arg id "$id" '(. // []) + [$id] | unique' \
          <(read_json "$shown" '[]') > "$shown.new"
        mv "$shown.new" "$shown"

        jq --arg id "$id" --arg v "$choice" '(. // {}) + {($id): $v}' \
          <(read_json "$answers" '{}') > "$answers.new"
        mv "$answers.new" "$answers"
      done

      echo
      echo "Thanks — Golem will finish applying this in the background."
      sleep 2
    '';
  };

  # Run AS THE OWNER by the apply helper (put_as_owner): stdin into a file.
  ownerPut = import ./owner-put.nix pkgs;

  applyScript = pkgs.writeShellApplication {
    name = "golem-postinstall-apply";
    # Own error handling throughout (must always write a status and
    # restore last-good on a failed rebuild) — see waverunner-apply.nix's
    # header for why errexit is dropped here too.
    bashOptions = [ "nounset" "pipefail" ];
    runtimeInputs = [
      config.system.build.nixos-rebuild
      config.nix.package
      config.golem.seal.check
      config.golem.rebuild
      pkgs.git
      pkgs.util-linux # runuser: every write into the owner's folders runs as the owner; flock
      pkgs.jq
      pkgs.coreutils
      pkgs.systemd # #61 reset-failed (clean-PATH: must be declared)
    ];
    text = ''
      answers=${lib.escapeShellArg answersFile}
      status=${lib.escapeShellArg statusFile}
      gen=${lib.escapeShellArg generated}
      flakedir=${lib.escapeShellArg flakeDir}
      lastgood="$gen.last-good"
      started=$(date +%s.%N)

      # Root's own scratch. What root reads from the owner, and what it
      # generates, lives here; nothing is read back from the owner's folders
      # once root has its copy (18-Nov).
      work=$(mktemp -d)
      buildfrom=""
      trap 'rm -rf "$work" ''${buildfrom:+"$buildfrom"}' EXIT

      # Every write into the owner's folders (the checkout, ~/.config/golem)
      # runs AS the owner, and every read from them too. Root writing there
      # by name could be steered: the owner can swap a link in for any name
      # in their own folder between two of root's steps (the old status
      # write moved the file in, then chowned the name, which follows a link
      # to any file on the machine). As the owner, a link leads only to what
      # the owner could already touch.
      put_as_owner() { # $1 root's file   $2 a path in the owner's folders
        runuser -u ${user} -- ${ownerPut} "$2" < "$1"
      }
      read_as_owner() { # $1 a path in the owner's folders   $2 root's file
        runuser -u ${user} -- cat -- "$1" > "$2" 2>/dev/null
      }

      write_status() {
        # $1 phase ("building"|"done")   $2 ok (true|false|null)   $3 error (json string or null)
        printf '{"phase":"%s","ok":%s,"started":%s,"finished":%s,"error":%s}\n' \
          "$1" "$2" "$started" "$(date +%s.%N)" "$3" > "$work/status"
        put_as_owner "$work/status" "$status" 2>/dev/null || true
      }

      # The whole apply under the rebuild lock, as an app install does: the
      # checkout and root's copy are never read while a nightly update has
      # them in flux (golem-seal.nix, base/autoupdate.nix).
      exec 8>>/run/golem-rebuild.lock
      flock -w 7200 8 || true
      export GOLEM_REBUILD_LOCK_HELD=1

      write_status "building" null null

      # #61: clear an orphaned mid-switch transient unit (see
      # waverunner-apply.nix) so a switch after a crash isn't refused.
      systemctl reset-failed nixos-rebuild-switch-to-configuration.service 2>/dev/null || true

      # The seed blessing gate (#56, golem-seal.nix) — same guard as
      # waverunner-apply: the answers file is validated DATA (exempt);
      # everything else in the tree must match the blessed manifest.
      if ! sealmsg=$(golem-seal-check 2>&1); then
        errjson=$(printf '%s' "$sealmsg" | tail -c 2000 | jq -Rs .)
        write_status "done" false "$errjson"
        echo "$sealmsg" >&2
        exit 1
      fi

      # Root's copy of the approved files (golem-seal-copy): what gets built.
      # It used to build the checkout itself, which the owner can change
      # after the gate above looked at it.
      if ! out=$(${config.golem.seal.copy}/bin/golem-seal-copy 2>&1); then
        errjson=$(printf 'Golem could not prepare its copy of the system files: %s' "$out" | tail -c 2000 | jq -Rs .)
        write_status "done" false "$errjson"
        echo "$out" >&2
        exit 1
      fi
      buildfrom=$(printf '%s\n' "$out" | tail -n 1)

      # Validate: keep only (id, optionId) pairs the SHIPPED question set
      # actually declares — the set in root's copy, which the seal checked,
      # not the checkout's. The answers file is owner-writable data, never
      # trusted structure — same rule waverunner-apply's packages.list
      # lives by (an unknown id, a stale id from an older question set, or
      # an option id that question never offered are all silently
      # dropped, not evaluated). Both must also be plain words (letters,
      # digits, . _ -): the only shape the generated file is read back by.
      questions="$buildfrom/hosts/target/postinstall-questions.json"
      pairs="{}"
      if read_as_owner "$answers" "$work/answers" && [[ -s "$work/answers" && -f "$questions" ]]; then
        pairs=$(jq -c -n \
          --slurpfile ans "$work/answers" \
          --slurpfile qs "$questions" \
          '
            def word: type == "string" and test("^[A-Za-z0-9._-]+$");
            ($ans[0] // {}) as $a
            | ($qs[0] // []) as $q
            | if ($a | type) != "object" then {} else
              reduce ($a | to_entries[]) as $e ({};
                (($q[] | select(.id == $e.key)) // null) as $question
                | if $question != null
                     and ($e.key | word) and ($e.value | word)
                     and (([$question.options[].id]) | index($e.value)) != null
                  then . + {($e.key): $e.value}
                  else .
                  end)
              end
          ') || pairs="{}"
      fi

      # Generate the answers file from the validated pairs, in root's own
      # scratch. It keeps the shape of a Nix module so an older Golem (going
      # back a version) still reads it; this one reads it as data only
      # (golem.postinstall.generatedFile below).
      {
        echo "# Generated by golem-postinstall-apply from postinstall-answers.json. Do not edit by hand."
        echo "{ ... }:"
        echo "{"
        echo "  golem.postinstall.answers = {"
        printf '%s\n' "$pairs" | jq -r 'to_entries[] | "    \"\(.key)\" = \"\(.value)\";"'
        echo "  };"
        echo "}"
      } > "$work/generated"
      # Into the copy that gets built, from root's own file …
      install -D -m644 "$work/generated" "$buildfrom/system/postinstall-generated.nix"
      # … and into the checkout, as the owner: the record of what was
      # answered, and what the next unattended build (the nightly update, an
      # app install) carries through the seal's data channels. Tracked, so a
      # flake reading the checkout (rebuild-golem) sees it too.
      if ! put_as_owner "$work/generated" "$gen"; then
        msg="Golem could not write the answer into the system folder ($gen)."
        write_status "done" false "$(printf '%s' "$msg" | jq -Rs .)"
        echo "$msg" >&2
        exit 1
      fi
      runuser -u ${user} -- git -C "$flakedir" add system/postinstall-generated.nix || true  # the checkout is the owner\'s: git writes run as them

      # #35c: the switch's exit code proves the rebuild ran; it does NOT
      # prove the answers reached the system — #35 was `ok:true` over a
      # switch that evaluated a config which never imported them. Map each
      # answered question to the observable its option implies, and refuse
      # ok:true unless every mapped observable is present in the SWITCHED
      # system (and its rival absent). An id without a mapping verifies
      # vacuously — a new question should ship with its check. On failure
      # the generated file is NOT rolled back: the answer is right, the
      # wiring is broken, and hiding that is the #35 lie again.
      verify_effect() {
        local id opt want lose
        while IFS=$'\t' read -r id opt; do
          want=""; lose=""
          case "$id:$opt" in
            gpu2-failing-action:hold) want=golem-dgpu-hold.service; lose=golem-dgpu-off.service ;;
            gpu2-failing-action:off)  want=golem-dgpu-off.service;  lose=golem-dgpu-hold.service ;;
          esac
          [[ -n "$want" ]] || continue
          if ! systemctl cat "$want" >/dev/null 2>&1; then
            echo "answer $id=$opt: expected $want in the switched system, not found"
            return 1
          fi
          if systemctl cat "$lose" >/dev/null 2>&1; then
            echo "answer $id=$opt: rival $lose still present in the switched system"
            return 1
          fi
        done < <(printf '%s\n' "$pairs" | jq -r 'to_entries[] | "\(.key)\t\(.value)"')
        return 0
      }

      # Shared success tail for both switch-ok paths: effect verified →
      # ok:true; effect missing → ok:false with the reason (#35c).
      finish_ok() {
        local effmsg
        # Staged for the next start (golem-rebuild: the first session after
        # an install): the effect is not in the running system to be found.
        if [ -e /run/golem-rebuild-staged ]; then
          rm -f /run/golem-rebuild-staged
          put_as_owner "$work/generated" "$lastgood" || true
          write_status "done" true null
          return 0
        fi
        if effmsg=$(verify_effect); then
          put_as_owner "$work/generated" "$lastgood" || true
          write_status "done" true null
        else
          errjson=$(printf '%s' "switch succeeded but the effect is missing — $effmsg" | jq -Rs .)
          write_status "done" false "$errjson"
          echo "postinstall-apply: $effmsg" >&2
          exit 1
        fi
      }

      # A switch that activated the system but hit a per-user activation
      # error still exits non-zero (switch-to-configuration-ng exit 4, AFTER
      # the system switched) — run as root here, root has no `systemd --user`
      # manager so its per-user activation always fails. That is not an apply
      # failure: the answer WAS applied. Check whether the system generation
      # actually changed and treat that as success (Golem #44; mirrors
      # system/waverunner-apply.nix).
      before=$(readlink -f /run/current-system 2>/dev/null || echo none)
      if err=$(golem-rebuild switch --flake "path:$buildfrom#${flakeAttr}" 2>&1); then
        finish_ok
      elif after=$(readlink -f /run/current-system 2>/dev/null); [[ -n "$after" && "$after" != "$before" ]]; then
        grep -qi "user activation" <<< "$err" \
          && echo "postinstall-apply: system switched; a user-activation warning was ignored (#44)" >&2
        finish_ok
      else
        if read_as_owner "$lastgood" "$work/lastgood" && [[ -s "$work/lastgood" ]]; then
          put_as_owner "$work/lastgood" "$gen" || true
          runuser -u ${user} -- git -C "$flakedir" add system/postinstall-generated.nix || true  # the checkout is the owner\'s: git writes run as them
        fi
        errjson=$(printf '%s' "$err" | tail -c 4000 | jq -Rs .)
        write_status "done" false "$errjson"
        echo "$err" >&2
        exit 1
      fi
    '';
  };

  # The owner's applied answers, READ AS DATA (18-Nov), never imported.
  # system/postinstall-generated.nix sits in the owner's checkout and the
  # seal exempts it (golem-seal.nix), so what it holds may have been written
  # by any program running as the owner, not by the apply helper above.
  # Imported, it was a system module: root's next build ran whatever it
  # said, a road from the owner to root with no password (found 17-Nov in
  # the review of main). Now only lines of the helper's own shape count,
  #     "id" = "option";
  # both plain words (letters, digits, . _ -); every other line is ignored.
  answerLine = ''[[:space:]]*"([A-Za-z0-9._-]+)"[[:space:]]*=[[:space:]]*"([A-Za-z0-9._-]+)";[[:space:]]*'';
  parseAnswers = text: lib.listToAttrs (map
    (m: lib.nameValuePair (builtins.elemAt m 0) (builtins.elemAt m 1))
    (lib.filter (m: m != null) (map (builtins.match answerLine) (lib.splitString "\n" text))));
in
{
  # The answer→system edge. golem-postinstall-apply writes the owner's
  # answers into ./postinstall-generated.nix and rebuilds — but a written
  # file changes nothing unless something READS it, and nothing did: the
  # first live run of #33 (ASUS, 2026-09-09) answered "off", watched the
  # rebuild report ok, and found golem-dgpu-hold still running — the
  # generated file was never part of the evaluation. It was then imported
  # as a module, which made it code (see parseAnswers above); now it is read
  # as data. The desktop and facts matrices point generatedFile at a
  # fixture with code in it and check that only the answer arrives.
  options.golem.postinstall.generatedFile = lib.mkOption {
    type = lib.types.nullOr lib.types.path;
    default = if builtins.pathExists ./postinstall-generated.nix then ./postinstall-generated.nix else null;
    defaultText = lib.literalExpression "./postinstall-generated.nix, once the first answer is applied";
    internal = true;
    description = "The applied post-install answers, read as data (never imported).";
  };

  options.golem.postinstall.questionsFile = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = if flakeDir != null then "${flakeDir}/hosts/target/postinstall-questions.json" else null;
    defaultText = lib.literalExpression ''"''${config.golem.flakeDir}/hosts/target/postinstall-questions.json"'';
    internal = true;
    description = "The questions the installer left for this machine's owner (a JSON list), on the machine's disk; null: nothing is asked.";
  };

  # The answers' option (golem.postinstall.answers) is DECLARED by each
  # profile, not here: the modular one in base/options.nix (its gpu2 leaf
  # reads it on stage-0 minimal too), the old one in configuration.nix. This
  # module is the ask/apply pipeline only, so both can import it.

  config = lib.mkMerge [
  {
    golem.postinstall.answers = lib.mkIf (cfg.postinstall.generatedFile != null)
      (parseAnswers (builtins.readFile cfg.postinstall.generatedFile));
  }
  (lib.mkIf (flakeDir != null) {
    environment.systemPackages = [ applyScript ];

    systemd.services.golem-postinstall-apply = {
      description = "Apply the owner's post-install answers (nixos-rebuild switch --flake)";
      # Same as waverunner-apply: this unit drives the switch, so a
      # change to its own definition must never stop the running
      # instance mid-switch (#58). Oneshot picks up new definitions on
      # the next run.
      restartIfChanged = false;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${applyScript}/bin/golem-postinstall-apply";
      };
    };

    systemd.paths.golem-postinstall-apply = {
      description = "Watch postinstall-answers.json for a new answer";
      wantedBy = [ "multi-user.target" ];
      pathConfig = {
        PathChanged = answersFile;
        Unit = "golem-postinstall-apply.service";
      };
    };

  })
  # THE ASKING is the same on both layouts: it only needs to know where the
  # questions are (the applying is each layout's own).
  (lib.mkIf (cfg.postinstall.questionsFile != null) {
    environment.systemPackages = [ askScript ];

    # Runs on every graphical session start; exits in milliseconds with no
    # window at all unless something is actually pending (see the script).
    home-manager.users.${user}.systemd.user.services.golem-postinstall-ask = {
      Unit = {
        Description = "Ask any pending post-install questions (changes.md #33)";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${askScript}/bin/golem-postinstall-ask";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  })
  ];
}
