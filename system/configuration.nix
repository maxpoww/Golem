# Golem core — everything common to every Golem machine.
# Ported from /etc/nixos/configuration.nix; hardware (nvidia, disks) lives
# in hosts/, home config in ./home/, wired up by flake.nix.
{ config, pkgs, lib, ... }:

{
  imports = [
    ./audio.nix
    ./bluetooth.nix
    ./waverunner-apply.nix
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

  config = {
    boot.loader = {
      timeout = 3;
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        configurationLimit = 15;
        editor = false;
      };
    };
    boot.kernel.sysctl = {
      "vm.swappiness"                   = 10;
      "vm.vfs_cache_pressure"           = 10;
      "vm.dirty_ratio"                  = 10;
      "vm.dirty_background_ratio"       = 5;
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

    networking.hostName = "Golem";
    networking.networkmanager.enable = true;

    networking.firewall.enable = true;
    networking.firewall = {
      allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
      allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
      allowedTCPPorts = [ 53317 ];
    };

    time.timeZone = "America/La_Paz";
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "es_BO.UTF-8";
      LC_IDENTIFICATION = "es_BO.UTF-8";
      LC_MEASUREMENT = "es_BO.UTF-8";
      LC_MONETARY = "es_BO.UTF-8";
      LC_NAME = "es_BO.UTF-8";
      LC_NUMERIC = "es_BO.UTF-8";
      LC_PAPER = "es_BO.UTF-8";
      LC_TELEPHONE = "es_BO.UTF-8";
      LC_TIME = "es_BO.UTF-8";
    };

    users.users."max" = {
      isNormalUser = true;
      description = "Max";
      shell = pkgs.zsh;
      extraGroups = [
        "networkmanager"
        "wheel"
        "video"
        "adbusers"
        "input"
      ];
    };

    services.xserver = {
      enable     = true;
      xkb.layout = "us";
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
          user = "max";
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

    nixpkgs.config.allowUnfree = true;

    programs.nix-ld.enable = true;
    services.envfs.enable = true;

    # Remote filesystems in the file manager. Without this Thunar cannot open
    # dav:// or sftp:// at all — it is what lets the Golem phone appear as a
    # browsable location rather than needing a FUSE mount.
    services.gvfs.enable = true;

    environment.systemPackages = with pkgs; [
      git
      # Stopgap kit (die when their Arc-2 OPTIONS modules ship):
      pavucontrol           # audio GUI
      networkmanagerapplet  # network GUI (nm-connection-editor)
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

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nix.settings.auto-optimise-store = true;
    nix.gc = {
      automatic = true;
      dates     = "daily";
      options   = "--delete-older-than 7d";
    };

    services.udev.extraRules = ''
      ACTION=="add|change",SUBSYSTEM=="input",KERNEL=="event*",ENV{ID_INPUT_TOUCHSCREEN}=="1",ENV{LIBINPUT_IGNORE_DEVICE}="1"
    '';

    # Golem dev loop: max (and Claude working as max) rebuilds without a
    # password. Build always runs before switch; generations are the net.
    security.sudo.extraRules = [{
      users = [ "max" ];
      commands = [{
        command = "/run/current-system/sw/bin/nixos-rebuild";
        options = [ "NOPASSWD" ];
      }];
    }];

    system.stateVersion = "26.05";
  };
}
