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
# Nothing leaves the machine to decide this: Golem has no telemetry. A
# version out before the machine first saw it counts from when it was
# published (its cache's upload time, read from GitHub like the cache).
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
      # THREE answers, kept apart (2026-11-19):
      #   the cache answers                  → its arguments;
      #   GitHub says there is none (404)    → nothing: a commit the lane
      #                                        never published compiles;
      #   GitHub could not be asked (no answer, DNS, a timeout, a server
      #   error, a page that is not the cache: a captive portal)
      #                                      → nothing, and EXIT 75.
      # Until then the third read as the second: the ASUS's nightly update
      # (19-Nov, 03:13) met a night of failing DNS and GitHub downloads,
      # took the published version for an unpublished one, set out to
      # compile the whole system, and failed anyway. golem-rebuild decides
      # what 75 means for its caller: the nightly update stops and tries
      # again later; anything else goes on without the cache, as before.
      # GitHub can answer 404 for a moment right after an upload, so a
      # miss is asked again too. GOLEM_REBUILD_NEED_CACHE=1 (the nightly
      # update) asks for longer when there is no answer: about 3 min, not 1.
      tries=3; pause=0
      if [ "''${GOLEM_REBUILD_NEED_CACHE:-}" = 1 ]; then tries=6; pause=10; fi
      body=$(mktemp); trap 'rm -f "$body"' EXIT
      code=""; missing=0
      for t in $(seq 1 "$tries"); do
        code=$(curl -sSL --max-time 15 -o "$body" -w '%{http_code}' "$url/nix-cache-info" 2>/dev/null || true)
        if [ "$code" = 200 ] && grep -q '^StoreDir: /nix/store$' "$body"; then
          printf '%s\n' --option extra-substituters "$url"
          echo "golem-cache-args: using the published cache of ''${rev:0:12} ($url)" >&2
          exit 0
        fi
        if [ "$code" = 404 ]; then
          missing=$((missing + 1))
          [ "$missing" -ge 3 ] && break
        fi
        [ "$t" -lt "$tries" ] || break
        if [ "$code" = 404 ]; then sleep 2; else sleep $(( 2 + (t - 1) * pause )); fi
      done
      if [ "$code" = 404 ]; then
        echo "golem-cache-args: no published cache for ''${rev:0:12} — this build compiles what it needs" >&2
        exit 0
      fi
      echo "golem-cache-args: GitHub could not be asked whether ''${rev:0:12} has a published cache (last answer: ''${code:-none}) — the network is down or GitHub is" >&2
      exit 75
    '';
  };

  # When the lane published a version: the upload time of its cache, which
  # GitHub serves as Last-Modified. Nothing when that is unknown (offline, a
  # commit the lane never published). Nothing is sent but the request.
  published = pkgs.writeShellApplication {
    name = "golem-update-published";
    runtimeInputs = [ pkgs.curl pkgs.coreutils pkgs.gnugrep pkgs.gnused ];
    text = ''
      # golem-update-published <commit>  →  seconds since the epoch, or nothing
      rev=''${1:-}
      [[ "$rev" =~ ^[0-9a-f]{40}$ ]] || exit 0
      lm=$(curl -fsIL --max-time 15 "https://github.com/${cfg.cache.repo}/releases/download/g-''${rev:0:12}/nix-cache-info" 2>/dev/null \
        | grep -i '^last-modified:' | tail -1 | sed 's/^[^:]*: *//; s/\r$//' || true)
      [ -n "$lm" ] || exit 0
      date -d "$lm" +%s 2>/dev/null || true
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
    publishedCommand = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = "golem-update-published: when the lane published a commit (its cache's upload time).";
    };
  };

  config = {
    assertions = [{
      assertion = cfg.wave == null || cfg.wave < cfg.waves;
      message = "golem.update.wave (${toString cfg.wave}) must be below golem.update.waves (${toString cfg.waves}).";
    }];
    golem.update.cacheArgs = cacheArgs;
    golem.update.waveCommand = waveOf;
    golem.update.publishedCommand = published;
    nix.settings.trusted-public-keys = cfg.cache.publicKeys;

    # An update must never freeze the machine. The Acer's first update
    # through the cache (2026-10-27) compiled nothing and still froze the
    # desktop: unpacking 8.7 GiB onto its spinning disk held I/O pressure at
    # 98%, and BFQ (disk/policy.nix) split the disk FAIRLY between the
    # daemon and the desktop. The daemon does every download, unpack and
    # build: in the idle I/O class, with a low cgroup weight (which also
    # covers its buffered writes, flushed by the kernel), the user's
    # programs get the disk and the CPU first and the update takes the rest.
    # Measured live on the Acer: nothing of the desktop left waiting on the
    # disk. CPU: batch, not idle, so a dock install still finishes while
    # someone works.
    nix.daemonIOSchedClass = "idle";
    nix.daemonCPUSchedPolicy = "batch";
    systemd.services.nix-daemon.serviceConfig = {
      IOWeight = 10;
      CPUWeight = 10;
    };
    # Both on PATH for debugging: `golem-update-wave`, and
    # `golem-cache-args ~/Golem` (is this checkout's version cached?).
    environment.systemPackages = [ waveOf cacheArgs ];
  };
}
