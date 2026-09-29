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

  # Lean image (the ISO) vs a full install. The home layer reads it to drop the
  # owner's launcher-installed app list + dev extras on lean builds. Declared
  # here (was fat-config-only in system/configuration.nix) so the Modular home
  # layer composes into golem-desktop; a real installed desktop leaves it OFF.
  options.golem.lean = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Ship only what the system needs (the ISO turns this on); a full install leaves it off and grows its own list.";
  };

  # Post-install answers (id → chosen option id), set only by the
  # generated system/postinstall-generated.nix. Declared here so the
  # gpu2/failing leaf evaluates on stage-0 minimal (no desktop to ask
  # at) and defaults to its safe branch. The ask/apply pipeline itself
  # (postinstall.nix, asked at graphical login) arrives with the desktop
  # stage. Lifted from system/postinstall.nix.
  options.golem.postinstall.answers = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    internal = true;
    description = "Applied post-install question answers; each consuming leaf keys off its own id, falling back to that question's safe default.";
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
  # How much the desktop's compositing effects may cost. "light" is set by a
  # weak-GPU leaf (gpu/intel-legacy): the home layer then turns Hyprland's
  # blur off. Measured on the 2013 MacBook Air (HD 5000), 2026-09-29: during
  # YouTube playback the 3D engine sat at 98% busy and the video stuttered;
  # blur off freed 13-17 points. Shadows, dimming and rounding cost nothing
  # measurable, so they stay. Every other machine keeps "full".
  options.golem.desktop.effects = lib.mkOption {
    type = lib.types.enum [ "full" "light" ];
    default = "full";
    description = "Desktop effect budget: full, or light for weak GPUs (no compositor blur).";
  };

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
    hasFacetimeHD = lib.mkOption { type = lib.types.bool; default = false; };
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
