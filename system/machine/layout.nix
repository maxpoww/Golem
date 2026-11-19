# machine/layout — THE /etc/nixos LAYOUT (docs/system/Layout.md).
#
# A machine built by mkMachine (./default.nix) lives where NixOS expects a
# machine to live:
#
#   /etc/nixos/                    THE MACHINE: root's, edited by hand or by
#                                  Golem's tools, never touched by an update
#   /etc/nixos/golem  →  store     GOLEM as this system was built from it:
#                                  read-only, replaced whole by an update
#   /var/lib/golem/                what the system keeps for itself (secrets,
#                                  update state)
#   ~/.config, ~/.local            the owner's settings and files — nothing the
#                                  system is built from
#
# So there is no checkout in a home directory, and with it goes everything
# that existed to make an owner-writable checkout safe for root to build:
# golem.flakeDir is null here, which switches off the seal, the seed adoption,
# the git pulls as the owner and the copies root made of the checkout
# (base/{seed,first-boot,recover,selfrebuild,autoupdate}.nix, golem-seal.nix,
# waverunner-apply.nix: every one is guarded on it). What replaces them:
#
#   sudo nixos-rebuild switch      the standard command, and it is enough:
#                                  nixos-rebuild finds /etc/nixos/flake.nix
#   rebuild-golem                  the same behind Golem's one rebuild lock
#   golem-update                   move this machine to the newest Golem
#
# STAGE 1 of the move (2026-11-19): the layout, the manual commands and the
# update by hand. The nightly update's waves and notices, the dock's app
# installs and the installer still drive the old layout; their port is
# stages 2 and 3 of docs/system/Layout.md.
{ config, lib, pkgs, ... }:

