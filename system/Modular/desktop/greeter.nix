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
  waitForOldSession = pkgs.writeShellScript "golem-session-wait" ''
    for _ in {1..60}; do
      ${config.systemd.package}/bin/systemctl --user --quiet is-active \
        graphical-session.target graphical-session-pre.target || break
      ${pkgs.coreutils}/bin/sleep 0.5
    done
    exec "$@" # after 30 s, start anyway and let uwsm say what is wrong
  '';
  # uwsm narrates its start on stdout/stderr ("Entry "hyprland-uwsm.desktop"
  # uses uwsm, reparsing args...", "Starting ... and waiting while it is
  # running..."), which the login tty painted on screen until Hyprland took
  # over (Max, 2026-09-30, on every boot of both laptops). systemd-cat sends
  # it to the journal (tag uwsm): still there for debugging, never on the
  # console. stdin stays the tty.
  session = "${waitForOldSession} ${config.systemd.package}/bin/systemd-cat -t uwsm uwsm start hyprland-uwsm.desktop";
in
{
  services.greetd = {
    enable = true;
    useTextGreeter = true; # tuigreet draws on tty1
    settings = {
      initial_session = {
        command = session;
        user = config.golem.owner;
      };
      # After a logout. --remember keeps the owner's name (the module owns
      # /var/cache/tuigreet); --cmd is what greetd runs for the user once the
      # password checks out — the same wrapped session.
      default_session.command =
        "${pkgs.tuigreet}/bin/tuigreet --time --remember --asterisks --cmd ${lib.escapeShellArg session}";
    };
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
