# Memory policy, sized by the machine — swap, zram, and the vm.* knobs,
# tiered on the `ramMB` fact (Max, 2026-09-04: "Golem has to be aware of
# the quantity of memory and decide how to play"). One family module
# (spec §5); this supersedes the two zram tiers that lived in
# hardware.nix and the three vm.* memory sysctls core carried.
#
# THE SHAPE: two swap layers with distinct jobs.
#   zram  (priority 100)  the working swap — compressed RAM, near-free to
#                         hit, absorbs pressure spikes so a 4 GB machine
#                         installs apps instead of thrashing.
#   disk  (kernel prio)   the hibernation image target, and the spillway
#                         when zram is full. Hibernation is a LOCKED
#                         decision (Max, 2026-09-04): the installer
#                         creates disk swap sized RAM+margin on every
#                         machine — see `lib.golem.swapForHibernationMB`
#                         in flake.nix for the one sizing rule.
#
# TIERS (ramMB; 0 = unknown = exactly the pre-module behavior, per the
# conservatism law §4):
#            zram   swappiness  vfs_cache_pressure  dirty/background
#   unknown   50%       10             10                10/5
#   < 6 GB   150%      180             50                 5/2
#   6-16 GB   50%       60             10                10/5
#   > 16 GB   25%       10             10                10/5
#
# WHY: swappiness 180 on tight RAM because moving cold pages to zram is
# ~RAM-speed and beats squeezing the working set (kernel docs bless >100
# for in-memory swap); 10 on big RAM where swapping at all is a smell.
# vfs_cache_pressure 10 hoards dentry/inode caches (core's historical
# choice — metadata cache is the desktop-latency win); on tight RAM 50,
# because hoarded metadata competes with application pages. dirty 5/2 on
# tight RAM keeps writeback bursts small (10% of 4 GB flushed to a
# laptop HDD is a visible stall — lab row 1 is exactly that machine).
# vm.page-cluster 0 whenever zram is on: swap "readahead" batches 8
# pages for spinning disks; against compressed RAM it only adds latency.
#
# Tier values are mkOverride 900 (the gpu-nvidia.nix pattern): they beat
# the baseline mkDefaults here, and any plain per-host definition beats
# them — the user stays sovereign (§2).
{ config, lib, ... }:

let
  cfg = config.golem.hardware;
  known = cfg.ramMB > 0;
  low = known && cfg.ramMB < 6144;
  mid = known && cfg.ramMB >= 6144 && cfg.ramMB <= 16384;
  high = known && cfg.ramMB > 16384;
  tier = lib.mkOverride 900;
in
{
  config = lib.mkMerge [
    # ── Baseline: the historical core values, now owned here ──────────
    {
      zramSwap.algorithm = lib.mkDefault "zstd";
      zramSwap.priority = lib.mkDefault 100;
      boot.kernel.sysctl = {
        "vm.swappiness" = lib.mkDefault 10;
        "vm.vfs_cache_pressure" = lib.mkDefault 10;
        "vm.dirty_ratio" = lib.mkDefault 10;
        "vm.dirty_background_ratio" = lib.mkDefault 5;
      };
    }
    (lib.mkIf config.zramSwap.enable {
      boot.kernel.sysctl."vm.page-cluster" = lib.mkDefault 0;
    })

    # ── RAM tiers ─────────────────────────────────────────────────────
    (lib.mkIf low {
      zramSwap.memoryPercent = tier 150;
      boot.kernel.sysctl = {
        "vm.swappiness" = tier 180;
        "vm.vfs_cache_pressure" = tier 50;
        "vm.dirty_ratio" = tier 5;
        "vm.dirty_background_ratio" = tier 2;
      };
      # Build parallelism is a memory decision on a tight machine: one
      # nixos-rebuild eval wants 2-3 GB, so two parallel derivations on
      # 4 GB is a freeze (zram merely makes it slow-motion). One job,
      # two compiler threads — rebuild-golem stays survivable.
      nix.settings.max-jobs = tier 1;
      nix.settings.cores = tier 2;
    })
    (lib.mkIf mid {
      boot.kernel.sysctl."vm.swappiness" = tier 60;
    })
    (lib.mkIf high {
      zramSwap.memoryPercent = tier 25;
    })

    # ── Hibernation wiring, when the installer created disk swap ──────
    # With the systemd initrd (core) resume mostly self-arranges via the
    # HibernateLocation EFI variable, but naming the device also covers
    # BIOS machines and makes `systemctl hibernate` verifiable up front.
    # First swap device = the installer's hibernation partition; a
    # multi-swap host can override.
    (lib.mkIf (config.swapDevices != [ ]) {
      boot.resumeDevice = lib.mkDefault (lib.head config.swapDevices).device;
    })
  ];
}
