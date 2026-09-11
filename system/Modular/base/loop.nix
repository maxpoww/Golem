# base/loop — the installed-machine self-rebuild wiring, stage 0.
# The minimal twin of hosts/target/default.nix's tail (which wires the
# FAT golem-target): point the seed's checkout and name the attr this
# machine rebuilds itself AS. Without this flakeDir is null →
# selfrebuild.nix emits no rebuild-golem and the machine cannot climb
# stages (finding #62, caught by the VM self-rebuild proof 2026-09-10).
#
# flakeAttr = golem-minimal: the machine reproduces the composition it
# actually runs, not the fat target. Stage 1/2 climbs are rebuilds of
# THIS attr with more leaves in modules.nix, never a different attr.
{ config, lib, ... }:

{
  golem.flakeDir = lib.mkDefault "/home/${config.golem.owner}/Golem";
  golem.flakeAttr = lib.mkDefault "golem-minimal";
}
