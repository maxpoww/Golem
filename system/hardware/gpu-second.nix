# The failing-dGPU path (changes.md #17c, decided by Max 2026-09-07):
# health-gated, not blanket — "we can not have Golem leaving all dedicated
# GPUs out." A second GPU that PASSED the boot audit's wake test is
# configured as a usable second GPU (gpu-nvidia.nix for nvidia; AMD healthy
# offload rides the default mesa stack, nothing to do). This module is the
# other verdict: the chip that provably cannot wake (the HP dm4's Evergreen
# — every runtime resume fails, spamming the console and burning battery on
# wake attempts) is POWERED OFF and kept quiet.
#
# Two layers, best effort, never the boot_vga card:
#   1. vgaswitcheroo OFF — actually cuts power to the inactive GPU (the
#      right tool on muxless hybrids, where the bound driver half-works).
#   2. PCI remove — takes the device out of sysfs so nothing (lspci -k,
#      desktop probes, power daemons) can runtime-poke it awake again;
#      the HP showed the pokes are what generate the error storm.
#
# An "unknown" health verdict deliberately does NOT land here (ambiguous
# evidence changes nothing — verdict discipline, changes.md #17).
{ config, lib, ... }:

let
  cfg = config.golem.hardware;
in
{
  config = lib.mkIf (cfg.gpu2Health == "failing" && cfg.gpu2BusAddr != null) {
    systemd.services.golem-dgpu-off = {
      description = "Power off the failing second GPU (census verdict: didn't wake up)";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-udev-settle.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        d=/sys/bus/pci/devices/${cfg.gpu2BusAddr}
        # Never touch the card driving the screen, whatever the facts say.
        if [ -e "$d" ] && [ "$(cat "$d/boot_vga" 2>/dev/null)" = "1" ]; then
          echo "refusing: ${cfg.gpu2BusAddr} is the boot display" >&2
          exit 0
        fi
        sw=/sys/kernel/debug/vgaswitcheroo/switch
        if [ -w "$sw" ]; then
          echo OFF > "$sw" 2>/dev/null || true
        fi
        if [ -e "$d" ]; then
          echo 1 > "$d/remove" 2>/dev/null || true
        fi
      '';
    };
  };
}
