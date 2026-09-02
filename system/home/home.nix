# Golem home layer — ported from /etc/nixos/home.nix.
# Differences from the channel version, all homedir-assumption kills:
#   • waverunner runs from its flake package via programs.waverunner
#     (systemd user service), not /home/max/launcher/waverunner-dev
#   • hyprland.lua's plugin-load / waverunner-ctl lines are rewritten to
#     store paths / PATH bins at build time (see the replaceStrings below)
{ config, osConfig, pkgs, lib, waverunner, waveview, ... }:

{
  imports = [
    ./zsh.nix
    waverunner.homeManagerModules.default
  ];
  # ./waverunner-packages.nix (the owner's launcher-installed list) is NOT
  # imported here any more — configuration.nix imports it for non-lean
  # systems only. It is one machine's state, not the distro: a lean image
  # (the ISO) must not inherit android-studio because Max once dragged it
  # into the Install section. Imports can't be conditional inside a module,
  # so the switch lives at the NixOS level.

  home.username = "max";
  home.homeDirectory = "/home/max";
  home.stateVersion = "26.05";

  # Tell systemd-oomd (enabled at the system level for the low-RAM freeze
  # guard) to never pick the dock daemon as its victim under memory pressure —
  # it should reap the runaway app instead. This lives here, not in
  # configuration.nix, because waverunner is a home-manager user unit and a
  # NixOS-level systemd.user override is shadowed by the ~/.config copy.
  systemd.user.services.waverunner.Service.ManagedOOMPreference = "avoid";

  programs.waverunner.enable = true;

  # notification-fix (vendored in ./notification-fix): the Chrome extension
  # that un-breaks FB/Messenger/IG notifications on Wayland — Chromium does
  # no occlusion tracking there, so those sites think the window is always
  # visible and never post a system notification. The daemon appends the
  # store path as --load-extension on every webapp launch (waverunner
  # ≥ 47b9793 reads this var; older pins ignore it — harmless).
  # As a systemd drop-in rather than programs.waverunner.webappExtension so
  # this evals against the CURRENT pinned waverunner too; switch to the
  # option once the input bumps past 47b9793.
  # CAVEAT (verified 2026-09-01 on Chrome 152): branded Chrome removed
  # --load-extension in 137, so there the extension still needs a one-time
  # manual chrome://extensions "Load unpacked" of this store path; Chromium
  # honours the flag. Matters for the open browser decision (todo5 item 1).
  xdg.configFile."systemd/user/waverunner.service.d/webapp-extension.conf".text = ''
    [Service]
    Environment=WAVERUNNER_WEBAPP_EXTENSION=${./notification-fix}
  '';

  # Desktop plumbing every Golem needs, lean or not.
  home.packages = with pkgs; [
    papirus-icon-theme
    phinger-cursors
    wl-clipboard

    ffmpegthumbnailer # Video previews
    unar              # Archive previews
    jq                # JSON previews
    poppler           # PDF previews
    fd                # Fast file searching
    ripgrep

    awww
    waypaper

    grim
    slurp

    playerctl
  ] ++ lib.optionals (!osConfig.golem.lean) [
    # Max's dev toolchain — not part of the system working (golem.lean).
    gcc

    android-tools
    scrcpy
    jdk21

    claude-code
    github-cli
    git

    easyeffects
    lsp-plugins
  ];

  home.sessionVariables = {
    _JAVA_AWT_WM_NONREPARENTING = "1";
  } // lib.optionalAttrs (!osConfig.golem.lean) {
    # JAVA_HOME interpolates the jdk store path, so on a lean system it
    # would drag the whole JDK into the image by reference alone.
    JAVA_HOME = "${pkgs.jdk21}";
    ANDROID_HOME = "${config.home.homeDirectory}/Android/Sdk";
  };

  # ── Theming pass (roadmap S5) ─────────────────────────────────────────
  # libadwaita apps cannot be re-skinned the old GTK3 way, so "look at home"
  # means the levers they DO honour, set to what the desktop already is:
  #   accent  → #ffbe98, the active window border in hyprland.lua
  #   dark    → the whole desktop is (inactive border #3c3836, foot gruvbox)
  #   fonts   → the ones configuration.nix already ships and defaults to
  #   icons   → Papirus-Dark, the same theme waverunner's config.toml uses
  #   corners → nothing to do: libadwaita's radius isn't configurable, and
  #             Hyprland rounds every window to 12 anyway, which is what
  #             Adwaita draws — they already agree.
  # Aesthetic judgement is still Max's; this only wires the levers.
  gtk = {
    enable = true;
    font = {
      name = "DejaVu Sans";
      size = 11;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    # GTK3 apps (file-roller, simple-scan) only go dark if told to.
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;

    # libadwaita reads ~/.config/gtk-4.0/gtk.css and lets these named
    # colours be overridden — the only way to get the desktop's exact amber
    # into GNOME apps. Foreground is foot's background (#1d2021): amber is a
    # light accent, so text on top of it must be dark to stay readable.
    gtk4.extraCss = ''
      @define-color accent_color #ffbe98;
      @define-color accent_bg_color #ffbe98;
      @define-color accent_fg_color #1d2021;
    '';
  };

  # The rest of what libadwaita reads at runtime. Only keys the gtk module
  # above does NOT already write, so nothing here can conflict with it:
  # accent-color is a named palette (GNOME 47+), so "orange" is the closest
  # NAME to #ffbe98 — the exact colour comes from the CSS above, but apps
  # that ask for the name still get a warm one. Cursor is deliberately
  # absent: hyprland.lua already exports it for every client.
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    accent-color = "orange";
    document-font-name = "DejaVu Sans 11";
    monospace-font-name = "JetBrainsMono Nerd Font 11";
  };

  xdg.configFile."waypaper/config.ini".text = ''
    [Settings]
    language = en
    folder = ~/Pictures/Wallpapers
    backend = swww
    monitors = All
    fill = Fill
    sort = name
    color = #ffffff
    subfolders = False
    show_hidden = False
    show_gifs_only = False
    post_command =
    number_of_columns = 3
    swww_transition_type = outer
    swww_transition_step = 90
    swww_transition_angle = 0
    swww_transition_duration = 2
  '';

  programs.chromium = {
    enable = true;
    package = pkgs.google-chrome;
    commandLineArgs = [
      "--disable-backgrounding-occluded-windows"
      "--disable-renderer-backgrounding"
      "--disable-background-timer-throttling"
      # Hardware video decode via VA-API — without this Chrome CPU-decodes
      # everything even when the driver (system/hardware.nix) is present, and
      # a weak/old iGPU cooks itself on 1080p (2026-09-02: 2013 HD 5000 hit
      # 95 °C software-decoding VP9). VaapiIgnoreDriverChecks lets the older
      # i965 driver's VP9 path through, which Chrome would otherwise skip.
      "--enable-features=VaapiVideoDecoder,VaapiIgnoreDriverChecks"
      # Run native Wayland where the compositor offers it (else XWayland),
      # so the video path isn't bounced through Xwayland.
      "--ozone-platform-hint=auto"
    ];
  };

  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "JetBrainsMono Nerd Font:size=16";
        pad = "12x12";
        box-drawings-uses-font-glyphs = "yes";
      };
      scrollback = {
        multiplier = 10;
      };
      mouse = {
        hide-when-typing = "yes";
      };
      key-bindings = {
        clipboard-paste = "Control+v";
      };
      "colors-dark" = {
        background = "1d2021";
        foreground = "ebdbb2";
        cursor = "1d2021 928374";
        regular0 = "282828";
        regular1 = "cc241d";
        regular2 = "98971a";
        regular3 = "d79921";
        regular4 = "458588";
        regular5 = "b16286";
        regular6 = "689d6a";
        regular7 = "a89984";
        bright0 = "928374";
        bright1 = "fb4934";
        bright2 = "b8bb26";
        bright3 = "fabd2f";
        bright4 = "83a598";
        bright5 = "d3869b";
        bright6 = "8ec07c";
        bright7 = "ebdbb2";
      };
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    plugins = with pkgs.vimPlugins; [
      nvim-web-devicons
      nvim-tree-lua
      nvim-treesitter.withAllGrammars
      telescope-nvim
      plenary-nvim
      {
        plugin = neoscroll-nvim;
        type = "lua";
        config = ''
          require('neoscroll').setup({
            mappings = {
              '<C-u>', '<C-d>',
              '<C-b>', '<C-f>',
              '<C-y>', '<C-e>',
              'zt', 'zz', 'zb',
            },
            hide_cursor = false,
            stop_eof = true,
            respect_scrolloff = true,
            cursor_scrolls_alone = false,
            duration_multiplier = 0.4,
            easing = 'linear',
            performance_mode = false,
          })
        '';
      }
    ];
    initLua = ''
      vim.g.mapleader = " "
      vim.g.maplocalleader = " "
      vim.opt.number = true
      vim.opt.relativenumber = false
      vim.opt.mousescroll = "ver:1,hor:1"
      vim.opt.cursorline = true
      vim.opt.scrolloff = 999
      vim.opt.tabstop = 4
      vim.opt.shiftwidth = 4
      vim.opt.expandtab = true
      vim.opt.clipboard = "unnamedplus"
      vim.opt.timeoutlen = 300
      vim.opt.background = "dark"
      vim.cmd("colorscheme retrobox")
      local status_ok, treesitter = pcall(require, "nvim-treesitter.configs")
      if status_ok then
      treesitter.setup({
       highlight = { enable = true },
       indent = { enable = true },
      }) end
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
      require("nvim-tree").setup({
       sort = { sorter = "case_sensitive" },
       view = { width = 30 },
       renderer = { group_empty = true },
       filters = { dotfiles = false },
      })
      local opts = { noremap = true, silent = true, nowait = true }
      local builtin_ok, builtin = pcall(require, 'telescope.builtin')
      if builtin_ok then
      vim.keymap.set('n', '<leader>ff', builtin.find_files, opts)
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, opts) end
      vim.keymap.set('n', '<C-n>', '<cmd>NvimTreeToggle<CR>', opts)
      vim.keymap.set('n', '<leader>e', '<cmd>NvimTreeFocus<CR>', opts)
      vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', opts)

      -- OPTIONS app-bridge: tell Golem's Brain the file/language/diagnostics of
      -- the buffer you're in, over the options-engine bridge socket (libuv, no
      -- external dep). Powers editor-aware offers ("Open folder", the problem
      -- count). Best-effort and silent.
      local function _golem_editor_bridge()
        local xrd = os.getenv("XDG_RUNTIME_DIR")
        if not xrd then return end
        local sock = xrd .. "/options/bridge.sock"
        if not vim.loop.fs_stat(sock) then return end
        local file = vim.api.nvim_buf_get_name(0)
        if file == "" or file:match("^%w+://") then return end
        local lang = vim.bo.filetype or ""
        local diags = 0
        pcall(function()
          diags = #vim.diagnostic.get(0, { severity = { min = vim.diagnostic.severity.WARN } })
        end)
        local msg = string.format(
          '{"v":1,"kind":"editor","file":%s,"language":%s,"diagnostics":%d}',
          vim.json.encode(file), vim.json.encode(lang), diags)
        local pipe = vim.loop.new_pipe(false)
        pipe:connect(sock, function(err)
          if err then pcall(function() pipe:close() end); return end
          pipe:write(msg .. "\n", function() pcall(function() pipe:close() end) end)
        end)
      end
      vim.api.nvim_create_autocmd({ "BufEnter", "FileType", "BufWritePost", "DiagnosticChanged" }, {
        group = vim.api.nvim_create_augroup("GolemOptionsBridge", { clear = true }),
        callback = function() pcall(_golem_editor_bridge) end,
      })
    '';
  };

  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;

    settings = {
      mgr = {
        show_hidden = true;
        sort_by = "alphabetical";
      };
      manager = {
        show_hidden = true;
        sort_by = "alphabetical";
      };
    };

    theme = {
      mgr = {
        cwd = { fg = "#d79921"; bold = true; };
        hovered = { fg = "#1d2021"; bg = "#fabd2f"; bold = true; };
        selected = { fg = "#1d2021"; bg = "#b8bb26"; bold = true; };
        border = { fg = "#504945"; };
      };

      status = {
        mode_normal = { fg = "#1d2021"; bg = "#83a598"; bold = true; };
        mode_select = { fg = "#1d2021"; bg = "#b8bb26"; bold = true; };
        mode_unset = { fg = "#1d2021"; bg = "#d3869b"; bold = true; };
        permissions_t = { fg = "#83a598"; };
        permissions_r = { fg = "#fabd2f"; };
        permissions_w = { fg = "#fb4934"; };
        permissions_x = { fg = "#b8bb26"; };
      };

      filetype = {
        rules = [
          { mime = "inode/directory"; fg = "#d79921"; bold = true; }
          { mime = "image/*"; fg = "#8ec07c"; }
          { mime = "video/*"; fg = "#d3869b"; }
          { mime = "audio/*"; fg = "#b16286"; }
          { mime = "application/archive"; fg = "#fb4934"; }
          { mime = "application/zip"; fg = "#fb4934"; }
          { mime = "application/pdf"; fg = "#fabd2f"; }
        ];
      };
    };
  };

  # Hyprland raw Lua file — the /etc/nixos copy's three homedir assumptions
  # rewritten at build time: waveview loads from its store path, waverunner
  # autostarts via its systemd unit, waverunner-ctl comes from PATH.
  xdg.configFile."hypr/hyprland.lua".text =
    builtins.replaceStrings
      [
        "hyprctl plugin load /home/max/waveview/result/lib/libwaveview.so"
        ''hl.exec_cmd("/home/max/launcher/waverunner-dev")''
        "/home/max/launcher/target/debug/waverunner-ctl"
      ]
      [
        "hyprctl plugin load ${waveview}/lib/libwaveview.so"
        "-- waverunner autostarts via systemd (programs.waverunner)"
        "waverunner-ctl"
      ]
      (builtins.readFile ./hyprland.lua);

  # Waverunner config
  xdg.configFile."waverunner/config.toml".text = ''
    [theme]
    icon_theme = "Papirus-Dark"

    [options]
    # Fetch each copied link's title + og:image over the network
    # (one request per copied URL) so link clips show a real miniature.
    link_unfurl = true
  '';

  # Seed webapps list
  home.activation.seedWebappsList = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.config/webapps.list" ]; then
      $DRY_RUN_CMD install -Dm644 ${./webapps.list} "$HOME/.config/webapps.list"
    fi
  '';

  # Bundled webapp icons
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-claude.svg".source = ./webapp-claude.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-gemini.svg".source = ./webapp-gemini.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-twitch.svg".source = ./webapp-twitch.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-zoom.svg".source = ./webapp-zoom.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-snapchat.svg".source = ./webapp-snapchat.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-pinterest.svg".source = ./webapp-pinterest.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-ebay.svg".source = ./webapp-ebay.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-chatgpt.svg".source = ./webapp-chatgpt.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-stackoverflow.svg".source = ./webapp-stackoverflow.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-airbnb.svg".source = ./webapp-airbnb.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-cloudflare.svg".source = ./webapp-cloudflare.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-coinbase.svg".source = ./webapp-coinbase.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-messenger.svg".source = ./webapp-messenger.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-asana.svg".source = ./webapp-asana.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-vercel.svg".source = ./webapp-vercel.svg;

  # XDG User Directories
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    download = "$HOME/Downloads";
    documents = "$HOME/Documents";
    desktop = "$HOME/Desktop";
    pictures = "$HOME/Pictures";
    music = "$HOME/Music";
    videos = "$HOME/Videos";
    templates = "$HOME/Templates";
    publicShare = "$HOME/Public";
  };

  # ── Default apps (roadmap S5) ─────────────────────────────────────────
  # Every file type opens in the CURATE pick from golem-apps.nix. Without
  # this, "open with" is whatever alphabetical accident the desktop-file
  # scan lands on — the difference between Golem feeling assembled and
  # feeling like a pile of packages.
  #
  # Not wired here: text/html and the http/https schemes. Those ARE the
  # browser decision (todo5 item 1) — wiring them now would settle it by
  # the back door. They land in the same commit that answers it.
  #
  # First rebuild on a machine that already has a hand-written
  # ~/.config/mimeapps.list will stop and say the file is in the way:
  # move it aside, it is being replaced by this.
  xdg.mimeApps =
    let
      files = [ "org.gnome.Nautilus.desktop" ];
      editor = [ "org.gnome.TextEditor.desktop" ];
      images = [ "org.gnome.Loupe.desktop" ];
      video = [ "org.gnome.Showtime.desktop" ];
      # Decibels is the play-this-one-file player, which is exactly what a
      # double-click is. If todo5 item 6 keeps Amberol instead, this flips.
      audio = [ "org.gnome.Decibels.desktop" ];
      docs = [ "org.gnome.Papers.desktop" ];
      archives = [ "org.gnome.FileRoller.desktop" ];
    in
    {
      enable = true;
      defaultApplications = {
        "inode/directory" = files;

        "text/plain" = editor;
        "text/markdown" = editor;
        "text/csv" = editor;
        "text/x-log" = editor;
        "application/json" = editor;
        "application/xml" = editor;
        "application/x-shellscript" = editor;
        "application/toml" = editor;
        "text/x-python" = editor;
        "text/x-csrc" = editor;
        "text/x-chdr" = editor;
        "text/rust" = editor;
        "text/x-nix" = editor;

        "image/png" = images;
        "image/jpeg" = images;
        "image/gif" = images;
        "image/webp" = images;
        "image/tiff" = images;
        "image/bmp" = images;
        "image/svg+xml" = images;
        "image/heif" = images;
        "image/avif" = images;

        "video/mp4" = video;
        "video/x-matroska" = video;
        "video/webm" = video;
        "video/quicktime" = video;
        "video/x-msvideo" = video;
        "video/mpeg" = video;

        "audio/mpeg" = audio;
        "audio/flac" = audio;
        "audio/ogg" = audio;
        "audio/x-vorbis+ogg" = audio;
        "audio/x-wav" = audio;
        "audio/mp4" = audio;
        "audio/x-opus+ogg" = audio;

        "application/pdf" = docs;
        "application/epub+zip" = docs;

        "application/zip" = archives;
        "application/x-tar" = archives;
        "application/gzip" = archives;
        "application/x-xz" = archives;
        "application/zstd" = archives;
        "application/x-7z-compressed" = archives;
        "application/vnd.rar" = archives;
        "application/x-bzip2" = archives;

        "application/x-cd-image" = [ "org.gnome.DiskUtility.desktop" ];
        "text/calendar" = [ "org.gnome.Calendar.desktop" ];
        "text/vcard" = [ "org.gnome.Contacts.desktop" ];
        "x-scheme-handler/geo" = [ "org.gnome.Maps.desktop" ];
      };
    };
}
