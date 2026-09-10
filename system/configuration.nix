# Golem core — everything common to every Golem machine.
# Ported from /etc/nixos/configuration.nix; hardware (nvidia, disks) lives
# in hosts/, home config in ./home/, wired up by flake.nix.
{ config, pkgs, lib, ... }:

{
  imports = [
    ./audio.nix
    ./bluetooth.nix
    ./golem-apps.nix
    ./hardware.nix
    # The hardware module library (GolemInstall.md §5): one family each,
    # permanently imported, internally mkIf-gated on golem.hardware facts.
    # Families too small to split yet live in hardware.nix itself.
    ./hardware/broadcom-wifi.nix
    ./hardware/fingerprint.nix
    ./hardware/gpu-nvidia.nix
    ./hardware/gpu-second.nix
    ./hardware/memory.nix
    ./hardware/power-laptop.nix
    ./hardware/storage.nix
    ./hardware/virt-guest.nix
    ./hardware-detect.nix
    ./hardware-runtime.nix
    ./golem-seal.nix
    ./waverunner-apply.nix
    ./postinstall.nix
    # GolemModules.md's software module library: same pattern as the
    # hardware family above, gated on a user CHOICE instead of a hardware
    # fact. One file per category, permanently imported, off by default.
    ./modules/music-production.nix
  ];

  options.golem.flakeDir = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = ''
      Local checkout of the Golem flake on this machine. Enables the
      waverunner declarative-install apply service and points rebuild-golem
      at it. null (a machine without a checkout) disables both.
    '';
  };

  options.golem.flakeAttr = lib.mkOption {
    type = lib.types.str;
    default = "golem";
    description = ''
      Which nixosConfigurations attr this machine rebuilds itself as
      (the VM is golem-vm; apply/rebuild must rebuild what actually runs).
    '';
  };

  options.golem.owner = lib.mkOption {
    type = lib.types.str;
    default = "max";
    description = ''
      The machine's single human user — the account greetd logs in, the home
      layer configures, waverunner-apply watches, and sudo trusts. ONE knob
      instead of the hardcoded name scattered across five files
      (release-checklist §2.2 "Every Golem user is named max"): the S9
      installer's rename job becomes setting this option. The GECOS full
      name (users.users.<owner>.description) stays the installer's to set.
    '';
  };

  options.golem.locale = {
    defaultLocale = lib.mkOption {
      type = lib.types.str;
      default = "en_US.UTF-8";
      example = "es_ES.UTF-8";
      description = ''
        The machine's language, as chosen in the installer's first step.
        Drives i18n.defaultLocale and, through supportedLocales, which
        locales actually get generated — an ungenerated locale falls back
        to C at first boot without saying so.
      '';
    };
    timeZone = lib.mkOption {
      type = lib.types.str;
      default = "UTC";
      example = "America/La_Paz";
      description = ''
        The machine's timezone. UTC is the default because it is the only
        answer that is merely WRONG rather than misleading — a stranger
        sees a clock that is off by hours and fixes it, where inheriting
        the distro author's zone looks deliberate and gets trusted.
        Nothing asks for this yet: the timezone step is still to be built,
        and until it exists this option is the thing it will set.
      '';
    };
  };

  options.golem.keyboard = {
    layout = lib.mkOption {
      type = lib.types.str;
      default = "us";
      description = ''
        XKB layout for this machine, as chosen in the installer's keyboard
        step. May be a comma-separated list: every non-Latin script gets
        "<script>,us" so the owner can still type a URL, a password or a
        shell command. See options.golem.keyboard.options for the toggle.
      '';
    };
    variant = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        XKB variant, positional against layout. This is where Colemak,
        Dvorak, Neo, Bépo, Turkish-F and US-International live — they are
        not layouts, they are variants of one ("us" + "colemak"). A
        two-group layout needs its second slot even when empty: "deva,".
      '';
    };
    options = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        XKB options — in practice the group toggle the installer adds
        alongside a second Latin group (grp:alt_shift_toggle).
      '';
    };
    model = lib.mkOption {
      type = lib.types.str;
      default = "pc104";
      description = ''
        XKB model — the PHYSICAL board, derived from the layout's form
        factor rather than asked. Not decoration: a JIS keyboard has
        henkan, muhenkan and katakana keys that pc104 has no keycodes for,
        and ABNT2 has the extra key beside the right shift.
      '';
    };
    consoleKeyMap = lib.mkOption {
      type = lib.types.str;
      default = "us";
      description = ''
        kbd keymap for the TTY. A SEPARATE VOCABULARY from the XKB layout
        above, not a copy of it: gb/uk, latam/la-latin1, br/br-abnt2,
        jp/jp106, tr/trq, hu/hu101, si/slovene, rs/sr-cy. kbd ships no
        keymap at all for Arabic, Persian, Thai, Korean or the Indic
        scripts, so those stay "us" on purpose — the console has no font
        for them, and a rescue shell that cannot type Latin is a brick.
      '';
    };
    consoleFont = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Console font, when the chosen keymap needs one the kernel's
        built-in font does not have. A Cyrillic keymap on the default font
        gives a TTY that types Russian and draws boxes — right keymap,
        unreadable screen. Only Cyrillic, Greek and Hebrew need it, because
        they are the only non-Latin scripts kbd ships a keymap for at all.
        null keeps the kernel default, which is correct for Latin.
      '';
    };
  };

  options.golem.lean = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Ship only what the system needs to work. Drops the owner's
      launcher-installed list (waverunner-packages.nix — that file is one
      machine's state, not the distro), the dev toolchain in the home layer,
      and the non-essential half of the CURATE set. The ISO turns this on
      (2026-09-01 audit: the full home layer made the image 6.33 GiB, led by
      android-studio at 3.3 GiB and three browsers); an installed machine
      leaves it off and grows its own list through waverunner-apply.
    '';
  };

  config = {
    # The owner's launcher-installed app list rides the home layer only on
    # non-lean systems (see options.golem.lean above; home/home.nix says why
    # the import lives here and not there).
    home-manager.users.${config.golem.owner}.imports =
      lib.optional (!config.golem.lean) ./home/waverunner-packages.nix;

    # /bin/sh and /usr/bin/env on FRESH roots (found booting the ISO in qemu,
    # 2026-09-01). This nixpkgs boots stage 2 through nixos-init (toplevel
    # /init is its ELF), which makes the classic `activationScripts.binsh` a
    # no-op — and on the ISO's tmpfs root nothing else created the links, so
    # /bin sat EMPTY. First casualty: greetd, whose worker execve's a
    # hardcoded "/bin/sh" (worker.rs:277) — it panicked with ENOENT, restarted
    # five times, hit the start limit, and the "live session IS Golem" booted
    # to a black screen with a running system underneath. Max's machine never
    # showed it because its stateful root carries /bin/sh from years of
    # generations. Verified live in the guest: symlinking /bin/sh and
    # restarting greetd took the session all the way to Hyprland.
    # Belt-and-suspenders as tmpfiles rules: harmless where the links already
    # exist, load-bearing on every fresh root (ISO today, installer targets
    # tomorrow — this would have hit S9's first real-metal install too).
    systemd.tmpfiles.rules = [
      "L+ /bin/sh - - - - ${config.environment.binsh}"
      "L+ /usr/bin/env - - - - ${config.environment.usrbinenv}"
    ];

    # Bootloader follows the firmware the machine booted (census
    # golem.hardware.firmware): UEFI gets systemd-boot, BIOS/legacy gets
    # GRUB. 3 of 5 lab machines boot BIOS, and it is where dual-boot will
    # live — so this is a real fork, not a fallback. GRUB (not systemd-boot,
    # which is UEFI-only) is also what chainloads other OSes, which is why
    # the disk uses GPT + a BIOS-boot partition on both paths (install.nix):
    # a layout dual-boot can grow into rather than MBR's 4-partition dead end.
    boot.loader = lib.mkMerge [
      { timeout = 3; }
      (lib.mkIf (config.golem.hardware.firmware == "uefi") {
        efi.canTouchEfiVariables = true;
        systemd-boot = {
          enable = true;
          configurationLimit = 15;
          editor = false;
        };
      })
      (lib.mkIf (config.golem.hardware.firmware == "bios") {
        grub = {
          enable = true;
          efiSupport = false;
          # The disk to embed GRUB on. mkDefault so the target evaluates
          # generically (matrix, dev host); golem-install overrides it in
          # machine.nix with the real target disk for a BIOS install.
          device = lib.mkDefault "/dev/sda";
          configurationLimit = 15;
        };
      })
    ];
    # The 26.11 default, set early (surfaced by the first `nix flake check`,
    # 2026-09-03): force-importing ZFS pools at boot risks data loss on a
    # pool that was live elsewhere. Golem ships no ZFS root — this only
    # protects a tester who plugs in a machine that has pools.
    boot.zfs.forceImportRoot = false;

    # vm.* memory sysctls (swappiness, cache pressure, dirty ratios) live
    # in hardware/memory.nix now — RAM-tiered on the golem.hardware facts,
    # same historical values when no detection ran.
    #
    # fq+BBR came in with the /etc/nixos port and STAY as distro policy
    # (Max asked, 2026-09-04): BBR models the path instead of backing off
    # on every loss — noticeably better throughput on wifi and long/lossy
    # routes, no worse on clean ones — and fq provides the pacing BBR
    # expects. Hardware-independent, so no fact and no gate.
    boot.kernel.sysctl = {
      "net.core.default_qdisc"          = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "kernel.printk"                   = "0 0 0 0";
    };
    boot.consoleLogLevel       = 0;
    boot.initrd.verbose        = false;
    boot.initrd.systemd.enable = true;
    boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
    boot.kernelModules = [ "v4l2loopback" ];
    boot.extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1 card_label="Android WebCam" video_nr=10
    '';
    boot.kernelParams = [
      "quiet"
      "loglevel=0"
      "rd.systemd.show_status=false"
      "rd.systemd.log_level=0"
      "systemd.show_status=false"
      "systemd.log_level=0"
      "rd.udev.log_level=0"
      "udev.log_level=0"
      "vt.global_cursor_default=0"
      "vt.default_red=0"
      "vt.default_green=0"
      "vt.default_blue=0"
      "fbcon=map:1"
      "splash"
    ];
    boot.supportedFilesystems = {
      ntfs  = true;
      exfat = true;
      vfat  = true;
      btrfs = true;
      xfs   = true;
      f2fs  = true;
    };
    system.activationScripts.clearStaleBootPin.text = ''
      ${pkgs.systemd}/bin/bootctl set-default "" 2>/dev/null || true
    '';

    # mkDefault, and it was not until 2026-09-05. The installer writes the
    # owner's chosen hostname into machine.nix, and a base value at normal
    # priority made that a CONFLICTING DEFINITION — evaluation failed, so
    # every install that named its machine anything but "Golem" would have
    # died at nixos-install with a message about option priorities.
    # Identical to the GECOS collision recorded in Installer/preinstall/PLAN.md:
    # a base value a per-machine file cannot override is not a default,
    # it is a decision.
    networking.hostName = lib.mkDefault "Golem";

    # The distro's NAME — what os-release (NAME/PRETTY_NAME) and the
    # systemd-boot entry titles say. Lives here (every Golem machine), not in
    # the ISO module, per release-checklist §1.2. The generation label / tags,
    # distroId, and the full version string are DECIDE items and stay Max's.
    system.nixos.distroName = "Golem";

    networking.networkmanager.enable = true;

    networking.firewall.enable = true;
    networking.firewall = {
      allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
      allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
      allowedTCPPorts = [ 53317 ];
    };

    # Language, from the installer's first question (golem.locale).
    #
    # WHAT WAS HERE UNTIL 2026-09-05, and why it had to go: a hardcoded
    # `time.timeZone = "America/La_Paz"` and nine LC_* lines pinned to
    # es_BO. Those are ONE OWNER'S SETTINGS, and they were sitting in the
    # file that defines every Golem machine — so a stranger installing on
    # their own laptop got Bolivian dates, money, paper size and clock no
    # matter what they picked in the installer. They now live in
    # hosts/golem/locale.nix, which is where one machine's facts belong.
    #
    # LC_* IS NOT SET HERE AT ALL, deliberately. Unset means every category
    # follows defaultLocale, which is right for almost everyone: someone who
    # picks Français wants French dates AND French numbers. The split case —
    # English interface, local formats — is real but it is a preference, and
    # preferences belong to OPTIONS rather than to a question asked of every
    # stranger during setup.
    i18n.defaultLocale = lib.mkDefault config.golem.locale.defaultLocale;
    # The chosen locale must actually be GENERATED or it silently falls back
    # to C at first boot — the same class of failure as an XKB name that
    # does not exist. en_US stays alongside it because a rescue shell and
    # most error messages assume it.
    i18n.supportedLocales = lib.mkDefault (lib.unique [
      "${config.golem.locale.defaultLocale}/UTF-8"
      "en_US.UTF-8/UTF-8"
      "C.UTF-8/UTF-8"
    ]);
    time.timeZone = lib.mkDefault config.golem.locale.timeZone;

    # Creates the `uinput` group and a udev rule giving it 0660 on
    # /dev/uinput. Without this the node is 0600 nobody:nogroup and nothing
    # unprivileged can open it — golem-connectd needs it to present the phone
    # as a virtual game controller, because gamepads have no Wayland protocol
    # (games read evdev directly) the way the pointer and keyboard do.
    hardware.uinput.enable = true;

    users.users.${config.golem.owner} = {
      isNormalUser = true;
      # GECOS full name: the installer's to personalize alongside the owner
      # (line 54, and spec §6's machine.nix). mkDefault is what makes that
      # sentence true — at normal priority this collided with the
      # machine.nix golem-install writes, and the very first real install
      # died on it (VM, 2026-09-04): "conflicting definition values: Max /
      # Max Power". A base value a per-machine file cannot override is not
      # a default, it is a decision.
      description = lib.mkDefault "Max";
      shell = pkgs.zsh;
      extraGroups = [
        "networkmanager"
        "wheel"
        "video"
        "adbusers"
        "input"
        # Membership is only picked up by a fresh login session.
        "uinput"
      ];
    };

    # Keyboard, from the installer's one question (golem.keyboard). THREE
    # SINKS, and they are not interchangeable: the TTY reads console.keyMap,
    # X11/XWayland clients read services.xserver.xkb, and the actual desktop
    # reads NEITHER — Hyprland has its own input block, wired in
    # home/home.nix. Setting only the two here leaves the session on us,
    # which is exactly the bug this replaces.
    console.keyMap = lib.mkDefault config.golem.keyboard.consoleKeyMap;
    console.font   = lib.mkIf (config.golem.keyboard.consoleFont != null)
                       (lib.mkDefault config.golem.keyboard.consoleFont);
    services.xserver = {
      enable = true;
      xkb = {
        layout  = lib.mkDefault config.golem.keyboard.layout;
        variant = lib.mkDefault config.golem.keyboard.variant;
        options = lib.mkDefault config.golem.keyboard.options;
        model   = lib.mkDefault config.golem.keyboard.model;
      };
    };

    programs.zsh = {
      enable = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
    };

    # waverunner-apply and rebuild-golem evaluate the user-owned checkout
    # AS ROOT; git's ownership guard (CVE-2022-24765) and nix's libgit2
    # copy of it must both be told that's safe. Both read /etc/gitconfig —
    # the only level libgit2 honors (never -c, never env).
    programs.git = lib.mkIf (config.golem.flakeDir != null) {
      enable = true;
      config.safe.directory = config.golem.flakeDir;
    };

    # Graphics drivers, in full (todo9 item 4): the open stack needs nothing
    # named here — the kernel carries the KMS driver, the firmware above
    # feeds it, and hardware.graphics comes on with this module, which is why
    # the VM renders without any host ever mentioning a driver. nvidia is the
    # single exception and it is a HOST choice (hosts/golem/nvidia.nix), so a
    # stranger's nvidia machine installs onto nouveau today — the generic
    # host that fixes that belongs to the install flow (item 3, parked).
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "uwsm start hyprland-uwsm.desktop";
          user = config.golem.owner;
        };
      };
    };

    # SH F4/F7: the daemon's glyphs need the Nerd Font; its "sans-serif"
    # request used to fall back to DejaVu by fontconfig accident — ship
    # DejaVu and make that default deliberate. (Choosing a real Golem UI
    # font is an open design call — todo7.)
    fonts.packages = with pkgs; [
      jetbrains-mono
      nerd-fonts.jetbrains-mono
      dejavu_fonts
    ];
    fonts.fontconfig.defaultFonts.sansSerif = [ "DejaVu Sans" ];

    # Foreign hardware (S9). The live ISO gets firmware from nixpkgs'
    # all-hardware profile, so wifi works while you install — and would die
    # on the first reboot if the installed system didn't carry the same
    # blobs. Nothing here ever set them: enableRedistributableFirmware was
    # only ever READ (hosts/golem/hardware-configuration.nix:32, for
    # microcode). enableAllFirmware is the wider set — the broadcom/b43-era
    # laptops a stranger might hand us live in the gap between the two — and
    # it implies the redistributable one. It needs allowUnfree, which Golem
    # sets below regardless.
    hardware.enableAllFirmware = true;

    # …and keep that firmware current: fwupd serves UEFI/SSD/dock updates
    # from the LVFS the same way every other distro's GUI updaters do.
    # Always-on (anti-over-gating): on hardware with no LVFS entries the
    # daemon idles. Nothing updates without an explicit fwupdmgr call or
    # a future OPTIONS surface — no surprise reboots.
    services.fwupd.enable = lib.mkDefault true;

    # Golem ships unfree and does not ask. The webapp engine is google-chrome
    # (home/home.nix), the firmware above is partly unfree, and nvidia's
    # driver is unfree (hosts/golem/nvidia.nix): an install-time "unfree?"
    # question (todo9 item 4) would be a question whose "no" breaks the app
    # set, so the answer is baked in here instead of asked.
    nixpkgs.config.allowUnfree = true;

    programs.nix-ld.enable = true;
    services.envfs.enable = true;

    # Remote filesystems in the file manager. Without this Thunar cannot open
    # dav:// or sftp:// at all — it is what lets the Golem phone appear as a
    # browsable location rather than needing a FUSE mount.
    services.gvfs.enable = true;
    # Enabling the daemon is not enough: GTK apps only speak to it if gvfs's
    # GIO module is on GIO_EXTRA_MODULES. Without this Thunar silently shows
    # no network locations at all.
    environment.sessionVariables.GIO_EXTRA_MODULES = [ "${pkgs.gvfs}/lib/gio/modules" ];

    environment.systemPackages = with pkgs; [
      git
      # Stopgap kit (die when their Arc-2 OPTIONS modules ship):
      pavucontrol           # audio GUI
      networkmanagerapplet  # network GUI (nm-connection-editor)
      brightnessctl         # hyprland.lua's brightness keys exec it; must
                            # exist system-wide, not ride the user's
                            # launcher-installed list (empty on fresh Golem)
    ] ++ lib.optional (config.golem.flakeDir != null)
      (pkgs.writeShellScriptBin "rebuild-golem" ''
        set -euo pipefail
        sudo nixos-rebuild switch --flake "${config.golem.flakeDir}#${config.golem.flakeAttr}" "$@"

        current=$(readlink -f /run/current-system)
        latest=$(readlink -f /nix/var/nix/profiles/system)
        booted=$(readlink -f /run/booted-system)

        if [ "$current" != "$latest" ]; then
          echo "FAIL: activated system != latest profile (drift)"; exit 1
        fi
        echo "OK: activated == latest"

        if [ "$current" != "$booted" ]; then
          echo "REBOOT REQUIRED: kernel/initrd/system changed — reboot to run latest"
        else
          echo "OK: activated == booted (already fully live)"
        fi
      '');

    # Compressed swap in RAM: a nixos-rebuild eval wants 2-3GB — on a 4G
    # machine that's the difference between installing apps and thrashing.
    zramSwap.enable = true;

    # Survive memory pressure instead of freezing under it. On an 8 GB DDR3
    # machine (the i5-6th-gen / HD 530 class Golem must serve) a spike — a
    # heavy webapp next to a nixos-rebuild eval, which wants 2-3 GB — pushes
    # the kernel into swap-thrash and the whole desktop locks, mouse and all.
    # systemd-oomd watches PSI pressure per cgroup and kills the GREEDIEST
    # slice before that happens, turning a full freeze into "one app closed".
    # For a distro whose promise is "works for everyone", a survivable failure
    # beats a dead machine. Acts on the user and system slices (kill at 80%
    # sustained pressure); needs the zram swap above to have room to act in.
    systemd.oomd = {
      enable = true;
      enableUserSlices = true;
      enableSystemSlice = true;
    };
    # Make oomd spare the shell: under pressure it should reap the runaway
    # app, never the daemon that draws the desktop — losing that is
    # indistinguishable from the freeze we are preventing. greetd is a system
    # service; the waverunner daemon is a home-manager USER service, so its
    # avoid-preference has to be set in the home layer (a NixOS-level
    # systemd.user unit is shadowed by ~/.config), see home/home.nix.
    systemd.services.greetd.serviceConfig.ManagedOOMPreference = "avoid";

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nix.settings.auto-optimise-store = true;
    # Rollback depth (release-checklist §2.6, CONFIRMED 2026-09-03): the old
    # `--delete-older-than 7d` deleted system generations by AGE — a machine
    # not rebuilt for 8 days lost every rollback while systemd-boot still
    # showed 15 (dangling) menu entries pointing at GC'd store paths. The gc
    # is now count-based on the system profile: keep the newest 15
    # generations (exactly matching configurationLimit, so every boot-menu
    # entry stays bootable), then collect unreachable store paths. Disk cost
    # is bounded by the 15 kept closures; rollback — the §3 headline — never
    # silently evaporates. `-` prefix: don't fail the gc on a system without
    # the profile (the live ISO).
    nix.gc = {
      automatic = true;
      dates     = "daily";
    };
    systemd.services.nix-gc.serviceConfig.ExecStartPre =
      "-${config.nix.package}/bin/nix-env --profile /nix/var/nix/profiles/system --delete-generations +15";

    services.udev.extraRules = ''
      ACTION=="add|change",SUBSYSTEM=="input",KERNEL=="event*",ENV{ID_INPUT_TOUCHSCREEN}=="1",ENV{LIBINPUT_IGNORE_DEVICE}="1"
    '';

    # Golem dev loop: max (and Claude working as max) rebuilds without a
    # password. Build always runs before switch; generations are the net.
    security.sudo.extraRules = [{
      users = [ config.golem.owner ];
      commands = [{
        command = "/run/current-system/sw/bin/nixos-rebuild";
        options = [ "NOPASSWD" ];
      }];
    }];

    system.stateVersion = "26.05";
  };
}
