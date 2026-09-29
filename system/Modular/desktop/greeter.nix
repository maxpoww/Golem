# desktop/greeter — the login, stage 1. greetd launches the owner's Hyprland
# session through uwsm (the same unit programs.hyprland.withUWSM installs, in
# hyprland.nix). Ported verbatim from the fat system/configuration.nix.
#
# This is Golem's current single-user behaviour: the session starts as the owner
# without a password gate at the greeter. A real multi-user greeter is a
# separate future decision; this leaf reproduces what the fat path does today.
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
in
{
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${waitForOldSession} uwsm start hyprland-uwsm.desktop";
      user = config.golem.owner;
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
