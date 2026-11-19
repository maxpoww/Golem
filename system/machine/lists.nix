# THE MACHINE'S LISTS, READ AS DATA (docs/system/Layout.md, "one door").
#
# /etc/nixos/machine/*.list are written by Golem's tools — the dock's app
# installer, the Modules page — through one root helper. They are the only
# way a choice made in the session reaches the system, so they are never Nix:
# a list is read as text, every line must be ONE name, and every name is
# looked up, never evaluated. Whatever a program manages to write there, the
# worst it gets is an app from nixpkgs installed for the owner.
#
#   # a comment
#   brave
#   kdePackages.kdenlive      (dots: a path inside nixpkgs)
#
# The same rule system/home/app-list.nix applies to the old layout's generated
# apps.nix; this is its plain-list twin.
{ lib }:

rec {
  # One name: letters, digits, and . _ - after the first character.
  nameLine = ''[[:space:]]*([a-zA-Z0-9_][a-zA-Z0-9._-]*)[[:space:]]*(#.*)?'';
  blankLine = ''[[:space:]]*(#.*)?'';

  # path → { names = [ … ]; refused = [ "line as written" … ]; }
  read = path:
    let
      lines = if path == null then [ ] else lib.splitString "\n" (builtins.readFile path);
      parsed = map (l: { line = l; m = builtins.match nameLine l; }) lines;
    in
    {
      names = lib.unique (map (p: builtins.head p.m) (lib.filter (p: p.m != null) parsed));
      refused = map (p: p.line)
        (lib.filter (p: p.m == null && builtins.match blankLine p.line == null) parsed);
    };

  # The apps list as a home-manager module: each name looked up in nixpkgs;
  # one nixpkgs does not have (renamed, removed, a typo) is skipped with a
  # warning instead of failing the whole system. lowPrio: an app the owner
  # adds never fails the batch by shipping a file Golem already ships.
  appsModule = path: { pkgs, lib, ... }:
    let
      list = read path;
      find = n: lib.attrByPath (lib.splitString "." n) null pkgs;
      # (A name that is there but is not a package — `lib`, `stdenv.cc` — is
      # no app either.)
      pkg = n: let p = find n; in if lib.isDerivation p then p else null;
      missing = builtins.filter (n: pkg n == null) list.names;
    in
    {
      warnings =
        map (n: "Golem: '${n}' (machine/apps.list) is not a program in nixpkgs (renamed or removed?) — skipped") missing
        ++ map (l: "Golem: machine/apps.list: not a program name, ignored: ${builtins.toJSON l}") list.refused;
      home.packages = map lib.lowPrio (builtins.filter (p: p != null) (map pkg list.names));
    };
}
