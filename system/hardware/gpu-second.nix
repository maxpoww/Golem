# The failing-dGPU path (changes.md #17c, decided by Max 2026-09-07, then
# revised by #33 2026-09-08: "that is not possible, the 720m works" — see
# postinstall/postinstall.md). A second GPU that PASSED the boot audit's
# wake test is configured as a usable second GPU (gpu-nvidia.nix for
# nvidia; AMD healthy offload rides the default mesa stack, nothing to
# do). This module is the other verdict: the chip that failed to survive a
# forced suspend/resume during setup.
#
# "Failing" a WAKE TEST is not the same claim as "cannot do work" — the
# ASUS's GF117M throws PRIVRING faults on autosuspend→resume but very
# plausibly renders fine while awake, and only the owner's real desktop
# can judge that. So this module no longer decides the chip's fate at
# install time; it holds a safe default and the post-install ASK
# framework (system/postinstall.nix) lets the owner choose once they can
# actually tell:
#
#   "hold" (the default, and the fallback for any unanswered/unrecognized
#   answer) — keep the chip available but force `power/control=on` so it
#   never autosuspends, and therefore never hits the resume fault that
#   "failing" measured. Usable for offload; never sleeps (a real
#   trade — a little more power, a little more heat — which is exactly
#   why the owner gets the call instead of the installer guessing).
#
#   "off" — the ORIGINAL behaviour: power the chip off entirely and keep
#   it quiet, for an owner who would rather not carry it at all.
#     1. vgaswitcheroo OFF — actually cuts power to the inactive GPU (the
#        right tool on muxless hybrids, where the bound driver
#        half-works).
#     2. PCI remove — takes the device out of sysfs so nothing (lspci -k,
#        desktop probes, power daemons) can runtime-poke it awake again;
#        the HP showed the pokes are what generate the error storm.
#
# An "unknown" health verdict deliberately does NOT land here (ambiguous
# evidence changes nothing — verdict discipline, changes.md #17).
{ config, lib, ... }:

let
  cfg = config.golem.hardware;
  # Any value other than "off" (including one this module has never heard
  # of) falls to "hold" — the safe, reversible branch. Never a default
  # pass to "off": that direction is destructive-ish (PCI remove) and
  # must be an explicit, validated owner choice, never a guess.
  action = if (config.golem.postinstall.answers."gpu2-failing-action" or "hold") == "off"
    then "off"
    else "hold";
  neverBootVga = script: ''
    d=/sys/bus/pci/devices/${cfg.gpu2BusAddr}
    # Never touch the card driving the screen, whatever the facts say.
    if [ -e "$d" ] && [ "$(cat "$d/boot_vga" 2>/dev/null)" = "1" ]; then
      echo "refusing: ${cfg.gpu2BusAddr} is the boot display" >&2
      exit 0
    fi
    ${script}
  '';
in
{
  # Both services are declared UNCONDITIONALLY (as attribute names) and
  # individually mkIf-gated at the LEAF — never an outer `if action == …
  # then {A} else {B}` picking between two whole attrsets. That shape
  # would force `action` (and therefore golem.postinstall.answers, i.e.
  # THIS MODULE'S OWN evaluated config through the shared fixpoint) just
  # to discover this module's config SHAPE, before mkIf's own laziness
  # ever gets a chance to short-circuit it — a real infinite recursion,
  # caught live writing this (golem.postinstall.answers's merge walks
  # every module's config structurally, including this one). Gating each
  # service at its own leaf keeps this module's shape static, so `action`
  # is only ever forced once something actually asks for
  # systemd.services.golem-dgpu-{off,hold} specifically — a question
  # golem.postinstall.answers's own resolution never asks.
  config = lib.mkIf (cfg.gpu2Health == "failing" && cfg.gpu2BusAddr != null) {
    systemd.services.golem-dgpu-off = lib.mkIf (action == "off") {
      description = "Power off the failing second GPU (owner chose: power off — changes.md #33)";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-udev-settle.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = neverBootVga ''
        sw=/sys/kernel/debug/vgaswitcheroo/switch
        if [ -w "$sw" ]; then
          echo OFF > "$sw" 2>/dev/null || true
        fi
        if [ -e "$d" ]; then
          echo 1 > "$d/remove" 2>/dev/null || true
        fi
      '';
    };
    systemd.services.golem-dgpu-hold = lib.mkIf (action != "off") {
      description = "Hold the failing-on-resume second GPU awake but usable (changes.md #33 default — ask post-install)";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-udev-settle.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = neverBootVga ''
        # If a prior "off" answer removed the chip from the bus, a plain
        # existence check silently no-ops and the owner's off→hold
        # re-answer leaves the GPU absent until a reboot (35d, found live
        # on the ASUS 2026-09-09: generation switched, hold active, chip
        # still gone). Rescan first — a no-op when the device is present.
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
