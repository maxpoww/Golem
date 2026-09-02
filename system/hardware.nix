# Golem hardware-aware tuning — the facts an installer/first-boot detects
# about THIS machine, folded into the config it builds.
#
# The problem this solves: one flake serves a 4 GB Broadwell laptop, an
# 8 GB VM and a 32 GB nvidia desktop. Shipping them identical zram and GPU
# settings is wrong for all three — a 32 GB box does not want 16 GB of zram,
# and a stranger's nvidia box must not land on nouveau while an Intel box
# pays for a driver it can't use.
#
# The detected facts live in `golem.hardware.*`. The installer (S9) runs
# `golem-hw-detect` (system/hardware/detect.nix) on the TARGET machine
# before the first build and writes a small `golem-hardware.nix` that sets
# these; a machine with no such file gets safe generic defaults (open GPU
# stack, 50 % zram) — exactly today's behavior, so nothing regresses.
{ config, pkgs, lib, ... }:

let
  cfg = config.golem.hardware;
  # RAM tier drives the swap policy. 0 = "unknown" (no detection has run):
  # keep the historical generic defaults so an un-detected machine is never
  # worse off than before this module existed.
  known = cfg.ramMB > 0;
  low  = known && cfg.ramMB <  6144;   # 4 GB class — lean on zram hard
  high = known && cfg.ramMB > 16384;   # 16 GB+ — a big zram is just waste
in
{
  options.golem.hardware = {
    ramMB = lib.mkOption {
      type = lib.types.int;
      default = 0;
      description = ''
        Installed RAM in MiB, as detected on the target machine. Scales the
        zram size and swappiness. 0 means "not detected" — safe generic
        defaults (50 % zram) are used.
      '';
    };
    cores = lib.mkOption {
      type = lib.types.int;
      default = 0;
      description = "Detected CPU core count (informational; 0 = unknown).";
    };
    gpu = lib.mkOption {
      type = lib.types.enum [ "auto" "intel" "amd" "nvidia" "virtio" ];
      default = "auto";
      description = ''
        The target machine's GPU vendor, detected from the PCI vendor id.
        "auto" and "virtio" use the generic open stack (kernel KMS + mesa,
        already enabled) — correct for Intel, AMD and virtio out of the box.
        "intel"/"amd" add that vendor's VA-API video acceleration. "nvidia"
        switches to the proprietary driver (a stranger's nvidia box would
        otherwise fall back to nouveau); PRIME offload turns on only when
        both bus ids below are set (a laptop with an iGPU), otherwise the
        nvidia GPU drives the display directly (a desktop).
      '';
    };
    intelLegacy = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        The Intel iGPU is pre-Skylake (Haswell/Ivy Bridge and older). Those
        parts need the legacy i965 VA-API driver — intel-media-driver (iHD)
        only supports Broadwell+ and gives NO hardware video decode on older
        GPUs, so they fall back to CPU-decoding (a 2013 HD 5000 hits 95 °C
        software-decoding VP9). Detected from the GPU's PCI device id.
      '';
    };
    nvidiaBusId = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "PCI:1:0:0";
      description = "nvidia GPU bus id for PRIME offload (null = no offload).";
    };
    intelBusId = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "PCI:0:2:0";
      description = "iGPU bus id for PRIME offload (null = no offload).";
    };
  };

  config = lib.mkMerge [
    # ── RAM-scaled swap ────────────────────────────────────────────────
    # zramSwap.memoryPercent is a percentage of the machine's ACTUAL RAM at
    # boot, so the absolute size already tracks hardware; what this tiers is
    # the POLICY. A 4 GB machine wants more compressed swap than physical
    # RAM (zram compresses ~2-3x, and swapping to RAM beats an OOM freeze),
    # so 150 %; a 16 GB+ machine will essentially never swap, so a big zram
    # is wasted reservation — 25 %. Between, the historical 50 %.
    (lib.mkIf low {
      zramSwap.memoryPercent = lib.mkForce 150;
      # zram is RAM-fast, so on a tight machine PREFER it over letting the
      # working set get squeezed — the opposite of the disk-swap-avoidance
      # 10 the core sets for machines with headroom.
      boot.kernel.sysctl."vm.swappiness" = lib.mkForce 150;
    })
    (lib.mkIf high {
      zramSwap.memoryPercent = lib.mkForce 25;
    })

    # ── GPU driver selection ───────────────────────────────────────────
    (lib.mkIf (cfg.gpu == "intel") {
      # Ship BOTH Intel VA-API drivers and let LIBVA_DRIVER_NAME pick the
      # right one for the detected generation. iHD (intel-media-driver) is
      # Broadwell+; i965 (intel-vaapi-driver) covers Haswell/Ivy and older.
      # Getting this wrong is not cosmetic: iHD on a pre-Skylake part yields
      # NO hardware decode, so the browser CPU-decodes video — measured on a
      # 2013 HD 5000: 95 °C / thermal-throttle / 720p-stutter, vs GNOME (same
      # box) forcing i965 → GPU-assisted decode → 74 °C / smooth 1080p60
      # (verified 2026-09-02 against its /etc/nixos config). Chrome's VA-API
      # is enabled in home.nix (programs.chromium args).
      hardware.graphics.extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
        libvdpau-va-gl
      ];
      environment.sessionVariables.LIBVA_DRIVER_NAME =
        if cfg.intelLegacy then "i965" else "iHD";
    })
    (lib.mkIf (cfg.gpu == "amd") {
      hardware.graphics.extraPackages = with pkgs; [
        libvdpau-va-gl
      ];
    })
    (lib.mkIf (cfg.gpu == "nvidia") {
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia = {
        modesetting.enable = true;
        open = true;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      } // lib.optionalAttrs (cfg.nvidiaBusId != null && cfg.intelBusId != null) {
        prime = {
          offload = {
            enable = true;
            enableOffloadCmd = true;
          };
          nvidiaBusId = cfg.nvidiaBusId;
          intelBusId = cfg.intelBusId;
        };
      };
    })
  ];
}
