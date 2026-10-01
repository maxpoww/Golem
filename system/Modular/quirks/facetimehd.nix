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
# Boot only: RemainAfterExit + no restart on switch. Before, every switch
# (a dock install, 2026-10-01 11:30) re-ran it mid-session and yanked the
# camera out from under PipeWire.
#
# FROZEN PICTURE IN EVERY PIPEWIRE/GSTREAMER APP (2026-10-01, Cheese on
# the .242): nixpkgs ships facetimehd 0.6.13, which hands every frame
# timestamp 0 and sequence 0. PipeWire and GStreamer take each new frame
# for a duplicate of the first and show it forever (frames kept flowing:
# 30 distinct raw frames via v4l2-ctl; Firefox reads v4l2 directly and
# never noticed). Upstream fixed it in b238cd9 ("v4l2: Provide sequence
# and timestamp to vbuf", issue #315, first in 0.7.0.3); we carry that one
# commit until nixpkgs moves past 0.7.0.3, so the fix rides whatever
# kernel set boot.kernelPackages defaults to.
{ pkgs, lib, ... }:

{
  hardware.facetimehd.enable = true;
  nixpkgs.overlays = [
    (final: prev: {
      linuxPackages = prev.linuxPackages.extend (lpFinal: lpPrev: {
        facetimehd = lpPrev.facetimehd.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ./facetimehd-timestamps.patch ];
        });
      });
    })
  ];
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
    serviceConfig.RemainAfterExit = true;
    restartIfChanged = false;
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
