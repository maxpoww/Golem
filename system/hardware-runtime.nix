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
  # The wl module ships on every Golem so the live ISO can serve Mac wifi.
  # Inert unless the service below loads it (never auto-loads, no alias
  # binding here) — chips served by in-tree drivers are left untouched.
  #
  # nixpkgs marks broadcom-sta insecure (abandoned upstream, old CVEs in a
  # driver Broadcom never maintained). Permitted deliberately and narrowly:
  # it is the ONLY driver that exists for BCM4360-class chips — the wifi in
  # a decade of MacBooks — and "no wifi on any Mac" fails Golem's first-boot
  # bar harder than a local-attack-surface CVE in a module that only loads
  # when that exact chip is present. Every distro that serves Macs ships it.
  nixpkgs.config.allowInsecurePredicate =
    p: (lib.getName p) == "broadcom-sta";
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];

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

      # ── Broadcom wl, only for chips that need it ──────────────────────
      # BCM4360/4352-class PCI ids (wl-only; brcmfmac/b43 cannot drive them).
      need_wl=0
      for d in /sys/bus/pci/devices/*; do
        [ "$(cat "$d/vendor" 2>/dev/null)" = "0x14e4" ] || continue
        case "$(cat "$d/device" 2>/dev/null)" in
          0x43a0|0x43a2|0x43a3|0x43b1) need_wl=1 ;;
        esac
      done
      if [ "$need_wl" = 1 ]; then
        echo "golem-hw-runtime: wl-only Broadcom chip found — switching drivers"
        modprobe -r b43 brcmsmac bcma ssb 2>/dev/null || true
        modprobe wl && echo "golem-hw-runtime: wl loaded" || echo "golem-hw-runtime: wl failed to load"
      fi
    '';
  };
}
