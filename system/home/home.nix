# Standard's home layer: the desktop of EVERY Standard machine, the dev box included
# (parity P1, 2026-09-30: the dev box imports this directory from its
# /etc/nixos/home.nix instead of keeping its own copy). What differs per
# machine is an option in ./options.nix, set by that machine's layer.
#
# One leaf per concern (the imports below are the map); what stays in this
# file is the account, the programs every Standard carries, and the session's
# variables.
{ osConfig, pkgs, lib, waverunner, ... }:

{
  imports = [
    ./options.nix         # the per-machine knobs (devCheckout, idle, hyprlandExtra)
    ../../seam/home.nix   # Seam: prefs, look, and the profile
    ./zsh.nix
    ./menubox.nix         # the menubox shows Seam only; the rest stays installed, hidden
    ./bash.nix            # the owner's bash: prompt, EDITOR, the OPTIONS shell bridge (P12)
    ./idle.nix            # hypridle + hyprlock: lock, screen off, suspend on idle (P11)
    ./fits.nix            # an app the owner installs works the moment it lands (OBS)
    ./warm-browser.nix    # on a spinning disk, Seam's files read ahead after the login
    ./phone.nix           # a plugged-in Android: mirror its screen, use it as the camera
    ./screenshot.nix      # the Print Screen keys: a file, the clipboard, a notification
    ./dock.nix            # the dock (waverunner): its service, the small tier, its package list, its config
    ./hyprland.nix        # Hyprland: ./hypr (one file a concern) + this machine's generated facts
    ./look.nix            # GTK, icons, fonts, what libadwaita reads; the palette's files
    ./terminal.nix        # foot
    ./editor.nix          # neovim
    ./files.nix           # yazi
    ./webapps.nix         # the webapps catalog's seed and the bundled icons
    ./user-dirs.nix       # Documents, Downloads… in the owner's language
    ./default-apps.nix    # which program opens each kind of file
    waverunner.homeManagerModules.default
  ];
  # ./waverunner-packages.nix (the owner's launcher-installed list) is NOT
  # imported here any more — configuration.nix imports it for non-lean
  # systems only. It is one machine's state, not the distro: a lean image
  # (the ISO) must not inherit android-studio because Max once dragged it
  # into the Install section. Imports can't be conditional inside a module,
  # so the switch lives at the NixOS level.


  # The account this home layer configures follows the machine's owner
  # (standard.owner) — the S9 installer renames ONE option, not five files.
  home.username = osConfig.standard.owner;
  home.homeDirectory = "/home/${osConfig.standard.owner}";
  home.stateVersion = "26.05";

  # Desktop plumbing every Standard needs, lean or not.
  home.packages = with pkgs; [
    adw-gtk3   # libadwaita's look for GTK 3 apps; the dock themes it with the palette (Golem-A/B)
    papirus-icon-theme
    phinger-cursors
    wl-clipboard
    xdg-user-dirs      # localizes ~/Downloads → ~/Transferências etc. (see below)

    ffmpegthumbnailer # Video previews (and a song's cover: its .thumbnailer files
                      # are how Golem Files previews them — waverunner thumb_more.rs)
    unar              # Archive previews
    jq                # JSON previews
    poppler-utils     # PDF previews (pdftoppm: a PDF's first page in Golem Files too)
    # MORE THUMBNAILS (Max, 2026-10-15: "as many files as possible as
    # thumbnails"): Golem Files runs every freedesktop .thumbnailer these bring.
    gnome-epub-thumbnailer  # an epub's / mobi's cover
    libgsf                  # gsf-office-thumbnailer: Word, Excel, PowerPoint, LibreOffice
    exiftool                # a camera RAW photo's own JPEG (dcraw is marked insecure)
    # QUICK LOOK (Max, 2026-10-16: Space in Golem Files — waverunner peek_kinds.rs):
    mupdf-headless          # mutool: a PDF's page at the size it is shown, the fastest there is
    libarchive              # bsdtar: what is in an archive, nothing unpacked
    libjxl                  # djxl + a thumbnailer: JPEG XL pictures in Quick Look and Files
    fd                # Fast file searching
    ripgrep

    awww
    mpvpaper          # a video as the wallpaper (the control panel's Wallpaper lists
                      # videos only where this is installed)
    ffmpeg-headless   # reads the frames of a GIF or video for its moving preview in
                      # the wallpapers' box (without it the preview stays still)

    grim
    slurp
    wf-recorder       # screen recording (the OPTIONS record control)
    # The capture tool's "Copy text": reads the words in a region of the
    # screen. Only the shell's six languages' data (all of them is 600 MB+).
    (tesseract.override { enableLanguages = [ "eng" "spa" "por" "fra" "deu" "ita" ]; })
    hyprsunset        # the SUNSET option's warm screen (daemon screen.rs runs it);
                      # only the dev box had it until 2026-09-30, so "turn on" did
                      # nothing on an install (found by the P1 diff)

    playerctl

    git
    xdg-terminal-exec # a .desktop entry with Terminal=true opens in the terminal below
    libnotify         # notify-send: the standard way a script or app posts a notification
  ];

  # KDE Connect (the phone's link) runs as an XDG autostart app, and nothing
  # brought it back when it died — it goes with the session bus — so the
  # phone features were silently gone until the next login (the Acer,
  # 2026-10-14). Restarted when it fails, like any service the desktop leans
  # on.
  xdg.configFile."systemd/user/app-org.kde.kdeconnect.daemon@autostart.service.d/golem-restart.conf".text = ''
    [Service]
    Restart=on-failure
    RestartSec=3
  '';
  # Max's dev toolchain (gcc, android-tools, scrcpy, jdk21, claude-code,
  # github-cli, easyeffects, lsp-plugins + JAVA_HOME/ANDROID_HOME) left the
  # distro 2026-09-29 (the debloat): it is one machine's setup, and it lives
  # in that machine's own config (/etc/nixos), not in Standard.

  home.sessionVariables = {
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };

  # No Chrome: Seam is Standard's only browser (the debloat, 2026-09-29). The
  # webapps (Chrome --app windows) come back when they move onto Seam.

  # The shader cache of before MESA_DISK_CACHE_DATABASE (session.nix): nothing reads it.
  home.activation.dropOldShaderCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD rm -rf "$HOME/.cache/mesa_shader_cache"
  '';
}
