# base/store-gc — the store never fills the disk on its own.
#
# Split out of base/nix.nix (2026-10-16) so a machine that keeps its own
# channel-based /etc/nixos (the dev box) can take the SAME policy: the dev box
# still ran the old `--delete-older-than 7d` and sat on 68 system generations
# at 99 % full — a busy week of rebuilds is all "younger than 7 days".
{ config, ... }:

{
  # Count-based rollback depth: keep the newest 15 system generations
  # (matching the boot menu limit, so every entry stays bootable), then
  # collect. Age-based deletion once silently evaporated rollback on a
  # machine not rebuilt for 8 days. `-`: don't fail on a system without
  # the profile.
  nix.gc = {
    automatic = true;
    dates = "daily";
  };
  systemd.services.nix-gc.serviceConfig.ExecStartPre = [
    "-${config.nix.package}/bin/nix-env --profile /nix/var/nix/profiles/system --delete-generations +15"
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
