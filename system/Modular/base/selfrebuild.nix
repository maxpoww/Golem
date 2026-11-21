# base/selfrebuild — the machine can grow, stage 0's load-bearing leaf.
# Stage climbs happen by REBUILD from the seed (the constitution's rule
# 5); this leaf is that ability: the rebuild-golem wrapper with its
# drift check, and the git ownership grants root's rebuild needs to
# read the owner's checkout. The seal (#56) rides beside it at the
# composition level (golem-seal.nix, unchanged). Data-driven on
# standard.flakeDir/flakeAttr — a machine without a checkout gets neither.
# Lifted verbatim from system/configuration.nix (2026-09-10).
{ config, pkgs, lib, ... }:

{
  programs.git = lib.mkIf (config.standard.flakeDir != null) {
    enable = true;
    config.safe.directory = config.standard.flakeDir;
    # Git's objects reach the disk before a ref points at them. Off (git's
    # default), a power cut during the nightly pull left an EMPTY object
    # file for the new HEAD — "bad object HEAD": no update, no install, no
    # recovery could touch the checkout again (MacBook, 2026-10-03).
    config.core.fsync = "added";
    config.core.fsyncMethod = "fsync";
  };

  environment.systemPackages = [
    pkgs.git
  ] ++ lib.optional (config.standard.flakeDir != null)
    (pkgs.writeShellScriptBin "rebuild-golem" ''
      set -euo pipefail
      # Built and switched with sudo: that IS the owner's consent. Root copies
      # the checkout once, builds that copy and seals that same copy
      # (golem-seal.nix): what is approved is exactly what was built, never a
      # file changed while the build ran. Without the seal every app install
      # from the dock would wait on a separate `sudo golem-bless`.
      sudo golem-seal-approve switch "$@"

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
