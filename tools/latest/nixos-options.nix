# tools/latest/nixos-options.nix — what Standard DEFINES of NixOS, against the
# latest NixOS (tools/latest/check.sh runs it; README.md beside this file).
#
# Every NixOS option that the app modules (system/modules), the loopback-
# camera leaf and the /etc/nixos layout (system/machine) define is found by
# walking what those files return — through mkIf / mkMerge / mkOverride, down
# to where the option tree of the pinned NixOS says "this is an option" — and
# then looked up in the LATEST NixOS: still there? still visible (a renamed
# option stays behind as a hidden alias)? the same type? The packages those
# files name outright, and every program of the dock's catalog, are looked
# up by attribute the same way. Nothing is built.
#
#   nix eval --impure --json --expr 'import ./tools/latest/nixos-options.nix {
#     flake = "git+file:///home/max/Golem"; unstable = /nix/store/…-source; }'
{ flake, unstable }:
let
  f = builtins.getFlake flake;
  lib = f.inputs.nixpkgs.lib;
  src = f.outPath;
  ml = import (src + "/system/modules/lib.nix") { inherit lib; };
  ids = builtins.attrNames ml.categories;

  base = (f.lib.standard.machine (src + "/system/machine/fixtures/thinkpad")).system;
  all = base.extendModules {
    modules = [ { standard.modules = lib.genAttrs ids (_: { enable = true; install = "all"; }); } ];
  };
  opts = all.options;
  pkgs = all.pkgs;

  isOpt = path: lib.hasAttrByPath path opts && lib.isOption (lib.getAttrFromPath path opts);
  collect = path: v:
    if path != [ ] && isOpt path then [ path ]
    else if builtins.isAttrs v && (v._type or "") == "if" then collect path v.content
    else if builtins.isAttrs v && (v._type or "") == "merge" then lib.concatMap (collect path) v.contents
    else if builtins.isAttrs v && (v._type or "") == "override" then collect path v.content
    else if builtins.isAttrs v && !(v ? _type) then lib.concatLists (lib.mapAttrsToList (n: x: collect (path ++ [ n ]) x) v)
    else [ ([ "NOT-AN-OPTION" ] ++ path) ];

  args = { config = all.config; inherit lib pkgs; options = opts; standardSource = src; };
  # What a module file returns, and what the modules it imports inline
  # (lib.nix's mkModule) return.
  body = m:
    let
      r = if builtins.isFunction m then m (builtins.intersectAttrs (builtins.functionArgs m) args // args) else m;
      own = if r ? config then r.config else builtins.removeAttrs r [ "imports" "options" "disabledModules" "_file" "key" "meta" ];
      inline = lib.filter (i: !(builtins.isPath i) && !(builtins.isString i)) (r.imports or [ ]);
    in
    collect [ ] own ++ lib.concatMap body inline;

  files =
    map (id: src + "/system/modules/${id}.nix") ids
    ++ [ (src + "/system/modules/default.nix") (src + "/system/Modular/desktop/phone.nix") (src + "/system/machine/layout.nix") ];
  defined = lib.unique (lib.concatMap (file: body (import file)) files);
  bad = lib.filter (p: builtins.head p == "NOT-AN-OPTION") defined;
  good = lib.filter (p: builtins.head p != "NOT-AN-OPTION") defined;

  # Only what NixOS itself declares (Standard's own options and home-manager's
  # are not NixOS's to keep).
  np = toString f.inputs.nixpkgs.outPath;
  ofNixos = p: lib.all (d: lib.hasPrefix np (toString d)) (lib.getAttrFromPath p opts).declarations;
  nixosPaths = lib.filter ofNixos good;

  u = (import (unstable + "/nixos/lib/eval-config.nix") { system = "x86_64-linux"; modules = [ ]; }).options;
  upkgs = import unstable { system = "x86_64-linux"; config.allowUnfree = true; };
  look = p:
    let
      there = lib.hasAttrByPath p u && lib.isOption (lib.getAttrFromPath p u);
      o = lib.getAttrFromPath p u;
      mine = lib.getAttrFromPath p opts;
      t = x: (x.type.description or "?");
      desc = x: let d = x.description or ""; in if builtins.isString d then d else (d.text or "");
    in
    { option = lib.showOption p; }
    // (if !there then { state = "GONE"; }
    else if !(o.visible or true) || lib.hasPrefix "Alias of" (desc o) then { state = "HIDDEN-OR-RENAMED"; note = desc o; }
    else if t o != t mine then { state = "TYPE-CHANGED"; pinned = t mine; latest = t o; }
    else { state = "same"; });
  results = map look nixosPaths;

  # The packages the modules name outright (not through the catalog).
  named = [ "ollama-cuda" "pinentry-qt" "argyllcms" "corefonts" "dolphin-emu" "zoom-us" "obs-studio" ];
  zoomArg = p: (p.zoom-us.override.__functionArgs or { }) ? hyprlandXdgDesktopPortalSupport;

  # The catalog's programs, by attribute, in the latest nixpkgs: which names
  # will no longer be there at the next move of the pin.
  catalog = builtins.fromJSON (builtins.readFile all.config.standard.modules.catalog);
  attrs = lib.unique (lib.concatMap (c: lib.concatMap (g: lib.concatMap (p: lib.optional (p ? pkg) p.pkg) (g.programs or [ ])) (c.groups or [ ])) (catalog.modules or [ ]));
  has = set: a: lib.hasAttrByPath (lib.splitString "." a) set;
in
{
  pinned = "${f.inputs.nixpkgs.lib.version}";
  latest = "${upkgs.lib.version}";
  definedTotal = builtins.length good;
  notAnOption = map lib.showOption bad;
  golemOrHomeManager = map lib.showOption (lib.filter (p: !(ofNixos p)) good);
  checked = builtins.length results;
  same = builtins.length (lib.filter (r: r.state == "same") results);
  different = lib.filter (r: r.state != "same") results;
  all = map (r: r.option) results;
  packagesNamed = map (n: { name = n; pinned = pkgs ? ${n}; latest = upkgs ? ${n}; }) named;
  zoomPortalArg = { pinned = zoomArg pkgs; latest = zoomArg upkgs; };
  catalogAttrs = builtins.length attrs;
  catalogMissingPinned = lib.filter (a: !(has pkgs a)) attrs;
  catalogMissingLatest = lib.filter (a: !(has upkgs a)) attrs;
}
