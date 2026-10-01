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
    # The owner's password hash never enters the (world-readable) store.
    (ex "the owner's password comes from a root-only file, never from the system source"
      (c.users.users.${c.golem.owner}.hashedPasswordFile == "/var/lib/golem/secrets/owner-password-hash"
        && c.users.users.${c.golem.owner}.hashedPassword == null
        && c.users.users.${c.golem.owner}.password == null))
    # P16: the desktop is a USER session (initial_session), never the greeter's.
    (ex "greetd autologs the owner's desktop once per boot (initial_session, class user)"
      (lib.hasInfix "uwsm start hyprland" (c.services.greetd.settings.initial_session.command or "")
        && (c.services.greetd.settings.initial_session.user or "") == c.golem.owner))
    (ex "greetd: uwsm's start chatter goes to the journal, not the console"
      (lib.hasInfix "systemd-cat -t uwsm uwsm start" c.services.greetd.settings.initial_session.command))
    (ex "greetd shows a real login after a logout (tuigreet), the same session behind it"
      (lib.hasInfix "tuigreet" c.services.greetd.settings.default_session.command
        && lib.hasInfix "uwsm start hyprland" c.services.greetd.settings.default_session.command
        && (c.services.greetd.settings.default_session.user or "greeter") != c.golem.owner))
    (ex "greetd does not restart itself (an initial_session would autologin again)"
      (!c.services.greetd.restart))
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
          services.options-notify.enable = true; # as the golem-desktop attr does (P8)
          home-manager.users.${config.golem.owner} = import ../../system/home/home.nix;
          home-manager.extraSpecialArgs = { inherit waverunner waveview; };
        })
      ]).config;
      owner = c.golem.owner;
      # The same desktop after the owner installed OBS from the dock (as the
      # generated hosts/target/apps.nix adds it): its fit rides along.
      cObs = (mkMinimal (builtins.head rows).facts [
        fakeDisk
        desktop
        waverunner.nixosModules.notification-service
        ({ config, pkgs, ... }: {
          services.options-notify.enable = true;
          home-manager.users.${config.golem.owner} = {
            imports = [ ../../system/home/home.nix ];
            home.packages = map lib.lowPrio [ pkgs.obs-studio ];
          };
          home-manager.extraSpecialArgs = { inherit waverunner waveview; };
        })
      ]).config;
      # The same desktop on a weak GPU (gpu/intel-legacy): effects go light.
      cLight = (mkMinimal (builtins.head rows).facts [
        fakeDisk
        desktop
        ../../system/Modular/gpu/intel-legacy.nix
        waverunner.nixosModules.notification-service
        ({ config, ... }: {
          services.options-notify.enable = true; # as the golem-desktop attr does (P8)
          home-manager.users.${config.golem.owner} = import ../../system/home/home.nix;
          home-manager.extraSpecialArgs = { inherit waverunner waveview; };
        })
      ]).config;
      # The dev box's shape (parity P1): the same home layer with its own
      # machine layer on top: live checkouts, no idle steps, a Lua tail.
      cDev = (mkMinimal (builtins.head rows).facts [
        fakeDisk
        desktop
        waverunner.nixosModules.notification-service
        ({ config, ... }: {
          services.options-notify.enable = true;
          home-manager.users.${config.golem.owner} = {
            imports = [ ../../system/home/home.nix ];
            golem.home.devCheckout = true;
            golem.home.idle.enable = false;
            golem.home.hyprlandExtra = "-- DEV-LAYER-TAIL";
            golem.home.menubox.hidePlumbing = false;
          };
          # waveview = null on purpose: a dev eval must never force it.
          home-manager.extraSpecialArgs = { inherit waverunner; waveview = null; };
        })
      ]).config;
      devHome = cDev.home-manager.users.${cDev.golem.owner};
      luaOf = cfg: cfg.home-manager.users.${cfg.golem.owner}.xdg.configFile."hypr/hyprland.lua".text;
      lightBlock = "hl.config({ decoration = { blur = { enabled = false } } })";
      dockCfgOf = cfg: cfg.home-manager.users.${cfg.golem.owner}.xdg.configFile."waverunner/config.toml".text;
      checks = [
        # Golem's patched Hyprland (desktop/hyprland-overlay.nix): the titlebar's
        # straight top edge needs square-top, and the waveview plugin must be
        # compiled against the very same Hyprland (struct layouts differ).
        (ex "real desktop: Hyprland carries the square-top titlebar patch"
          (lib.any (p: lib.hasSuffix "hyprland-window-square-top.patch" (toString p))
            (c.programs.hyprland.package.patches or [ ])))
        # A browser killed with a webapp open took the whole session down (P4).
        (ex "real desktop: golem-caffeine (stay awake) ships with its inhibitor unit"
          ((c.home-manager.users.${c.golem.owner}.systemd.user.services ? golem-caffeine)
            && lib.any (p: (p.name or "") == "golem-caffeine") c.home-manager.users.${c.golem.owner}.home.packages))
        # A systemd inhibitor does not stop hypridle (it reads Wayland and
        # D-Bus inhibits only): caffeine keeps the idle daemon itself off.
        (ex "caffeine: hypridle does not run while ~/.config/golem/caffeine exists"
          (c.home-manager.users.${c.golem.owner}.systemd.user.services.hypridle.Unit.ConditionPathExists
            == "!%h/.config/golem/caffeine"))
        # ...and it never blocks sleep itself: a low battery must still suspend.
        (ex "caffeine: holds only the lid switch, never sleep (the low-battery suspend must go through)"
          (let es = c.home-manager.users.${c.golem.owner}.systemd.user.services.golem-caffeine.Service.ExecStart; start = if lib.isList es then lib.concatStringsSep " " es else es; in
            lib.hasInfix "--what=handle-lid-switch " start && !(lib.hasInfix "sleep" (lib.head (lib.match ".*--what=([^ ]*).*" start)))))
        (ex "real desktop: a scripted resize keeps a floating window's own min/max"
          (lib.any (p: lib.hasSuffix "hyprland-floating-resize-limits.patch" (toString p))
            (c.programs.hyprland.package.patches or [ ])))
        (ex "real desktop: Hyprland's exit survives a live screen capture (P6 stack 1)"
          (lib.any (p: lib.hasSuffix "hyprland-screenshare-exit.patch" (toString p))
            (c.programs.hyprland.package.patches or [ ])))
        # A live switch must never stop the uwsm session skeleton (2026-09-07).
        (ex "real desktop: the uwsm session units carry X-RestartIfChanged=false"
          (lib.all (u: lib.hasInfix "X-RestartIfChanged=false" (c.systemd.user.units.${u}.text or ""))
            [ "wayland-session-bindpid@.service" "wayland-wm@.service" "wayland-wm-env@.service" "wayland-session-waitenv.service" "xdg-desktop-portal-hyprland.service" ]))
        (ex "real desktop: Hyprland survives a client dying with its subsurfaces mapped"
          (lib.any (p: lib.hasSuffix "hyprland-subsurface-orphan.patch" (toString p))
            (c.programs.hyprland.package.patches or [ ])))
        (ex "real desktop: waveview is built against the desktop's own Hyprland (ABI)"
          (lib.any (d: (d.drvPath or "") == c.programs.hyprland.package.drvPath)
            (waveview.buildInputs ++ waveview.nativeBuildInputs)))
        # Deep debug 2026-09-30 (parity P8–P12): what an install must carry.
        (ex "P8: the notification server is enabled and its user unit exists"
          (c.services.options-notify.enable && (c.systemd.user.services ? options-notify)))
        (ex "P9: the file-opening apps ship (Nautilus, Loupe, Papers, Text Editor, File Roller)"
          (lib.all (n: lib.any (p: (p.pname or "") == n) c.environment.systemPackages)
            [ "nautilus" "loupe" "papers" "gnome-text-editor" "file-roller" ]))
        (ex "P9: no input method rides in with the apps (fcitx5 is desktop/ime.nix's call)"
          (!c.i18n.inputMethod.enable))
        (ex "P9: the session plumbing (gvfs, dconf, udisks2) is on"
          (c.services.gvfs.enable && c.programs.dconf.enable && c.services.udisks2.enable))
        (ex "the placeholder wallpaper daemon cannot leave a crash dump when a session ends"
          (lib.hasInfix ''hl.exec_cmd("prlimit --core=1 awww-daemon")'' (luaOf c)))
        (ex "P9: TERMINAL and EDITOR reach every app (hyprland.lua env)"
          (lib.all (k: lib.hasInfix ''hl.env("${k}"'' (luaOf c)) [ "TERMINAL" "EDITOR" ]))
        (ex "P10: the seed has an upstream and golem-seed-adopt is on the PATH"
          (c.golem.upstream.url != "" && lib.any (p: (p.pname or p.name or "") == "golem-seed-adopt") c.environment.systemPackages))
        (ex "P11: idle → lock, screen off, suspend (hypridle + hyprlock + its PAM service)"
          (c.home-manager.users.${owner}.services.hypridle.enable
           && c.home-manager.users.${owner}.programs.hyprlock.enable
           && (c.security.pam.services ? hyprlock)))
        (ex "P11: the screen's power goes by action (a bare dpms string toggles), and input wakes it"
          (!(lib.hasInfix "dsp.dpms(\"" (builtins.toJSON c.home-manager.users.${owner}.services.hypridle.settings))
           && lib.hasInfix "golem-dpms" (builtins.toJSON c.home-manager.users.${owner}.services.hypridle.settings)
           && lib.hasInfix "key_press_enables_dpms   = true" (luaOf c)))
        (ex "P11: the lock screen is the compositor's child, and a dead one can be replaced"
          (let s = builtins.toJSON c.home-manager.users.${owner}.services.hypridle.settings; in
           lib.hasInfix "golem-lock" s && !(lib.hasInfix "|| hyprlock" s)
           && lib.hasInfix "allow_session_lock_restore = true" (luaOf c)
           && lib.hasInfix "hyprlock'\"), { locked = true })" (luaOf c)))
        (ex "P11: the lock never goes through loginctl (a greeter-class session refuses it)"
          (!(lib.hasInfix "lock-session" (builtins.toJSON c.home-manager.users.${owner}.services.hypridle.settings))
           && !(lib.hasInfix "lock-session" (luaOf c))))
        (ex "P12: the owner's bash carries the prompt, EDITOR and the OPTIONS bridge"
          (c.home-manager.users.${owner}.programs.bash.enable
           && lib.hasInfix "bridge.sock" c.home-manager.users.${owner}.programs.bash.initExtra))
        # Found by the P1 diff (2026-09-30): only the dev box had these.
        (ex "the sunset option's hyprsunset ships in the home layer"
          (lib.any (p: (p.pname or "") == "hyprsunset") c.home-manager.users.${owner}.home.packages))
        (ex "an Intel iGPU can report its load (perf_event_paranoid 0 on intel leaves)"
          ((cLight.boot.kernel.sysctl."kernel.perf_event_paranoid" or null) == 0))
        (ex "trusted Bluetooth devices reconnect after hibernate"
          (c.systemd.services ? bluetooth-reconnect-after-hibernate))
        # Webapps run in Seam (2026-09-30, parity P4): the catalog is seeded on an
        # install again, Seam's chrome script carries the -golem-app handler, and the
        # Chrome-only extension wiring is gone.
        (ex "webapps: the catalog is seeded and Seam handles -golem-app"
          ((c.home-manager.users.${owner}.home.activation ? seedWebappsList)
           # contains, without a regex: lib.hasInfix's ".*x.*" match overflows the
           # regex stack on the 150 KB chrome script
           && (let has = n: f: builtins.replaceStrings [ n ] [ "" ] f != f; in
               has "b-golem-app" (builtins.readFile ../../seam/golem-chrome.js)
               && has "golem-app" (builtins.readFile ../../seam/userChrome.css))))
        (ex "webapps: no Chrome extension drop-in on the dock"
          (!(c.home-manager.users.${owner}.xdg.configFile ? "systemd/user/waverunner.service.d/webapp-extension.conf")))
        # P1: the dev box runs this same home layer in its dev shape.
        (ex "P1 dev shape: live checkouts kept, no waverunner unit, never a store rewrite"
          (lib.hasInfix ''hl.exec_cmd("/home/max/launcher/waverunner-dev")'' (luaOf cDev)
           && lib.hasInfix "/home/max/waveview/result/lib/libwaveview.so" (luaOf cDev)
           && !(devHome.programs.waverunner.enable or false)
           && !(devHome.xdg.configFile ? "systemd/user/waverunner.service.d/webapp-extension.conf")))
        (ex "P1 dev shape: no idle steps, the lock screen stays; the machine's Lua comes after Golem's, right before the live settings"
          (!devHome.services.hypridle.enable && devHome.programs.hyprlock.enable
           && lib.hasInfix "-- DEV-LAYER-TAIL\n---- LIVE SETTINGS" (luaOf cDev)))
        # Fits (system/home/fits.nix): an app the owner installs works the
        # moment it lands. OBS: a first-run scene that already holds the
        # screen-capture source, in OBS's relative form (any canvas), with
        # desktop audio and the microphone — and nothing at all when OBS is
        # not installed.
        (ex "fits: OBS installed by the owner gets its first-run scene; no OBS, no fit"
          (let
            hm = cfg: cfg.home-manager.users.${cfg.golem.owner};
            seed = builtins.fromJSON (builtins.readFile ../home/fits/obs-studio/Untitled.json);
            scene = lib.findFirst (s: s.id == "scene") { settings.items = [ { } ]; } seed.sources;
            item = builtins.head scene.settings.items;
            script = (hm cObs).home.activation.fitObsStudio.data;
          in
          (hm cObs).home.activation ? fitObsStudio
          && !((hm c).home.activation ? fitObsStudio)
          && lib.hasInfix "golem/fits/obs-studio" script
          && lib.hasInfix ".before-golem" script
          && seed.version == 2
          && lib.any (s: s.id == "pipewire-screen-capture-source") seed.sources
          && seed ? DesktopAudioDevice1 && seed ? AuxAudioDevice1
          && item ? pos_rel && item ? scale_rel && item ? scale_ref && item ? bounds_rel
          && item.bounds_type == 2))
        (ex "ups ships on the desktop: the CLI, rootless podman, ~/.local/bin on PATH, the built-in recipes"
          (lib.any (p: (p.name or "") == "ups") c.environment.systemPackages
            && c.virtualisation.podman.enable && c.environment.localBinInPath
            && c.environment.etc ? "ups/recipes.d/opencode.sh"))
        # The Install section's list is Golem's checked one, made for the
        # nixpkgs this flake pins (refresh.sh after every nixpkgs bump).
        (ex "install list: Golem's checked package index, made for the pinned nixpkgs"
          (let
            lock = builtins.fromJSON (builtins.readFile ../../flake.lock);
            made = lib.removeSuffix "\n" (builtins.readFile ../home/package-index.rev);
            idx = c.home-manager.users.${owner}.programs.waverunner.packageIndex;
          in
          made == lock.nodes.nixpkgs.locked.rev
          && lib.hasPrefix "golem-package-index" (idx.name or "")))
        # Live settings (the control panel's scale and resolution): the dock
        # saves the owner's choices as ~/.config/golem/settings.lua and the
        # compositor runs that file last, guarded, never watched.
        (ex "live settings: hyprland.lua ends by running the owner's settings.lua, guarded (every tier, the dev shape too)"
          (lib.all (cfg:
            let
              lua = luaOf cfg;
              # Only the file's end is searched (a split over the whole
              # config is a regex over tens of kilobytes).
              end = builtins.substring (builtins.stringLength lua - 2000) 2000 lua;
              tail = lib.last (lib.splitString "---- LIVE SETTINGS" end);
            in
            lib.hasInfix "---- LIVE SETTINGS" end
            && lib.hasInfix ''"/golem/settings.lua"'' tail
            && lib.hasInfix "pcall(dofile, path)" tail
            && lib.hasSuffix "end\nend\n" tail
            && !(lib.hasInfix "require(" tail)
            && !(lib.hasInfix "hl.config(" tail))
            [ c cLight cDev ]))
        (ex "P1: the menubox debloat is on for installs and off in the dev shape"
          ((c.home-manager.users.${owner}.xdg.dataFile ? "applications/xterm.desktop")
           && !(devHome.xdg.dataFile ? "applications/xterm.desktop")))
        (ex "P1 install shape: no live-checkout path survives the rewrite"
          (!(lib.hasInfix "/home/max/launcher" (luaOf c)) && !(lib.hasInfix "/home/max/waveview" (luaOf c))))
        (ex "real desktop: full effects by default (no light block)"
          (c.golem.desktop.effects == "full" && !(lib.hasInfix lightBlock (luaOf c))))
        (ex "real desktop: a weak GPU (intel-legacy) gets light effects: compositor blur off"
          (cLight.golem.desktop.effects == "light" && lib.hasInfix lightBlock (luaOf cLight)))
        # No blur behind the shell → denser glass (90%), and only there.
        (ex "light effects: the dock's glass is denser (no blur behind it); full effects keep the default"
          (lib.hasInfix ''background = "#050709e6"'' (dockCfgOf cLight)
            && !(lib.hasInfix "background =" (dockCfgOf c))))
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
