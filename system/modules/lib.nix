# system/modules/lib — what every app module shares.
#
# A module here is one of the dock's Modules (Gaming, Development…): a set of
# programs the owner switches on, and the SYSTEM those programs need. The
# programs are DATA — the dock's own catalog (crates/daemon/assets/
# modules.json in the waverunner input), read once (default.nix) — so what a
# module offers and what "Install recommended" takes can change without a
# line of Nix. What is written here by hand is only what data cannot say: the
# services, ports, device rules and kernel bits a program needs to work.
#
# The option shape (docs/system/GolemModules.md §2, §5):
#   golem.modules.<module>.enable            the module is on
#   golem.modules.<module>.install           what `enable` takes: "recommended"
#                                            (the catalog's picks), "all", "chosen"
#   golem.modules.<module>.<tool>.enable     one program: true, false, or unsaid
# The set is closed: a tool the catalog does not have is an evaluation error.
{ lib }:

let
  inherit (lib) mkOption types;
in
rec {
  # The module's id (its file, its option) → its name in the catalog. Closed:
  # a module the catalog gains has no options until its file is written.
  categories = {
    "office" = "Office";
    "internet" = "Internet";
    "social" = "Social";
    "media" = "Media & Entertainment";
    "gaming" = "Gaming";
    "productivity" = "Productivity";
    "content-creation" = "Content Creation";
    "photography" = "Photography";
    "education" = "Education";
    "kids" = "Kids";
    "ai" = "AI";
    "remote-work" = "Remote Work";
    "privacy-security" = "Privacy & Security";
    "music-production" = "Music Production";
    "video-editing" = "Video Editing";
    "graphic-design" = "Graphic Design";
    "3d-printing" = "3D & Printing";
    "writing" = "Writing";
    "web-design" = "Web Design";
    "development" = "Development";
    "commerce" = "Commerce";
    "trading-finance" = "Trading & Finance";
    "science-data" = "Science & Data";
    "accessibility" = "Accessibility";
    "windows-apps" = "Windows Apps";
  };

  # A module's own words: no tool may be called one of these.
  reserved = [ "enable" "install" ];

  # "YouTube Music" → "youtube-music".
  slug = s:
    lib.concatStringsSep "-"
      (lib.filter (x: builtins.isString x && x != "")
        (builtins.split "[^a-z0-9]+" (lib.toLower s)));

  # A package's tool id: its attribute's last word, lower-case, without the
  # underscore nixpkgs puts before a digit (kdePackages.kdenlive → kdenlive,
  # _1password-gui → 1password-gui). Where the last word says nothing, by hand.
  idOverrides = {
    "wineWow64Packages.stable" = "wine";
  };
  pkgId = attr:
    idOverrides.${attr} or (lib.toLower (lib.removePrefix "_" (lib.last (lib.splitString "." attr))));

  # A module's tools, in the catalog's order:
  #   { id, name, what, group, recommended, pkg | web }
  # A web program is called by its name; where a package of the same module
  # has that id already (Spotify the site, spotify the app), it is `<id>-web`.
  # "recommended" only ever takes editorial entries (the catalog's rule: a
  # paid placement is offered, never switched on for anyone).
  toolsOf = catalog: catalogName:
    let
      found = lib.findFirst (c: (c.name or "") == catalogName) null (catalog.modules or [ ]);
      raw =
        if found == null then [ ] else
        lib.concatMap (g: map (p: p // { group = g.name or ""; }) (g.programs or [ ])) (found.groups or [ ]);
      pkgIds = map (p: pkgId p.pkg) (lib.filter (p: p ? pkg) raw);
      idOf = p:
        if p ? pkg then pkgId p.pkg
        else let s = slug (p.name or ""); in if builtins.elem s pkgIds then "${s}-web" else s;
    in
    map
      (p: {
        id = idOf p;
        name = p.name or (idOf p);
        what = p.what or "";
        inherit (p) group;
        recommended = (p.recommended or false) && (p.placement or "editorial") == "editorial";
      }
      // lib.optionalAttrs (p ? pkg) { inherit (p) pkg; }
      // lib.optionalAttrs (!(p ? pkg) && p ? web) { inherit (p) web; })
      raw;

  # The machine's selection file (golem.modules.listPath), READ AS DATA: one
  # `<module>` or `<module>.<tool>` per line, `#` starts a comment. Never
  # imported: the file is written without a password, so a line is only ever
  # a name that is looked up. → { modules = [ id ]; tools = { id = [ tool ]; };
  # bad = [ line ] } (bad: not that shape; whether a name EXISTS is asked
  # where the catalog is at hand).
  parseList = text:
    let
      lines = lib.filter (l: l != "")
        (map (l: lib.trim (builtins.head (lib.splitString "#" l))) (lib.splitString "\n" text));
      shape = l: builtins.match "([a-z0-9][a-z0-9-]*)(\\.([A-Za-z0-9_][A-Za-z0-9_+-]*))?" l;
      parsed = map (l: { line = l; m = shape l; }) lines;
      good = lib.filter (p: p.m != null) parsed;
      whole = lib.filter (p: builtins.elemAt p.m 2 == null) good;
      single = lib.filter (p: builtins.elemAt p.m 2 != null) good;
    in
    {
      modules = lib.unique (map (p: builtins.head p.m) whole);
      tools = lib.foldl'
        (acc: p: let c = builtins.head p.m; in acc // { ${c} = (acc.${c} or [ ]) ++ [ (builtins.elemAt p.m 2) ]; })
        { }
        single;
      bad = map (p: p.line) (lib.filter (p: p.m == null) parsed);
    };

  # What a module file asks about the machine it is evaluated for.
  #   has "steam"   the program is among the owner's installed apps — however
  #                 it got there: a module's switch or a drag into the grid
  #                 (names as lib.getName gives them)
  #   any [ … ]     one of them is
  #   on "gaming"   the module is on (switched on, or one of its tools is)
  scope = config: rec {
    owner = config.golem.owner;
    has = name: builtins.elem name config.golem.modules.installed;
    any = names: lib.any has names;
    on = id: builtins.elem id config.golem.modules.active;
  };

  # The half every module has in common: its options, its programs' packages,
  # its web programs as data, and the checks that keep the set closed.
  mkModule = { id, description }: { config, pkgs, ... }:
    let
      cfg = config.golem.modules.${id};
      owner = config.golem.owner;
      tools = toolsOf config.golem.modules.catalogData categories.${id};
      ids = map (t: t.id) tools;
      listed = config.golem.modules.listData;

      # What was said tool by tool (in a configuration, or in the list).
      named = builtins.removeAttrs cfg reserved;
      listedTools = listed.tools.${id} or [ ];
      enabled = cfg.enable || builtins.elem id listed.modules;
      defaults =
        if cfg.install == "all" then ids
        else if cfg.install == "recommended" then map (t: t.id) (lib.filter (t: t.recommended) tools)
        else [ ];
      # A tool said outright wins; else the list's word; else the module's.
      isOn = t:
        let said = (named.${t.id} or { enable = null; }).enable; in
        if said != null then said
        else builtins.elem t.id listedTools || (enabled && builtins.elem t.id defaults);
      chosen = lib.filter isOn tools;

      # LOOKED UP, never referenced (system/home/app-list.nix's rule): a
      # program nixpkgs lacks, or one that does not evaluate there today
      # (marked broken or insecure upstream), is skipped with a warning
      # instead of failing the whole system.
      find = attr:
        let p = lib.attrByPath (lib.splitString "." attr) null pkgs; in
        if p != null && lib.isDerivation p && (builtins.tryEval (builtins.seq p.drvPath true)).success
        then p else null;
      withPkg = lib.filter (t: t ? pkg) chosen;
      missing = lib.filter (t: find t.pkg == null) withPkg;

      unknown = lib.filter (n: !(builtins.elem n ids)) (builtins.attrNames named);
      unknownListed = lib.filter (n: !(builtins.elem n ids)) listedTools;
      twice = lib.unique (lib.filter (i: lib.count (j: j == i) ids > 1) ids);
      clash = lib.filter (i: builtins.elem i reserved) ids;
    in
    {
      options.golem.modules.${id} = mkOption {
        default = { };
        inherit description;
        type = types.submodule {
          # Any other name is a tool: `<tool>.enable`. Which names ARE tools
          # is the catalog's to say (checked below): an option declaration
          # cannot depend on a file the configuration names.
          freeformType = types.attrsOf (types.submodule {
            options.enable = mkOption {
              type = types.nullOr types.bool;
              default = null;
              description = ''
                This program: true installs it (with the system it needs),
                false leaves it out even when the module's `install` would
                take it, null (unsaid) follows the module.
              '';
            };
          });
          options.enable = mkOption {
            type = types.bool;
            default = false;
            description = "Whether the ${categories.${id}} module is on: its plumbing, and the programs `install` names.";
          };
          options.install = mkOption {
            type = types.enum [ "recommended" "all" "chosen" ];
            default = "recommended";
            description = ''
              Which programs `enable` takes: "recommended" (the catalog's
              picks), "all" (every program of the module nixpkgs has),
              "chosen" (only those switched on one by one).
            '';
          };
        };
      };

      config = {
        assertions = [
          {
            assertion = unknown == [ ];
            message = "golem.modules.${id}: ${lib.concatStringsSep ", " unknown} — not a program of the ${categories.${id}} module"
              + (if tools == [ ] then " (this system has no module catalog: golem.modules.catalog)" else " (the catalog's ids: ${lib.concatStringsSep " " ids})");
          }
          {
            assertion = twice == [ ] && clash == [ ];
            message = "golem.modules.${id}: the catalog gives two programs one id, or one of the module's own words (${lib.concatStringsSep ", " (twice ++ clash)}) — give it an id in system/modules/lib.nix (idOverrides)";
          }
        ];
        warnings =
          map (t: "golem.modules.${id}: '${t.pkg}' (${t.name}) is not in nixpkgs or does not evaluate there today — skipped") missing
          ++ map (n: "golem.modules list: '${id}.${n}' is not a program of the ${categories.${id}} module — skipped") unknownListed;

        # Where the dock's installs go (hosts/target/apps.nix → the owner's
        # home packages), at the same low priority: Golem's own copy of a
        # shared file wins.
        home-manager.users.${owner}.home.packages =
          map lib.lowPrio (lib.filter (p: p != null) (map (t: find t.pkg) withPkg));

        golem.modules.active = lib.optional (enabled || chosen != [ ]) id;
        golem.modules.web =
          map (t: { module = id; inherit (t) id name; url = t.web; }) (lib.filter (t: t ? web) chosen);
      };
    };
}
