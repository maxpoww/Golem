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
    cpuModel = lib.mkOption {
      type = lib.types.str;
      default = "unknown";
      description = ''
        The CPU's marketing name, straight from /proc/cpuinfo
        (informational). It identifies a lab machine at a glance in the
        census summary; nothing gates on it.
      '';
    };
    cores = lib.mkOption {
      type = lib.types.int;
      default = 0;
      description = ''
        PHYSICAL CPU cores (informational; 0 = unknown) — distinct
        (physical id, core id) pairs, not `nproc`. Until 2026-09-05 this
        held the logical count, which reported a 2-core i5-5200U as 4.
        See `threads` for the logical one.
      '';
    };
    threads = lib.mkOption {
      type = lib.types.int;
      default = 0;
      description = "Logical CPUs / hardware threads (informational; 0 = unknown).";
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
    nvidiaGen = lib.mkOption {
      type = lib.types.enum [ "unknown" "pre-turing" "turing+" ];
      default = "unknown";
      description = ''
        NVIDIA GPU generation, from the PCI device id (probe: >= 0x1e00 is
        Turing or newer, 0x1340-0x1dff Maxwell/Pascal/Volta). Decides the
        driver stack in hardware/gpu-nvidia.nix: "turing+" gets the open
        GSP kernel module + current branch, "pre-turing" the 580 legacy
        branch (last to support those parts). "unknown" is the iron law
        (GolemInstall.md §8): an nvidia GPU whose generation we could not
        classify stays on the modesetting/nouveau floor that boots on
        everything — an RTX on nouveau is a bug report, a black screen is
        a dead distro.
      '';
    };
    intelBusId = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "PCI:0:2:0";
      description = "iGPU bus id for PRIME offload (null = no offload).";
    };
    hasBluetooth = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        A Bluetooth radio is present. Default TRUE on purpose (the
        conservatism rule, GolemInstall.md §4): an undetected machine keeps
        today's always-on stack — only a confident "no radio" verdict drops
        bluez/blueman. First demanded by lab row 1 (Acer E5-573), whose
        radio hides from a single sysfs glob: detection triangulates
        /sys/class/bluetooth, rfkill and USB interface class.
      '';
    };
    cpuVendor = lib.mkOption {
      type = lib.types.enum [ "unknown" "intel" "amd" ];
      default = "unknown";
      description = ''
        CPU vendor from /proc/cpuinfo; drives microcode updates. "unknown"
        changes nothing (today's behavior — nothing in this tree ever set
        updateMicrocode, see configuration.nix's firmware note).
      '';
    };
    firmware = lib.mkOption {
      type = lib.types.enum [ "uefi" "bios" ];
      default = "uefi";
      description = ''
        How this machine boots, from /sys/firmware/efi at probe time. Drives
        the bootloader (configuration.nix): "uefi" → systemd-boot, "bios" →
        GRUB (BIOS/legacy). 3 of the 5 lab machines boot BIOS, and premium
        ~2013 gaming rigs still do — legacy support is not an edge case.
        Default "uefi": the safe modern assumption when no probe ran (the
        live ISO, the dev host).
      '';
    };
    broadcomWifi = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        A Broadcom (PCI 0x14e4) wireless card is present — the wifi that
        does not just work. Drives the Broadcom driver stack
        (hardware/broadcom-wifi.nix): redistributable firmware carries
        brcmfmac for most parts (incl. the Intel-MacBook BCM4360), with the
        unfree broadcom_sta (wl) enabled for reliability. Default false:
        every other wifi is handled by in-tree drivers already present.
      '';
    };
    chassis = lib.mkOption {
      type = lib.types.enum [ "unknown" "laptop" "desktop" ];
      default = "unknown";
      description = ''
        Machine class from DMI chassis-type (battery presence as the
        fallback tell). Drives the laptop power stack
        (hardware/power-laptop.nix).
      '';
    };
    vmGuest = lib.mkOption {
      type = lib.types.enum [ "none" "qemu" "vmware" "virtualbox" "hyperv" ];
      default = "none";
      description = ''
        Hypervisor this machine is a guest of, from DMI vendor strings.
        Drives that hypervisor's guest tools (hardware/virt-guest.nix);
        "none" — a physical machine, or one we could not classify — adds
        nothing.
      '';
    };
    fingerprint = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        A USB fingerprint reader is present — detected by USB vendor id
        (Validity 138a, Synaptics 06cb, Goodix 27c6: the vendors that are
        fingerprint hardware in practice). Enables fprintd
        (hardware/fingerprint.nix). A false positive costs an idle daemon;
        a false negative costs enrollment — the reader still does nothing
        until its owner enrolls a finger, so default false is safe.
      '';
    };
    panelDpi = lib.mkOption {
      type = lib.types.int;
      default = 0;
      description = ''
        The internal panel's physical DPI — native horizontal pixels
        against the EDID's physical width (eDP connector only; externals
        are the user's business). 0 = unknown/no internal panel = no
        scaling opinion. The home layer turns this into a Hyprland
        monitor scale for the eDP output so a 4K 13-inch stranger's
        laptop doesn't boot at ant size (and a 1366x768 Acer isn't
        cramped at 2.0 — the 2026-09-02 lesson in hyprland.lua).
      '';
    };
  };

  config = lib.mkMerge [
    # RAM-tiered swap/zram/sysctl policy moved to hardware/memory.nix
    # (spec §5's library) — grown into the full memory family when
    # hibernation-backed disk swap became a locked decision (2026-09-04).

    # ── CPU microcode — free correctness/security once the vendor is known
    (lib.mkIf (cfg.cpuVendor == "intel") {
      hardware.cpu.intel.updateMicrocode = lib.mkDefault true;
    })
    (lib.mkIf (cfg.cpuVendor == "amd") {
      hardware.cpu.amd.updateMicrocode = lib.mkDefault true;
    })

    # ── GPU driver selection ───────────────────────────────────────────
    # ── Undetected machines (the LIVE ISO above all): ship every userspace
    # VA-API driver so runtime detection has something to pick from. These
    # are inert unless libva selects them, and small next to the image — but
    # without them the live session on an Intel laptop has NO hardware video
    # decode at all (the Air CPU-decoded VP9 at 95 °C for exactly this
    # reason: detection only ran at install, and the ISO is pre-install by
    # definition). The right driver NAME is chosen at boot by
    # hardware-runtime.nix; AMD needs nothing here (mesa's radeonsi VA
    # driver rides the default stack).
    (lib.mkIf (cfg.gpu == "auto") {
      hardware.graphics.extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
        libvdpau-va-gl
      ];
    })

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

      # Pre-Skylake has NO VP9/AV1 hardware decode — i965 does H.264 only.
      # YouTube serves VP9 by default, so even with a perfect VA-API stack
      # these machines CPU-decode, overheat, throttle and stutter (measured:
      # 2013 HD 5000, 92-95 °C, 36% dropped frames — while the same chip
      # hardware-decodes H.264 effortlessly). Force-install
      # enhanced-h264ify (id verified against the Chrome Web Store
      # 2026-09-02) via Chrome enterprise policy so YouTube falls back to
      # H.264 on exactly these machines. Applies to installed systems whose
      # detection set intelLegacy; needs network at first Chrome start to
      # fetch the extension.
      environment.etc."opt/chrome/policies/managed/golem-legacy-video.json" =
        lib.mkIf cfg.intelLegacy {
          text = builtins.toJSON {
            ExtensionInstallForcelist = [
              "omkfmpieigblcllmkgbflkikinpkodlk;https://clients2.google.com/service/update2/crx"
            ];
          };
        };
    })
    (lib.mkIf (cfg.gpu == "amd") {
      hardware.graphics.extraPackages = with pkgs; [
        libvdpau-va-gl
      ];
    })
    # nvidia moved to hardware/gpu-nvidia.nix (spec §5's module library):
    # the ported dev-host module — open kmod on Turing+, the suspend/VRAM
    # fix, legacy_580 for pre-Turing, nouveau floor when the generation is
    # unknown. This file keeps the facts schema and the families too small
    # to split (zram tiers, microcode, intel/amd VA-API).
  ];
}
