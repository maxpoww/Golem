# memory/zram-tier0 — RAM UNKNOWN (ramMB = 0: no census ran, or the
# probe failed). The conservative pre-module behavior, exactly:
#
#   zram 50% zstd prio 100 · swappiness 10 · vfs_cache_pressure 10
#   dirty 10%/5% · page-cluster 0
#
# Values lifted from hardware/memory.nix's baseline (2026-09-10). The
# chooser reaching for this leaf on a real install is itself worth a
# look — the census should know the RAM.
{ ... }:

{
  zramSwap.enable = true;
  zramSwap.algorithm = "zstd";
  zramSwap.priority = 100;
  zramSwap.memoryPercent = 50;
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 10;
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;
    "vm.page-cluster" = 0;
  };
}
