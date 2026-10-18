# base/nix — the store's policy + surviving memory pressure, stage 0.
# Lifted verbatim from system/configuration.nix (2026-09-10).
{ config, lib, ... }:

{
  imports = [ ./store-gc.nix ./store-check.nix ];

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

  # The gc policy (keep 15 system generations, collect daily, collect during
  # a build when the disk runs low) lives in base/store-gc.nix.

  # The weekly store check lives in base/store-check.nix (a machine whose
  # store policy is its own — the dev box — imports it alone).

  # Survive memory pressure instead of freezing under it: oomd kills
  # the greediest slice at sustained PSI pressure — a survivable
  # failure beats a dead machine. Needs zram (the memory tier leaf) to
  # have room to act in.
  systemd.oomd = {
    enable = true;
    enableUserSlices = true;
    enableSystemSlice = true;
    # Act sooner than the stock 30 s: by then a thrashing machine has been
    # frozen to its owner for the whole of it.
    settings.OOM = {
      DefaultMemoryPressureDurationSec = "15s";
      # 60 % of ALL swap: on a machine with zram plus a disk swap for
      # hibernation (the Acer: 5.6 GB zram + 6 GB on a spinning disk) that is
      # about where zram runs out and the disk thrash starts. Measured with a
      # runaway app: at the stock 90 % it was put down after ~290 s of a
      # crawling desktop, at 60 % after 75-92 s.
      SwapUsedLimit = "60%";
    };
  };
  # What the stock limits missed (the Acer, 2026-10-14: a runaway app froze
  # the desktop for NINE minutes until the kernel's own OOM killer, swap 99 %
  # full, oomd silent):
  # - oomd's pressure limit counts the time when EVERY task is stalled
  #   ("full"); in a swap thrash the desktop is unusable long before that
  #   reaches 80 %. 50 % on the user side, where the apps are.
  # - oomd kills on SWAP (over 90 % used) only in slices that ask for it, and
  #   none did. The user and system slices now ask.
  systemd.slices."user".sliceConfig = {
    ManagedOOMMemoryPressureLimit = "50%";
    ManagedOOMSwap = "kill";
  };
  systemd.slices."system".sliceConfig.ManagedOOMSwap = "kill";
  systemd.user.units."slice" = lib.mkForce {
    text = ''
      [Slice]
      ManagedOOMMemoryPressure=kill
      ManagedOOMMemoryPressureLimit=50%
      ManagedOOMSwap=kill
    '';
    overrideStrategy = "asDropin";
  };
  # The desktop keeps its memory: without a reservation the compositor's own
  # pages were swapped out for the runaway app, and it froze for 12 s while
  # oomd was still deciding. With memory_recursiveprot (systemd's default
  # mount) the protection reaches the session from these two; the session's
  # own share is below. Measured: worst compositor stall 12 s -> 4.5 s.
  systemd.slices."user".sliceConfig.MemoryLow = "450M";
  systemd.services."user@".serviceConfig.MemoryLow = "450M";
  systemd.user.units."session.slice" = {
    text = ''
      [Slice]
      MemoryLow=400M
    '';
    overrideStrategy = "asDropin";
  };
  # The compositor is spared too (desktop/hyprland.nix, in its unit's own
  # drop-in: a second definition here broke the build).
}
