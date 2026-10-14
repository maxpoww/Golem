# desktop/greeter — the login, stage 1. greetd launches the owner's Hyprland
# session through uwsm (the same unit programs.hyprland.withUWSM installs, in
# hyprland.nix).
#
# TWO sessions, not one (parity P16, 2026-09-30). The owner's desktop used to
# BE greetd's default_session, so logind classed it `greeter`: every session
# policy treated the desktop as not-a-user — CanSuspend/mount refused whenever
# a second login existed (P5), `loginctl lock-session` refused (P11), a
# session that could never be the display session. Now:
#   initial_session  the owner's desktop, started ONCE per boot with no
#                    password (the single-owner machine as before) — logind
#                    class `user`;
#   default_session  what greetd shows AFTER a logout: tuigreet on tty1, the
#                    owner's name remembered, a password, the same session.
# greetd never restarts on its own with an initial_session (the module's
# `restart` default): a restart would autologin again.
#
# THE SESSION NEVER ENDS UNLESS THE OWNER ASKS (Max, 2026-10-14: "el usuario
# nunca tendría que lidiar con que se le caiga el sistema"; there is no "log
# out" on Golem — lock, suspend, hibernate, power off). The owner's desktop
# runs inside a KEEPER (`golem-session-keeper`, the initial_session's own
# process, so the logind session, the seat and the PAM login all stay as they
# are): when the desktop ends and the machine is not shutting down, the keeper
# starts it again at once — the session bus comes back on demand, the window
# places and the side's column are kept in files, Seam restores its windows —
# and a note on the desktop says it came back on its own. The brake: more than
# three ends in ten minutes and the keeper gives up, so a desktop that cannot
# stay up shows tuigreet with a line saying so, instead of flickering for ever
# (a compositor crash loop never gets this far: start-hyprland's own watchdog
# rolls Golem back first, desktop/crash-recovery.nix). The night it was built
# for: the session bus died of a file-descriptor leak and uwsm tore the whole
# session down — the owner was at the greeter, and rebooted.
{ config, lib, pkgs, ... }:

