{ lib, pkgs, golem, hw-decide, hw-postinstall-questions, install, setup, offlineSeed, ... }:

let
  # ── Lab wifi, baked ───────────────────────────────────────────────────
  # The stick has no persistence, so every boot used to need the network
  # re-joined by hand before the dev box could reach it (PLAN.md's "a
  # reflashed stick sat dark"). HOLA is an OPEN network (Max, 2026-09-06)
  # — no passphrase, so there is no secret to keep out of this public
  # repo and no build ceremony: a plain `nix build .#iso` carries the
  # profile. It rides the same ladder as GOLEM_REHEARSE in setup.nix —
  # lab equipment, gone when the medium graduates to product.
  #
  # Should the lab ever move to a protected network, the secret path
  # still exists without touching a tracked file: pure evaluation reads
  # getEnv as "", and
  #
  #   GOLEM_LAB_WIFI_SSID='…' GOLEM_LAB_WIFI_PSK='…' nix build --impure .#iso
  #
  # bakes a wpa-psk profile instead, the PSK living only inside the image
  # — same trust level as the SSH key below: whoever holds Max's stick
  # holds Max's LAN.
  labWifiSsid =
    let s = builtins.getEnv "GOLEM_LAB_WIFI_SSID";
    in if s != "" then s else "HOLA";
  labWifiPsk = builtins.getEnv "GOLEM_LAB_WIFI_PSK";

  # The Install boot's tty1 launcher — the DEFINITIVE no-banner autostart
  # (Max, 2026-09-23: "do the definitive fix, no banner at all"). The install
  # specialisation runs getty with `--skip-login --login-program ${this}`, so
  # agetty prompts for nothing, prints no autologin banner at all, and execs
  # THIS as root (skip-login never drops privilege — which is exactly what
  # golem-install needs from its first step, so no sudo either). On tty1 we
  # clear and BECOME the surface; on any other VT we hand off to the real
  # login, so tty2-6 stay a normal, debuggable console. This replaces the old
  # autologin + loginShellInit path, whose one unavoidable artefact was
  # agetty's own "golem-installer login: nixos (automatic login)" line.
  installSurface = pkgs.writeShellScript "golem-install-surface" ''
    if [ "$(${pkgs.coreutils}/bin/tty)" = /dev/tty1 ]; then
      printf '\033[H\033[2J\033[3J'
      exec ${setup}/bin/golem-setup-install
    fi
    exec ${pkgs.shadow}/bin/login
  '';
