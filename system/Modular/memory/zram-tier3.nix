# memory/zram-tier3 — the BIG machine: ramMB > 16384 (the 32 GB class
# — lab: the lenovo dev box).
#
#   zram 25% zstd prio 100 · swappiness 10 · vfs_cache_pressure 10
#   dirty 10%/5% · page-cluster 0
#
# Values lifted from hardware/memory.nix's high tier + baseline
# (2026-09-10): swapping at all is a smell here — zram stays as a
# pressure valve, small.
{ ... }:

{
  zramSwap.enable = true;
  zramSwap.algorithm = "zstd";
  zramSwap.priority = 100;
  zramSwap.memoryPercent = 25;
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 10;
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;
    "vm.page-cluster" = 0;
  };
}