let
  cfg = config.golem.machine;

  # `rebuild-golem`: what an owner types after editing /etc/nixos. Behind the
  # one rebuild lock (golem-rebuild), always this machine's `default`, so it
  # also works right after a rename (nixos-rebuild asks for the attribute
  # named after the RUNNING hostname).
  rebuildGolem = pkgs.writeShellApplication {
    name = "rebuild-golem";
    runtimeInputs = [ config.golem.rebuild ];
    text = ''
      action=''${1:-switch}; [ $# -gt 0 ] && shift
      if [ "$(id -u)" != 0 ]; then
        exec sudo "$0" "$action" "$@"
      fi
      exec golem-rebuild "$action" --flake ${lib.escapeShellArg "${cfg.dir}#default"} "$@"
    '';
  };

  # `golem-update`: this machine onto the newest Golem of the branch it
  # follows. The pin (flake.lock) moves ONLY when the new system builds: the
  # lock is tried in a root-only copy of the folder first, so a version that
  # does not build leaves /etc/nixos exactly as it was. The new system starts
  # at the next boot (as the nightly update's does), or now with `--now`.
  update = pkgs.writeShellApplication {
    name = "golem-update";
    runtimeInputs = [ config.golem.rebuild config.nix.package pkgs.coreutils pkgs.jq pkgs.curl pkgs.gnugrep pkgs.util-linux ];
    text = ''
      [ "$(id -u)" = 0 ] || exec sudo "$0" "$@"
      action=boot
      [ "''${1:-}" = --now ] && action=switch
      dir=${lib.escapeShellArg cfg.dir}
      [ -f "$dir/flake.nix" ] || { echo "golem-update: no $dir/flake.nix — this machine has no folder to update" >&2; exit 1; }

      # One rebuild at a time, held from the try to the install of the lock.
      exec 9>>/run/golem-rebuild.lock
      flock -w 7200 9 || { echo "golem-update: another rebuild has been running for 2 h — giving up" >&2; exit 1; }
      export GOLEM_REBUILD_LOCK_HELD=1

      try=$(mktemp -d /var/lib/golem/update.XXXXXX)
      trap 'rm -rf "$try"' EXIT
      cp -a "$dir/." "$try/"

      rev_of() { jq -r '.nodes.golem.locked.rev // empty' "$1/flake.lock" 2>/dev/null || true; }
      old=$(rev_of "$dir")
      nix --extra-experimental-features 'nix-command flakes' flake update golem --flake "path:$try"
      new=$(rev_of "$try")
      if [ -n "$new" ] && [ "$new" = "$old" ]; then
        echo "golem-update: already on the newest Golem (''${new:0:12})"
        exit 0
      fi
      echo "golem-update: ''${old:0:12} → ''${new:0:12}"

      # The version's published cache: what the update lane built is
      # downloaded, not compiled. None published: it compiles what it needs.
      extra=()
      url="https://github.com/${config.golem.update.cache.repo}/releases/download/g-''${new:0:12}"
      if [[ "$new" =~ ^[0-9a-f]{40}$ ]] && curl -fsSL --max-time 15 "$url/nix-cache-info" 2>/dev/null | grep -q '^StoreDir: /nix/store$'; then
        extra=(--option extra-substituters "$url")
      fi

      golem-rebuild "$action" --flake "path:$try#default" "''${extra[@]}"

      # It built (and is the next boot's system, or the running one): the pin moves.
      install -m 644 "$try/flake.lock" "$dir/flake.lock.new"
      mv -f "$dir/flake.lock.new" "$dir/flake.lock"
      echo "golem-update: this machine is on Golem ''${new:0:12}$([ "$action" = boot ] && echo ' from its next start')"
    '';
  };

  # `golem-recover [system]`: the pin back to what built a given system (the
  # running one by default). Going back a version — after a crash loop, or
  # asked for in Controls → Updates (desktop/crash-recovery.nix) — switches
  # the generation; without this the folder would still name the version left
  # behind, and the next rebuild would bring it straight back. Only the pin
  # moves: configuration.nix and modules/ are the owner's and stay as they are.
  recover = pkgs.writeShellApplication {
    name = "golem-recover";
    runtimeInputs = [ pkgs.coreutils pkgs.diffutils ];
    text = ''
      sys=$(readlink -f "''${1:-/run/current-system}")
      kept="$sys/etc/golem/machine/flake.lock"
      dir=${lib.escapeShellArg cfg.dir}
      if [ ! -f "$kept" ]; then
        echo "golem-recover: $(basename "$sys") keeps no machine folder — the pin stays as it is" >&2
        exit 1
      fi
      if cmp -s "$kept" "$dir/flake.lock"; then
        echo "golem-recover: $dir already names the Golem that built $(basename "$sys")"
        exit 0
      fi
      [ -f "$dir/flake.lock" ] && cp -f "$dir/flake.lock" "$dir/flake.lock.before-recover"
      install -m 644 "$kept" "$dir/flake.lock.new"
      mv -f "$dir/flake.lock.new" "$dir/flake.lock"
      echo "golem-recover: $dir names the Golem that built $(basename "$sys") again (the pin it had is flake.lock.before-recover)"
    '';
  };
in
{
  options.golem.machine = {
    dir = lib.mkOption {
      type = lib.types.str;
      default = "/etc/nixos";
      description = "Where this machine's own files live on disk.";
    };
    source = lib.mkOption {
      type = lib.types.path;
      internal = true;
      description = "The Golem source this system is built from (shown at <dir>/golem).";
    };
    folder = lib.mkOption {
      type = lib.types.path;
      internal = true;
      description = "The machine folder as this build saw it (kept with the generation at /etc/golem/machine).";
    };
    profile = lib.mkOption {
      type = lib.types.enum [ "desktop" "minimal" ];
      default = "desktop";
      description = "The stage this machine runs: the desktop, or the base alone (machine/install.json).";
    };
    leaves = lib.mkOption {
      type = lib.types.listOf (lib.types.attrsOf lib.types.str);
      default = [ ];
      internal = true;
      description = "The hardware leaves the chooser pointed at for this machine's facts, each with its why.";
    };
  };

  config = {
    # No checkout in a home: nothing below base/loop.nix's default applies.
    golem.flakeDir = null;
    golem.flakeAttr = "default";

    # GOLEM, where the owner can read it: the exact source of the running
    # system, beside the machine's own files. A store path: nobody edits it,
    # and it cannot differ from what was built.
    environment.etc."nixos/golem".source = cfg.source;

    # Every generation keeps the machine folder it was built from. With
    # system.configurationRevision it names the whole source of the system:
    # a generation can always be rebuilt, and a folder edited into a state
    # that no longer builds can be put back from the running system.
    environment.etc."golem/machine".source =
      builtins.path { path = cfg.folder; name = "golem-machine-folder"; };

    # What Golem's tools and a curious owner ask the system: which layout,
    # and why this hardware got the modules it got.
    environment.etc."golem/layout.json".text = builtins.toJSON {
      layout = "etc-nixos";
      inherit (cfg) dir profile;
      leaves = cfg.leaves;
    };

    environment.systemPackages = [ rebuildGolem update recover ];

    # Going back a version puts the pin back with it (see `recover` above).
    golem.recover = recover;

    # /var/lib/golem holds the secrets (base/users.nix) and the update's
    # root-only tries: it exists, root's alone, before anything writes there.
    systemd.tmpfiles.rules = [ "d /var/lib/golem 0700 root root -" ];
  };
}
