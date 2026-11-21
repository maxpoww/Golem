# The /etc/nixos LAYOUT, PROVEN ON SOURCE (docs/system/Layout.md).
#
# Two machine folders made from the template (./fixtures: a ThinkPad on the
# desktop, a VM on the base alone), composed by lib.standard.machine exactly as
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
  owner = c.standard.owner;
  home = c.home-manager.users.${owner};
  homeNames = map lib.getName home.home.packages;

  # The same two folders through machine.nix: Standard called with the pins of
  # its own flake.lock, the way a machine's /etc/nixos/flake.nix calls it.
  viaLock = dir: (import ../../machine.nix dir).nixosConfigurations.default.config;
  tl = viaLock ./fixtures/thinkpad;
  ql = viaLock ./fixtures/qemu;
  drv = x: builtins.unsafeDiscardStringContext x.drvPath;

  facts = builtins.fromJSON (builtins.readFile ./fixtures/thinkpad/machine/facts.json);
  chosen = (import ../Modular/choose.nix { inherit facts; }).leaves;

  checks = [
    # ── the machine answers to its names ────────────────────────────────
    (ex "nixos-rebuild finds the machine by its hostname, and by `default`"
      (thinkpad.nixosConfigurations ? thinkpad-ana && thinkpad.nixosConfigurations ? default
        && qemu.nixosConfigurations ? standard-vm))

    # ── configuration.nix is what decides ───────────────────────────────
    (ex "configuration.nix: the owner, the name, the language, the zone, the keyboard"
      (owner == "ana"
        && c.networking.hostName == "thinkpad-ana"
        && c.i18n.defaultLocale == "es_AR.UTF-8"
        && c.time.timeZone == "America/Argentina/Buenos_Aires"
        && c.standard.keyboard.layout == "latam"))

    # ── the facts are data, and the chooser runs at evaluation ──────────
    (ex "machine/facts.json is the hardware (standard.hardware), read as data"
      (c.standard.hardware.gpu == "amd" && c.standard.hardware.ramMB == 7159 && c.standard.hardware.chassis == "laptop"))
    (ex "the hardware modules are the chooser's for those facts, chosen at evaluation"
      (map (p: p.leaf) c.standard.machine.leaves == chosen
        && c.hardware.cpu.amd.updateMicrocode
        && c.boot.loader.grub.efiSupport))
    (ex "…and the why of each is kept with the system (/etc/golem/layout.json)"
      (lib.hasInfix "cpuVendor=amd" c.environment.etc."golem/layout.json".text))

    # ── the two stages ───────────────────────────────────────────────────
    (ex "profile desktop: Hyprland, the greeter, the home layer"
      (c.programs.hyprland.enable && c.services.greetd.enable && home.xdg.configFile ? "hypr/hyprland.lua"))
    (ex "profile minimal: the base alone"
      (!(q.programs.hyprland.enable or false) && !(q.services.greetd.enable or false)
        && q.networking.hostName == "standard-vm" && q.standard.hardware.vmGuest == "qemu"))

    # ── Hyprland, in modules ─────────────────────────────────────────────
    (ex "Hyprland: ONE link in the home (the entry, pointing at this build's tree), and this machine's facts in the tree"
      (let facts = home.standard.home.hyprFacts; in
        home.xdg.configFile ? "hypr/hyprland.lua" && !(home.xdg.configFile ? "hypr/standard")
        && lib.hasInfix (builtins.unsafeDiscardStringContext "${home.standard.home.hyprTree}")
          home.xdg.configFile."hypr/hyprland.lua".text
        && lib.hasInfix ''layout  = "latam"'' facts
        && lib.hasInfix ''ctl = "waverunner-ctl"'' facts
        && lib.hasInfix "dev = false" facts
        && !(lib.hasInfix "/home/max" facts)))

    # ── the owner's own modules ──────────────────────────────────────────
    (ex "modules/*.nix: every file is imported"
      (c.environment.variables.GOLEM_TEST_DROPIN == "own"
        && lib.any (p: lib.getName p == "hello") c.environment.systemPackages))
    (ex "a module of Standard's is replaced by the owner's copy (disabledModules by standardSource)"
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
      (lib.elem "gaming" c.standard.modules.active
        && c.hardware.graphics.enable32Bit && c.programs.gamemode.enable && c.hardware.steam-hardware.enable))
    (ex "modules.list: one program of a module comes with the system it needs (Docker, rootless: no group that is root)"
      (lib.elem "docker" homeNames
        && c.virtualisation.docker.rootless.enable
        && !(lib.elem "docker" c.users.users.${owner}.extraGroups)))
    (ex "modules.list: what is on is told to Hyprland (the modules' own Lua)"
      (lib.hasInfix ''modules = { "gaming", "development" }'' home.standard.home.hyprFacts
        || lib.hasInfix ''modules = { "development", "gaming" }'' home.standard.home.hyprFacts))
    (ex "modules.list: a name that is no module or no program, and a line that is not a name, are warnings"
      (lib.any (w: lib.hasInfix "'not-a-module' is not a module" w) c.warnings
        && lib.any (w: lib.hasInfix "'gaming.not-a-program' is not a program" w) c.warnings
        && lib.any (w: lib.hasInfix "import /etc/passwd" w && lib.hasInfix "skipped" w) c.warnings))

    # ── where things live ────────────────────────────────────────────────
    (ex "Standard is root's own folder (/etc/nixos/standard), no link into the store is laid over it"
      (!(c.environment.etc ? "nixos/standard")))
    (ex "machine.nix (Standard from its OWN flake.lock, as a machine's flake calls it) is the same Standard as the flake: kernel, dock, Hyprland, the whole home"
      (ql.networking.hostName == "standard-vm" && tl.networking.hostName == "thinkpad-ana"
        && drv ql.system.build.kernel == drv q.system.build.kernel
        && tl.system.nixos.version == c.system.nixos.version
        && drv tl.programs.hyprland.package == drv c.programs.hyprland.package
        && drv tl.home-manager.users.${owner}.programs.waverunner.package == drv home.programs.waverunner.package
        && drv tl.home-manager.users.${owner}.home.activationPackage == drv home.home.activationPackage))
    (ex "…and there a Standard module is still replaced by the owner's copy (the source is named as a string)"
      (tl.services.journald.extraConfig == "SystemMaxUse=42M"))
    (ex "every generation keeps the machine folder it was built from (/etc/golem/machine)"
      (c.environment.etc ? "golem/machine"))
    (ex "the owner's password stays in root's own file, outside the folder and the store"
      (c.users.users.${owner}.hashedPasswordFile == "/var/lib/golem/secrets/owner-password-hash"
        && c.users.users.${owner}.hashedPassword == null))

    # ── nothing of the home-checkout layout is left ─────────────────────
    (ex "no checkout in a home: flakeDir is null"
      (c.standard.flakeDir == null && q.standard.flakeDir == null))
    (ex "…so no seal and no seed adoption"
      (!(c.systemd.services ? golem-seed-adopt)
        && !(lib.any (p: (p.name or "") == "golem-bless") c.environment.systemPackages)))
    (ex "the first-boot build is this layout's own: only where the installer asked for it, and it is the update's --converge"
      (c.systemd.services.golem-first-boot.unitConfig.ConditionPathExists == "/var/lib/golem/first-boot.pending"
        && lib.hasInfix "golem-update --converge" c.systemd.services.golem-first-boot.script
        && !(lib.hasInfix "golem-seal" c.systemd.services.golem-first-boot.script)
        && q.systemd.services ? golem-first-boot))
    (ex "the dock's installs are this layout's own: the owner's list is watched, and what it becomes is machine/apps.list (the base alone has no dock)"
      (c.systemd.paths.waverunner-apply.pathConfig.PathChanged == "/home/ana/.config/waverunner/packages.list"
        && c.systemd.services.waverunner-apply.restartIfChanged == false
        && !(q.systemd.services ? waverunner-apply)))
    (ex "the nightly update is this layout's own, under the names the desktop knows: it runs golem-update, and nothing of the seal"
      (c.systemd.timers ? golem-autoupdate && c.systemd.services ? golem-update-now
        && lib.hasInfix "golem-update --nightly" c.systemd.services.golem-autoupdate.script
        && !(lib.hasInfix "golem-seal" c.systemd.services.golem-autoupdate.script)
        && !(lib.hasInfix "git -C" c.systemd.services.golem-autoupdate.script)
        && q.systemd.timers ? golem-autoupdate))
    (ex "the commands of this layout are there: rebuild-golem, golem-update, golem-recover, golem-status, golem-machine-checkout"
      (lib.all (n: lib.any (p: (p.name or "") == n) c.environment.systemPackages)
        [ "rebuild-golem" "golem-update" "golem-recover" "golem-status" "golem-machine-checkout" ]))
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
