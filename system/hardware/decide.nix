# The decision surface — what Golem CHOOSES for a machine, as data.
#
# GolemInstall.md §8's second proof leg. The matrix (matrix.nix) asks
# "given these facts, does the config still assert correctly?" and answers
# in CI. This file asks the same question the other way round — "given
# THIS machine, what exactly did Golem decide?" — and answers on the
# machine itself, over SSH, before anything is written to a disk.
#
# Both go through lib.golem.mkTarget, so the composition audited here is
# byte-for-byte the one `nixos-install --flake …#golem-target` builds.
# A decision that reads right here and wrong after install would mean the
# two diverged; they cannot, because there is only one mkTarget.
#
#   golem-hw-decide            # human table
#   golem-hw-decide --json     # the same, machine-readable
#
# THE OUTPUT IS AN ORDERED LIST, not an attrset (Max, 2026-09-05: "i want
# to see cpu at the top, then RAM and then the GPU"). Nix attrsets sort
# alphabetically on the way to JSON, which is why the first version of
# this report opened with BIOMETRICS. A list of sections keeps the order
# the reader wants, and keeps the renderer dumb: it prints what it is
# given, so adding a row here needs no renderer change.
#
# Measurement and decision are shown TOGETHER per subsystem — "the radio
# is there, so the stack is on" reads as one thought, where a facts block
# followed by a decisions block makes the reader join them by hand.
#
# LAZINESS IS LOAD-BEARING. Every field is a separate thunk, and the panel
# scale is the only one that forces the home-manager user fixpoint
# (seconds vs. tens of seconds on a 4 GB lab machine). It is therefore
# gated on panelDpi actually being detected — a machine with no internal
# panel never pays for it. Do not "simplify" that guard away.
{ lib, mkTarget, swapForHibernationMB }:

# factsModule: the probe's golem-hardware.nix, imported (or an attrset).
factsModule:

let
  # What the install flow WILL create. Hibernation is locked (memory.nix
  # header), so a swap device is part of every plan and the preview must
  # include it or it would under-report resume + lid policy.
  plannedDisk = {
    nixpkgs.hostPlatform = "x86_64-linux";
    fileSystems."/" = { device = "/dev/disk/by-label/golem"; fsType = "ext4"; };
    fileSystems."/boot" = { device = "/dev/disk/by-label/ESP"; fsType = "vfat"; };
    swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];
  };

  cfg = (mkTarget [ plannedDisk factsModule ]).config;

  # Read the facts back off the evaluated config rather than re-evaluating
  # the module on its own: same fixpoint, so this is free, and it reports
  # the DEFAULTED values (what actually drove the modules) instead of only
  # the keys the probe happened to emit.
  facts = cfg.golem.hardware;
  swapMB = swapForHibernationMB facts.ramMB;

  sysctl = cfg.boot.kernel.sysctl;
  nv = cfg.hardware.nvidia;

  # Presentation helpers. Booleans are rendered as words because this is
  # read by a person auditing a laptop, not parsed by a machine — the
  # JSON is right there for that.
  yesno = b: if b then "yes" else "no";
  onoff = b: if b then "on" else "off";
  row = k: v: { inherit k v; };
  # A row the installer SURFACE shows to a stranger carries, alongside the
  # English v, a stable key + args so the surface can render the value in
  # the chosen language (changes.md #18e — v is composed here at audit
  # time, before any language exists, so translating v itself is
  # impossible). Consumers that only read k/v are unchanged; an empty key
  # means "no translation, show v".
  rowT = k: key: args: v: { inherit k key args v; };
  section = name: rows: { inherit name; rows = lib.filter (r: r != null) rows; };
  when = c: r: if c then r else null;

  panelScale =
    let
      lua = cfg.home-manager.users.${cfg.golem.owner}.xdg.configFile."hypr/hyprland.lua".text;
      m = builtins.match ".*output = \"eDP-1\".*scale = ([0-9.]+).*" lua;
    in
    if m == null then "none (normal density)" else lib.head m;
