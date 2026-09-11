# gpu2/failing — a SECOND GPU that FAILED the boot audit's wake test
# (changes.md #17c/#33). Chosen when gpu2Health=failing (any vendor —
# the asus's nvidia GF117M, the hp's amd Radeon). Ported verbatim from
# system/hardware/gpu-second.nix (2026-09-10), minus the outer
# gpu2Health mkIf — the chooser owns that decision now.
#
# "Failing a WAKE TEST" is not "cannot do work": the chip may render
# fine while awake and only fault on autosuspend→resume. So this leaf
# holds a SAFE default and the post-install ASK framework lets the owner
# choose once they can judge — the ask fires at graphical login, so on
# stage-0 minimal (no desktop) this simply holds; the ask arrives with
# the desktop stage. Both services are declared unconditionally and
# mkIf-gated at the LEAF (never an outer if/else picking whole attrsets)
# — that shape avoids forcing `action` (and thus golem.postinstall.
# answers, this module's own fixpoint) just to learn its config SHAPE, a
# real infinite recursion caught live writing the original.
{ config, lib, ... }:

let
  cfg = config.golem.hardware;
  # Any answer other than "off" (incl. unrecognized) falls to "hold" —
  # safe and reversible. Never a default pass to "off" (PCI remove is
  # destructive-ish; it must be an explicit validated owner choice).
  action = if (config.golem.postinstall.answers."gpu2-failing-action" or "hold") == "off"
    then "off"
    else "hold";
  neverBootVga = script: ''
    d=/sys/bus/pci/devices/${toString cfg.gpu2BusAddr}
    if [ -e "$d" ] && [ "$(cat "$d/boot_vga" 2>/dev/null)" = "1" ]; then
      echo "refusing: ${toString cfg.gpu2BusAddr} is the boot display" >&2
      exit 0
    fi
    ${script}
  '';
in
{
  # Safety guard on the bus addr (data, not a hardware-choice — the
  # chooser already decided this machine is gpu2Health=failing).
  config = lib.mkIf (cfg.gpu2BusAddr != null) {
    systemd.services.golem-dgpu-off = lib.mkIf (action == "off") {
      description = "Power off the failing second GPU (owner chose: power off — changes.md #33)";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-udev-settle.service" ];
      serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
      script = neverBootVga ''
        sw=/sys/kernel/debug/vgaswitcheroo/switch
        if [ -w "$sw" ]; then echo OFF > "$sw" 2>/dev/null || true; fi
        if [ -e "$d" ]; then echo 1 > "$d/remove" 2>/dev/null || true; fi
      '';
    };
    systemd.services.golem-dgpu-hold = lib.mkIf (action != "off") {
      description = "Hold the failing-on-resume second GPU awake but usable (changes.md #33 default — ask post-install)";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-udev-settle.service" ];
      serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
      script = neverBootVga ''
        # A prior "off" answer removed the chip; rescan so an off→hold
        # re-answer brings it back without a reboot (35d, ASUS 2026-09-09).
        if [ ! -e "$d" ]; then
          echo 1 > /sys/bus/pci/rescan 2>/dev/null || true
          udevadm settle 2>/dev/null || true
        fi
        if [ -e "$d/power/control" ]; then
          echo on > "$d/power/control" 2>/dev/null || true
        fi
      '';
    };
  };
}
