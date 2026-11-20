# machine/answers — THE POST-INSTALL ANSWERS on a machine of the /etc/nixos
# layout. (The framework, and the asking, are system/postinstall.nix: some
# decisions cannot be made honestly before there is a desktop, so Golem asks
# once, after the first login.)
#
# What differs here is where things are and who may write them:
#
#   /etc/nixos/machine/questions.json   the questions the installer left
#                                       (root's; the ask reads it)
#   ~/.config/golem/postinstall-answers.json
#                                       what the owner answered: DATA, read
#                                       as the owner
#   /etc/nixos/machine/answers.list     the answers that passed, one
#                                       `"question" = "option";` a line, read
#                                       as data by the build (never imported)
#
# An answer counts only if its question is one of this machine's and its
# option is one of that question's. As with the dock's installs
# (./apps.nix), the new list is built first in a root-only copy of the
# folder: the one in /etc/nixos changes only when that system built,
# switched, and shows the answer's effect.
{ config, pkgs, lib, ... }:

let
  cfg = config.golem.machine;
  user = config.golem.owner;
  userHome = config.users.users.${user}.home;
  configDir = "${userHome}/.config/golem";
  answersFile = "${configDir}/postinstall-answers.json";
  statusFile = "${configDir}/postinstall-apply-status.json";
  questionsFile = "${cfg.dir}/machine/questions.json";
  answersList = "${cfg.dir}/machine/answers.list";
  ownerPut = import ../owner-put.nix pkgs;

  applyScript = pkgs.writeShellApplication {
    name = "golem-postinstall-apply";
    bashOptions = [ "nounset" "pipefail" ];
    runtimeInputs = [
      config.golem.rebuild
      pkgs.util-linux # runuser, flock
      pkgs.rsync
      pkgs.jq
      pkgs.coreutils
      pkgs.systemd
    ];
    text = ''
      answers=${lib.escapeShellArg answersFile}
      status=${lib.escapeShellArg statusFile}
      dir=${lib.escapeShellArg cfg.dir}
      questions=${lib.escapeShellArg questionsFile}
      list=${lib.escapeShellArg answersList}
      started=$(date +%s.%N)

      work=$(mktemp -d)
      try=""
      trap 'rm -rf "$work" ''${try:+"$try"}' EXIT
      trap 'exit 143' TERM   # stopped (a shutdown in the middle): the EXIT trap still runs
      trap 'exit 130' INT

      put_as_owner() { # $1 root's file   $2 a path in the owner's folders
        runuser -u ${user} -- ${ownerPut} "$2" < "$1"
      }
      read_as_owner() { # $1 a path in the owner's folders   $2 root's file
        runuser -u ${user} -- cat -- "$1" > "$2" 2>/dev/null
      }
      write_status() {
        printf '{"phase":"%s","ok":%s,"started":%s,"finished":%s,"error":%s}\n' \
          "$1" "$2" "$started" "$(date +%s.%N)" "$3" > "$work/status"
        put_as_owner "$work/status" "$status" 2>/dev/null || true
      }

      exec 8>>/run/golem-rebuild.lock
      flock -w 7200 8 || true
      export GOLEM_REBUILD_LOCK_HELD=1

      write_status "building" null null
      systemctl reset-failed nixos-rebuild-switch-to-configuration.service 2>/dev/null || true

      # Only an answer to one of THIS machine's questions, naming one of that
      # question's options, both plain words: the only shape the list is
      # read back by (system/postinstall.nix, parseAnswers).
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

      new="$work/answers.list"
      {
        echo "# The answers given to Golem's questions after the install (\"question\" = \"answer\";)."
        echo "# Written by golem-postinstall-apply from the owner's answers; data, never code."
        printf '%s\n' "$pairs" | jq -r 'to_entries[] | "\"\(.key)\" = \"\(.value)\";"'
      } > "$new"
      chmod 644 "$new"

      # A ROOT-ONLY COPY OF THE FOLDER with the new answers, and the build.
      install -d -m 700 /var/lib/golem
      find /var/lib/golem -maxdepth 1 -name 'answers.*' -mmin +1440 -exec rm -rf {} + 2>/dev/null || true
      try=$(mktemp -d /var/lib/golem/answers.XXXXXX)
      rsync -a --exclude=/golem/.git "$dir/" "$try/"
      install -D -m 644 "$new" "$try/machine/answers.list"

      # Prove the answer's EFFECT in the switched system, not just that the
      # switch ran (the first live run reported ok and changed nothing).
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
      finish_ok() {
        local effmsg
        # Staged for the next start (golem-rebuild: the first session after
        # an install): the effect is not in the running system to be found.
        if [ -e /run/golem-rebuild-staged ]; then
          rm -f /run/golem-rebuild-staged
          install -d -m 755 "$dir/machine"
          install -m 644 "$new" "$list.new" && mv -f "$list.new" "$list"
          write_status "done" true null
          return 0
        fi
        if effmsg=$(verify_effect); then
          install -d -m 755 "$dir/machine"
          install -m 644 "$new" "$list.new" && mv -f "$list.new" "$list"
          write_status "done" true null
        else
          errjson=$(printf '%s' "switch succeeded but the effect is missing — $effmsg" | jq -Rs .)
          write_status "done" false "$errjson"
          echo "postinstall-apply: $effmsg" >&2
          exit 1
        fi
      }

      before=$(readlink -f /run/current-system 2>/dev/null || echo none)
      if err=$(golem-rebuild switch --flake "path:$try#default" 2>&1); then
        finish_ok
      elif after=$(readlink -f /run/current-system 2>/dev/null); [[ -n "$after" && "$after" != "$before" ]]; then
        grep -qi "user activation" <<< "$err" \
          && echo "postinstall-apply: system switched; a user-activation warning was ignored" >&2
        finish_ok
      else
        errjson=$(printf '%s' "$err" | tail -c 4000 | jq -Rs .)
        write_status "done" false "$errjson"
        echo "$err" >&2
        exit 1
      fi
    '';
  };
in
{
  options.golem.machine.answersCommand = lib.mkOption {
    type = lib.types.package;
    internal = true;
    readOnly = true;
    description = "golem-postinstall-apply: the owner's post-install answers into machine/answers.list, then a rebuild.";
  };

  config = {
    golem.machine.answersCommand = applyScript;
    # The asking (system/postinstall.nix) reads this machine's questions here.
    golem.postinstall.questionsFile = questionsFile;

    environment.systemPackages = [ applyScript ];

    systemd.services.golem-postinstall-apply = {
      description = "Apply the owner's post-install answers (machine/answers.list, then nixos-rebuild switch)";
      restartIfChanged = false;   # it drives the switch: never stopped by it
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
  };
}
