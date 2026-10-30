# memory/zram-tier2 — the MIDDLE machine: 6144 ≤ ramMB ≤ 16384 (the
# 8-16 GB class — lab faces: the asus 8012, the thinkpad 7159; the
# dell's 5809 sits just under the boundary and correctly takes tier1).
#
#   zram 50% zstd prio 100 · swappiness 60 · vfs_cache_pressure 10
#   dirty 256/64 MiB · page-cluster 0
#
# Values lifted from hardware/memory.nix's mid tier + baseline
# (2026-09-10): enough RAM that metadata hoarding wins again (10), a
# moderate swappiness, the historical dirty ratios.
{ ... }:

{
  zramSwap.enable = true;
  zramSwap.algorithm = "zstd";
  zramSwap.priority = 100;
  zramSwap.memoryPercent = 50;
  boot.kernel.sysctl = {
    "vm.swappiness" = 60;
    "vm.vfs_cache_pressure" = 10;
    # Capped in bytes (Omarchy's numbers, 2026-10-30): 10 % of this much memory is
    # gigabytes of writes piling up and then flushing in a stall, the longer the
    # slower the disk. Bytes zero the percentages, which must not be set with them.
    "vm.dirty_bytes" = 268435456; # 256 MiB
    "vm.dirty_background_bytes" = 67108864; # 64 MiB
    "vm.page-cluster" = 0;
  };
}
