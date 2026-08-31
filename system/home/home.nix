# Golem home layer — ported from /etc/nixos/home.nix.
# Differences from the channel version, all homedir-assumption kills:
#   • waverunner runs from its flake package via programs.waverunner
#     (systemd user service), not /home/max/launcher/waverunner-dev
#   • hyprland.lua's plugin-load / waverunner-ctl lines are rewritten to
#     store paths / PATH bins at build time (see the replaceStrings below)
{ config, pkgs, lib, waverunner, waveview, ... }:

{
  imports = [
    ./zsh.nix
    ./waverunner-packages.nix
    waverunner.homeManagerModules.default
  ];

  home.username = "max";
  home.homeDirectory = "/home/max";
  home.stateVersion = "26.05";

  programs.waverunner.enable = true;

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
    gcc

    android-tools
    scrcpy
    jdk21

    claude-code
    github-cli
    git

    awww
    waypaper

    grim
    slurp

    playerctl
    easyeffects
    lsp-plugins
  ];

  home.sessionVariables = {
    JAVA_HOME = "${pkgs.jdk21}";
    ANDROID_HOME = "${config.home.homeDirectory}/Android/Sdk";
    _JAVA_AWT_WM_NONREPARENTING = "1";
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
}
