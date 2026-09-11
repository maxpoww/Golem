# base/nix — the store's policy + surviving memory pressure, stage 0.
# Lifted verbatim from system/configuration.nix (2026-09-10).
{ config, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;

  # Count-based rollback depth: keep the newest 15 system generations
  # (matching the boot menu limit, so every entry stays bootable), then
  # collect. Age-based deletion once silently evaporated rollback on a
  # machine not rebuilt for 8 days. `-`: don't fail on a system without
  # the profile.
  nix.gc = {
    automatic = true;
    dates = "daily";
  };
  systemd.services.nix-gc.serviceConfig.ExecStartPre =
    "-${config.nix.package}/bin/nix-env --profile /nix/var/nix/profiles/system --delete-generations +15";

  # Survive memory pressure instead of freezing under it: oomd kills
  # the greediest slice at sustained PSI pressure — a survivable
  # failure beats a dead machine. Needs zram (the memory tier leaf) to
  # have room to act in.
  systemd.oomd = {
    enable = true;
    enableUserSlices = true;
    enableSystemSlice = true;
  };
}
