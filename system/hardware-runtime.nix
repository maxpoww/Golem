# Boot-time hardware adaptation — the RUNTIME sibling of hardware-detect.nix.
#
# hardware-detect.nix serves the INSTALLER: it writes golem-hardware.nix so
# the installed system is *built* for its machine. But the live ISO runs on
# hardware nobody has detected yet — the same image must come up right on a
# 2013 Broadcom MacBook and a 2023 nvidia tower. Anything that can be chosen
# at runtime is chosen here, every boot, before the session starts:
#
#   • LIBVA_DRIVER_NAME — libva defaults Intel to iHD, which supports only
#     Broadwell+; on Haswell/Ivy that yields NO hardware video decode and the
#     browser CPU-decodes (measured: 2013 HD 5000 at 95 °C, 720p stutter,
#     while GNOME on the same box picked i965 → 74 °C, smooth 1080p60).
#     hardware.nix ships BOTH drivers; this picks the right name per boot.
#   • Broadcom wl — BCM4360-class chips (Mac staples) have no in-tree
#     driver; the in-tree b43/bcma/brcmsmac grab them and fail. When such a
#     chip is present, unload the in-tree stack and load wl. Only then:
#     touching brcmfmac-served chips would break working wifi.
#
# The env lands in /run/environment.d, which systemd's user manager reads —
# so greetd → uwsm → Hyprland → waverunner → Chrome all inherit it. On an
# installed machine hardware.nix's build-time value (from detection) exists
# too and agrees; this file simply makes the pre-install boot equally right.
{ config, pkgs, lib, ... }:

{
  # Broadcom wl: TRIED AND WITHDRAWN (2026-09-02, MacBookAir6,2 / BCM4360,
  # kernel 6.18.48). The module compiles and loads, but binding it to the
  # chip Oopsed the kernel on the live machine ([#1] SMP PTI, tainted P+O,
  # networking left unstable). "It compiles" is not "it works" — the driver
  # is abandoned upstream and its 6.x compat patches are not enough for this
  # chip/kernel. Shipping a boot-time kernel oops to every Mac is strictly
  # worse than shipping no internal wifi (a USB dongle works today; even the
  # owner's GNOME install never got this chip up). Re-attempt only with an
  # LTS-kernel ISO variant or a repaired driver, tested on the real machine
  # BEFORE it ships. The VA-API half below is live and verified.

  systemd.services.golem-hw-runtime = {
    description = "Golem boot-time hardware adaptation (VA-API driver, Broadcom wl)";
    wantedBy = [ "multi-user.target" ];
    before = [ "greetd.service" "display-manager.service" ];
    after = [ "systemd-modules-load.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ pkgs.kmod ];
    script = ''
      mkdir -p /run/environment.d

      # ── VA-API driver name, by GPU generation ─────────────────────────
      libva=""
      for v in /sys/class/drm/card[0-9]*/device/vendor; do
        [ -r "$v" ] || continue
        vend=$(tr -d '[:space:]' < "$v")
        if [ "$vend" = "0x8086" ]; then
          dev=$(tr -d '[:space:]' < "$(dirname "$v")/device" 2>/dev/null || echo 0xffff)
          # Pre-Skylake (device id < 0x1600: Haswell/Ivy and older) → i965;
          # Broadwell+ → iHD. Mirrors hardware-detect.nix's install-time rule.
          if [ $((dev)) -lt $((0x1600)) ]; then libva="i965"; else libva="iHD"; fi
        fi
      done
      if [ -n "$libva" ]; then
        echo "LIBVA_DRIVER_NAME=$libva" > /run/environment.d/50-golem-hw.conf
        echo "golem-hw-runtime: LIBVA_DRIVER_NAME=$libva"
      fi

      # (Broadcom wl handling removed — see the withdrawal note at the top
      # of this file: binding wl to a BCM4360 Oopsed kernel 6.18 on the real
      # machine. Detection-only breadcrumb for the journal:)
      for d in /sys/bus/pci/devices/*; do
        [ "$(cat "$d/vendor" 2>/dev/null)" = "0x14e4" ] || continue
        case "$(cat "$d/device" 2>/dev/null)" in
          0x43a0|0x43a2|0x43a3|0x43b1)
            echo "golem-hw-runtime: wl-only Broadcom chip present ($(cat "$d/device")) — no working driver on this kernel; internal wifi unavailable (USB dongle works)" ;;
        esac
      done
    '';
  };
}
