{ lib, pkgs, golem, hw-decide, install, offlineSeed, ... }:

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
    ../system/hardware-detect.nix
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
  system.extraDependencies = [ offlineSeed ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  environment.systemPackages = [ hw-decide install ];
  # Console only, on purpose — the guided surface comes later. Behaviour is
  # stock installation-cd-minimal (autologin to `nixos` on tty1, nmtui,
  # nixos-install in PATH); this file is naming and the boot menu.
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

  # "Install" boots the same system plus a marker the install flow will
  # ride later (systemd unit gated on ConditionKernelCommandLine).
  specialisation.install.configuration = {
    isoImage.prependToMenuLabel = lib.mkForce "Install";
    isoImage.golemMenuIndent = lib.mkForce 0;
    boot.kernelParams = [ "golem.install" ];
  };

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
  isoImage.grubTheme = pkgs.callPackage ./grub-theme.nix { };
  isoImage.efiSplashImage = ./black.png;
  isoImage.splashImage = ./black.png;
}
