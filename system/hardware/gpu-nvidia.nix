# Golem NVIDIA policy, fact-gated — the ported dev-host module
# (/etc/nixos/nvidia-module.nix, spec §3 "port pending" → done). The origin
# gesture generalized: this is the nvidia.nix Max pasted into /etc/nixos
# after every reinstall, now shipped to every machine, dormant until a
# facts file wakes it (GolemInstall.md §1).
#
# WHAT THE FACTS DECIDE (golem.hardware.*, see system/hardware.nix):
#   gpu == "nvidia"            an NVIDIA dGPU is present — nothing activates
#                              without this
#   nvidiaGen == "turing+"     open GSP kernel module + current branch, plus
#                              THE SUSPEND FIX: preserve VRAM across s2idle
#                              or the GSP RPC state desyncs on resume and
#                              the session freezes (kernel_gsp.c:1447
#                              assert — fixed & metal-verified 2026-09-03
#                              on the Slim Pro 9i).
#   nvidiaGen == "pre-turing"  the 580 legacy branch (Maxwell/Pascal/Volta —
#                              580.x is the last branch that supports them),
#                              proprietary kmod: the open module is
#                              Turing-only.
#   nvidiaGen == "unknown"     THE IRON LAW (§8): nothing happens. The
#                              machine stays on the modesetting/nouveau
#                              floor that boots on everything. An RTX on
#                              nouveau is a bug report; a black screen is a
#                              dead distro.
#   intelBusId + nvidiaBusId   both set (a hybrid laptop) → PRIME render
#                              offload with the offload wrapper; either
#                              null (a desktop) → the dGPU drives displays
#                              directly, no PRIME.
#
# Every value is lib.mkDefault (spec §2: the user stays sovereign) — a
# hand override in the machine's flake always wins without mkForce.
#
# Wayland note: the PRIME bus IDs only reach generated X11 Device sections;
# on a Wayland-only Golem (greetd + Hyprland) they are inert — kept for
# X-fallback correctness and as the override point.
{ config, lib, pkgs, ... }:

let
  cfg = config.golem.hardware;
  hybrid = cfg.nvidiaBusId != null && cfg.intelBusId != null;
in
{
  config = lib.mkIf (cfg.gpu == "nvidia") (lib.mkMerge [

    # ── Common to every classified generation ─────────────────────────
    (lib.mkIf (cfg.nvidiaGen != "unknown") {
      # Historical option name; also the correct switch for Wayland —
      # `modesetting` below is what makes Wayland actually work.
      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.graphics = {
        enable = lib.mkDefault true;
        enable32Bit = lib.mkDefault pkgs.stdenv.hostPlatform.isx86_64;
      };

      hardware.nvidia = {
        modesetting.enable = lib.mkDefault true;
        nvidiaSettings = lib.mkDefault true;

        # PRIME render offload, only when detection filled BOTH bus ids —
        # the only truly per-host values in the whole library (§4).
        # mkOverride 900, not mkDefault: upstream nvidia.nix config-defines
        # offload.enable (mkDefault false), which ties and conflicts at
        # 1000 — 900 beats the upstream default and still yields to any
        # plain per-host definition (priority 100).
        prime = lib.mkIf hybrid {
          offload = {
            enable = lib.mkOverride 900 true;
            enableOffloadCmd = lib.mkOverride 900 true;
          };
          intelBusId = lib.mkDefault cfg.intelBusId;
          nvidiaBusId = lib.mkDefault cfg.nvidiaBusId;
        };
      };
    })

    # ── Turing and newer: the open-module path ────────────────────────
    (lib.mkIf (cfg.nvidiaGen == "turing+") {
      hardware.nvidia = {
        # Open kernel modules — the supported/required path on Ada; GSP
        # firmware is mandatory on this generation and cannot be off.
        open = lib.mkDefault true;
        package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.stable;

        powerManagement = {
          # *** THE SUSPEND/RESUME FIX *** — NVreg_PreserveVideoMemoryAllocations=1
          # plus the nvidia-suspend/resume/hibernate services, so the open
          # GSP module does not assert on resume (see header).
          enable = lib.mkDefault true;

          # Clean state save/restore handshake via the kernel's suspend
          # notifier. Needs driver >= 595 AND the open modules — guarded so
          # a host pinning an older driver or forcing open off (it is a
          # nullable bool upstream — hence `== true`, not truthiness)
          # degrades gracefully instead of crashing the eval.
          kernelSuspendNotifier = lib.mkIf
            (config.hardware.nvidia.open == true
             && lib.versionAtLeast config.hardware.nvidia.package.version "595")
            (lib.mkDefault true);

          # Runtime-D3 (dGPU off while idle): a real battery win on an
          # offload laptop but a known resume-instability source. OFF by
          # default on purpose — enable per-host only after testing suspend
          # on that model.
          finegrained = lib.mkDefault false;
        };
      };
    })

    # ── Maxwell / Pascal / Volta: the legacy branch ───────────────────
    (lib.mkIf (cfg.nvidiaGen == "pre-turing") {
      hardware.nvidia = {
        # The open kmod is Turing+ only; these parts run the proprietary
        # module from the 580 branch — the last that supports them.
        open = lib.mkDefault false;
        package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.legacy_580;
        # No VRAM-preserve default here: the GSP resume assert is an
        # open-module problem; the classic branch's default suspend path
        # has served these parts for a decade. Opt in per-host if a model
        # needs it.
      };
    })
  ]);
}
