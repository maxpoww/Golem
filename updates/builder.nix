# updates/builder — the machine that runs the update lane: today the dev box,
# later any NixOS server. Import this file in THAT machine's configuration
# and set golem.lane.enable + golem.lane.user. Nothing here goes on installs
# (they get updates/client.nix through system/Modular/composition.nix).
#
# It needs, once, on that machine (RUNBOOK.md, "A new build machine"):
#   - the cache signing key at ~/.local/share/golem-lane/cache-key.sec (600),
#   - `gh auth login` as the user, with push rights to Golem and golem-cache.
{ config, lib, pkgs, ... }:

let
  cfg = config.golem.lane;

  lane = pkgs.writeShellApplication {
    name = "golem-lane";
    runtimeInputs = [
      config.nix.package pkgs.git pkgs.gh pkgs.curl pkgs.jq pkgs.python3
      pkgs.coreutils pkgs.util-linux pkgs.gnugrep pkgs.gnused pkgs.gawk
      pkgs.findutils pkgs.libnotify
    ];
    # select.py and the rest of lane/ travel with the command.
    text = ''
      export GOLEM_LANE_LIB=''${GOLEM_LANE_LIB:-${./lane}}
    '' + builtins.readFile ./lane/golem-lane.sh;
  };
in
{
  options.golem.lane = {
    enable = lib.mkEnableOption "Golem's update lane: build, test, cache and publish each Golem version";
    user = lib.mkOption {
      type = lib.types.str;
      description = "The maintainer account it runs as; its GitHub login pushes stable and the caches.";
    };
    at = lib.mkOption {
      type = lib.types.str;
      default = "*-*-* 05:00:00";
      description = "When the daily run starts (systemd OnCalendar). A run missed while the machine slept starts at the next boot or wake.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ lane ];

    systemd.services.golem-lane = {
      description = "Golem update lane: build, test, cache and publish the next Golem version";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      restartIfChanged = false;   # a switch never waits for an hour-long build
      environment.HOME = config.users.users.${cfg.user}.home;
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        ExecStart = "${lane}/bin/golem-lane run";
        # The maintainer is working on this machine: the lane's own work
        # yields to theirs (the nix-daemon's builds keep their own priority).
        Nice = 19;
        IOSchedulingClass = "idle";
        CPUWeight = 20;
      };
    };

    systemd.timers.golem-lane = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.at;
        Persistent = true;
        RandomizedDelaySec = "20min";
      };
    };
  };
}
