# updates/client — what every Golem machine needs to take updates from the
# lane fast: trust the cache's signing key, find the cache of the version
# it is building, and know its own wave. (The nightly update itself is
# system/Modular/base/autoupdate.nix; this directory's README has the map.)
#
# THE CACHE, per version. The lane publishes each Golem version as one
# GitHub release of maxpoww/golem-cache, tagged g-<first 12 of the commit>,
# holding the version's own pieces (the dock, patched Hyprland, nvidia…),
# signed. golem-rebuild asks golem-cache-args for the release that matches
# the checkout's HEAD and passes it to nixos-rebuild as an extra substituter,
# so the build DOWNLOADS what the lane built instead of compiling it. A
# commit the lane never published (a local commit, a lab branch) has no
# release: the check below finds nothing and the build compiles as before.
#
# Trust: only the key below. The release URL comes from HEAD, but a piece
# is accepted only if this key signed it, so a wrong or hostile URL can make
# a build slower, never different. Rotating the key = add the new one here,
# publish, and drop the old one a few versions later (RUNBOOK.md).
#
# THE WAVE. Each machine takes a new version a fixed number of days after it
# first sees it (0 … waves-1), computed here from /etc/machine-id, so the
# machines spread over a week and a bad version meets a few of them first.
# Nothing leaves the machine to decide this: Golem has no telemetry.
{ config, lib, pkgs, ... }:

let
  cfg = config.golem.update;

  cacheArgs = pkgs.writeShellApplication {
    name = "golem-cache-args";
    runtimeInputs = [ pkgs.curl pkgs.coreutils pkgs.gawk pkgs.gnugrep ];
    text = ''
      # golem-cache-args <flake dir>  →  nixos-rebuild arguments, one per line
      # (nothing at all when this version has no published cache).
      dir=''${1:-}
      dir=''${dir#path:}; dir=''${dir#git+file://}
      # A build from the root-only snapshot (/var/lib/golem/build, no .git)
      # is the seed's blessed version plus the owner's app list: the seed's
      # HEAD names its cache.
      ${lib.optionalString (config.golem.flakeDir != null) ''
        [ -d "$dir/.git" ] || dir=${lib.escapeShellArg config.golem.flakeDir}
      ''}
      [ -n "$dir" ] && [ -d "$dir/.git" ] || exit 0
      # The commit, read from the files: this runs as root, and git run inside
      # the owner's repository would obey its config (golem-seal.nix, heal).
      headref=$(cat "$dir/.git/HEAD" 2>/dev/null || true)
      if [[ "$headref" == ref:\ * ]]; then
        ref=''${headref#ref: }
        rev=$(cat "$dir/.git/$ref" 2>/dev/null || awk -v r="$ref" '$2 == r { print $1 }' "$dir/.git/packed-refs" 2>/dev/null || true)
      else
        rev=$headref
      fi
      [[ "$rev" =~ ^[0-9a-f]{40}$ ]] || exit 0
      url="https://github.com/${cfg.cache.repo}/releases/download/g-''${rev:0:12}"
      # GitHub can answer 404 for a moment right after an upload, so a
      # miss is retried before the build goes on without the cache.
      for _ in 1 2 3; do
        if curl -fsSL --max-time 15 "$url/nix-cache-info" 2>/dev/null | grep -q '^StoreDir: /nix/store$'; then
          printf '%s\n' --option extra-substituters "$url"
          echo "golem-cache-args: using the published cache of ''${rev:0:12} ($url)" >&2
          exit 0
        fi
        sleep 2
      done
      echo "golem-cache-args: no published cache for ''${rev:0:12} — this build compiles what it needs" >&2
    '';
  };

  waveOf = pkgs.writeShellApplication {
    name = "golem-update-wave";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      # This machine's wave: the configured one, or a number taken from its
      # own machine-id (stable for the life of the install, never sent).
      ${if cfg.wave != null then ''
        echo ${toString cfg.wave}
      '' else ''
        id=$(tr -dc '0-9a-f' < /etc/machine-id 2>/dev/null | head -c 8)
        echo $(( 16#''${id:-0} % ${toString cfg.waves} ))
      ''}
    '';
  };
in
{
  options.golem.update = {
    cache.repo = lib.mkOption {
      type = lib.types.str;
      default = "maxpoww/golem-cache";
      description = "GitHub repo whose releases are the per-version binary caches (owner/name).";
    };
    cache.publicKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "golem-cache-1:lUUA5lNDJ8EJhxXLuebT5a3bL7c0SRJKUhNooEwO1B0=" ];
      description = "Keys whose signature makes a cache piece acceptable (added to cache.nixos.org's).";
    };
    waves = lib.mkOption {
      type = lib.types.ints.positive;
      default = 7;
      description = "How many days a new version takes to reach every machine (one wave a day).";
    };
    wave = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.unsigned;
      default = null;
      description = ''
        This machine's wave: it takes a new version this many days after
        first seeing it. null = derived from /etc/machine-id. The lab sets 0,
        so it meets every version first.
      '';
    };
    cacheArgs = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = "golem-cache-args: the extra-substituter arguments for a checkout's published version.";
    };
    waveCommand = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = "golem-update-wave: prints this machine's wave.";
    };
  };

  config = {
    assertions = [{
      assertion = cfg.wave == null || cfg.wave < cfg.waves;
      message = "golem.update.wave (${toString cfg.wave}) must be below golem.update.waves (${toString cfg.waves}).";
    }];
    golem.update.cacheArgs = cacheArgs;
    golem.update.waveCommand = waveOf;
    nix.settings.trusted-public-keys = cfg.cache.publicKeys;
    environment.systemPackages = [ waveOf ];
  };
}
