# base/weak — the WEAK tier's boot: what a 4 GB or light-effects machine
# does not pay for at its login. The tier itself is chosen at install time
# (hardware/memory.nix: ramMB; gpu/intel-legacy.nix: effects light); the
# same predicate quiet-login.nix gates heavy work by. Max, 2026-10-30:
# "2 sí" (a lean layer of services for weak machines).
#
# Measured on the 2013 MacBook Air (i5-4250U, SATA SSD cold):
#   firewall.service 1.5 s — the iptables script runs its rules one call
#   at a time; nftables loads the same ruleset in one go (~50 ms). Only
#   when neither Docker nor libvirt is on: both drive iptables themselves
#   and the two backends do not share a table.
# What the tier already does elsewhere: the camera and printing after the
# desktop (quirks/facetimehd, desktop/printing), the 128² icon tiles
# (home: programs.waverunner.smallIcons), updates and gc gated and
# niced (base/quiet-login, store-gc, autoupdate). What it does not touch:
# the disk's probe (~5 s), the unit loading at switch-root (~3 s) and the
# kernel's modules — the hardware's and systemd's.
{ config, lib, ... }:

let
  weak = ((config.golem.hardware.ramMB or 0) > 0 && (config.golem.hardware.ramMB or 0) < 6144)
    || (config.golem.desktop.effects or "full") == "light";
  iptablesUsers = (config.virtualisation.docker.enable or false) || (config.virtualisation.libvirtd.enable or false);
in
{
  networking.nftables.enable = lib.mkDefault (weak && !iptablesUsers);
}
