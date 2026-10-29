# base/store-gc — the store never fills the disk on its own.
#
# Split out of base/nix.nix (2026-10-16) so a machine that keeps its own
# channel-based /etc/nixos (the dev box) can take the SAME policy: the dev box
# still ran the old `--delete-older-than 7d` and sat on 68 system generations
# at 99 % full — a busy week of rebuilds is all "younger than 7 days".
{ config, pkgs, ... }:

let
  # Count-based rollback depth: keep the newest 15 system generations, then
  # collect. Age-based deletion once silently evaporated rollback on a
  # machine not rebuilt for 8 days. On a disk with under 15 GiB free, only
  # the newest 3: a Golem system is 10-12 GiB, a weekly NixOS update changes
  # a good part of it, and 15 versions nothing may collect would fill a
  # small disk (audit, 2026-10-29). 3 is also the UEFI boot menu's depth
  # (boot/grub-efi.nix).
  trim = pkgs.writeShellScript "golem-store-trim" ''
    keep=15
    avail=$(${pkgs.coreutils}/bin/df --output=avail -B1G /nix/store | ${pkgs.coreutils}/bin/tail -1 | ${pkgs.coreutils}/bin/tr -d ' ')
    if [ "''${avail:-99}" -lt 15 ]; then
      keep=3
      echo "golem-store-trim: only ''${avail} GiB free, keeping the newest 3 system versions"
    fi
    exec ${config.nix.package}/bin/nix-env --profile /nix/var/nix/profiles/system --delete-generations "+$keep"
  '';
in
{
  nix.gc = {
    automatic = true;
    dates = "daily";
  };
  systemd.services.nix-gc.serviceConfig.ExecStartPre = [
    "-${trim}"   # `-`: don't fail on a system without the profile
  ];  # after base/quiet-login's gate (mkBefore): no collecting during a login
  # A switch never restarts a long background oneshot: switch-to-configuration
  # waits for a restarted oneshot to FINISH, so a dock install (which
  # switches) sat behind a store check running on the Acer's spinning disk
  # for as long as the check took (night dogfood, 2026-10-03). A changed job
  # simply runs its new version next time.
  systemd.services.nix-gc.restartIfChanged = false;

  # A daily gc can't stop a single big install or rebuild from filling the
  # disk between two runs. With these, Nix collects garbage DURING a build
  # whenever free space drops under 5 GiB, until 20 GiB are free again.
  nix.settings.min-free = 5 * 1024 * 1024 * 1024;
  nix.settings.max-free = 20 * 1024 * 1024 * 1024;
}
