# The golem.* option DECLARATIONS — the vocabulary every leaf, target
# file and fact file speaks. Declarations only, no config: a leaf never
# reads these (the dumb-leaf law); machine.nix and golem-hardware.nix
# SET them, the chooser and the data-driven base leaves (locale,
# console, users, selfrebuild) consume them as answers.
#
# Lifted verbatim from system/configuration.nix (golem.owner/locale/
# keyboard/flakeDir/flakeAttr) and system/hardware.nix
# (golem.hardware.*) on 2026-09-10 — one home for the schema so the
# Modular composition stands without importing the fat tree. When the
# fat path retires, those files' copies die and this one remains.
{ lib, ... }:

{
  options.golem.flakeDir = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "Local checkout of the Golem flake on this machine (null = none).";
  };
  options.golem.flakeAttr = lib.mkOption {
    type = lib.types.str;
    default = "golem-minimal";
    description = "Which nixosConfigurations attr this machine rebuilds itself as.";
  };
  options.golem.owner = lib.mkOption {
    type = lib.types.str;
    default = "max";
    description = "The machine's single human user — one knob for the installer.";
  };

  options.golem.locale = {
    defaultLocale = lib.mkOption {
      type = lib.types.str;
      default = "en_US.UTF-8";
      description = "The machine's language, from the installer's first step.";
    };
    timeZone = lib.mkOption {
      type = lib.types.str;
      default = "UTC";
      description = "The machine's timezone. UTC: merely wrong, never misleading.";
    };
  };

  options.golem.keyboard = {
    layout = lib.mkOption { type = lib.types.str; default = "us"; };
    variant = lib.mkOption { type = lib.types.str; default = ""; };
    options = lib.mkOption { type = lib.types.str; default = ""; };
    model = lib.mkOption { type = lib.types.str; default = "pc104"; };
    consoleKeyMap = lib.mkOption { type = lib.types.str; default = "us"; };
    consoleFont = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  # The census facts (informational at eval time in the Modular world:
  # the CHOOSER already consumed them to write modules.nix; they stay
  # set so the reveal, postinstall questions and any census re-derive
  # can compare against what was measured at install).
  options.golem.hardware = {
    ramMB = lib.mkOption { type = lib.types.int; default = 0; };
    cpuModel = lib.mkOption { type = lib.types.str; default = "unknown"; };
    cores = lib.mkOption { type = lib.types.int; default = 0; };
    threads = lib.mkOption { type = lib.types.int; default = 0; };
    gpu = lib.mkOption {
      type = lib.types.enum [ "auto" "intel" "amd" "nvidia" "virtio" ];
      default = "auto";
    };
    intelLegacy = lib.mkOption { type = lib.types.bool; default = false; };
    nvidiaBusId = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };
    nvidiaGen = lib.mkOption {
      type = lib.types.enum [ "unknown" "pre-turing" "turing+" ];
      default = "unknown";
    };
    intelBusId = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };
    gpu2 = lib.mkOption {
      type = lib.types.enum [ "none" "intel" "amd" "nvidia" "virtio" "other" ];
      default = "none";
    };
    gpu2Health = lib.mkOption {
      type = lib.types.enum [ "unknown" "working" "failing" ];
      default = "unknown";
    };
    gpu2BusAddr = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };
    hasBluetooth = lib.mkOption { type = lib.types.bool; default = true; };
    cpuVendor = lib.mkOption {
      type = lib.types.enum [ "unknown" "intel" "amd" ];
      default = "unknown";
    };
    firmware = lib.mkOption {
      type = lib.types.enum [ "uefi" "bios" ];
      default = "uefi";
    };
    broadcomWifi = lib.mkOption { type = lib.types.bool; default = false; };
    chassis = lib.mkOption {
      type = lib.types.enum [ "unknown" "laptop" "desktop" ];
      default = "unknown";
    };
    vmGuest = lib.mkOption {
      type = lib.types.enum [ "none" "qemu" "vmware" "virtualbox" "hyperv" ];
      default = "none";
    };
    fingerprint = lib.mkOption { type = lib.types.bool; default = false; };
    panelDpi = lib.mkOption { type = lib.types.int; default = 0; };
  };
}
