# memory/zram-tier3 — the BIG machine: ramMB > 16384 (the 32 GB class
# — lab: the lenovo dev box).
#
#   zram 25% zstd prio 100 · swappiness 10 · vfs_cache_pressure 10
#   dirty 256/64 MiB · page-cluster 0
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
    # Capped in bytes (Omarchy's numbers, 2026-10-30): 10 % of this much memory is
    # gigabytes of writes piling up and then flushing in a stall, the longer the
    # slower the disk. Bytes zero the percentages, which must not be set with them.
    "vm.dirty_bytes" = 268435456; # 256 MiB
    "vm.dirty_background_bytes" = 67108864; # 64 MiB
    "vm.page-cluster" = 0;
  };
}