in
{
  # The boot menu is ours: upstream iso-image.nix hardcodes rows (Options
  # submenu, Firmware Setup, Shutdown, rEFInd) and autoboots after at most
  # ~1h — Golem's menu is Start/Install, waiting forever. See the vendored
  # copy's header for the exact diff.
  disabledModules = [ "installer/cd-dvd/iso-image.nix" ];
  imports = [
    ./iso-image-golem.nix
    # The lab tools (PLAN.md): the census probe — shared with the full
    # system on purpose (same probe everywhere is reuse, not ISO-mixing) —
    # and the raw-evidence collector that feeds the fixture corpus.
    "${golem}/system/hardware-detect.nix"
    ./evidence.nix
    # The machine audits itself at boot and leaves the verdict in
    # /var/log/golem-audit/ — this module also owns the getty helpLine,
    # because what the console has to say is "here is where I am, and the
    # census is done".
    ./audit.nix
  ];

  # ── The whole distro, on the stick, evaluable without a network ───────
  #
  # Max, 2026-09-03: "i want golem (on start) to decide which modules will
  # use for the installation, the zram, the drivers, etc." NixOS decides at
  # EVALUATION time, so for the medium to decide anything it has to be able
  # to evaluate the distro on the machine it booted. Three things make that
  # true, and all three are required:
  #
  #   1. the source            /etc/golem/src → the parent flake
  #   2. every input's source  in the medium's store, via offlineSeed —
  #      hosts/iso.nix:83-85 called this out as the unsolved half ("having
  #      the source on the ISO is not yet an offline install"); decide.nix
  #      pins each one with --override-input so the lock's github URLs are
  #      never consulted
  #   3. flakes enabled        installation-cd-minimal does not enable them
  #
  # golem-hw-decide then reads the machine and prints what Golem chose,
  # through the same lib.golem.mkTarget the installer will build.
  environment.etc."golem/src".source = golem;
  environment.etc."golem/inputs".source = offlineSeed;
  # 8e — bake the ALL-IN hardware matrix onto the medium (Max, 2026-09-18,
  # the Omarchy model): every class's minimal closure in the store, so the
  # install is a LOCAL COPY, no network. The union is ~6.6 GiB → ~4 GiB
  # compressed ISO (fits an 8 GB stick with room). A machine whose exact
  # combo isn't a listed fixture still installs offline — the heavy
  # driver/kernel/firmware paths are all here, so its toplevel assembles from
  # these baked components; anything unclassifiable lands on gpu/auto (the
  # floor that boots on anything).
  system.extraDependencies = [ offlineSeed golem.packages.x86_64-linux.bakedMatrix ];
  # The manifest golem-install reads to pick the baked toplevel matching a
  # machine's chosen leaf-list (install by DIRECT COPY, no rebuild — 8e opt A).
  environment.etc."golem/baked-manifest.json".source =
    golem.packages.x86_64-linux.bakedManifest;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  environment.systemPackages = [ hw-decide hw-postinstall-questions install setup ];

  # ── All-hardware firmware on the medium (Max, 2026-09-06: "all-in") ────
  # installation-cd-minimal ships almost no firmware to stay small, which
  # cost the lab twice in round 1: internal wifi was dark (the MacBook's
  # Broadcom needed a USB dongle) and the reveal's driver count read a
  # demoralising "74%" on the HP — both the same missing-firmware root
  # cause. The installed Golem already carries the full set
  # (configuration.nix: hardware.enableAllFirmware = true); the medium must
  # match, or "works on the stick" and "works installed" diverge — and the
  # census's driver count finally tells the truth. This is the biggest
  # single thing behind the Intel-MacBook goal: brcmfmac brings the BCM4360
  # up on the stick with these blobs, no dongle. Needs unfree; Golem allows
  # it distro-wide, and the medium must too.
  hardware.enableAllFirmware = true;
  nixpkgs.config.allowUnfree = true;
  # Console only, still on purpose — but the guided surface is HERE now:
  # `golem-setup` on tty1 asks the six questions (language, timezone,
  # keyboard, disk, you) and writes the answers file golem-install
  # consumes. It is typed, not autostarted: the audit owns tty1's first
  # seconds, and a person has to be AT the machine to answer a keyboard
  # question anyway — autostarting would only race the census banner.
  # Behaviour is otherwise stock installation-cd-minimal (autologin to
  # `nixos` on tty1, nmtui, nixos-install in PATH).
  networking.hostName = "golem-installer";

  # Same option pair the full ISO settled on (hosts/iso.nix, todo9 item 2:
  # `image.baseName` is the renamed option, `isoImage.volumeID` never was).
  image.baseName = lib.mkForce "golem-installer";
  isoImage.volumeID = lib.mkForce "GOLEM_INST";

  services.getty.greetingLine = lib.mkForce "<<< Golem installer — minimal cut >>>";
  # agetty expands \4 to the machine's IPv4 at prompt time. The helpLine
  # itself is set in audit.nix, which has the other half of what the
  # console needs to say.

  # ── Lab access: SSH up, key-only, zero-touch ──────────────────────────
  # The dev machine's lab key (~/.ssh/id_ed25519.pub, "golem-vm-loop"),
  # embedded literally: the flake evals pure, so it cannot read $HOME —
  # and the medium's trust anchor SHOULD be pinned in-repo anyway.
  users.users.nixos.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILn4GLtnQEthtkhvWmcPpl7Y1GtMlBVUyTAJrNcHcX5K golem-vm-loop"
  ];
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILn4GLtnQEthtkhvWmcPpl7Y1GtMlBVUyTAJrNcHcX5K golem-vm-loop"
  ];
  # The installer profile allows password logins with EMPTY passwords —
  # fine air-gapped, not on lab LAN with sshd up. Keys only.
  services.openssh.settings.PasswordAuthentication = lib.mkForce false;
  services.openssh.settings.KbdInteractiveAuthentication = lib.mkForce false;

  # The lab wifi profile (see the let-binding up top — open network, no
  # secret, always baked). NetworkManager autoconnects it at boot, so a
  # lab laptop is reachable the moment the census banner lands — the pull
  # half of the rehearsal loop: the machine rehearses, the dev box SSHes
  # in and collects /var/log/golem-rehearsal. No wifi-security section IS
  # the open-network spelling; the PSK branch appears only when one was
  # injected at build time.
  networking.networkmanager.ensureProfiles.profiles.golem-lab = {
    connection = { id = "golem-lab"; type = "wifi"; autoconnect = true; };
    wifi = { mode = "infrastructure"; ssid = labWifiSsid; };
  } // lib.optionalAttrs (labWifiPsk != "") {
    wifi-security = { key-mgmt = "wpa-psk"; psk = labWifiPsk; };
  };

  # The medium is a terminal; don't spend boot time compressing for looks.
  isoImage.squashfsCompression = "zstd -Xcompression-level 3";

  # ── Boot menu: systemd-boot look, two entries ─────────────────────────
  #
  # Entry names are assembled as prepend+distroName+" "+label+append
  # (iso-image.nix menuBuilder*), so the whole middle is blanked and the
  # prepend carries the entire name: base config → "Start", and the
  # `install` specialisation below → "Install". Blanking distroName/label
  # only bruises the live medium's os-release — nothing on the medium
  # reads it.
  # Selection-bar geometry, from syslinux menumain.c draw_row (the
  # screenshots kept lying by half a column): the highlight is
  # 1 space + text-area(WIDTH−4) + 1 space, between invisible border
  # columns. WIDTH 11 → text area 7 = "Install" exactly, so the bar HUGS
  # the long label (one breathing space each side); "Start" (5) centers in
  # the same area via MENU INDENT 1 (a vendored addition — syslinux trims
  # leading label whitespace, so pad-spaces can't center anything).
  isoImage.prependToMenuLabel = "Start";
  isoImage.golemMenuIndent = 1;
  isoImage.appendToMenuLabel = lib.mkForce "";
  system.nixos.distroName = lib.mkForce "";
  system.nixos.label = lib.mkForce "";

  # "Install" boots the same system plus the marker the install flow rides,
  # and — the 8e product half (Max, 2026-09-18: "autoarranque") — autostarts
  # the guided surface in PRODUCT mode on tty1. The base (Start) boot leaves
  # tty1 to the audit banner and a TYPED `golem-setup` (rehearse-safe); only
  # this specialisation drops a stranger straight into the real installer.
  # Everything here is a separate toplevel, so none of it touches Start.
  specialisation.install.configuration = {
    isoImage.prependToMenuLabel = lib.mkForce "Install";
    isoImage.golemMenuIndent = lib.mkForce 0;
    boot.kernelParams = [ "golem.install" ];

    # Black boot → straight into the installer (Max, 2026-09-23: "get rid of
    # the splash before Press ENTER"). The greeting, the census banner
    # (audit.nix skips it on golem.install) and the help lines are the
    # interactive "Start" console's furniture; on the Install boot the TUI owns
    # the screen, so blank them. mkOverride beats the base's mkForce so nothing
    # of the getty prints before the surface clears the screen.
    #   installation-cd's autologin left ONE unavoidable line — agetty's own
    #   "golem-installer login: nixos (automatic login)" (it hardcodes the
    #   "(automatic login)" notice; no flag mutes it). So the Install boot drops
    #   autologin entirely: tty1's getty runs --skip-login --login-program, and
    #   agetty prints NOTHING and execs installSurface (the let-binding) as root
    #   — no login shell, no banner, ever. installSurface clears tty1 and becomes
    #   the surface; other VTs fall through to the real login. greeting/help/issue
    #   are blanked too (belt to --noissue); the Start boot keeps all of them.
    services.getty.autologinUser = lib.mkForce null;
    services.getty.loginProgram = lib.mkForce "${installSurface}";
    services.getty.extraArgs = lib.mkForce [ "--skip-login" "--nohostname" "--noissue" ];
    services.getty.greetingLine = lib.mkOverride 10 "";
    services.getty.helpLine = lib.mkOverride 10 "";

    # No environment.loginShellInit autostart anymore: tty1 has no login shell
    # on the Install boot — getty execs installSurface directly (above), which
    # IS the autostart. SSH logins get a plain shell as before (installSurface's
    # tty guard only fires on /dev/tty1; an SSH pty falls through to login). The
    # surface runs as root (skip-login), so the old `sudo` and the #103
    # privilege dance are gone; golem-install's first privileged step just works.
  };

  # Silent boot (Max, on metal 2026-09-23: "Golem boot is black screen until
  # booted — I don't want to see all those letters after I pick Start or
  # Install"). The medium now boots as quietly as an INSTALLED Golem: the same
  # log-quieting kernel params base/core.nix uses. This is the SAFE set — it
  # does NOT include fbcon=map:1 / splash, which take the display away and left
  # the first metal machine's minimal console a DEAD black screen (#65); these
  # only silence the log, the framebuffer console still exists.
  #   consoleLogLevel 0 also keeps the HP's red Radeon resume errors off the
  #   installer surface (the old #17a reason for lowering it — 0 is stricter
  #   than the previous 3). dmesg + the journal still keep everything.
  #   The Install specialisation's `boot.kernelParams = [ "golem.install" ]`
  #   APPENDS to these (list merge), so both entries boot silently.
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
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
  ];

  # English-on-fresh-boot as a GUARANTEE, not an accident (#6): without
  # the pin the tty is English only because the kernel default happens to
  # be us — systemd-vconsole-setup logs "Configuration of first virtual
  # console was skipped", so vconsole.conf was never actively applied.
  # mkDefault so golem-setup's loadkeys (the keyboard step) still wins.
  console.keyMap = lib.mkDefault "us";

  # The minimal profile adds a Memtest86+ row; Start/Install is the whole
  # menu.
  boot.loader.grub.memtest86.enable = lib.mkForce false;

  # No timing: the menu waits until a choice is made. null → grub -1 and
  # (vendored) syslinux TIMEOUT 0, both "wait forever".
  boot.loader.timeout = lib.mkForce null;

  # BIOS/syslinux (what qemu SeaBIOS shows): two small rows, centered on a
  # black screen, reverse-video selection — systemd-boot's look. 800x600 at
  # the 8x16 font is a 100x37 character grid: WIDTH 12 at HSHIFT 44 puts a
  # text-sized bar on the center column, VSHIFT 16 centers two rows
  # vertically. Auxiliary text (tab/cmdline hints) is alpha-zeroed — the
  # screen holds the two entries and nothing else.
  isoImage.syslinuxTheme = lib.mkForce ''
    MENU BACKGROUND #FF000000
    MENU CLEAR
    MENU ROWS 2
    MENU MARGIN 0
    MENU WIDTH 11
    MENU HSHIFT 33
    MENU VSHIFT 11

    #                                FG:AARRGGBB  BG:AARRGGBB   shadow
    MENU COLOR SCREEN       37;40    #FFCCCCCC    #FF000000     none
    MENU COLOR BORDER       30;40    #00000000    #00000000     none
    MENU COLOR TITLE        1;37;40  #00000000    #00000000     none
    MENU COLOR UNSEL        37;40    #FFCCCCCC    #FF000000     none
    MENU COLOR SEL          7;37;40  #FF000000    #FFEEEEEE     none
    MENU COLOR HOTKEY       37;40    #FFCCCCCC    #FF000000     none
    MENU COLOR HOTSEL       7;37;40  #FF000000    #FFEEEEEE     none
    MENU COLOR TABMSG       37;40    #00000000    #00000000     none
    MENU COLOR TIMEOUT      37;40    #00000000    #00000000     none
    MENU COLOR TIMEOUT_MSG  37;40    #00000000    #00000000     none
    MENU COLOR HELP         37;40    #00000000    #00000000     none
    MENU COLOR CMDMARK      37;40    #FFFFFFFF    #FF000000     none
    MENU COLOR CMDLINE      37;40    #FFCCCCCC    #FF000000     none
  '';

  # UEFI/GRUB: the same two entries, drawn the same way — see
  # grub-theme.nix. This used to be `null`, which is NOT "close enough" as
  # the old comment here claimed: it left GRUB's stock menu, top-left and
  # full width with a blue selection bar, on every UEFI machine (caught on
  # the Acer, 2026-09-05 — the BIOS-booting older PC looked correct with
  # the same stick).
  # black.png: 16x16 solid black (inkscape-generated, eyeball-verified),
  # stretched to fill by both loaders — kills the NixOS artwork.
  # The theme moved to system/Modular/boot/grub-theme.nix (#68) so the
  # medium and an INSTALLED machine draw the same Golem menu. The medium
  # keeps its proven geometry (the defaults — a box that hugs "Install").
  isoImage.grubTheme = pkgs.callPackage "${golem}/system/Modular/boot/grub-theme.nix" { };
  isoImage.efiSplashImage = ./black.png;
  isoImage.splashImage = ./black.png;

  # #89/#95/#92, the ISO side owed at the recut: the medium's UEFI GRUB was
  # stock, so it FLASHED grub's banner+cursor and IGNORED the theme's
  # `item_align` (staying left-aligned) while every installed machine was
  # already silent and centred. Import the SAME patch overlay the installed
  # bootloader leaves use (grub-patched.nix), so `pkgs.grub2_efi` — which
  # iso-image-golem.nix builds the medium's EFI grub from — carries the quiet
  # + item_align patches. After this, all four boot surfaces (ISO BIOS/UEFI,
  # installed BIOS/UEFI) show the same Golem menu; the ISO's BIOS syslinux is
  # the one bespoke sibling (already silent+centred, round 8).
  nixpkgs.overlays = [ (import "${golem}/system/Modular/boot/grub-patch-overlay.nix") ];
}
