# The eval matrix — GolemInstall.md §8's first proof leg, and the replay
# harness Installer/preinstall/PLAN.md promised ("the laptops teach once; the repo
# remembers forever").
#
# Every gated fact permutation is evaluated as a FULL golem-target system
# (the exact composition `nixos-install --flake …#golem-target` builds —
# golemModules + hosts/target + a fake disk), and semantic expectations
# are asserted on the evaluated config: not just "it evaluates" but "the
# no-bluetooth machine really dropped bluez", "the unknown nvidia really
# stayed off the proprietary driver". The committed lab fixtures' facts
# files are permutations too, so a probe or module change that would
# regress a past machine fails CI in seconds, no hardware involved.
#
#   nix build .#checks.x86_64-linux.facts-matrix
#
# Cost note: each row is a complete NixOS+home-manager eval — the matrix
# is minutes of CPU, not seconds. That is the price of evaluating what we
# actually ship; keep rows meaningful (anti-over-gating rule, §5: every
# gate added is a test permutation owed — this file is where the debt is
# paid).
{ lib, pkgs, mkTarget, keyboards }:

let
  # What nixos-generate-config provides on a real machine — the minimum a
  # bootable system needs so the eval can reach a toplevel.
  fakeDisk = {
    nixpkgs.hostPlatform = "x86_64-linux";
    fileSystems."/" = { device = "/dev/disk/by-label/golem"; fsType = "ext4"; };
    fileSystems."/boot" = { device = "/dev/disk/by-label/ESP"; fsType = "vfat"; };
  };

  # One row: a facts module (an attrset or an imported fixture facts.nix)
  # plus expectations on the evaluated config.
  rows = [
    {
      name = "floor"; # no detection ran: everything at safe defaults
      facts = { };
      expect = cfg: [
        (ex "bluetooth stays on (conservatism)" cfg.services.blueman.enable)
        (ex "no nvidia driver" (!(lib.elem "nvidia" cfg.services.xserver.videoDrivers)))
        (ex "no laptop power stack" (!cfg.services.power-profiles-daemon.enable))
        (ex "historical memory policy (sw 10 / vcp 10)"
          (cfg.boot.kernel.sysctl."vm.swappiness" == 10
           && cfg.boot.kernel.sysctl."vm.vfs_cache_pressure" == 10))
        (ex "no swap → no resume device" (cfg.boot.resumeDevice == ""))
        (ex "fstrim always on" cfg.services.fstrim.enable)
        (ex "fwupd always on" cfg.services.fwupd.enable)
        (ex "no reader → no fprintd" (!cfg.services.fprintd.enable))
        (ex "no hypervisor → no guest tools" (!cfg.services.qemuGuest.enable))
      ];
    }
    {
      name = "fixture-acer-e5-573"; # lab row 1, as detected on the metal
      facts = ../../Installer/preinstall/fixtures/acer-aspire-e5-573/facts.nix;
      expect = cfg: [
        (ex "Broadwell picks iHD" (cfg.environment.sessionVariables.LIBVA_DRIVER_NAME or "" == "iHD"))
        (ex "4GB tier: zram 150%" (cfg.zramSwap.memoryPercent == 150))
        (ex "4GB tier: zram-first swappiness 180" (cfg.boot.kernel.sysctl."vm.swappiness" == 180))
        (ex "4GB tier: small writeback bursts" (cfg.boot.kernel.sysctl."vm.dirty_ratio" == 5))
        (ex "zram present: page-cluster 0" (cfg.boot.kernel.sysctl."vm.page-cluster" == 0))
        (ex "intel microcode on" cfg.hardware.cpu.intel.updateMicrocode)
        (ex "bluetooth stack on" cfg.services.blueman.enable)
        (ex "laptop power stack on" cfg.services.power-profiles-daemon.enable)
        (ex "intel laptop: thermald on" cfg.services.thermald.enable)
        (ex "4GB tier: one build job" (cfg.nix.settings.max-jobs == 1))
        (ex "102 DPI panel: NO generated scale rule (the 2026-09-02 lesson)"
          (!lib.hasInfix ''output = "eDP-1"''
            cfg.home-manager.users.${cfg.golem.owner}.xdg.configFile."hypr/hyprland.lua".text))
      ];
    }
    {
      name = "fixture-qemu-virtio"; # lab row 0
      facts = ../../Installer/preinstall/fixtures/qemu-virtio/facts.nix;
      expect = cfg: [
        (ex "confident no-radio drops bluez" (!cfg.services.blueman.enable && !cfg.hardware.bluetooth.enable))
        (ex "unknown chassis: no laptop stack" (!cfg.services.power-profiles-daemon.enable))
        (ex "no nvidia driver" (!(lib.elem "nvidia" cfg.services.xserver.videoDrivers)))
      ];
    }
    {
      name = "intel-legacy"; # the 2013-Air class (Haswell and older)
      facts.golem.hardware = { gpu = "intel"; intelLegacy = true; ramMB = 4096; cores = 4; cpuVendor = "intel"; chassis = "laptop"; };
      expect = cfg: [
        (ex "legacy picks i965" (cfg.environment.sessionVariables.LIBVA_DRIVER_NAME or "" == "i965"))
        (ex "H.264 fallback policy shipped"
          (lib.hasAttr "opt/chrome/policies/managed/golem-legacy-video.json" cfg.environment.etc))
      ];
    }
    {
      name = "amd";
      facts.golem.hardware = { gpu = "amd"; ramMB = 16384; cores = 12; cpuVendor = "amd"; chassis = "desktop"; };
      expect = cfg: [
        (ex "amd microcode on" cfg.hardware.cpu.amd.updateMicrocode)
        (ex "mid tier: zram 50%" (cfg.zramSwap.memoryPercent == 50))
        (ex "mid tier: swappiness 60" (cfg.boot.kernel.sysctl."vm.swappiness" == 60))
        (ex "amd desktop: no thermald" (!cfg.services.thermald.enable))
      ];
    }
    {
      name = "nvidia-hybrid-ada"; # the Slim Pro 9i shape, from detection
      facts = {
        golem.hardware = {
          gpu = "nvidia"; nvidiaGen = "turing+";
          nvidiaBusId = "PCI:1:0:0"; intelBusId = "PCI:0:2:0";
          ramMB = 32768; cores = 20; cpuVendor = "intel"; chassis = "laptop";
        };
        # What the install flow creates on every machine (hibernation is
        # locked): disk swap, sized by lib.golem.swapForHibernationMB.
        swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];
      };
      expect = cfg: [
        (ex "nvidia driver active" (lib.elem "nvidia" cfg.services.xserver.videoDrivers))
        (ex "open kmod on Ada" (cfg.hardware.nvidia.open == true))
        (ex "THE suspend fix present" cfg.hardware.nvidia.powerManagement.enable)
        (ex "PRIME offload with detected ids"
          (cfg.hardware.nvidia.prime.offload.enable
           && cfg.hardware.nvidia.prime.nvidiaBusId == "PCI:1:0:0"))
        (ex "32GB tier: zram 25%" (cfg.zramSwap.memoryPercent == 25))
        (ex "32GB tier: swappiness 10" (cfg.boot.kernel.sysctl."vm.swappiness" == 10))
        (ex "resume wired to the swap device"
          (cfg.boot.resumeDevice == "/dev/disk/by-label/swap"))
        (ex "laptop + swap: lid suspends-then-hibernates"
          (cfg.services.logind.settings.Login.HandleLidSwitch == "suspend-then-hibernate"))
      ];
    }
    {
      name = "nvidia-desktop-ada"; # no iGPU → direct drive, no PRIME
      facts.golem.hardware = { gpu = "nvidia"; nvidiaGen = "turing+"; ramMB = 32768; cores = 16; cpuVendor = "amd"; chassis = "desktop"; };
      expect = cfg: [
        (ex "nvidia driver active" (lib.elem "nvidia" cfg.services.xserver.videoDrivers))
        (ex "no PRIME without both bus ids" (!cfg.hardware.nvidia.prime.offload.enable))
      ];
    }
    {
      name = "nvidia-pre-turing"; # GTX 9xx/10xx: the 580 legacy branch
      facts.golem.hardware = { gpu = "nvidia"; nvidiaGen = "pre-turing"; ramMB = 8192; cores = 8; cpuVendor = "intel"; chassis = "desktop"; };
      expect = cfg: [
        (ex "nvidia driver active" (lib.elem "nvidia" cfg.services.xserver.videoDrivers))
        (ex "proprietary kmod (open is Turing+)" (cfg.hardware.nvidia.open == false))
        (ex "580 legacy branch" (lib.hasPrefix "580." cfg.hardware.nvidia.package.version))
      ];
    }
    {
      name = "nvidia-unknown-gen"; # THE IRON LAW: uncertain → the floor
      facts.golem.hardware = { gpu = "nvidia"; ramMB = 8192; cores = 8; };
      expect = cfg: [
        (ex "unclassified nvidia stays on the floor"
          (!(lib.elem "nvidia" cfg.services.xserver.videoDrivers)))
      ];
    }
    {
      name = "gpu2-failing-default-hold"; # changes.md #33: the ASUS shape, unanswered
      facts.golem.hardware = {
        gpu = "intel"; intelBusId = "PCI:0:2:0";
        gpu2 = "nvidia"; gpu2BusAddr = "0000:01:00.0"; gpu2Health = "failing";
      };
      expect = cfg: [
        (ex "held, not powered off, until the owner answers"
          (cfg.systemd.services ? golem-dgpu-hold && !(cfg.systemd.services ? golem-dgpu-off)))
      ];
    }
    {
      name = "gpu2-failing-answered-off"; # the owner answered the post-install question
      facts = {
        golem.hardware = {
          gpu = "intel"; intelBusId = "PCI:0:2:0";
          gpu2 = "nvidia"; gpu2BusAddr = "0000:01:00.0"; gpu2Health = "failing";
        };
        golem.postinstall.answers."gpu2-failing-action" = "off";
      };
      expect = cfg: [
        (ex "off wins once explicitly chosen"
          (cfg.systemd.services ? golem-dgpu-off && !(cfg.systemd.services ? golem-dgpu-hold)))
      ];
    }
    {
      name = "gpu2-failing-unrecognized-answer"; # never a default pass to the destructive branch
      facts = {
        golem.hardware = {
          gpu = "intel"; intelBusId = "PCI:0:2:0";
          gpu2 = "nvidia"; gpu2BusAddr = "0000:01:00.0"; gpu2Health = "failing";
        };
        # A stale id from an older question set, or hand-edited garbage —
        # either way this must NOT read as "off" (that branch is a PCI
        # remove; "hold" is the only safe interpretation of "not sure").
        golem.postinstall.answers."gpu2-failing-action" = "garbage";
      };
      expect = cfg: [
        (ex "unrecognized answer falls back to hold, never off"
          (cfg.systemd.services ? golem-dgpu-hold && !(cfg.systemd.services ? golem-dgpu-off)))
      ];
    }
    {
      name = "no-bluetooth";
      facts.golem.hardware = { hasBluetooth = false; };
      expect = cfg: [
        (ex "bluez and blueman dropped" (!cfg.services.blueman.enable && !cfg.hardware.bluetooth.enable))
      ];
    }
    {
      # The qemu fixture caught up on 2026-09-04 (regenerated as root from
      # a live MiniGolem boot, which is where vmGuest first got measured
      # rather than assumed). This row stays as the SYNTHETIC guest-tools
      # permutation — round ramMB, no chassis — so the assertions below
      # keep holding even when the lab's VM is retired or re-specced.
      name = "vm-qemu";
      facts.golem.hardware = { gpu = "virtio"; vmGuest = "qemu"; ramMB = 4096; cores = 4; };
      expect = cfg: [
        (ex "qemu guest agent on" cfg.services.qemuGuest.enable)
        (ex "spice agent on" cfg.services.spice-vdagentd.enable)
        (ex "no vmware tools" (!cfg.virtualisation.vmware.guest.enable))
      ];
    }
    {
      name = "fingerprint-reader";
      facts.golem.hardware = { fingerprint = true; chassis = "laptop"; };
      expect = cfg: [
        (ex "fprintd on" cfg.services.fprintd.enable)
      ];
    }
    {
      name = "hidpi-panel"; # 239 = the Slim Pro's probe-measured DPI (34cm/3200px)
      facts.golem.hardware = { gpu = "intel"; panelDpi = 239; chassis = "laptop"; ramMB = 16384; cores = 8; };
      expect = cfg:
        let lua = cfg.home-manager.users.${cfg.golem.owner}.xdg.configFile."hypr/hyprland.lua".text;
        in [
          (ex "generated eDP scale rule at 1.6"
            (lib.hasInfix ''output = "eDP-1", mode = "preferred", position = "auto", scale = 1.6'' lua))
        ];
    }

    # ── The installer's answers, all the way to the files ───────────────
    #
    # THESE ROWS EXIST BECAUSE THE LAB HAS NO SCREEN. The five laptops boot
    # MiniGolem on a bare console and are driven over SSH, so "did the
    # keyboard come out right" can never be answered by looking at a
    # session. It has to be answered by READING WHAT WAS WRITTEN — and if
    # that is worth doing on the metal it is worth doing in CI, where it
    # costs seconds and covers every layout instead of the one in the room.
    #
    # The rows call keyboards.derive rather than restating its output, so a
    # table edit, a derivation change and a module change are all proven by
    # the same assertion. Nothing here is hand-copied.
    #
    # THE HYPRLAND ASSERTION IS THE POINT. Hyprland does not read
    # services.xserver.xkb — it has its own input block, so the NixOS
    # options can be perfectly right while the actual desktop stays on us.
    # That was the real bug this whole thread found, and it is invisible to
    # any check that only looks at NixOS options.
    {
      name = "install-answer-colemak"; # a variant layout, single group
      facts = { golem.keyboard = keyboards.derive "colemak"; };
      expect = cfg:
        let lua = cfg.home-manager.users.${cfg.golem.owner}.xdg.configFile."hypr/hyprland.lua".text;
        in [
          (ex "console keymap is kbd's name, not xkb's"
            (cfg.console.keyMap == "colemak"))
          (ex "xkb layout us + variant colemak"
            (cfg.services.xserver.xkb.layout == "us"
             && cfg.services.xserver.xkb.variant == "colemak"))
          (ex "no second group, so no toggle" (cfg.services.xserver.xkb.options == ""))
          (ex "latin script keeps the default console font" (cfg.console.font == null))
          (ex "HYPRLAND carries the variant (it does not read xkb.*)"
            (lib.hasInfix ''kb_variant = "colemak"'' lua))
          (ex "HYPRLAND is not left on the dev-checkout literal"
            (!lib.hasInfix ''kb_layout  = "us",
        kb_variant = "",'' lua))
        ];
    }
    {
      name = "install-answer-russian"; # non-latin: the second group + font
      facts = { golem.keyboard = keyboards.derive "ru"; };
      expect = cfg:
        let lua = cfg.home-manager.users.${cfg.golem.owner}.xdg.configFile."hypr/hyprland.lua".text;
            xkb = cfg.services.xserver.xkb;
        in [
          (ex "a latin group is appended, or the owner cannot type a URL"
            (xkb.layout == "ru,us"))
          (ex "variant has a slot per group (xkb reads them positionally)"
            (xkb.variant == ","))
          (ex "and a way to switch between them" (xkb.options == "grp:alt_shift_toggle"))
          (ex "cyrillic console gets a font that can draw it"
            (cfg.console.font == "LatArCyrHeb-16"))
          (ex "ISO board is pc105, not the pc104 default" (xkb.model == "pc105"))
          (ex "HYPRLAND carries both groups" (lib.hasInfix ''kb_layout  = "ru,us"'' lua))
          (ex "HYPRLAND carries the toggle"
            (lib.hasInfix ''kb_options = "grp:alt_shift_toggle"'' lua))
        ];
    }
    {
      name = "install-answer-japanese"; # the physical-board case
      facts = { golem.keyboard = keyboards.derive "jp"; };
      expect = cfg: [
        (ex "JIS model, or henkan/muhenkan have no keycodes"
          (cfg.services.xserver.xkb.model == "jp106"))
        (ex "console keymap jp106, not the xkb name jp"
          (cfg.console.keyMap == "jp106"))
        (ex "latin-capable layout gets NO pointless second group"
          (cfg.services.xserver.xkb.layout == "jp"))
      ];
    }
    {
      name = "install-answer-language"; # step 1's answer, and what it must NOT leak
      facts = { golem.locale.defaultLocale = "es_ES.UTF-8"; };
      expect = cfg: [
        (ex "the chosen language is the default locale"
          (cfg.i18n.defaultLocale == "es_ES.UTF-8"))
        (ex "and is actually GENERATED (ungenerated silently falls back to C)"
          (lib.elem "es_ES.UTF-8/UTF-8" cfg.i18n.supportedLocales))
        (ex "en_US stays for rescue shells and error messages"
          (lib.elem "en_US.UTF-8/UTF-8" cfg.i18n.supportedLocales))
        # The regression guard for 2026-09-05: one owner's LC_* and clock
        # were in system/configuration.nix, so every stranger got Bolivian
        # formats and a La Paz clock whatever they chose.
        (ex "NO owner's formats leak into a stranger's install"
          (cfg.i18n.extraLocaleSettings == { }))
        (ex "NO owner's timezone leaks either" (cfg.time.timeZone == "UTC"))
      ];
    }
  ];

  ex = name: ok: { inherit name ok; };

  runRow = row:
    let
      factsModule =
        if builtins.isPath row.facts then import row.facts else row.facts;
      cfg = (mkTarget [ fakeDisk factsModule ]).config;
      failed = builtins.filter (e: !e.ok) (row.expect cfg);
    in
    if failed == [ ] then
      # Discarding the context keeps this EVAL-only: the drv is
      # instantiated (the whole config must be buildable-shaped) but the
      # matrix never builds ten systems.
      "${row.name} ${builtins.unsafeDiscardStringContext cfg.system.build.toplevel.drvPath}"
    else
      throw "facts-matrix row '${row.name}' failed: ${
        lib.concatMapStringsSep "; " (e: e.name) failed}";

  report = map runRow rows;
in
pkgs.runCommand "golem-facts-matrix"
  { passAsFile = [ "report" ]; report = lib.concatStringsSep "\n" report; }
  ''
    cp "$reportPath" $out
    echo "facts-matrix: ${toString (builtins.length rows)} permutations evaluated" >&2
  ''
