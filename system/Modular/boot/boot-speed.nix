# Golem boot — the general fast + reliable pass (#125, 2026-09-24).
#
# Profiled over SSH on the comodore + HP metal (the lab door earning its keep).
# #124 already made the initrd systemd-based and loads the GPU via udev so a slow
# GPU probe can't block storage. Two more GENERAL wins land here — portable to any
# machine, not comodore-specific:
#
# 1. `8250.nr_uarts=0` — skip the legacy 8250 serial-port autoconfig. On older
#    chipsets that probe runs slow loopback/IRQ tests on every port (present or
#    not); `ttyS0-3` alone ate ~22 s of udev work on BOTH old lab machines, which
#    drags the initrd's device settle and congests userspace udev (delaying the
#    disk/swap device units the boot waits on). Golem is a desktop OS with no
#    serial console — the VGA/framebuffer console (tty0) is untouched — so there
#    is nothing to lose. This is BASE, i.e. INSTALLED systems only; the installer
#    MEDIUM keeps its serial for lab diagnostics.
#
# 2. `NetworkManager-wait-online` off — nothing in a desktop boot should block on
#    the network being UP. NM connects in the background; `multi-user` must not
#    wait on a link / DHCP / a slow wifi dongle (that wait was ~10 s on the
#    comodore's rtl8187). Standard NixOS boot-speed hygiene; the auto-upgrade uses
#    its own `golem-wait-online` gate, unaffected.
{ lib, ... }:

{
  boot.kernelParams = lib.mkAfter [ "8250.nr_uarts=0" ];

  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
}
