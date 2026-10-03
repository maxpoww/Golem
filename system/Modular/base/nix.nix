# base/nix — the store's policy + surviving memory pressure, stage 0.
# Lifted verbatim from system/configuration.nix (2026-09-10).
{ config, lib, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  # A store path's CONTENTS reach the disk before the path is registered
  # valid. Off (Nix's default), a power cut during an install left files
  # whose hashes no longer match but which Nix trusted as valid — the ASUS,
  # plug pulled mid dock-install (2026-10-03): openjdk-minimal-jre "was
  # modified!". Laptops with dead batteries lose power without warning.
  # Costs some install speed (each file is flushed); correctness first.
  nix.settings.fsync-store-paths = true;

  # Flakes-only, no channels. Without this, every `nix-shell` / `nix search`
  # on an installed Golem prints:
  #   warning: Nix search path entry '/nix/var/nix/profiles/per-user/root/channels' does not exist
  # — a channel profile a flakes system never creates. Turn channels off and
  # point <nixpkgs> at the flake registry instead, so nix-shell -p still works
  # and NIX_PATH carries no dead channel entry. (2026-09-26, Max.)
  nix.channel.enable = false;
  nix.nixPath = lib.mkForce [ "nixpkgs=flake:nixpkgs" ];

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
