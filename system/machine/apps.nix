# machine/apps — THE DOCK'S INSTALLS on a machine of the /etc/nixos layout.
#
# The twin of system/waverunner-apply.nix (the checkout-in-a-home layout),
# with the same door and the same promises, and none of the seal:
#
#   THE ONE DOOR. The only thing the owner's programs can write is DATA:
#     ~<owner>/.config/waverunner/packages.list   (one nixpkgs name a line)
#   This helper (root) reads that file AS THE OWNER, validates every line
#   (^[a-zA-Z0-9][a-zA-Z0-9._-]*$) and writes the accepted names to
#     /etc/nixos/machine/apps.list
#   which the build reads as text and looks up (./lists.nix): never Nix.
#
#   NEVER A BROKEN FOLDER. The new list is built first in a root-only copy
#   of /etc/nixos; machine/apps.list changes only when that system built and
#   switched. So the list in the folder is always the last one that worked,
#   and a failed install leaves nothing to put back.
#
#   THE SAME NAMES. waverunner-apply.service / .path, the status file the
#   dock reads (apply-status.json, written as the owner), the retries on a
#   passing network problem, the words an owner is told when it fails.
{ config, pkgs, lib, ... }:

let
  cfg = config.standard.machine;
  user = config.standard.owner;
  userHome = config.users.users.${user}.home;
  listFile = "${userHome}/.config/waverunner/packages.list";
  statusFile = "${userHome}/.config/waverunner/apply-status.json";
  appsList = "${cfg.dir}/machine/apps.list";
  golemSay = pkgs.callPackage ../i18n/golem-say.nix { };
  ownerPut = import ../owner-put.nix pkgs;

  applyScript = pkgs.writeShellApplication {
    name = "waverunner-apply";
    # It does its own error handling (it must always write a status), so no
    # errexit: nounset + pipefail.
    bashOptions = [ "nounset" "pipefail" ];
    runtimeInputs = [
      config.standard.rebuild
      config.nix.package
      pkgs.gnugrep
      pkgs.glibc.bin # getent: the connectivity wait
      pkgs.util-linux # runuser, flock
      pkgs.rsync
      pkgs.jq
      pkgs.libnotify
      golemSay
      pkgs.coreutils
      pkgs.systemd
    ];
    text = ''
      list=${lib.escapeShellArg listFile}
      status=${lib.escapeShellArg statusFile}
      dir=${lib.escapeShellArg cfg.dir}
      apps=${lib.escapeShellArg appsList}
      work=$(mktemp -d)
      try=""
      trap 'rm -rf "$work" ''${try:+"$try"}' EXIT
      trap 'exit 143' TERM   # stopped (a shutdown in the middle): the EXIT trap still runs
      trap 'exit 130' INT

      # The owner's files are read and written AS THE OWNER: root following a
      # path inside a home follows whatever link a program put there.
      put() {   # put SRC DEST: root's file SRC into DEST in the owner's folders
        runuser -u ${user} -- ${ownerPut} "$2" < "$1"
      }
      take() {  # take SRC DEST: SRC in the owner's folders, into root's DEST
        if runuser -u ${user} -- cat -- "$1" > "$2" 2>/dev/null; then return 0; fi
        rm -f "$2"; return 1
      }
      started=$(date +%s.%N)
      say() { GOLEM_SETTINGS=${lib.escapeShellArg "${userHome}/.config/golem/settings.json"} golem-say "$@"; }
      notify() {  # notify TITLE BODY, on the owner's desktop when they have one
        local uid; uid=$(id -u ${user})
        if [ -S "/run/user/$uid/bus" ]; then
          runuser -u ${user} -- env DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
            notify-send -a Golem "$1" "$2" || true
        fi
      }
      write_status() {
        printf '{"phase":"%s","ok":%s,"started":%s,"finished":%s,"error":%s}\n' \
          "$1" "$2" "$started" "$(date +%s.%N)" "$3" > "$work/status"
        put "$work/status" "$status" 2>/dev/null || true
      }

      # One rebuild at a time, held from the read of the list to the file put
      # in place (the nightly update takes the same lock).
      exec 8>>/run/golem-rebuild.lock
      flock -w 7200 8 || true
      export GOLEM_REBUILD_LOCK_HELD=1

      if [ ! -f "$dir/flake.nix" ]; then
        write_status "done" false "\"this machine has no $dir\""
        echo "waverunner-apply: no $dir/flake.nix — nothing to build" >&2
        exit 1
      fi

      # THE LIST, read as the owner. One cut off by a full disk (no header, or
      # no final newline) would uninstall every app not on it: the last list
      # that applied is put back instead, and nothing changes.
      listgood="$list.last-good"
      haslist=false
      if take "$list" "$work/list"; then
        haslist=true
      elif [ -e "$list" ] || [ -L "$list" ]; then
        echo "waverunner-apply: the app list cannot be read as its owner — changing nothing" >&2
        write_status "done" false "\"the app list could not be read; nothing changed\""
        exit 0
      fi
      listok() { [ -s "$work/list" ] && head -n 1 "$work/list" | grep -q '^# waverunner declarative packages' && [ -z "$(tail -c 1 "$work/list")" ]; }
      if [ "$haslist" = true ] && ! listok; then
        if runuser -u ${user} -- test -f "$listgood"; then
          echo "waverunner-apply: the app list is cut off (a full disk?) — restoring the last one applied" >&2
          runuser -u ${user} -- cp -- "$listgood" "$list" || true
          notify "$(say "Golem couldn't save the change to your apps")" \
            "$(say "The disk may be full. Nothing was removed; free some space and try again.")"
        else
          echo "waverunner-apply: the app list is cut off and there is no earlier one — changing nothing" >&2
        fi
        write_status "done" false "\"the app list was cut off; nothing changed\""
        exit 0
      fi
      write_status "building" null null

      # A click while this run builds changes the list again: apply once more
      # (at most five passes) so the last click is never lost.
      again_if_list_changed() {
        local pass="''${GOLEM_APPLY_PASS:-1}"
        local now=none
        if take "$list" "$work/list.now"; then now=$(sha256sum < "$work/list.now"); fi
        if [[ "$now" != "$listsum" && "$pass" -lt 5 ]]; then
          echo "waverunner-apply: the list changed during the rebuild — applying again (pass $((pass + 1)))" >&2
          rm -rf "$work" ''${try:+"$try"}   # the exec skips the trap
          GOLEM_APPLY_PASS=$((pass + 1)) exec "$0"
        fi
      }
      listsum=$(sha256sum < "$work/list" 2>/dev/null || echo none)

      # EVERY LINE IS ONE NAME, or it is not written.
      new="$work/apps.list"
      {
        echo "# The programs installed from the dock: one nixpkgs name a line."
        echo "# Written by waverunner-apply from the owner's list; data, never code."
        if [[ -f "$work/list" ]]; then
          while IFS= read -r line || [[ -n "$line" ]]; do
            line="''${line%%#*}"
            line="$(printf '%s' "$line" | tr -d '[:space:]')"
            [[ -n "$line" ]] || continue
            if [[ "$line" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]]; then
              echo "$line"
            else
              echo "waverunner-apply: rejected invalid entry: $line" >&2
            fi
          done < "$work/list"
        fi
      } > "$new"
      chmod 644 "$new"

      # A ROOT-ONLY COPY OF THE FOLDER with the new list, and the build.
      install -d -m 700 /var/lib/golem
      find /var/lib/golem -maxdepth 1 -name 'apply.*' -mmin +1440 -exec rm -rf {} + 2>/dev/null || true
      try=$(mktemp -d /var/lib/golem/apply.XXXXXX)
      rsync -a --exclude=/standard/.git "$dir/" "$try/"
      install -D -m 644 "$new" "$try/machine/apps.list"
      flakeref="path:$try#default"

      systemctl reset-failed nixos-rebuild-switch-to-configuration.service 2>/dev/null || true

      # A passing network problem is tried again (a download that broke, a
      # DNS that blinked); anything else fails at once.
      transient() {
        grep -qiE 'unable to download|Could not resolve|resolve host|Connection (reset|refused|timed out)|timed out|Network is unreachable|Failure when receiving|Operation too slow|HTTP error (5[0-9][0-9]|429)|error: download|curl error|SSL|TLS|cannot connect|Could not acquire lock|No space left on device|unexpected end of file|Temporary failure'
      }
      wait_online() {
        for _ in $(seq 1 60); do getent ahosts cache.nixos.org >/dev/null 2>&1 && return 0; sleep 5; done
        return 1
      }
      attempt=1; backoff=20; ok=no; err=""
      while :; do
        before=$(readlink -f /run/current-system 2>/dev/null || echo none)
        if err=$(golem-rebuild switch --flake "$flakeref" 2>&1); then
          ok=yes
        elif after=$(readlink -f /run/current-system 2>/dev/null); [[ -n "$after" && "$after" != "$before" ]]; then
          # The system switched; what failed came after (a user's activation).
          grep -qi "user activation" <<< "$err" \
            && echo "waverunner-apply: system switched; a user-activation warning was ignored" >&2
          ok=yes
        fi
        [[ "$ok" == yes ]] && break
        if (( attempt < 6 )) && transient <<< "$err"; then
          echo "waverunner-apply: attempt $attempt hit a passing problem — retrying in ''${backoff}s:" >&2
          printf '%s\n' "$err" | tail -n 3 >&2
          if grep -qi 'No space left on device' <<< "$err"; then
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
        # It built and switched: the list goes in the folder (whole, or not).
        install -d -m 755 "$dir/machine"
        install -m 644 "$new" "$apps.new" && mv -f "$apps.new" "$apps"
        if listok; then put "$work/list" "$listgood" || true; fi
        again_if_list_changed
        write_status "done" true null
        # Built, but for the next start (golem-rebuild: the first session
        # after an install, before the owner's account has its name).
        if [ -e /run/golem-rebuild-staged ]; then
          rm -f /run/golem-rebuild-staged
          notify "$(say "Your apps arrive at the next restart")" \
            "$(say "This computer is still finishing its setup. Restart it and they will be there.")"
        fi
      else
        errjson=$(printf '%s' "$err" | tail -c 4000 | jq -Rs .)
        write_status "done" false "$errjson"
        echo "$err" >&2
        # Tell the owner WHY, in plain words: the dock only takes the app
        # back off.
        freemb=$(df --output=avail -BM / 2>/dev/null | tail -1 | tr -dc 0-9)
        if grep -qi 'No space left on device' <<< "$err" || [ "''${freemb:-9999}" -lt 400 ]; then
          if [ -n "$freemb" ]; then
            why=$(say "Your disk is full (only {0} MB free). Empty the Trash or remove apps you don't use, then try again." "$freemb")
          else
            why=$(say "Your disk is full. Empty the Trash or remove apps you don't use, then try again.")
          fi
        elif ! getent ahosts cache.nixos.org >/dev/null 2>&1; then
          why=$(say "There is no internet connection. Connect, then try again.")
        else
          why=$(say "Something went wrong while installing it. Try again later; Golem keeps the details (journalctl -u waverunner-apply).")
        fi
        notify "$(say "Golem couldn't install the app")" "$why"
        exit 1
      fi
    '';
  };