in
# `when` drops whole sections that do not apply to this machine (no
# panel, not a VM, no reader) rather than printing them empty.
lib.filter (s: s != null) [
  (section "cpu" [
    (row "model" facts.cpuModel)
    (row "vendor" facts.cpuVendor)
    (row "cores" (toString facts.cores))
    (row "threads" (toString facts.threads))
    (row "microcode"
      (if cfg.hardware.cpu.intel.updateMicrocode then "intel"
      else if cfg.hardware.cpu.amd.updateMicrocode then "amd"
      else "none"))
  ])

  (section "ram" [
    (row "total" "${toString facts.ramMB} MB")
    (rowT "zram"
      (if cfg.zramSwap.enable then "zram" else "off")
      (lib.optionals cfg.zramSwap.enable
        [ cfg.zramSwap.algorithm (toString cfg.zramSwap.priority) ])
      (if cfg.zramSwap.enable
      # Just "active" — no percentage, no size (Max, round 2). Any number
      # here is misread: "50% of 8 GB" reads as "am I losing half my RAM?"
      # or "do they only see half of it?", and the device can exceed RAM on
      # small machines (zram is compressed) which looks impossible. A number
      # a stranger will misread is worse than no number.
      then "active, ${cfg.zramSwap.algorithm}, priority ${toString cfg.zramSwap.priority}"
      else "off"))
    (row "swappiness" (toString sysctl."vm.swappiness"))
    (row "cache pressure" (toString sysctl."vm.vfs_cache_pressure"))
    (row "dirty ratio" "${toString sysctl."vm.dirty_ratio"}% / ${toString sysctl."vm.dirty_background_ratio"}% background")
    (row "page cluster" (toString (sysctl."vm.page-cluster" or 3)))
    (rowT "swap" "swap_hib" [ (toString (swapMB / 1024)) ]
      "${toString (swapMB / 1024)} GiB, for hibernation")
    (row "resume" (if cfg.boot.resumeDevice == "" then "none" else cfg.boot.resumeDevice))
  ])

  (section "gpu" ([
    (row "detected" facts.gpu)
    (row "driver" (lib.concatStringsSep ", " cfg.services.xserver.videoDrivers))
    # Not only the Intel driver names: mesa's radeonsi VA driver rides the
    # default stack for AMD and the proprietary driver brings NVDEC — the
    # old `or "none"` told an AMD owner they get no decode (#11, HP).
    (row "video decode"
      (cfg.environment.sessionVariables.LIBVA_DRIVER_NAME
        or (if facts.gpu == "amd" then "vaapi, mesa radeonsi"
            # NVDEC comes from the proprietary driver — on the iron-law
            # floor (unknown generation, driver inactive) there is none.
            else if facts.gpu == "nvidia"
                    && lib.elem "nvidia" cfg.services.xserver.videoDrivers
                 then "nvdec, nvidia"
            else "none")))
  ] ++ lib.optionals (facts.gpu2 != "none") [
    # The hybrid's second GPU: named with its health verdict, so the audit
    # table tells the same story the reveal does (#17b/c). "unknown" is
    # the deliberate gray zone — conservative config, no claim either way.
    (row "gpu 2" facts.gpu2)
    (row "gpu 2 health" facts.gpu2Health)
    (when (facts.gpu2Health == "failing") (row "gpu 2 action" "powered off, kept quiet"))
  ] ++ lib.optionals (facts.gpu == "nvidia" || facts.gpu2 == "nvidia") (
    [ (row "generation" facts.nvidiaGen) ]
    ++ (if lib.elem "nvidia" cfg.services.xserver.videoDrivers then [
      (row "kernel module" (if nv.open == true then "open" else "proprietary"))
      (row "prime offload"
        (if nv.prime.offload.enable
        then "on, nvidia ${toString nv.prime.nvidiaBusId} / intel ${toString nv.prime.intelBusId}"
        else "off"))
      (row "suspend fix" (onoff nv.powerManagement.enable))
    ] else [
      # The iron law's row. When the driver is NOT active (unknown
      # generation, or an unhealthy dGPU), hardware.nvidia.* must not
      # even be READ: with nvidia absent from videoDrivers the upstream
      # module's internal package is null and evaluating options like
      # `open` crashes the whole surface — the audit's first decide
      # failure on metal (ASUS X550LC GF117M, round 2, changes.md #22).
      (row "kernel module" "none — open floor (modesetting/nouveau)")
    ]))))

  (section "disk" [
    (rowT "scheduler"
      (if lib.elem "bfq" cfg.boot.kernelModules then "bfq" else "kernel_default") [ ]
      (if lib.elem "bfq" cfg.boot.kernelModules
      # R3-4: state the whole policy, not just half of it — the udev rule
      # (storage.nix) applies bfq ONLY to rotational disks and leaves
      # SSD/NVMe on their default, so "bfq on rotational disks" read as
      # vacuous on the NVMe-only Lenovo. This is deliberately fact-free
      # (no per-target gating), so the row describes the rule completely.
      then "bfq on hard disks, default on SSD/NVMe" else "kernel default"))
    (row "trim" (if cfg.services.fstrim.enable then "weekly" else "off"))
  ])

  (section "bluetooth" [
    (row "radio" (yesno facts.hasBluetooth))
    (row "stack" (if cfg.hardware.bluetooth.enable then "bluez, blueman" else "not installed"))
  ])

  (section "power" [
    (row "chassis" facts.chassis)
    (row "battery daemon" (onoff cfg.services.upower.enable))
    (row "power profiles" (onoff cfg.services.power-profiles-daemon.enable))
    (rowT "thermald" (onoff cfg.services.thermald.enable) [ ]
      (onoff cfg.services.thermald.enable))
    (rowT "lid"
      (if (cfg.services.logind.settings.Login.HandleLidSwitch or "") == "suspend-then-hibernate"
       then "lid_sth" else "") [ ]
      (cfg.services.logind.settings.Login.HandleLidSwitch or "systemd default"))
    (row "hibernate after" (cfg.systemd.sleep.settings.Sleep.HibernateDelaySec or "systemd default"))
  ])

  # Gated: forcing the scale evaluates the whole home-manager user config.
  (when (facts.panelDpi > 0) (section "panel" [
    (row "dpi" (toString facts.panelDpi))
    (row "scale" panelScale)
  ]))

  (when (facts.vmGuest != "none") (section "virtual machine" [
    (row "host" facts.vmGuest)
    (row "guest agent" (onoff cfg.services.qemuGuest.enable))
    (row "clipboard agent" (onoff cfg.services.spice-vdagentd.enable))
  ]))

  (when facts.fingerprint (section "fingerprint" [
    (row "reader" "yes")
    (row "fprintd" (onoff cfg.services.fprintd.enable))
  ]))

  (section "builds" [
    (row "parallel builds" (toString cfg.nix.settings.max-jobs))
    (row "cores per build" (toString cfg.nix.settings.cores))
  ])
]
