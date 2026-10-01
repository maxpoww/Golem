{ config, pkgs, lib, ... }:

# Seam's security update lane.
#
# Seam = Mozilla's own Firefox Linux build, pinned in ./sources.json and wrapped
# with Golem's chrome script + policies (golem-browser.nix). It does NOT come from
# the nixpkgs channel: the channel lags Mozilla by days, and a browser can't.
#
# seam-update.timer checks Mozilla every 4h. On a new release it rewrites
# sources.json (hash from Mozilla's SHA256SUMS), rebuilds, restores the old pin if
# the build fails, and tells the logged-in user to restart Seam. Only Seam moves —
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
  seamDir = if isFlake then "${flakeDir}/seam" else toString ./.;
  sealCheck = lib.attrByPath [ "golem" "seal" "check" ] null config;
  sealBless = lib.attrByPath [ "golem" "seal" "bless" ] null config;
  flakeEnv = lib.optionalString isFlake (''
    export SEAM_FLAKE=${lib.escapeShellArg flakeDir}
    export SEAM_FLAKE_ATTR=${lib.escapeShellArg flakeAttr}
  '' + lib.optionalString (sealCheck != null && sealBless != null) ''
    export SEAM_SEAL_CHECK=${sealCheck}/bin/golem-seal-check
    export SEAM_SEAL_BLESS=${sealBless}/bin/golem-bless
  '');
  src = builtins.fromJSON (builtins.readFile ./sources.json);

  selftest = pkgs.writeShellApplication {
    name = "seam-selftest";
    runtimeInputs = with pkgs; [ coreutils gnugrep gnused findutils binutils python3 ];
    checkPhase = ''
      runHook preCheck
      ${pkgs.stdenv.shellDryRun} "$target"
      runHook postCheck
    '';
    # SEAM_DIR from the caller wins: the updater runs this as `nobody` on a world-readable
    # copy (the owner's home is 0700). Hard-coding it here sent the first real update's
    # test (157.0, 2026-09-29) into /home/max — "Permission denied", and a false
    # "overview paused" notice.
    text = ''
      : "''${SEAM_DIR:=${seamDir}}"; export SEAM_DIR
      ${builtins.readFile ./selftest.sh}
    '';
  };

  updater = pkgs.writeShellApplication {
    name = "seam-update";
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
      export SEAM_DIR=${lib.escapeShellArg seamDir}
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
      golem-seam-unwrapped = prev.firefox-bin-unwrapped.override {
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
      # Its own binary (`seam`), window class (`seam`) and icon name — never `firefox`:
      # a plain Firefox can be installed beside it (2026-09-27, Max: "totally independent").
      # (applicationName must stay the UNWRAPPED binary's name, "firefox" — the wrapper
      # wraps ${browser}/bin/${applicationName}; the user-facing `seam` launcher is made
      # in browser.nix, and the inner bin/firefox is removed there so nothing collides.)
      golem-seam-base = final.wrapFirefox final.golem-seam-unwrapped {
        pname = "seam"; wmClass = "seam"; icon = "seam";
      };
    })
  ];

  environment.systemPackages = [ updater selftest ];

  systemd.services.seam-update = {
    description = "Seam (Firefox) security update lane";
    serviceConfig.Type = "oneshot";
    # never restart ourselves mid-switch (the switch is run BY this unit)
    restartIfChanged = false;
    environment = config.nix.envVars // {
      inherit (config.environment.sessionVariables) NIX_PATH;
      HOME = "/root";
    };
    path = [ "/run/current-system/sw" ]; # golem-wait-online lives here
    script = "${updater}/bin/seam-update";
  };

  systemd.timers.seam-update = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "10min";
      OnCalendar = "*-*-* 00/4:00:00";
      Persistent = true;
      RandomizedDelaySec = "15min";
    };
  };
}
