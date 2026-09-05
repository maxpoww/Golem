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
    (row "zram"
      (if cfg.zramSwap.enable
      then "${toString cfg.zramSwap.memoryPercent}% of ram, ${cfg.zramSwap.algorithm}, priority ${toString cfg.zramSwap.priority}"
      else "off"))
    (row "swappiness" (toString sysctl."vm.swappiness"))
    (row "cache pressure" (toString sysctl."vm.vfs_cache_pressure"))
    (row "dirty ratio" "${toString sysctl."vm.dirty_ratio"}% / ${toString sysctl."vm.dirty_background_ratio"}% background")
    (row "page cluster" (toString (sysctl."vm.page-cluster" or 3)))
    (row "swap" "${toString (swapMB / 1024)} GiB, for hibernation")
    (row "resume" (if cfg.boot.resumeDevice == "" then "none" else cfg.boot.resumeDevice))
  ])

  (section "gpu" ([
    (row "detected" facts.gpu)
    (row "driver" (lib.concatStringsSep ", " cfg.services.xserver.videoDrivers))
    (row "video decode" (cfg.environment.sessionVariables.LIBVA_DRIVER_NAME or "none"))
  ] ++ lib.optionals (facts.gpu == "nvidia") [
    (row "generation" facts.nvidiaGen)
    (row "kernel module" (if nv.open == true then "open" else "proprietary"))
    (row "prime offload"
      (if nv.prime.offload.enable
      then "on, nvidia ${toString nv.prime.nvidiaBusId} / intel ${toString nv.prime.intelBusId}"
      else "off"))
    (row "suspend fix" (onoff nv.powerManagement.enable))
  ]))

  (section "disk" [
    (row "scheduler" (if lib.elem "bfq" cfg.boot.kernelModules
      then "bfq on rotational disks" else "kernel default"))
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
    (row "thermald" (onoff cfg.services.thermald.enable))
    (row "lid" (cfg.services.logind.settings.Login.HandleLidSwitch or "systemd default"))
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
