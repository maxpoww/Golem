# base/recover — golem-recover: make the source match a system that works.
#
# NixOS can BOOT a previous generation, but the source (~/Golem) stays where
# it was; if the declaration is what broke, the machine can never rebuild
# again (Max, 2026-10-03: "if the error is on your declaration you are done.
# the system wont rebuild anymore … how do we recovery the system so it
# really comes back and rebuild?").
#
# Every generation now names its whole source: its git revision
# (system.configurationRevision) and the machine layer it was built from
# (/etc/golem/machine, flake.nix). `golem-recover [system]` puts the source
# back to exactly that — default: the running system:
#   1. the owner's edits to Golem's own files are kept in
#      ~/Golem-local-edits/<when>/ (never lost);
#   2. git goes to the system's revision (reset --hard on the owner's branch);
#   3. hosts/target comes back from the system's own copy and is staged
#      (a flake only sees tracked or staged files);
#   4. the tree is sealed again.
# Afterwards a rebuild reproduces the system. Used by the crash rollback
# (desktop/crash-recovery.nix), by a failed update (base/autoupdate.nix), and
# by hand: `sudo golem-recover`.
{ config, lib, pkgs, ... }:

let
  owner = config.golem.owner;
  dir = toString config.golem.flakeDir;
  home = config.users.users.${owner}.home;
  recover = pkgs.writeShellApplication {
    name = "golem-recover";
    runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.git pkgs.util-linux pkgs.diffutils pkgs.gnugrep ];
    text = ''
      sys=$(readlink -f "''${1:-/run/current-system}")
      dir=${lib.escapeShellArg dir}
      owner=${lib.escapeShellArg owner}
      asowner() { runuser -u "$owner" -- "$@"; }

      rev=$("$sys/sw/bin/nixos-version" --configuration-revision 2>/dev/null || true)
      rev=''${rev%-dirty}
      snap="$sys/etc/golem/machine"
      if ! [[ "$rev" =~ ^[0-9a-f]{40}$ ]]; then
        echo "golem-recover: $sys does not name its revision — cannot recover from it" >&2
        exit 1
      fi
      if [ ! -d "$dir/.git" ]; then
        echo "golem-recover: $dir is not a checkout yet (golem-seed-adopt makes it one)" >&2
        exit 1
      fi
      cd "$dir"
      if ! asowner git cat-file -e "$rev^{commit}" 2>/dev/null; then
        asowner git fetch --quiet || true
      fi
      if ! asowner git cat-file -e "$rev^{commit}" 2>/dev/null; then
        echo "golem-recover: revision $rev is not in the checkout's history" >&2
        exit 1
      fi

      # 1. the owner's edits are kept, never lost
      keep="${home}/Golem-local-edits/$(date +%Y-%m-%d-%H%M%S)-recover"
      edited=$(asowner git diff --name-only HEAD 2>/dev/null | grep -v '^hosts/target/' || true)
      if [ -n "$edited" ] || { [ -d "$snap" ] && ! diff -rq "$snap" hosts/target >/dev/null 2>&1; }; then
        asowner mkdir -p "$keep"
        printf '%s\n' "$edited" | while IFS= read -r f; do
          [ -n "$f" ] && [ -e "$f" ] && { asowner mkdir -p "$keep/$(dirname "$f")"; asowner cp -a "$f" "$keep/$f"; }
        done
        [ -d hosts/target ] && { asowner mkdir -p "$keep/hosts"; asowner cp -a hosts/target "$keep/hosts/"; }
        echo "golem-recover: the current edits are kept in $keep"
      fi

      # 2. the code: exactly the system's revision. `reset --hard` DELETES
      #    files that are staged but not in the commit — every machine file —
      #    so the current ones are held aside first.
      held=$(mktemp -d)
      cp -a hosts/target/. "$held/" 2>/dev/null || true
      asowner git reset --quiet --hard "$rev"

      # 3. the machine layer: the system's own copy (or, from a generation
      #    built before it kept one, the files that were there), staged
      src="$snap"; [ -d "$src" ] || { src="$held"; echo "golem-recover: $(basename "$sys") keeps no machine layer (built before 2026-10-03) — keeping the current one" >&2; }
      find "$src" -maxdepth 1 -type f -print0 | while IFS= read -r -d "" f; do
        b=$(basename "$f")
        [ "$b" = default.nix ] && continue
        install -m 0644 -o "$owner" -g "$(id -gn "$owner")" "$f" "hosts/target/$b"
        asowner git add -f "hosts/target/$b"
      done
      rm -rf "$held"

      # 4. sealed again: this tree built a system that works
      ${config.golem.seal.bless}/bin/golem-bless >/dev/null 2>&1 || true
      echo "golem-recover: the source now matches $(basename "$sys") (revision ''${rev:0:8}) — a rebuild reproduces it"
    '';
  };
in
{
  options.golem.recover = lib.mkOption {
    type = lib.types.package;
    internal = true;
    readOnly = true;
    default = recover;
    description = "golem-recover: put the source back to what built a given system.";
  };
  config = lib.mkIf (config.golem.flakeDir != null) {
    environment.systemPackages = [ recover ];
  };
}
