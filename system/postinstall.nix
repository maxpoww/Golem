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
#      switch`, rollback to last-good on failure.
#   4. the consuming module (gpu-second.nix) reads the newly-set
#      golem.postinstall.answers.<id> on the next eval that rebuild
#      performs, and the machine is now running the owner's actual choice.
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
  questionsFile = "${flakeDir}/hosts/target/postinstall-questions.json";
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

  applyScript = pkgs.writeShellApplication {
    name = "golem-postinstall-apply";
    # Own error handling throughout (must always write a status and
    # restore last-good on a failed rebuild) — see waverunner-apply.nix's
    # header for why errexit is dropped here too.
    bashOptions = [ "nounset" "pipefail" ];
    runtimeInputs = [
      config.system.build.nixos-rebuild
      config.nix.package
      pkgs.git
      pkgs.jq
      pkgs.coreutils
    ];
    text = ''
      questions=${lib.escapeShellArg questionsFile}
      answers=${lib.escapeShellArg answersFile}
      status=${lib.escapeShellArg statusFile}
      gen=${lib.escapeShellArg generated}
      flakedir=${lib.escapeShellArg flakeDir}
      lastgood="$gen.last-good"
      started=$(date +%s.%N)

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

      # Validate: keep only (id, optionId) pairs the SHIPPED question set
      # actually declares. The answers file is owner-writable data, never
      # trusted structure — same rule waverunner-apply's packages.list
      # lives by (an unknown id, a stale id from an older question set, or
      # an option id that question never offered are all silently
      # dropped, not evaluated).
      pairs="{}"
      if [[ -f "$answers" && -f "$questions" ]]; then
        pairs=$(jq -c -n \
          --slurpfile ans "$answers" \
          --slurpfile qs "$questions" \
          '
            ($ans[0] // {}) as $a
            | ($qs[0] // []) as $q
            | reduce ($a | to_entries[]) as $e ({};
                (($q[] | select(.id == $e.key)) // null) as $question
                | if $question != null
                     and (([$question.options[].id]) | index($e.value)) != null
                  then . + {($e.key): $e.value}
                  else .
                  end)
          ')
      fi

      # Generate the root-owned Nix from the validated pairs, and make sure
      # the flake can see it (tracked file; dirty is fine — same git-add
      # trick waverunner-apply uses, for the same reason: a flake cannot
      # read outside its tree, and an untracked file is invisible to it).
      {
        echo "# Generated by golem-postinstall-apply from postinstall-answers.json. Do not edit by hand."
        echo "{ ... }:"
        echo "{"
        echo "  golem.postinstall.answers = {"
        echo "$pairs" | jq -r 'to_entries[] | "    \"\(.key)\" = \"\(.value)\";"'
        echo "  };"
        echo "}"
      } > "$gen.new"
      mv "$gen.new" "$gen"
      git -C "$flakedir" add system/postinstall-generated.nix || true

      if err=$(nixos-rebuild switch --flake "$flakedir#${flakeAttr}" 2>&1); then
        cp -f "$gen" "$lastgood"
        write_status "done" true null
      else
        if [[ -f "$lastgood" ]]; then
          cp -f "$lastgood" "$gen"
          git -C "$flakedir" add system/postinstall-generated.nix || true
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
  # The answer→system edge. golem-postinstall-apply writes the owner's
  # answers into ./postinstall-generated.nix and rebuilds — but a written
  # file changes nothing unless something IMPORTS it, and nothing did:
  # the first live run of #33 (ASUS, 2026-09-09) answered "off", watched
  # the rebuild report ok, and found golem-dgpu-hold still running —
  # the generated module was never part of the evaluation. (The eval
  # matrix could not catch this: its rows set golem.postinstall.answers
  # directly, bypassing the import.) Path-conditional, not
  # config-conditional — `imports` cannot depend on `config`, and
  # pathExists resolves at eval time: absent on a fresh install (the
  # option's default {} = every question's safe default), present from
  # the first applied answer onward.
  imports = lib.optional (builtins.pathExists ./postinstall-generated.nix)
    ./postinstall-generated.nix;

  options.golem.postinstall.answers = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    internal = true;
    description = ''
      Post-install question answers already applied to this machine, id →
      chosen option id. Set only by the generated
      system/postinstall-generated.nix (regenerated by
      golem-postinstall-apply from the owner's answer) — nothing reads
      this directly; each question's consuming module keys off its own id
      to decide which branch to take, falling back to that question's
      documented safe default for any id it does not recognize.
    '';
  };

  config = lib.mkIf (flakeDir != null) {
    environment.systemPackages = [ askScript applyScript ];

    systemd.services.golem-postinstall-apply = {
      description = "Apply the owner's post-install answers (nixos-rebuild switch --flake)";
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
  };
}
