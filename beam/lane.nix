{ config, pkgs, lib, ... }:

# Beam's security update lane.
#
# Beam = Mozilla's own Firefox Linux build, pinned in ./sources.json and wrapped
# with Golem's chrome script + policies (golem-browser.nix). It does NOT come from
# the nixpkgs channel: the channel lags Mozilla by days, and a browser can't.
#
# beam-update.timer checks Mozilla every 4h. On a new release it rewrites
# sources.json (hash from Mozilla's SHA256SUMS), rebuilds, restores the old pin if
# the build fails, and tells the logged-in user to restart Beam. Only Beam moves —
# the rest of the system stays on the channel and the daily nixos-upgrade.
#
# See ./README.md.

let
  # Where the updater writes the pin, and how it rebuilds:
  #  - Golem (flake): the machine's own checkout (golem.flakeDir) — a flake's ./. is a
  #    read-only store copy, and flakes only see git-TRACKED files, so the pin is
  #    written into the checkout, `git add`ed, and the system rebuilt with --flake.
  #  - dev box (channel /etc/nixos): this directory itself, plain `nixos-rebuild`.
  flakeDir = lib.attrByPath [ "golem" "flakeDir" ] null config;
  flakeAttr = lib.attrByPath [ "golem" "flakeAttr" ] null config;
  isFlake = flakeDir != null && flakeAttr != null;
  beamDir = if isFlake then "${flakeDir}/beam" else toString ./.;
  flakeEnv = lib.optionalString isFlake ''
    export BEAM_FLAKE=${lib.escapeShellArg flakeDir}
    export BEAM_FLAKE_ATTR=${lib.escapeShellArg flakeAttr}
  '';
  src = builtins.fromJSON (builtins.readFile ./sources.json);

  selftest = pkgs.writeShellApplication {
    name = "beam-selftest";
    runtimeInputs = with pkgs; [ coreutils gnugrep gnused findutils binutils python3 ];
    checkPhase = ''
      runHook preCheck
      ${pkgs.stdenv.shellDryRun} "$target"
      runHook postCheck
    '';
    text = ''
      export BEAM_DIR=${lib.escapeShellArg beamDir}
      ${builtins.readFile ./selftest.sh}
    '';
  };

  updater = pkgs.writeShellApplication {
    name = "beam-update";
    runtimeInputs = with pkgs; [
      coreutils curl jq gnugrep gnused util-linux libnotify git
      config.system.build.nixos-rebuild selftest
    ];
    # syntax-check only: a shellcheck style nit must never fail a SECURITY rebuild
    checkPhase = ''
      runHook preCheck
      ${pkgs.stdenv.shellDryRun} "$target"
      runHook postCheck
    '';
    text = ''
      export BEAM_DIR=${lib.escapeShellArg beamDir}
      ${flakeEnv}
      ${builtins.readFile ./update.sh}
    '';
  };
in
{
  nixpkgs.overlays = [
    (final: prev: {
      # Mozilla's official build at the pinned version. ./browser.nix wraps
      # this (chrome script, policies) into the `firefox` attribute.
      golem-beam-unwrapped = prev.firefox-bin-unwrapped.override {
        systemLocale = "en-US";
        generated = {
          inherit (src) version;
          sources = [{
            inherit (src) url sha256;
            locale = "en-US";
            arch = "linux-x86_64";
          }];
        };
      };
      golem-beam-base = final.wrapFirefox final.golem-beam-unwrapped { pname = "firefox"; };
    })
  ];

  environment.systemPackages = [ updater selftest ];

  systemd.services.beam-update = {
    description = "Beam (Firefox) security update lane";
    serviceConfig.Type = "oneshot";
    # never restart ourselves mid-switch (the switch is run BY this unit)
    restartIfChanged = false;
    environment = config.nix.envVars // {
      inherit (config.environment.sessionVariables) NIX_PATH;
      HOME = "/root";
    };
    path = [ "/run/current-system/sw" ]; # golem-wait-online lives here
    script = "${updater}/bin/beam-update";
  };

  systemd.timers.beam-update = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "10min";
      OnCalendar = "*-*-* 00/4:00:00";
      Persistent = true;
      RandomizedDelaySec = "15min";
    };
  };
}
