# The owner's app list, READ AS DATA (18-Nov), never imported as a module.
#
# waverunner-apply turns the list the dock keeps (packages.list) into a
# generated file in the checkout: hosts/target/apps.nix on the modular
# desktop, system/home/waverunner-packages.nix on the old profile. That file
# is the owner's and outside the seal (golem-seal.nix), so whatever is in it
# may have been written by any program running as the owner. Imported as a
# home module it was code in root's builds, and a home module can even rename
# the user its activation runs as (home.username = "root"): the next nightly
# update then ran it as root (checked by evaluation, 18-Nov). Now only lines
# that are one app name, indented, count:
#     "android-studio"        (the generator's shape since 2026-10-02)
#     android-studio          (older lists)
# every other line is ignored, and each name is looked up in nixpkgs, never
# evaluated. The generated file keeps its module shape, so an older Golem
# (going back a version) still reads it.
#
#   path: the generated file (a path in the flake's source), or null.
path:
{ pkgs, lib, ... }:
let
  nameLine = ''[[:space:]]+"?([a-zA-Z0-9][a-zA-Z0-9._-]*)"?[[:space:]]*'';
  wanted = if path == null then [ ] else
    map builtins.head (lib.filter (m: m != null)
      (map (builtins.match nameLine) (lib.splitString "\n" (builtins.readFile path))));
  # LOOKED UP, not referenced: a name nixpkgs does not have (a bad entry, an
  # app a nixpkgs update renamed or removed) is skipped with a warning instead
  # of failing the whole system (ASUS dogfood, 2026-10-02).
  find = n: lib.attrByPath (lib.splitString "." n) null pkgs;
  missing = builtins.filter (n: find n == null) wanted;
in
{
  warnings = map (n: "waverunner: '${n}' is not in nixpkgs (renamed or removed?) — skipped") missing;
  # lowPrio: an app the owner adds must never fail the whole batch by shipping
  # a file Golem already ships; Golem's copy wins the shared paths (mpv,
  # 2026-09-29).
  home.packages = map lib.lowPrio (builtins.filter (p: p != null) (map find wanted));
}
