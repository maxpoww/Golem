# disk/policy — the ONE disk leaf, always chosen, and deliberately so:
# this group is a single model because the rule is per-DEVICE and
# self-selecting at runtime (a udev match on queue/rotational), which
# an install-time hdd/ssd split would break the day a stranger plugs a
# USB spinner into an NVMe machine. The anti-over-gating exception,
# written down so nobody "fixes" it into two leaves. Lifted verbatim
# from hardware/storage.nix (2026-09-10).
{ lib, ... }:

{
  # BFQ on rotational disks: the desktop-latency scheduler — a
  # background copy or nix build no longer freezes the UI on an HDD
  # machine. SSDs/NVMe keep their defaults, where BFQ only costs CPU.
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", \
      ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
  '';
  boot.kernelModules = [ "bfq" ];

  # Weekly TRIM: fast/long-lived SSDs; skips silently where unsupported.
  services.fstrim.enable = lib.mkDefault true;
}