in
{
  # (For the tests: the helper itself, built — and so shell-checked — with
  # the layout's other commands.)
  options.standard.machine.applyCommand = lib.mkOption {
    type = lib.types.package;
    internal = true;
    readOnly = true;
    description = "waverunner-apply: the dock's app list into machine/apps.list, then a rebuild.";
  };

  config.standard.machine.applyCommand = applyScript;

  config.systemd.services.waverunner-apply = {
    description = "Apply the dock's app list (machine/apps.list, then nixos-rebuild switch)";
    # NEVER restart-on-change: this unit DRIVES the switch, and a switch that
    # changed its own definition stopped the running instance, killing the
    # switch with it (the ASUS, 2026-09-09).
    restartIfChanged = false;
    # No start limit: the dock retries a failed install at once, and each run
    # is a whole rebuild (the ThinkPad, 2026-10-01: start-limit-hit, and the
    # next install was never picked up).
    startLimitIntervalSec = 0;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${applyScript}/bin/waverunner-apply";
    };
  };

  config.systemd.paths.waverunner-apply = {
    description = "Watch the dock's packages.list for changes";
    wantedBy = [ "multi-user.target" ];
    unitConfig.StartLimitIntervalSec = 0;
    pathConfig = {
      PathChanged = listFile;
      Unit = "waverunner-apply.service";
    };
  };
}
