# memory/zram-tier1 — the TIGHT machine: ramMB < 6144 (the 2-4 GB
# class — lab: comodore 1931, acer 3833, the VM 3912).
#
#   zram 150% zstd prio 100 · swappiness 180 · vfs_cache_pressure 50
#   dirty 5%/2% · page-cluster 0 · nix max-jobs 1 / cores 2
#
# WHY (lifted with the values from hardware/memory.nix, 2026-09-10):
# swappiness 180 because moving cold pages to zram is ~RAM-speed and
# beats squeezing the working set; cache-pressure 50 because hoarded
# metadata competes with application pages here; dirty 5/2 keeps
# writeback bursts small on the laptop HDDs this class carries;
# page-cluster 0 because swap readahead only adds latency against
# compressed RAM. One build job, two compiler threads: a rebuild eval
# wants 2-3 GB — two parallel derivations on 4 GB is a freeze.
{ ... }:

{
  zramSwap.enable = true;
  zramSwap.algorithm = "zstd";
  zramSwap.priority = 100;
  zramSwap.memoryPercent = 150;
  boot.kernel.sysctl = {
    "vm.swappiness" = 180;
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_ratio" = 5;
    "vm.dirty_background_ratio" = 2;
    "vm.page-cluster" = 0;
  };
  nix.settings.max-jobs = 1;
  nix.settings.cores = 2;
}