let
  # A new session must not race the old one's teardown. uwsm refuses to start
  # while the previous session's graphical-session*/wayland-session* targets
  # are still active ("A compositor or graphical-session* target is already
  # active!"), and they stay active for as long as the old compositor takes to
  # die. Hyprland 0.55.4 SEGVs on exit (parity.md P6), so that includes a
  # core dump: ~13 s on the macbook. greetd retried five times in six seconds,
  # hit its start limit, and left a black screen (macbook, 2026-09-29, a
  # session restart). So: wait (up to 30 s) for the old targets to go down,
  # then start.
  # A wrapper, not `wait; uwsm …`: greetd runs the command as `sh -c "exec
  # <command>"`, so the wait must exec the real command itself.
  #
  # A question that gets NO answer is not "it is gone": after the session bus
  # dies the user manager does not answer for up to 90 s (it waits on its own
  # bus connection), and reading that silence as "inactive" started the new
  # session into the old one's teardown — "Transaction order is cyclic", a
  # failed start, two of the keeper's three tries spent on one incident (the
  # Acer, 2026-10-14). Only an answer of inactive/failed lets it go; up to
  # 150 s in all.
  waitForOldSession = pkgs.writeShellScript "golem-session-wait" ''
    deadline=$(( $(${pkgs.coreutils}/bin/date +%s) + 150 ))
    while [ "$(${pkgs.coreutils}/bin/date +%s)" -lt "$deadline" ]; do
      s=$(${pkgs.coreutils}/bin/timeout 20 ${config.systemd.package}/bin/systemctl --user is-active \
        graphical-session.target graphical-session-pre.target 2>/dev/null)
      # Gone = an answer, and every line of it inactive or failed.
      if [ -n "$s" ] && ! printf '%s\n' "$s" | ${pkgs.gnugrep}/bin/grep -qvxE 'inactive|failed'; then break; fi
      ${pkgs.coreutils}/bin/sleep 0.5
    done
    exec "$@" # after 150 s, start anyway and let uwsm say what is wrong
  '';
  # uwsm narrates its start on stdout/stderr ("Entry "hyprland-uwsm.desktop"
  # uses uwsm, reparsing args...", "Starting ... and waiting while it is
  # running..."), which the login tty painted on screen until Hyprland took
  # over (Max, 2026-09-30, on every boot of both laptops). systemd-cat sends
  # it to the journal (tag uwsm): still there for debugging, never on the
  # console. stdin stays the tty.
  session = "${waitForOldSession} ${config.systemd.package}/bin/systemd-cat -t uwsm uwsm start hyprland-uwsm.desktop";

  # The keeper: runs its arguments (the session) again and again. The counter
  # lives in the runtime dir, which logind keeps for as long as the session
  # does. A marker there has golem-return-notice say so once the desktop is
  # up. `is-system-running` says `stopping` through a power-off or reboot.
  keeper = pkgs.writeShellScript "golem-session-keeper" ''
    run="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}/golem"
    ${pkgs.coreutils}/bin/mkdir -p "$run"
    # The brake counts INCIDENTS, not attempts: a desktop that ran (60 s or
    # more) and then ended is one; a start that fails at once is a retry of
    # the same incident, with a growing pause (2, 4, 8… 30 s), and only six
    # of those in a row give up. More than three incidents in ten minutes
    # give up too: a desktop that cannot stay up.
    ends=0; since=$(${pkgs.coreutils}/bin/date +%s); quick=0
    log() { echo "golem-session-keeper: $2" | ${config.systemd.package}/bin/systemd-cat -t golem-session-keeper -p "$1"; }
    while :; do
      started=$(${pkgs.coreutils}/bin/date +%s)
      "$@"; rc=$?
      state=$(${config.systemd.package}/bin/systemctl is-system-running 2>/dev/null)
      if [ "$state" = stopping ] || [ -e /run/systemd/shutdown/scheduled ]; then
        exit $rc
      fi
      now=$(${pkgs.coreutils}/bin/date +%s)
      if [ $((now - started)) -lt 60 ]; then
        quick=$((quick + 1))
        if [ $quick -gt 6 ]; then
          log err "the desktop failed to start $quick times in a row (last rc $rc); giving up"
          exit $rc
        fi
        pause=$(( 1 << quick )); [ $pause -gt 30 ] && pause=30
        log warning "the desktop did not stay up (rc $rc after $((now - started)) s); trying again in $pause s ($quick/6)"
        ${pkgs.coreutils}/bin/sleep $pause
        continue
      fi
      quick=0
      if [ $((now - since)) -gt 600 ]; then ends=0; since=$now; fi
      ends=$((ends + 1))
      if [ $ends -gt 3 ]; then
        log err "the desktop ended $ends times in ten minutes (last rc $rc); giving up"
        exit $rc
      fi
      log warning "the desktop ended (rc $rc) without being asked; starting it again ($ends/3)"
      ${pkgs.coreutils}/bin/date +%s > "$run/session-returned"
    done
  '';

  returnNotice = pkgs.writeShellScript "golem-return-notice" ''
    run="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}/golem"
    [ -f "$run/session-returned" ] || exit 0
    ${pkgs.libnotify}/bin/notify-send -a Golem "El escritorio volvió solo" \
      "Algo cerró la sesión sin que lo pidieras. Golem la volvió a abrir y guardó el motivo en el registro."
    ${pkgs.coreutils}/bin/rm -f "$run/session-returned"
  '';
in
{
  services.greetd = {
    enable = true;
    useTextGreeter = true; # tuigreet draws on tty1
    settings = {
      initial_session = {
        # The keeper around the session: the command still reads "… systemd-cat
        # -t uwsm uwsm start hyprland-uwsm.desktop" (desktop-matrix checks it).
        command = "${keeper} ${session}";
        user = config.golem.owner;
      };
      # After a logout. --remember keeps the owner's name (the module owns
      # /var/cache/tuigreet); --cmd is what greetd runs for the user once the
      # password checks out — the same wrapped session.
      default_session.command =
        "${pkgs.tuigreet}/bin/tuigreet --time --remember --asterisks --greeting ${lib.escapeShellArg "Golem: el escritorio se cerró varias veces seguidas. Entrá y mirá el registro en Cuidado."} --cmd ${lib.escapeShellArg "${keeper} ${session}"}";
    };
  };

  # "El escritorio volvió solo", once the desktop is up again.
  systemd.user.services.golem-return-notice = {
    description = "Golem: say so after the desktop came back on its own";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    unitConfig.ConditionPathExists = "%t/golem/session-returned";
    serviceConfig = { Type = "oneshot"; ExecStartPre = "${pkgs.coreutils}/bin/sleep 12"; ExecStart = "${returnNotice}"; };
  };

  # The backstop, should the wait still lose: NixOS's greetd retries after
  # 100 ms and gives up after 5 tries in 10 s, which is shorter than a slow
  # teardown. Retry every 2 s, up to 20 times a minute.
  systemd.services.greetd = {
    serviceConfig.RestartSec = lib.mkForce "2s";
    unitConfig = {
      StartLimitIntervalSec = lib.mkForce 60;
      StartLimitBurst = lib.mkForce 20;
    };
  };
}
