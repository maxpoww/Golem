# updates/gate — every Golem system a version must BUILD before the lane
# publishes it, and whose pieces then go into its cache.
#
# The baked matrix is already the right set: one full desktop per hardware
# class Golem knows (each lab fixture in both firmwares, plus the generic
# floor), exactly what an install copies. Added here: the two synthetic
# nvidia desktops, so the open (Turing+) and legacy (pre-Turing) nvidia
# drivers are built against every new kernel too. They are what broke when
# kernel 7.2 dropped strncpy (2026-10-27) and nothing else would have
# noticed: no lab machine has an nvidia card driving its screen.
#
# Evaluating proves the configuration composes; BUILDING proves the kernel,
# the out-of-tree drivers and the initrd go together. The lane builds this
# plus the flake's checks (README.md, "The gate").
{ pkgs, bakedUnique, mkBakedEntry, synthetic }:

let
  syntheticEntries = map (f: mkBakedEntry {
    name = "${f.name}-uefi-en_US.UTF-8";
    firmware = "uefi";
    isFloor = false;
    facts = (import f.path { }).golem.hardware // { firmware = "uefi"; };
    locale = "en_US.UTF-8";
  }) synthetic;
in
pkgs.linkFarm "golem-update-gate"
  (map (e: { inherit (e) name; path = e.toplevel; }) (bakedUnique ++ syntheticEntries))
