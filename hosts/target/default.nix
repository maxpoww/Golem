# The installed-Golem shape — WHAT the installer installs (spec §6).
#
# `nixos-install --flake <seeded-checkout>#standard-target` builds this. The
# machine-specific surface is exactly the files the install flow drops
# into THIS directory of the seeded checkout (the one rule, spec §2 —
# facts in, evaluation out, no assembled configuration prose):
#
#   golem-hardware.nix          the probe's facts (golem-hw-detect -o)
#   hardware-configuration.nix  nixos-generate-config's output: filesystems
#                               (incl. LUKS when chosen), initrd modules,
#                               microcode toggle
#   machine.nix                 the human choices: standard.owner, the GECOS
#                               full name (users.users.<owner>.description),
#                               networking.hostName if not "Standard"
#
# A fourth file, postinstall-questions.json (postinstall/postinstall.md,
# changes.md #33), lands alongside these but is deliberately NOT imported
# here — it is data for golem-postinstall-ask to read on the INSTALLED
# system after first login, not a NixOS module for this eval to consume.
#
# Everything else — compositor, dock, OPTIONS, the hardware module library
# waking on the facts — is the same flake every Standard machine ships. In
# the repo as published none of the three files exist, so flake.nix only
# exposes `standard-target` once a hardware-configuration.nix is present
# (a target without a disk layout cannot evaluate, and `nix flake check`
# on the plain repo must stay green).
{ config, lib, ... }:

let
  dropped = f: lib.optional (builtins.pathExists (./. + "/${f}")) (./. + "/${f}");
in
{
  imports =
    dropped "hardware-configuration.nix"
    ++ dropped "golem-hardware.nix"
    ++ dropped "machine.nix"
    # A lab testbed's flag (system/Modular/lab/lab-door.nix): only lab machines have it.
    ++ dropped "lab.nix";

  # The installed-machine loop: waverunner-apply and rebuild-golem work
  # against the seeded checkout in the owner's home, and the machine
  # rebuilds itself as what it actually runs (hosts/vm.nix is the shape).
  standard.flakeDir = lib.mkDefault "/home/${config.standard.owner}/Golem";
  standard.flakeAttr = "standard-target";
}
