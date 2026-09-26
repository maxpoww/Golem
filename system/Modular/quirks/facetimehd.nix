# quirks/facetimehd — the Broadcom 720p FaceTime HD camera (PCI
# 0x14e4:0x1570) in 2013+ Intel Macs. Chosen when hasFacetimeHD=true
# (additive — a quirk, not a group). The camera needs the out-of-tree
# `facetimehd` (bcwc_pcie) kernel module AND an ISP firmware blob that
# nixpkgs extracts from a 2 MB byte-range of Apple's OSXUpd10.11.5.dmg
# (unfree). hardware.facetimehd.enable wires both — the module into
# boot.extraModulePackages, the firmware into hardware.firmware.
#
# PROVEN LIVE on the MacBookAir6,2 (2026-09-18, before its install): the
# module loads on the 6.18.48 kernel, the ISP firmware loads ("Loaded
# firmware, size: 1392kb"), /dev/video0 appears as "Apple Facetime HD"
# and CAPTURES 1280x720 YUYV frames (1,843,200 bytes). The per-sensor
# calibration (facetimehd/1871_01XX.dat) is NOT shipped and NOT needed —
# capture works without it. (Lab: the MacBook — the boss fight, #5's camera.)
#
# COLD-BOOT PLL GLITCH (2026-09-25, seen on the .242 install): the very
# first probe after a cold boot sometimes fails the ISP PLL lock — dmesg
# shows "Failed to lock S2 PLL" then "magic value: 00000000", and the
# camera enumerates but never captures. A second probe locks it. So we
# re-bind the driver to the device once at boot (re-runs probe), the same
# sysfs lever gpu2/failing uses — no module-path fragility, no-op if the
# driver never bound, safe because nothing opens the camera this early.
{ pkgs, lib, ... }:

{
  hardware.facetimehd.enable = true;
  # facetimehd-firmware is unfree (extracted from Apple's driver). Permit
  # it by NAME, scoped to this leaf — only a FaceTime-HD machine relaxes
  # the policy, exactly as broadcom-wl scopes broadcom-sta's insecure flag.
  # (Distinct option from broadcom-wl's allowInsecurePredicate, so the two
  # leaves compose on the MacBook without a module-system conflict.)
  nixpkgs.config.allowUnfreePredicate =
    pkg: lib.getName pkg == "facetimehd-firmware";

  systemd.services.golem-facetimehd-relock = {
    description = "Re-bind the FaceTime HD camera so its ISP PLL locks (cold-boot glitch)";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];   # after the initial autoload
    before = [ "graphical.target" ];             # camera ready before any desktop session
    path = [ pkgs.coreutils ];
    serviceConfig.Type = "oneshot";
    script = ''
      drv=/sys/bus/pci/drivers/facetimehd
      for dev in "$drv"/0000:*; do
        [ -e "$dev" ] || continue
        b=''${dev##*/}
        echo "$b" > "$drv/unbind" 2>/dev/null || true
        sleep 1
        echo "$b" > "$drv/bind" 2>/dev/null || true
      done
    '';
  };
}
