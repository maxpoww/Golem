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
      (lib.hasInfix "uwsm start -g -1 hyprland" (c.services.greetd.settings.initial_session.command or "")
        && (c.services.greetd.settings.initial_session.user or "") == c.golem.owner))
    (ex "greetd: uwsm's start chatter goes to the journal, not the console"
      (lib.hasInfix "systemd-cat -t uwsm uwsm start" c.services.greetd.settings.initial_session.command))
    (ex "greetd shows a real login after a logout (tuigreet), the same session behind it"
      (lib.hasInfix "tuigreet" c.services.greetd.settings.default_session.command
        && lib.hasInfix "uwsm start -g -1 hyprland" c.services.greetd.settings.default_session.command
        && (c.services.greetd.settings.default_session.user or "greeter") != c.golem.owner))
    (ex "greetd does not restart itself (an initial_session would autologin again)"
      (!c.services.greetd.restart))
    (ex "uinput on (virtual gamepad)" c.hardware.uinput.enable)
    # Apps keep their passwords somewhere (desktop/keyring): the Secret
    # Service, opened by the password typed at the login (the lock screen).
    (ex "keyring: the lock screen's PAM starts or unlocks it; the autologin's never does"
      (c.services.gnome.gnome-keyring.enable
        && c.security.pam.services.hyprlock.enableGnomeKeyring
        && (c.security.pam.services.hyprlock.rules.auth.gnome_keyring.settings.auto_start or false)
        # (only a password pam_unix accepted reaches it: the check first, requisite)
        && (let auth = lib.filter (l: lib.hasPrefix "auth " l)
                  (lib.splitString "\n" c.security.pam.services.hyprlock.text); in
            lib.length auth == 2
            && lib.hasPrefix "auth requisite " (lib.elemAt auth 0) && lib.hasInfix "/pam_unix.so" (lib.elemAt auth 0)
            && lib.hasPrefix "auth optional " (lib.elemAt auth 1) && lib.hasInfix "pam_gnome_keyring.so auto_start" (lib.elemAt auth 1))
        && !c.security.pam.services.greetd.enableGnomeKeyring
        && !c.services.gnome.gcr-ssh-agent.enable
        # (nothing starts it before that password: its autostart entries hidden)
        && lib.all (f: lib.hasInfix "Hidden=true" (c.environment.etc."xdg/autostart/${f}".text or ""))
             [ "gnome-keyring-pkcs11.desktop" "gnome-keyring-secrets.desktop" ]))
    (ex "xserver on for XWayland xkb" c.services.xserver.enable)
    (ex "owner joined uinput + adbusers at the desktop stage"
      (lib.elem "uinput" c.users.users.${c.golem.owner}.extraGroups
        && lib.elem "adbusers" c.users.users.${c.golem.owner}.extraGroups))
    (ex "the owner is not in the input group: no program reads every keyboard directly (2026-11-12)"
      (!lib.elem "input" c.users.users.${c.golem.owner}.extraGroups))
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
    (ex "home-manager activates only when something changed (desktop/home-boot: no 13 s re-link on every HDD boot)" (lib.hasInfix "golem-home-needs-activation" (c.systemd.services."home-manager-${c.golem.owner}".serviceConfig.ExecCondition or "")))
    (ex "an update waiting 2+ days for a restart is announced (desktop/update-notice: autoupdate stages for the next boot; laptops that only sleep never boot)" (c.systemd.user.timers ? golem-update-notice && c.systemd.user.services ? golem-update-notice))
    (ex "a desktop crash loop goes back to the previous version, never Hyprland's safe mode (desktop/crash-recovery: last-resort config, golem-rollback, polkit for the owner)" (c.environment.etc ? "golem/last-resort.lua" && c.systemd.services ? golem-rollback && lib.hasInfix "golem-rollback.service" c.security.polkit.extraConfig))
    (ex "going back because the owner asked is its own unit, with its own words after (desktop/crash-recovery: golem-go-back runs golem-rollback asked; the owner may start it)" (c.systemd.services ? golem-go-back && lib.hasSuffix "golem-rollback asked" c.systemd.services.golem-go-back.serviceConfig.ExecStart && lib.hasInfix "golem-go-back.service" c.security.polkit.extraConfig))
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

  # APP SETUP (2026-10-13; since 2026-11-19 the program setup of
  # system/modules, whose own matrix is modules/matrix.nix): a clean machine carries
  # none of it, and a machine with the programs installed has the system each
  # needs — in the one evaluation that installs them.
  appSetup =
    let
      facts = (builtins.head rows).facts;
      clean = (mkMinimal facts [ fakeDisk desktop ]).config;
      c = (mkMinimal facts [
        fakeDisk
        desktop
        ({ config, pkgs, ... }: {
          # As hosts/target/apps.nix does for what the dock installed.
          home-manager.users.${config.golem.owner}.home.packages =
            map lib.lowPrio [ pkgs.steam pkgs.docker pkgs.virt-manager pkgs.localsend pkgs.ollama pkgs.syncthing
                              pkgs.kdePackages.kdeconnect-kde pkgs.teamviewer pkgs.noisetorch pkgs.retroarch ];
        })
      ]).config;
      groups = cfg: cfg.users.users.${cfg.golem.owner}.extraGroups;
      checks = [
        (ex "app-setup: a clean machine has no Steam, Docker, libvirtd or Ollama"
          (!clean.programs.steam.enable && !clean.virtualisation.docker.enable
           && !clean.virtualisation.libvirtd.enable && !clean.services.ollama.enable))
        (ex "app-setup: a clean machine opens no sharing port and gives no extra group"
          (!(lib.elem 53317 clean.networking.firewall.allowedTCPPorts)
           && !(lib.elem "docker" (groups clean)) && !(lib.elem "libvirtd" (groups clean))))
        (ex "app-setup: Steam installed → the Steam system side, 32-bit graphics, GameMode"
          (c.programs.steam.enable && c.hardware.graphics.enable32Bit && c.programs.gamemode.enable
           && c.hardware.steam-hardware.enable))
        (ex "app-setup: Docker installed → rootless Docker (the owner's own daemon, DOCKER_HOST), no system daemon"
          (c.virtualisation.docker.rootless.enable && c.virtualisation.docker.rootless.setSocketVariable
           && !c.virtualisation.docker.enable))
        (ex "app-setup: virt-manager installed → libvirtd, virt-manager on the owner's own session"
          (c.virtualisation.libvirtd.enable && c.programs.virt-manager.enable
           && lib.hasInfix "qemu:///session" (builtins.toJSON
                c.home-manager.users.${c.golem.owner}.dconf.settings."org/virt-manager/virt-manager/connections".uris)))
        # The security study's road 1 (2026-11-12): the app list is written
        # without a password, so no app may put the owner in a group that is
        # root. Everything installed at once, and still none of them.
        (ex "app-setup: no installed app puts the owner in a root-equivalent group"
          (!(lib.any (g: lib.elem g (groups c)) [ "docker" "libvirtd" "lxd" "incus-admin" "disk" "shadow" ])))
        (ex "app-setup: LocalSend and Syncthing installed → their ports are open"
          (lib.elem 53317 c.networking.firewall.allowedTCPPorts && lib.elem 22000 c.networking.firewall.allowedTCPPorts
           && lib.elem 21027 c.networking.firewall.allowedUDPPorts))
        (ex "app-setup: Ollama installed → its service" c.services.ollama.enable)
        (ex "app-setup: KDE Connect installed → 1714–1764 open, both ways; a clean machine keeps them shut"
          (lib.elem { from = 1714; to = 1764; } c.networking.firewall.allowedTCPPortRanges
           && lib.elem { from = 1714; to = 1764; } c.networking.firewall.allowedUDPPortRanges
           && clean.networking.firewall.allowedTCPPortRanges == [ ]))
        (ex "app-setup: TeamViewer → its daemon; NoiseTorch → its capability wrapper; an emulator → the controllers' rules"
          (c.services.teamviewer.enable && c.programs.noisetorch.enable && c.hardware.steam-hardware.enable
           && !clean.services.teamviewer.enable && !clean.programs.noisetorch.enable))
        (ex "app-setup: the base groups are still there (merged, not replaced)"
          (lib.elem "wheel" (groups c) && lib.elem "uinput" (groups c)))
      ];
      failed = builtins.filter (e: !e.ok) checks;
    in
    if failed == [ ]
    then "app-setup ${toString (builtins.length checks)} checks"
    else throw "desktop-matrix app-setup failed: ${lib.concatMapStringsSep "; " (e: e.name) failed}";

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
            home.packages = map lib.lowPrio [ pkgs.obs-studio pkgs.btop pkgs.mpv ];
          };
          home-manager.extraSpecialArgs = { inherit waverunner waveview; };
        })
      ]).config;
      # The same desktop with a post-install answers file that has code in it
      # (../postinstall-hostile.fixture), as a program running as the owner
      # could leave it.
      cHostile = (mkMinimal (builtins.head rows).facts [
        fakeDisk
        desktop
        waverunner.nixosModules.notification-service
        ({ config, ... }: {
          services.options-notify.enable = true;
          home-manager.users.${config.golem.owner} = import ../../system/home/home.nix;
          home-manager.extraSpecialArgs = { inherit waverunner waveview; };
          golem.postinstall.generatedFile = ../postinstall-hostile.fixture;
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
      # THE DEFAULT APPS name apps that are there (2026-10-28): after the
      # debloat four defaults still named GNOME Disks, Calendar, Contacts and
      # Maps. Every desktop file the home layer's table names is shipped by a
      # package this desktop installs (below), and is looked for IN that
      # package when the matrix builds (an upstream rename fails too). A new
      # default needs its app here. The dock writes golem-files.desktop
      # itself, at its first start.
      hm = c.home-manager.users.${owner};
      shippedBy = {
        "org.gnome.Nautilus.desktop" = "nautilus";
        "org.gnome.TextEditor.desktop" = "gnome-text-editor";
        "org.gnome.Loupe.desktop" = "loupe";
        "org.gnome.Papers.desktop" = "papers";
        "org.gnome.FileRoller.desktop" = "file-roller";
        "mpv.desktop" = "mpv";
        "seam.desktop" = "seam";
      };
      writtenByTheDock = [ "golem-files.desktop" ];
      installed = c.environment.systemPackages ++ hm.home.packages;
      # (By its name; else the one whose name it begins — mpv with its scripts.)
      installedNamed = n:
        let exact = lib.findFirst (p: lib.getName p == n) null installed; in
        if exact != null then exact else lib.findFirst (p: lib.hasPrefix "${n}-" (lib.getName p)) null installed;
      defaultIds = lib.subtractLists writtenByTheDock
        (lib.unique (lib.concatMap lib.toList (lib.attrValues hm.xdg.mimeApps.defaultApplications)));
      unshipped = builtins.filter (id: !(shippedBy ? ${id}) || installedNamed shippedBy.${id} == null) defaultIds;
      defaultFiles = lib.optionalString (unshipped == [ ])
        (lib.concatMapStringsSep "\n" (id: "desktop-file ${id} ${installedNamed shippedBy.${id}}/share/applications/${id}") defaultIds);
      # THE HYPRLAND CONFIGURATION AS DEPLOYED (system/home/hypr): Golem's
      # modules are the same text on every machine (`staticLua`, read from the
      # tree), what differs is the generated table of facts (`factsOf`) and
      # the machine's own tail (`extraOf`). `luaOf` is all of it as one text,
      # the entry last (it is what runs last).
      hyprDir = ../home/hypr;
      hyprEntry = builtins.readFile (hyprDir + "/hyprland.lua");
      staticLua = lib.concatMapStrings builtins.readFile
        (lib.filter (p: lib.hasSuffix ".lua" (toString p)) (lib.filesystem.listFilesRecursive (hyprDir + "/golem")));
      # (The facts are an option of the home layer, read here by evaluation:
      # nothing is built. On a machine they are golem/machine.lua in the one
      # store folder ~/.config/hypr/hyprland.lua points at.)
      hyprOf = cfg: cfg.home-manager.users.${cfg.golem.owner}.golem.home;
      factsOf = cfg: (hyprOf cfg).hyprFacts;
      extraOf = cfg: (hyprOf cfg).hyprlandExtra;
      luaOf = cfg: staticLua + factsOf cfg + extraOf cfg + hyprEntry;
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
          (lib.hasInfix ''hl.exec_cmd("prlimit --core=1 awww-daemon --no-cache")'' (luaOf c)))
        (ex "no second wallpaper chooser: waypaper is gone, the session starts on the bare grey"
          (!(lib.hasInfix ''hl.exec_cmd("waypaper'' (luaOf c)) && lib.hasInfix "background_color = 0xff3a3a3c" (luaOf c)))
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
           && lib.hasInfix ''hl.dsp.exec_cmd("golem-lock-screen"), { locked = true })'' (luaOf c)))
        (ex "F3.17: the portal is said out loud: Hyprland's then GTK's, nobody for Secret"
          (c.xdg.portal.enable
           # (the option's type joins a list into the file's own "a;b")
           && c.xdg.portal.config.hyprland.default == "hyprland;gtk"
           && c.xdg.portal.config.hyprland."org.freedesktop.impl.portal.Secret" == "none"
           && lib.any (p: lib.hasPrefix "xdg-desktop-portal-gtk" (p.name or "")) c.xdg.portal.extraPortals
           && lib.any (p: lib.hasPrefix "xdg-desktop-portal-hyprland" (p.name or "")) c.xdg.portal.extraPortals))
        (ex "the login: the lock screen is the first thing the desktop starts, and it opens the keyring"
          (let
            lockScreen = lib.findFirst (p: (p.name or "") == "golem-lock-screen")
              null c.home-manager.users.${owner}.home.packages;
          in
           lib.hasInfix "hl.on(\"hyprland.start\", function()\n-- The lock screen first: it is the login (home/idle.nix, golem-lock-screen).\nhl.exec_cmd(\"golem-lock-screen --login\")" (luaOf c)
           && lockScreen != null
           && !(lib.hasInfix ''[ -n "$returning" ] || exit 0'' (lockScreen.text or ""))
           && lib.hasInfix "gnome-keyring-daemon --start --components=pkcs11,secrets" (lockScreen.text or "")))
        (ex "P11: the lock never goes through loginctl (a greeter-class session refuses it)"
          (!(lib.hasInfix "lock-session" (builtins.toJSON c.home-manager.users.${owner}.services.hypridle.settings))
           && !(lib.hasInfix "lock-session" (luaOf c))))
        (ex "P12: the owner's bash carries the prompt, EDITOR and the OPTIONS bridge"
          (c.home-manager.users.${owner}.programs.bash.enable
           && lib.hasInfix "bridge.sock" c.home-manager.users.${owner}.programs.bash.initExtra))
        # Found by the P1 diff (2026-09-30): only the dev box had these.
        (ex "the sunset option's hyprsunset ships in the home layer"
          (lib.any (p: (p.pname or "") == "hyprsunset") c.home-manager.users.${owner}.home.packages))
        # Print Screen (2026-11-16): the three keys run a command that ships.
        (ex "the screenshot keys run golem-screenshot, and it ships in the home layer"
          (lib.any (p: (p.name or "") == "golem-screenshot") c.home-manager.users.${owner}.home.packages
           && lib.all (m: lib.hasInfix "golem-screenshot ${m}\")" (luaOf c)) [ "screen" "window" ]))
        # The capture tool (2026-11-16): Print tells the dock both ends of
        # the press (a tap is a shot, a hold records), by the dock's command
        # as it is on an install, and is still a shot of the screen where the
        # dock does not answer; the text reader ships.
        (ex "Print tells the dock its press and its release, falls back to a screen shot, and tesseract ships"
          (lib.hasInfix "ctl = \"waverunner-ctl\"," (factsOf c)
           && lib.hasInfix "exec_cmd(\"sh -c '\" .. ctl .. \" capture press || golem-screenshot screen'\")" staticLua
           && lib.hasInfix "exec_cmd(ctl .. \" capture release\"), { release = true" staticLua
           && lib.hasInfix "exec_cmd(\"sh -c '\" .. ctl .. \" capture shot || golem-screenshot screen'\")" staticLua
           && lib.any (p: (p.pname or "") == "tesseract") c.home-manager.users.${owner}.home.packages))
        (ex "what each update changed is written by hand and carried by the system"
          (c.environment.etc ? "golem/whats-new.json"))
        (ex "F3.3: Ctrl+Print asks the dock to record, and the recorder ships in the home layer"
          (lib.hasInfix "ctl .. \" record\")" staticLua
           && lib.any (p: (p.pname or "") == "wf-recorder") c.home-manager.users.${owner}.home.packages))
        # The control panel's Default apps (2026-10-13): the owner's file is theirs.
        (ex "the owner's default-apps file is not a link of ours, and Golem's defaults ship below it"
          (!(c.home-manager.users.${owner}.xdg.configFile."mimeapps.list".enable)
           && c.home-manager.users.${owner}.xdg.dataFile ? "applications/mimeapps.list"))
        (ex "every default app is an app this desktop installs (not installed: ${lib.concatStringsSep ", " unshipped})"
          (unshipped == [ ]))
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
          (lib.hasInfix ''dock = "/home/max/launcher/waverunner-dev",'' (factsOf cDev)
           && lib.hasInfix ''plugin = "/home/max/waveview/result/lib/libwaveview.so",'' (factsOf cDev)
           && lib.hasInfix ''ctl = "/home/max/launcher/target/debug/waverunner-ctl",'' (factsOf cDev)
           && !(devHome.programs.waverunner.enable or false)
           && !(devHome.xdg.configFile ? "systemd/user/waverunner.service.d/webapp-extension.conf")))
        (ex "P1 dev shape: no idle steps, the lock screen stays; the machine's Lua comes after Golem's, right before the live settings"
          (!devHome.services.hypridle.enable && devHome.programs.hyprlock.enable
           && lib.hasInfix "-- DEV-LAYER-TAIL" (extraOf cDev)
           && (let around = lib.splitString "pcall(require, \"golem.extra\")" hyprEntry; in
               builtins.length around == 2
               && lib.hasInfix "require(\"golem.lab\")" (builtins.elemAt around 0)
               && !(lib.hasInfix "require(\"golem." (builtins.elemAt around 1))
               && lib.hasInfix "---- LIVE SETTINGS" (builtins.elemAt around 1))))
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
        (ex "live settings: hyprland.lua (the entry) ends by running the owner's settings.lua, guarded (every tier, the dev shape too)"
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
        (ex "menubox: what the owner installed is not hidden, what ships with Golem is"
          (let
            clean = c.home-manager.users.${owner}.xdg.dataFile;
            picked = cObs.home-manager.users.${cObs.golem.owner}.xdg.dataFile;
            on = files: id: files ? "applications/${id}.desktop";
          in
            lib.all (on clean) [ "btop" "mpv" "umpv" "xterm" "foot" ]
            && !lib.any (on picked) [ "btop" "mpv" "umpv" ]
            && lib.all (on picked) [ "xterm" "foot" ]))
        (ex "P1: the menubox debloat is on for installs and off in the dev shape"
          ((c.home-manager.users.${owner}.xdg.dataFile ? "applications/xterm.desktop")
           && !(devHome.xdg.dataFile ? "applications/xterm.desktop")))
        (ex "P1 install shape: no live-checkout path in anything deployed"
          (!(lib.hasInfix "/home/max/launcher" (luaOf c)) && !(lib.hasInfix "/home/max/waveview" (luaOf c))))
        (ex "real desktop: full effects by default (no light block)"
          (c.golem.desktop.effects == "full" && lib.hasInfix ''effects = "full",'' (factsOf c)))
        (ex "real desktop: a weak GPU (intel-legacy) gets light effects: compositor blur off"
          (cLight.golem.desktop.effects == "light" && lib.hasInfix ''effects = "light",'' (factsOf cLight)
           && lib.hasInfix ("if M.effects == \"light\" then\n    " + lightBlock) staticLua))
        # No blur behind the shell → denser glass (90%), and only there.
        (ex "light effects: the dock's glass is denser (no blur behind it); full effects keep the default"
          (lib.hasInfix ''background = "#050709e6"'' (dockCfgOf cLight)
            && lib.hasInfix "open_opacity = 0.95" (dockCfgOf cLight)
            && !(lib.hasInfix "background =" (dockCfgOf c))
            && !(lib.hasInfix "open_opacity" (dockCfgOf c))))
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
          (let lua = luaOf c; in
            lib.all (k: lib.hasInfix ''hl.bind("${k}"'' lua)
              [ "XF86LaunchA" "XF86LaunchB" "XF86KbdBrightnessUp" "XF86KbdBrightnessDown" ]))
        # The power key (2026-11-03): short = the banner's pills, long = off.
        (ex "real desktop: the power key's short press is the banner's, a long one powers off"
          (let lua = luaOf c; in
            lib.hasInfix ''hl.bind("XF86PowerOff", hl.dsp.exec_cmd(ctl .. " power")'' lua
            && lib.hasInfix ''ctl = "waverunner-ctl",'' (factsOf c)
            && c.services.logind.settings.Login.HandlePowerKey == "ignore"
            && c.services.logind.settings.Login.HandlePowerKeyLongPress == "poweroff"
            # the kernel's tiny driver asks for the pills too, never a poweroff
            && lib.hasInfix "tiny_power_button power_signal=28" c.boot.extraModprobeConfig
            && lib.elem "golem-power-key.service" c.systemd.targets.kbrequest.wants))
        (ex "real desktop: a desktop that comes back after a crash comes back locked (2026-11-12)"
          (let
            lua = luaOf c;
            lockScreen = lib.findFirst (p: (p.name or "") == "golem-lock-screen")
              null c.home-manager.users.${owner}.home.packages;
          in
            lib.hasInfix ''hl.exec_cmd("golem-lock-screen --login")'' lua
            && lockScreen != null
            # the second start of a boot is told from the first by a marker
            && lib.hasInfix ''[ -e "$run/desktop-started" ] && returning=1'' (lockScreen.text or "")))
        (ex "F2.3: what the install left to the owner is asked at the desktop and applied by a rebuild"
          (c.home-manager.users.${owner}.systemd.user.services ? golem-postinstall-ask
           && c.systemd.paths ? golem-postinstall-apply
           && c.systemd.services ? golem-postinstall-apply
           && lib.any (p: (p.name or "") == "golem-postinstall-apply") c.environment.systemPackages))
        # The answers file sits in the owner's checkout, outside the seal.
        # Imported as a module (F2.3's first cut, 17-Nov) it let any program
        # running as the owner write code root's next build ran; it is read
        # as data now, and this holds it.
        (ex "F2.3: an answers file with code in it gives its answer, and nothing else"
          (cHostile.golem.postinstall.answers == { "gpu2-failing-action" = "off"; }
           && !(cHostile.environment.etc ? "golem-planted")
           && !(lib.elem "ssh-ed25519 AAAAplanted" cHostile.users.users.root.openssh.authorizedKeys.keys)
           && cHostile.security.sudo.wheelNeedsPassword == c.security.sudo.wheelNeedsPassword))
        (ex "real desktop: the menubox hides the plumbing (foot, yazi, xterm…)"
          (lib.all (id: c.home-manager.users.${owner}.xdg.dataFile ? "applications/${id}.desktop")
            [ "foot" "yazi" "xterm" "nixos-manual" ]))
      ];
      failed = builtins.filter (e: !e.ok) checks;
    in
    if failed == [ ]
    then "real desktop ${builtins.unsafeDiscardStringContext c.system.build.toplevel.drvPath}\n${defaultFiles}"
    else throw "desktop-matrix real-desktop failed: ${lib.concatMapStringsSep "; " (e: e.name) failed}";

  report = (map runRow rows) ++ [ testChrome appSetup realDesktop ];
in
pkgs.runCommand "golem-desktop-matrix"
  { passAsFile = [ "report" ]; report = lib.concatStringsSep "\n" report; }
  ''
    # Each default app's desktop file, in the package that ships it.
    missing=0
    while read -r _ id file; do
      [ -e "$file" ] || { echo "desktop-matrix: the default app $id is not in its package ($file)" >&2; missing=1; }
    done < <(grep '^desktop-file ' "$reportPath")
    [ "$missing" = 0 ]
    cp "$reportPath" $out
    echo "desktop-matrix: ${toString (builtins.length rows)} desktop stages composed & asserted" >&2
  ''
