# system/modules — THE MODULES: the dock's Modules (Gaming, Development,
# Music Production…) as NixOS modules. One file per module; each installs the
# programs the owner switched on AND sets the system up for them
# (docs/system/GolemModules.md; README.md beside this file).
#
# Permanently imported by the desktop stage (system/Modular/desktop/
# default.nix) and off until asked: a machine that chose nothing evaluates to
# exactly the system it was before this tree existed.
#
# Three ways in, one result:
#   · the dock (Modules → Apply, or a drag into the grid): the programs land
#     in the owner's installed apps, and each file's PROGRAM SETUP — keyed on
#     the installed program's name — gives it the system it needs;
#   · by hand, in the machine's configuration:
#         standard.modules.gaming.enable = true;              # the recommended set
#         standard.modules.gaming.install = "all";            # …or everything
#         standard.modules.gaming.lutris.enable = true;       # …or one program
#   · the machine's selection file (standard.modules.listPath), read as data.
{ config, lib, ... }:

let
  m = import ./lib.nix { inherit lib; };
  cfg = config.standard.modules;
  owner = config.standard.owner;
in
{
  imports = [
    ./office.nix
    ./internet.nix
    ./social.nix
    ./media.nix
    ./gaming.nix
    ./productivity.nix
    ./content-creation.nix
    ./photography.nix
    ./education.nix
    ./kids.nix
    ./ai.nix
    ./remote-work.nix
    ./privacy-security.nix
    ./music-production.nix
    ./video-editing.nix
    ./graphic-design.nix
    ./3d-printing.nix
    ./writing.nix
    ./web-design.nix
    ./development.nix
    ./commerce.nix
    ./trading-finance.nix
    ./science-data.nix
    ./accessibility.nix
    ./windows-apps.nix
  ];

  options.standard.modules = {
    catalog = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      # The dock's own catalog, wherever the home layer carries the dock (the
      # compositions hand the waverunner input to it): the system and the
      # dock then read one file of one version. Without the dock: none.
      default =
        let
          dock = config.home-manager.extraSpecialArgs.waverunner or null;
          file = "${dock}/crates/daemon/assets/modules.json";
        in
        if dock != null && builtins.pathExists file then file else null;
      defaultText = lib.literalExpression ''"''${waverunner}/crates/daemon/assets/modules.json"'';
      description = ''
        The module catalog (the dock's modules.json): which programs each
        module offers and which "Install recommended" takes. Data, never
        code. null: the modules offer no programs (their program setup,
        keyed on what is installed, still works).
      '';
    };

    listPath = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        The machine's selection, as a text file: one `<module>` (the module
        with its `install` default) or `<module>.<tool>` per line; `#` starts
        a comment. Read as data and checked against the catalog; a line that
        names nothing is skipped with a warning.
      '';
    };

    catalogData = lib.mkOption {
      internal = true;
      readOnly = true;
      type = lib.types.raw;
      default = if cfg.catalog == null then { modules = [ ]; } else builtins.fromJSON (builtins.readFile cfg.catalog);
      description = "The catalog, parsed once.";
    };

    listData = lib.mkOption {
      internal = true;
      readOnly = true;
      type = lib.types.raw;
      default =
        if cfg.listPath == null then { modules = [ ]; tools = { }; bad = [ ]; }
        else m.parseList (builtins.readFile cfg.listPath);
      description = "The selection file, parsed once.";
    };

    installed = lib.mkOption {
      internal = true;
      readOnly = true;
      type = lib.types.listOf lib.types.str;
      # Every program among the owner's apps, by lib.getName: what a module
      # switched on, what was dragged into the grid, Standard's own.
      default = map lib.getName config.home-manager.users.${owner}.home.packages;
      description = "The names of the owner's installed programs (what PROGRAM SETUP is keyed on).";
    };

    active = lib.mkOption {
      internal = true;
      type = lib.types.listOf lib.types.str;
      default = [ ];
      # (Also read by the home layer: a module that is on may bring window
      # rules and keys of its own — system/home/hypr/standard/modules/<module>.lua,
      # loaded by system/home/hyprland.nix's facts.)
      description = "The modules that are on (what a module's plumbing is keyed on).";
    };

    web = lib.mkOption {
      internal = true;
      type = lib.types.listOf (lib.types.attrsOf lib.types.str);
      default = [ ];
      description = "The web programs switched on (module, id, name, url).";
    };
  };

  config = {
    warnings =
      map (l: "standard.modules list: '${l}' is not `<module>` or `<module>.<tool>` — skipped") cfg.listData.bad
      ++ map (c: "standard.modules list: '${c}' is not a module — skipped")
        (lib.filter (c: !(m.categories ? ${c}))
          (lib.unique (cfg.listData.modules ++ builtins.attrNames cfg.listData.tools)));

    # The web programs a module switched on install nothing here: they are the
    # dock's to open (webapps). Handed over as data, only when there are any.
    environment.etc = lib.mkIf (cfg.web != [ ]) {
      "golem/modules-web.json".text = builtins.toJSON cfg.web;
    };
  };
}
