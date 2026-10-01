# base/selfrebuild — the machine can grow, stage 0's load-bearing leaf.
# Stage climbs happen by REBUILD from the seed (the constitution's rule
# 5); this leaf is that ability: the rebuild-golem wrapper with its
# drift check, and the git ownership grants root's rebuild needs to
# read the owner's checkout. The seal (#56) rides beside it at the
# composition level (golem-seal.nix, unchanged). Data-driven on
# golem.flakeDir/flakeAttr — a machine without a checkout gets neither.
# Lifted verbatim from system/configuration.nix (2026-09-10).
{ config, pkgs, lib, ... }:

{
  programs.git = lib.mkIf (config.golem.flakeDir != null) {
    enable = true;
    config.safe.directory = config.golem.flakeDir;
  };

  environment.systemPackages = [
    pkgs.git
  ] ++ lib.optional (config.golem.flakeDir != null)
    (pkgs.writeShellScriptBin "rebuild-golem" ''
      set -euo pipefail
      sudo golem-rebuild switch --flake "${config.golem.flakeDir}#${config.golem.flakeAttr}" "$@"
      # Built and switched with sudo: that IS the owner's consent to what is
      # in the checkout now. Re-seal it, or every app install from the dock
      # would be refused until a separate `sudo golem-bless`.
      sudo golem-bless

      current=$(readlink -f /run/current-system)
      latest=$(readlink -f /nix/var/nix/profiles/system)
      booted=$(readlink -f /run/booted-system)

      if [ "$current" != "$latest" ]; then
        echo "FAIL: activated system != latest profile (drift)"; exit 1
      fi
      echo "OK: activated == latest"

      if [ "$current" != "$booted" ]; then
        echo "REBOOT REQUIRED: kernel/initrd/system changed — reboot to run latest"
      else
        echo "OK: activated == booted (already fully live)"
      fi
    '');
}
