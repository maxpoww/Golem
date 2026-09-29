# The DESKTOP-STAGE effect matrix (Phase B, 2026-09-26) — the stage-1 twin of
# effect-matrix.nix. Compose a real fixture's hardware leaves PLUS the desktop
# bundle via mkMinimal and assert the composed desktop config: not "the file
# imports hyprland.nix" but "the composed stage-1 system really enables Hyprland
# under uwsm, greetd launching it as the owner, uinput on". A desktop leaf whose
# values drift fails HERE, on source, before a metal climb. Runs the desktop
# leaves TOGETHER with the machine's hardware leaves, so a compose conflict
# (a desktop leaf fighting a gpu/memory leaf) also surfaces here.
#
#   nix build .#checks.x86_64-linux.desktop-matrix
{ lib, pkgs, mkMinimal, waverunner, waveview }:

let
  fakeDisk = {
    nixpkgs.hostPlatform = "x86_64-linux";
    fileSystems."/" = { device = "/dev/disk/by-label/golem"; fsType = "ext4"; };
    fileSystems."/boot" = { device = "/dev/disk/by-label/ESP"; fsType = "vfat"; };
  };
  desktop = ../../system/Modular/desktop/default.nix;

  ex = name: ok: { inherit name ok; };

  rows = [
    {
      name = "lenovo desktop stage (intel+nvidia — the richest GPU class)";
      facts = (import ../../Installer/preinstall/fixtures/lenovo-slim-pro-9-16irp8/facts.nix { }).golem.hardware;
    }
    {
      name = "thinkpad desktop stage (AMD Renoir — the amd class)";
      facts = (import ../../Installer/preinstall/fixtures/thinkpad-e15-gen2/facts.nix { }).golem.hardware;
    }
  ];

  # Same assertions for every class — the desktop skeleton is hardware-agnostic;
  # the point is that it COMPOSES cleanly on each and sets what it promises.
  expect = c: [
    (ex "hyprland enabled" c.programs.hyprland.enable)
    (ex "hyprland under uwsm" c.programs.hyprland.withUWSM)
    (ex "hyprland xwayland on" c.programs.hyprland.xwayland.enable)
    (ex "greetd enabled" c.services.greetd.enable)
    (ex "greetd starts hyprland via uwsm"
      (lib.hasInfix "uwsm start hyprland" c.services.greetd.settings.default_session.command))
    (ex "greetd session runs as the owner"
      (c.services.greetd.settings.default_session.user == c.golem.owner))
    (ex "uinput on (virtual gamepad)" c.hardware.uinput.enable)
    (ex "xserver on for XWayland xkb" c.services.xserver.enable)
    (ex "owner joined uinput + adbusers at the desktop stage"
      (lib.elem "uinput" c.users.users.${c.golem.owner}.extraGroups
        && lib.elem "adbusers" c.users.users.${c.golem.owner}.extraGroups))
    # base groups still present (extraGroups MERGED, not replaced)
    (ex "base groups survive the merge (wheel, video)"
      (lib.elem "wheel" c.users.users.${c.golem.owner}.extraGroups
        && lib.elem "video" c.users.users.${c.golem.owner}.extraGroups))
    # audio: pipewire replaces pulseaudio
    (ex "pipewire on, pulseaudio off" (c.services.pipewire.enable && !c.services.pulseaudio.enable))
    (ex "pipewire pulse + alsa shims" (c.services.pipewire.pulse.enable && c.services.pipewire.alsa.enable))
    (ex "rtkit on (realtime audio)" c.security.rtkit.enable)
    # bluetooth: these fixtures have a radio → blueman + bluez on
    (ex "bluetooth on (census hasBluetooth)" (c.hardware.bluetooth.enable && c.services.blueman.enable))
    # fonts: the Nerd Font ships, sans-serif pinned to DejaVu
    (ex "JetBrains Mono Nerd Font shipped"
      (lib.any (p: lib.hasInfix "jetbrains-mono" (p.pname or p.name or "")) c.fonts.packages))
    (ex "sans-serif pinned to DejaVu" (c.fonts.fontconfig.defaultFonts.sansSerif == [ "DejaVu Sans" ]))
  ];

  runRow = row:
    let
      c = (mkMinimal row.facts [ fakeDisk desktop ]).config;
      failed = builtins.filter (e: !e.ok) (expect c);
    in
    if failed == [ ]
    then "${row.name} ${builtins.unsafeDiscardStringContext c.system.build.toplevel.drvPath}"
    else throw "desktop-matrix row '${row.name}' failed: ${
      lib.concatMapStringsSep "; " (e: e.name) failed}";

  # The TEST cut: desktop + the test-chrome autostart (NOT in default.nix).
  # Compose it and assert the owner's Chrome lands via home-manager with the
  # VA-API flag, forcing the full eval (home config included).
  testChrome =
    let
      testLeaf = ../../system/Modular/desktop/test-chrome.nix;
      c = (mkMinimal (builtins.head rows).facts [ fakeDisk desktop testLeaf ]).config;
      owner = c.golem.owner;
      hm = c.home-manager.users.${owner};
      checks = [
        (ex "test-chrome: chromium/google-chrome enabled for the owner" hm.programs.chromium.enable)
        (ex "test-chrome: VaapiVideoDecoder flag present"
          (lib.any (a: lib.hasInfix "VaapiVideoDecoder" a) hm.programs.chromium.commandLineArgs))
        (ex "test-chrome: CDP port for SSH-driven tests"
          (lib.any (a: lib.hasInfix "remote-debugging-port=9222" a) hm.programs.chromium.commandLineArgs))
        (ex "test-chrome: hyprland.conf autostarts chrome"
          (lib.hasInfix "exec-once = google-chrome" hm.xdg.configFile."hypr/hyprland.conf".text))
      ];
      failed = builtins.filter (e: !e.ok) checks;
    in
    if failed == [ ]
    then "test-chrome cut ${builtins.unsafeDiscardStringContext c.system.build.toplevel.drvPath}"
    else throw "desktop-matrix test-chrome failed: ${lib.concatMapStringsSep "; " (e: e.name) failed}";

  # THE REAL OPTIONS DESKTOP: compose the home layer (waverunner's bar/dock +
  # OPTIONS surfaces, hyprland.lua, Beam) onto a fixture — the same wiring the
  # golem-desktop attr uses — and force the full eval. Catches a home-layer /
  # leaf compose break on source, before a metal recut. (Heavier: pulls the
  # waverunner/waveview/Beam closures into eval.)
  realDesktop =
    let
      c = (mkMinimal (builtins.head rows).facts [
        fakeDisk
        desktop
        waverunner.nixosModules.notification-service
        ({ config, ... }: {
          home-manager.users.${config.golem.owner} = import ../../system/home/home.nix;
          home-manager.extraSpecialArgs = { inherit waverunner waveview; };
        })
      ]).config;
      owner = c.golem.owner;
      # The same desktop on a weak GPU (gpu/intel-legacy): effects go light.
      cLight = (mkMinimal (builtins.head rows).facts [
        fakeDisk
        desktop
        ../../system/Modular/gpu/intel-legacy.nix
        waverunner.nixosModules.notification-service
        ({ config, ... }: {
          home-manager.users.${config.golem.owner} = import ../../system/home/home.nix;
          home-manager.extraSpecialArgs = { inherit waverunner waveview; };
        })
      ]).config;
      luaOf = cfg: cfg.home-manager.users.${cfg.golem.owner}.xdg.configFile."hypr/hyprland.lua".text;
      lightBlock = "hl.config({ decoration = { blur = { enabled = false } } })";
      checks = [
        (ex "real desktop: full effects by default (no light block)"
          (c.golem.desktop.effects == "full" && !(lib.hasInfix lightBlock (luaOf c))))
        (ex "real desktop: a weak GPU (intel-legacy) gets light effects: compositor blur off"
          (cLight.golem.desktop.effects == "light" && lib.hasInfix lightBlock (luaOf cLight)))
        (ex "real desktop: waverunner (OPTIONS bar/dock) enabled for the owner"
          (c.home-manager.users.${owner}.programs.waverunner.enable or false))
        (ex "real desktop: still has the system compositor (hyprland + greetd)"
          (c.programs.hyprland.enable && c.services.greetd.enable))
        # The debloat (2026-09-29): Seam is the only browser and the only app
        # on the menubox. These fail the check if Chrome or the menubox
        # overrides come back or go missing.
        (ex "real desktop: no Chrome (Seam is the only browser)"
          (!(c.home-manager.users.${owner}.programs.chromium.enable or false)))
        (ex "real desktop: Seam is installed"
          (lib.any (p: (p.pname or "") == "seam" || lib.hasPrefix "seam" (p.name or ""))
            (c.environment.systemPackages ++ c.home-manager.users.${owner}.home.packages)))
        # Drag-to-install (2026-09-29, Brave on the thinkpad): the root helper
        # must be on the desktop, watching the owner's list, writing the
        # machine's own file — or every install fails without a word.
        (ex "real desktop: waverunner-apply installs (service + path watch)"
          ((c.systemd.services ? waverunner-apply)
           && (c.systemd.paths ? waverunner-apply)
           && lib.hasSuffix "/.config/waverunner/packages.list"
                c.systemd.paths.waverunner-apply.pathConfig.PathChanged))
        (ex "real desktop: rebuilds itself AS the desktop (flakeAttr), never golem-minimal"
          (c.golem.flakeAttr == "golem-desktop"))
        (ex "real desktop: installs land in hosts/target/apps.nix, not the dev box's list"
          (c.golem.appsFile == "hosts/target/apps.nix"))
        # The Mac keys ship in every Golem (2026-09-29): F3 Mission Control →
        # spread/overview, F4 Launchpad → the apps box, the keyboard-light
        # keys. hid_apple sends them on every classic-F-row MacBook.
        (ex "real desktop: the MacBook keys are bound (F3, F4, keyboard light)"
          (let lua = c.home-manager.users.${owner}.xdg.configFile."hypr/hyprland.lua".text; in
            lib.all (k: lib.hasInfix ''hl.bind("${k}"'' lua)
              [ "XF86LaunchA" "XF86LaunchB" "XF86KbdBrightnessUp" "XF86KbdBrightnessDown" ]))
        (ex "real desktop: the menubox hides the plumbing (foot, yazi, xterm…)"
          (lib.all (id: c.home-manager.users.${owner}.xdg.dataFile ? "applications/${id}.desktop")
            [ "foot" "yazi" "xterm" "nixos-manual" ]))
      ];
      failed = builtins.filter (e: !e.ok) checks;
    in
    if failed == [ ]
    then "real desktop ${builtins.unsafeDiscardStringContext c.system.build.toplevel.drvPath}"
    else throw "desktop-matrix real-desktop failed: ${lib.concatMapStringsSep "; " (e: e.name) failed}";

  report = (map runRow rows) ++ [ testChrome realDesktop ];
in
pkgs.runCommand "golem-desktop-matrix"
  { passAsFile = [ "report" ]; report = lib.concatStringsSep "\n" report; }
  ''
    cp "$reportPath" $out
    echo "desktop-matrix: ${toString (builtins.length rows)} desktop stages composed & asserted" >&2
  ''
