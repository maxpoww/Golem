# The /etc/nixos LAYOUT, PROVEN ON SOURCE (docs/system/Layout.md).
#
# Two machine folders made from the template (./fixtures: a ThinkPad on the
# desktop, a VM on the base alone), composed by lib.golem.machine exactly as
# a machine's /etc/nixos/flake.nix composes itself, and asserted: the whole
# system evaluates, the machine's files are what decide it, its lists are
# data whatever is written in them, and nothing of the home-checkout layout
# (the seal, the pulls as the owner) is left running.
#
#   nix build .#checks.x86_64-linux.machine-layout
{ lib, pkgs, machine }:

let
  ex = name: ok: { inherit name ok; };

  thinkpad = machine ./fixtures/thinkpad;
  qemu = machine ./fixtures/qemu;

  c = thinkpad.system.config;
  q = qemu.system.config;
  owner = c.golem.owner;
  home = c.home-manager.users.${owner};
  homeNames = map lib.getName home.home.packages;

  facts = builtins.fromJSON (builtins.readFile ./fixtures/thinkpad/machine/facts.json);
  chosen = (import ../Modular/choose.nix { inherit facts; }).leaves;

  checks = [
    # ── the machine answers to its names ────────────────────────────────
    (ex "nixos-rebuild finds the machine by its hostname, and by `default`"
      (thinkpad.nixosConfigurations ? thinkpad-ana && thinkpad.nixosConfigurations ? default
        && qemu.nixosConfigurations ? golem-vm))

    # ── configuration.nix is what decides ───────────────────────────────
    (ex "configuration.nix: the owner, the name, the language, the zone, the keyboard"
      (owner == "ana"
        && c.networking.hostName == "thinkpad-ana"
        && c.i18n.defaultLocale == "es_AR.UTF-8"
        && c.time.timeZone == "America/Argentina/Buenos_Aires"
        && c.golem.keyboard.layout == "latam"))

    # ── the facts are data, and the chooser runs at evaluation ──────────
    (ex "machine/facts.json is the hardware (golem.hardware), read as data"
      (c.golem.hardware.gpu == "amd" && c.golem.hardware.ramMB == 7159 && c.golem.hardware.chassis == "laptop"))
    (ex "the hardware modules are the chooser's for those facts, chosen at evaluation"
      (map (p: p.leaf) c.golem.machine.leaves == chosen
        && c.hardware.cpu.amd.updateMicrocode
        && c.boot.loader.grub.efiSupport))
    (ex "…and the why of each is kept with the system (/etc/golem/layout.json)"
      (lib.hasInfix "cpuVendor=amd" c.environment.etc."golem/layout.json".text))

    # ── the two stages ───────────────────────────────────────────────────
    (ex "profile desktop: Hyprland, the greeter, the home layer"
      (c.programs.hyprland.enable && c.services.greetd.enable && home.xdg.configFile ? "hypr/hyprland.lua"))
    (ex "profile minimal: the base alone"
      (!(q.programs.hyprland.enable or false) && !(q.services.greetd.enable or false)
        && q.networking.hostName == "golem-vm" && q.golem.hardware.vmGuest == "qemu"))

    # ── Hyprland, in modules ─────────────────────────────────────────────
    (ex "Hyprland: ONE link in the home (the entry, pointing at this build's tree), and this machine's facts in the tree"
      (let facts = home.golem.home.hyprFacts; in
        home.xdg.configFile ? "hypr/hyprland.lua" && !(home.xdg.configFile ? "hypr/golem")
        && lib.hasInfix (builtins.unsafeDiscardStringContext "${home.golem.home.hyprTree}")
          home.xdg.configFile."hypr/hyprland.lua".text
        && lib.hasInfix ''layout  = "latam"'' facts
        && lib.hasInfix ''ctl = "waverunner-ctl"'' facts
        && lib.hasInfix "dev = false" facts
        && !(lib.hasInfix "/home/max" facts)))

    # ── the owner's own modules ──────────────────────────────────────────
    (ex "modules/*.nix: every file is imported"
      (c.environment.variables.GOLEM_TEST_DROPIN == "own"
        && lib.any (p: lib.getName p == "hello") c.environment.systemPackages))
    (ex "a module of Golem's is replaced by the owner's copy (disabledModules by golemSource)"
      (c.services.journald.extraConfig == "SystemMaxUse=42M"))

    # ── machine/apps.list is DATA ────────────────────────────────────────
    (ex "apps.list: each name is looked up and installed for the owner"
      (lib.elem "htop" homeNames && lib.elem "kate" homeNames))
    (ex "apps.list: a name nixpkgs does not have, or that is no program, is a warning"
      (lib.any (w: lib.hasInfix "'this-program-does-not-exist-in-nixpkgs'" w) c.warnings
        && lib.any (w: lib.hasInfix "'lib' (machine/apps.list) is not a program" w) c.warnings))
    (ex "apps.list: a line that is not one name is refused, and is nothing but a warning"
      (lib.length (lib.filter (w: lib.hasInfix "not a program name, ignored" w) c.warnings) == 2
        && !(c.environment.etc ? "passwd-planted")))

    # ── machine/modules.list is DATA ─────────────────────────────────────
    (ex "modules.list: a module switched on brings its plumbing (Gaming: 32-bit graphics, GameMode, the controllers' rules)"
      (lib.elem "gaming" c.golem.modules.active
        && c.hardware.graphics.enable32Bit && c.programs.gamemode.enable && c.hardware.steam-hardware.enable))
    (ex "modules.list: one program of a module comes with the system it needs (Docker, rootless: no group that is root)"
      (lib.elem "docker" homeNames
        && c.virtualisation.docker.rootless.enable
        && !(lib.elem "docker" c.users.users.${owner}.extraGroups)))
    (ex "modules.list: what is on is told to Hyprland (the modules' own Lua)"
      (lib.hasInfix ''modules = { "gaming", "development" }'' home.golem.home.hyprFacts
        || lib.hasInfix ''modules = { "development", "gaming" }'' home.golem.home.hyprFacts))
    (ex "modules.list: a name that is no module or no program, and a line that is not a name, are warnings"
      (lib.any (w: lib.hasInfix "'not-a-module' is not a module" w) c.warnings
        && lib.any (w: lib.hasInfix "'gaming.not-a-program' is not a program" w) c.warnings
        && lib.any (w: lib.hasInfix "import /etc/passwd" w && lib.hasInfix "skipped" w) c.warnings))

    # ── where things live ────────────────────────────────────────────────
    (ex "/etc/nixos/golem is the Golem this system was built from"
      (c.environment.etc ? "nixos/golem" && toString c.environment.etc."nixos/golem".source == toString c.golem.machine.source))
    (ex "every generation keeps the machine folder it was built from (/etc/golem/machine)"
      (c.environment.etc ? "golem/machine"))
    (ex "the owner's password stays in root's own file, outside the folder and the store"
      (c.users.users.${owner}.hashedPasswordFile == "/var/lib/golem/secrets/owner-password-hash"
        && c.users.users.${owner}.hashedPassword == null))

    # ── nothing of the home-checkout layout is left ─────────────────────
    (ex "no checkout in a home: flakeDir is null"
      (c.golem.flakeDir == null && q.golem.flakeDir == null))
    (ex "…so no seal, no seed adoption, no pull as the owner, no root copy of a checkout"
      (!(c.systemd.services ? golem-autoupdate)
        && !(c.systemd.services ? golem-seed-adopt)
        && !(c.systemd.services ? golem-first-boot)
        && !(c.systemd.services ? waverunner-apply)
        && !(c.systemd.paths ? waverunner-apply)
        && !(lib.any (p: (p.name or "") == "golem-bless") c.environment.systemPackages)))
    (ex "the commands of this layout are there: rebuild-golem, golem-update"
      (lib.all (n: lib.any (p: (p.name or "") == n) c.environment.systemPackages) [ "rebuild-golem" "golem-update" ]))
  ];

  failed = builtins.filter (e: !e.ok) checks;
  report =
    if failed != [ ] then
      throw "machine-layout failed: ${lib.concatMapStringsSep "; " (e: e.name) failed}"
    else
      lib.concatStringsSep "\n" ([
        "thinkpad ${builtins.unsafeDiscardStringContext c.system.build.toplevel.drvPath}"
        "qemu ${builtins.unsafeDiscardStringContext q.system.build.toplevel.drvPath}"
      ] ++ map (e: "ok ${e.name}") checks);
in
pkgs.runCommand "golem-machine-layout"
  { passAsFile = [ "report" ]; inherit report; }
  ''
    cp "$reportPath" $out
    echo "machine-layout: 2 machines composed from their folders, ${toString (builtins.length checks)} assertions" >&2
  ''
