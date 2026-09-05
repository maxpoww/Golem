# Storage policy — deliberately FACT-FREE (the anti-over-gating rule,
# spec §5): both decisions here key on what the kernel already knows per
# device at runtime, so gating them on an install-time fact would only add
# a permutation and miss hotplugged disks. Demanded by lab row 1: the
# Acer E5-573 carries a 1 TB spinning WD, and the default mq-deadline
# scheduler is why old-laptop desktops feel like molasses under any IO.
{ lib, ... }:

{
  # BFQ on rotational disks: the desktop-latency scheduler — a background
  # copy or nix build no longer freezes the UI on an HDD machine. SSDs/
  # NVMe keep their defaults (mq-deadline/none), where BFQ only costs CPU.
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", \
      ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
  '';
  boot.kernelModules = [ "bfq" ];

  # Weekly TRIM keeps SSDs fast and long-lived; on filesystems/devices
  # without discard support fstrim skips silently — safe everywhere.
  services.fstrim.enable = lib.mkDefault true;
}
