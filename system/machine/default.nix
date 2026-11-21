# mkMachine — ONE COMPUTER, FROM ITS OWN FOLDER (docs/system/Layout.md).
#
#   /etc/nixos/flake.nix:   outputs = { golem, ... }: {
#                             nixosConfigurations = standard.lib.standard.machine ./.;
#                           };
#
# Standard is the system (the pinned `golem` input, in the store, read-only);
# the folder is the machine (root-owned, never overwritten by an update):
#
#   configuration.nix            the owner's file: name, owner, language, and
#                                every manual change
#   hardware-configuration.nix   nixos-generate-config's, for this hardware
#   modules/*.nix                the owner's own modules: every one is imported
#   machine/facts.json           what the census measured (standard.hardware) — DATA
#   machine/install.json         { "profile": "desktop" | "minimal" } — DATA
#   machine/apps.list            the apps installed from the dock — DATA
#   machine/modules.list         the app modules switched on in the dock — DATA
#   machine/answers.list         the answers to Standard's post-install questions — DATA
#
# The folder is the three things an installed Standard kept in its owner's home
# (hosts/target/{machine,golem-hardware,modules}.nix inside ~/Golem), in the
# place NixOS has for them. What changes with it:
#
# - THE CHOOSER RUNS HERE, at evaluation, from the facts. A machine no longer
#   carries a rendered modules.nix full of paths into Standard's tree (the reason
#   `system/Modular` could never be renamed).
# - Everything under machine/ is read as DATA: parsed, looked up, validated.
#   None of it is imported as Nix, so a tool that writes there (the dock's
#   installer, the census) cannot hand root code.
# - Nothing is read from a home directory.
#
# The same module list as flake.nix's `standard-desktop` (the installs of today),
# minus the files it took from hosts/target. Keep the two in step until the
# installer writes this layout and `standard-desktop` retires.
{ nixpkgs, home-manager, waverunner, waveview, standardRev, standardSrc }:

let
  lib = nixpkgs.lib;

  # THE LAYOUT'S OWN LEAVES, for whoever composes a system that lives in it:
  # a machine from its folder (below), and the install medium's baked systems
  # (flake.nix, mkBakedEntry), which are this layout's first generation.
  layoutModules = profile:
    [
      ./layout.nix
      ./update.nix       # the nightly update
      ./first-boot.nix   # the one build after an install, where the installer asked for it
    ]
    ++ lib.optionals (profile == "desktop") [
      ./apps.nix      # the dock's installs → machine/apps.list
      ./answers.nix   # the post-install answers → machine/answers.list
    ];

  machine = dir:

let

  has = rel: builtins.pathExists (dir + "/${rel}");
  json = rel: builtins.fromJSON (builtins.readFile (dir + "/${rel}"));
  need = rel: why:
    if has rel then dir + "/${rel}"
    else throw "Standard: ${rel} is missing from this machine's folder — ${why}";

  install = if has "machine/install.json" then json "machine/install.json" else { };
  profile = install.profile or "desktop";

  # THE FACTS: data. (An install made before this layout kept them as a Nix
  # module, golem-hardware.nix; `golem-relocate` turns it into this file.)
  facts =
    if has "machine/facts.json" then json "machine/facts.json"
    else throw ''
      Standard: machine/facts.json is missing from this machine's folder.
      It is what the census measured (golem-hw-detect --json > machine/facts.json);
      without it Standard cannot choose this hardware's modules.'';

  # THE CHOOSER, at evaluation: facts → the hardware leaves, in order.
  chosen = import ../Modular/choose.nix { inherit facts; };

  # The owner's own modules: every .nix file in modules/, in name order.
  dropins =
    if has "modules" then
      map (n: dir + "/modules/${n}")
        (lib.sort (a: b: a < b)
          (lib.filter (n: lib.hasSuffix ".nix" n)
            (lib.attrNames (lib.filterAttrs (_: t: t == "regular" || t == "symlink")
              (builtins.readDir (dir + "/modules"))))))
    else [ ];

  lists = import ./lists.nix { inherit lib; };
  appsList = if has "machine/apps.list" then dir + "/machine/apps.list" else null;
  modulesList = if has "machine/modules.list" then dir + "/machine/modules.list" else null;

  system = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    # `standardSource`: the Standard source, for the owner's modules — the one use
    # is naming a Standard module to replace (disabledModules needs it before
    # the configuration exists, so it cannot be an ordinary module argument).
    # A STRING, never a path value: "''${path}/x" of a path inside a flake's
    # source copies it to a store path of its own, which is not where the
    # modules are imported from, and the replacement would then match nothing.
    specialArgs = { standardSource = toString standardSrc; };
    modules =
      [
        { system.configurationRevision = standardRev; }
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        }
        ../Modular/composition.nix
      ]
      ++ layoutModules profile
      ++ [
        {
          standard.hardware = facts;
          standard.machine = {
            source = standardSrc;
            folder = dir;
            inherit profile;
            leaves = chosen.pointers;
          };
        }
      ]
      ++ map (leaf: ../Modular + "/${leaf}") chosen.leaves
      ++ lib.optionals (profile == "desktop") [
        ../Modular/desktop/default.nix
        waverunner.nixosModules.notification-service
        ({ config, ... }: {
          services.options-notify.enable = true;
          home-manager.backupFileExtension = "before-golem";
          # The answers given to Standard's questions after the install
          # (system/postinstall.nix reads them as data: `"question" = "answer";`).
          standard.postinstall.generatedFile =
            if has "machine/answers.list" then dir + "/machine/answers.list" else null;
          # The app modules switched on in the dock (system/modules reads it
          # as data: `<module>` or `<module>.<program>` a line).
          standard.modules.listPath = modulesList;
          home-manager.users.${config.standard.owner}.imports = [
            ../home/home.nix
            (lists.appsModule appsList)
          ];
          home-manager.extraSpecialArgs = { inherit waverunner waveview; };
        })
      ]
      ++ [
        (need "hardware-configuration.nix" "run: sudo nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration.nix")
        (need "configuration.nix" "it is this computer's own file (see the template in standard/system/machine/template)")
      ]
      ++ dropins;
  };

  # What `nixos-rebuild` asks for is the attribute named after the RUNNING
  # hostname, so the machine answers to its name (as configuration.nix says
  # it), to the name it was installed with, and to `default`: after a rename,
  # one `sudo nixos-rebuild switch --flake /etc/nixos#default` and the new
  # name answers from then on.
  # And to "Standard": the system the installer copied is called that
  # (base/core.nix) and is the one running until the first restart, so a
  # plain `nixos-rebuild boot` in that first session finds the machine too.
  names = lib.unique (
    [ "default" system.config.networking.hostName ]
    ++ lib.optional (install ? hostname && builtins.isString install.hostname && install.hostname != "") install.hostname
    ++ [ "Standard" ]
  );
in
{
  inherit system;
  nixosConfigurations = lib.genAttrs names (_: system);
};
in
# Called with a folder, it is the machine; asked for `layoutModules`, it is
# the layout's leaves.
{
  __functor = _: machine;
  inherit layoutModules;
}
