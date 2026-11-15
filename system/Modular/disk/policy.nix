# disk/policy — the ONE disk leaf, always chosen, and deliberately so:
# this group is a single model because the rule is per-DEVICE and
# self-selecting at runtime (a udev match on queue/rotational), which
# an install-time hdd/ssd split would break the day a stranger plugs a
# USB spinner into an NVMe machine. The anti-over-gating exception,
# written down so nobody "fixes" it into two leaves. Lifted verbatim
# from hardware/storage.nix (2026-09-10).
{ config, lib, ... }:

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

  # AN ENCRYPTED DISK WAITS FOR ITS OWNER (2026-10-28, VM). The initrd gives
  # every device 90 s to appear — and `/` only appears once the passphrase is
  # typed, so whoever took longer than that (or came back from a coffee) was
  # dropped into emergency mode, which on Golem is a locked dead end (root
  # has no password). With an encrypted disk the initrd waits for its devices
  # as long as it takes. A plain install has no such wait: its devices are
  # there from the start, and the initrd's default stays.
  boot.initrd.systemd.settings.Manager.DefaultDeviceTimeoutSec =
    lib.mkIf (config.boot.initrd.luks.devices != { }) "infinity";
}
