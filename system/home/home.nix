# Golem's home layer: the desktop of EVERY Golem machine, the dev box included
# (parity P1, 2026-09-30: the dev box imports this directory from its
# /etc/nixos/home.nix instead of keeping its own copy). What differs per
# machine is an option in ./options.nix, set by that machine's layer.
#
# On an install (golem.home.devCheckout = false, the default):
#   • waverunner runs from its flake package via programs.waverunner
#     (systemd user service), not /home/max/launcher/waverunner-dev
#   • hyprland.lua's plugin-load / waverunner-ctl lines are rewritten to
#     store paths / PATH bins at build time (see the replaceStrings below)
# On the dev box (devCheckout = true) both stay pointed at the live checkouts.
{ config, osConfig, pkgs, lib, waverunner, waveview, ... }:

let
  dev = config.golem.home.devCheckout;
  # VK_LOADER_DRIVERS_SELECT from the GPUs present (PCI vendor ids), then
  # exec the command. No GPU found or one we don't know: no selection.
  vulkanDrivers = pkgs.writeShellScript "golem-vulkan-drivers" ''
    sel=""; known=1
    for v in /sys/class/drm/card*/device/vendor; do
      [ -r "$v" ] || continue
      case "$(cat "$v")" in
        0x8086) sel="$sel,*intel*" ;;
        0x1002) sel="$sel,*radeon*" ;;
        0x10de) sel="$sel,*nouveau*,*nvidia*" ;;
        0x1af4) sel="$sel,*virtio*" ;;
        *) known=0 ;;
      esac
    done
    if [ "$known" = 1 ] && [ -n "$sel" ]; then
      export VK_LOADER_DRIVERS_SELECT="''${sel#,}"
    fi
    exec "$@"
  '';
  # Golem's own icons (tools/icons writes them): folders, files, devices in
  # the dock's cast metal, in two tones — Golem (silver, the light look) and
  # Golem-Dark (graphite, the dark one); the dock's Dark mode switches the
  # apps and itself between them. Every other name falls through to Papirus.
  golemIcons = pkgs.runCommand "golem-icon-theme" { } ''
    mkdir -p $out/share/icons
    cp -r --no-preserve=mode ${./icons/Golem} $out/share/icons/Golem
    cp -r --no-preserve=mode ${./icons/Golem-Dark} $out/share/icons/Golem-Dark
  '';
in
{
  imports = [
    ./options.nix         # the per-machine knobs (devCheckout, idle, hyprlandExtra)
    ../../seam/home.nix   # Seam: prefs, look, and the profile
    ./zsh.nix
    ./menubox.nix         # the menubox shows Seam only; the rest stays installed, hidden
    ./bash.nix            # the owner's bash: prompt, EDITOR, the OPTIONS shell bridge (P12)
    ./idle.nix            # hypridle + hyprlock: lock, screen off, suspend on idle (P11)
    ./fits.nix            # an app the owner installs works the moment it lands (OBS)
    ./phone.nix           # a plugged-in Android: mirror its screen, use it as the camera
    waverunner.homeManagerModules.default
  ];
  # ./waverunner-packages.nix (the owner's launcher-installed list) is NOT
  # imported here any more — configuration.nix imports it for non-lean
  # systems only. It is one machine's state, not the distro: a lean image
  # (the ISO) must not inherit android-studio because Max once dragged it
  # into the Install section. Imports can't be conditional inside a module,
  # so the switch lives at the NixOS level.

  # The account this home layer configures follows the machine's owner
  # (golem.owner) — the S9 installer renames ONE option, not five files.
  home.username = osConfig.golem.owner;
  home.homeDirectory = "/home/${osConfig.golem.owner}";
  home.stateVersion = "26.05";

  # Tell systemd-oomd (enabled at the system level for the low-RAM freeze
  # guard) to never pick the dock daemon as its victim under memory pressure —
  # it should reap the runaway app instead. This lives here, not in
  # configuration.nix, because waverunner is a home-manager user unit and a
  # NixOS-level systemd.user override is shadowed by the ~/.config copy.
  # (Installs only: on the dev box the dock is not a systemd unit.)
  systemd.user.services.waverunner = lib.mkIf (!dev) {
    Service.ManagedOOMPreference = "avoid";
    # Only the Vulkan drivers for the GPUs this machine has. The loader opens
    # EVERY installed driver otherwise — 13 of them on a Golem, ~200 MB, and
    # lavapipe + radeon pull in LLVM (180 MB) — once per dock surface. On
    # the Acer's spinning disk that cost ~5 s before the first pixel (night
    # dogfood, 2026-10-03). An unknown GPU keeps the loader's full list.
    Service.ExecStart = lib.mkForce "${vulkanDrivers} ${config.programs.waverunner.package}/bin/waverunner";
    Service.SyslogIdentifier = "waverunner";   # not the wrapper's store name
  };

  programs.waverunner.enable = !dev;
  # The Install section offers Golem's checked package list, never the
  # launcher's raw one: only packages that can actually install on this
  # nixpkgs (617 of ~23,700 could not, 2026-10-01), and no laptop ever runs
  # the ~6.5 GB evaluation that builds it. tools/package-index/refresh.sh
  # regenerates it whenever flake.lock's nixpkgs moves (the matrix insists).
  programs.waverunner.packageIndex = pkgs.runCommand "golem-package-index" { } ''
    install -D -m644 ${./package-index.tsv} $out/share/waverunner/nixpkgs-index.tsv
  '';

  # Desktop plumbing every Golem needs, lean or not.
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
    poppler           # PDF previews
    # MORE THUMBNAILS (Max, 2026-10-15: "as many files as possible as
    # thumbnails"): Golem Files runs every freedesktop .thumbnailer these bring.
    poppler-utils           # pdftoppm: a PDF's first page
    gnome-epub-thumbnailer  # an epub's / mobi's cover
    libgsf                  # gsf-office-thumbnailer: Word, Excel, PowerPoint, LibreOffice
    exiftool                # a camera RAW photo's own JPEG (dcraw is marked insecure)
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
    hyprsunset        # the SUNSET option's warm screen (daemon screen.rs runs it);
                      # only the dev box had it until 2026-09-30, so "turn on" did
                      # nothing on an install (found by the P1 diff)

    playerctl

    git
    xdg-terminal-exec # a .desktop entry with Terminal=true opens in the terminal below
    libnotify         # notify-send: the standard way a script or app posts a notification
  ];

  # Which terminal a Terminal=true entry (nvim.desktop, …) opens in.
  xdg.configFile."xdg-terminals.list".text = "foot.desktop\n";

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
  # in that machine's own config (/etc/nixos), not in Golem.

  home.sessionVariables = {
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };

  # ── Theming pass (roadmap S5) ─────────────────────────────────────────
  # libadwaita apps cannot be re-skinned the old GTK3 way, so "look at home"
  # means the levers they DO honour, set to what the desktop already is:
  #   colours → THE PALETTE (Controls → Colours, waverunner palette.rs): the
  #             dock writes it for GTK 3/4, foot, hyprlock and Qt into
  #             ~/.local/state/golem/theme, and these configs import it
  #   dark    → the palette's dark variant; the dock flips the look live
  #   fonts   → the ones configuration.nix already ships and defaults to
  #   icons   → Golem-Dark (system/home/icons, built by tools/icons): Golem's
  #             own folders, files and devices, inheriting Papirus-Dark for the
  #             rest; Golem in the light look. waverunner's config.toml names
  #             "Golem" and the dock picks the tone itself
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
      # Golem ships dark; the dock writes the light one when that is chosen.
      name = "Golem-Dark";
      package = golemIcons;
    };
    # No prefer-dark-theme: the look is the dock's to set, live — GTK 3 wears
    # the palette's theme over adw-gtk3 or adw-gtk3-dark by look (waverunner
    # palette.rs), libadwaita follows the portal's colour scheme (and warns
    # about this key, which it ignores). Forced dark here kept GTK 3 apps dark
    # in the light look (2026-10-15).
    # No window buttons in the apps' own header bars: Golem's titlebar
    # already has close/minimize/maximize (red/yellow/green), and GNOME apps
    # showed a second close × beside it (ASUS dogfood, 2026-10-02; Max: "yes
    # hide it, floating is the default anyway"). The libadwaita half is the
    # dconf key below; these cover GTK3/GTK4 apps reading settings.ini.
    gtk3.extraConfig.gtk-decoration-layout = ":";
    gtk4.extraConfig.gtk-decoration-layout = ":";

    # THE PALETTE (Controls → Colours): libadwaita reads
    # ~/.config/gtk-4.0/gtk.css, which only imports what the dock writes —
    # every libadwaita colour variable, both looks (a dark/light switch is
    # live in running apps; a palette or accent change at their next start).
    gtk4.extraCss = ''
      @import url("file://${config.home.homeDirectory}/.local/state/golem/theme/gtk4.css");
    '';
    # GTK 3 has no user stylesheet: its apps wear the palette as a THEME the
    # dock writes over adw-gtk3 (below) and switches by name, which GTK 3
    # reloads live — a user gtk.css is read once and would pin the old one.
  };

  # The rest of what libadwaita reads at runtime. Only keys the gtk module
  # above does NOT already write, so nothing here can conflict with it:
  # accent-color is a named palette (GNOME 47+), so "orange" is the closest
  # NAME to #ffbe98 — the exact colour comes from the CSS above, but apps
  # that ask for the name still get a warm one. Cursor is deliberately
  # absent: hyprland.lua already exports it for every client.
  dconf.settings."org/gnome/desktop/wm/preferences".button-layout = ":";   # see gtk-decoration-layout above
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    accent-color = "orange";
    document-font-name = "DejaVu Sans 11";
    monospace-font-name = "JetBrainsMono Nerd Font 11";
  };

  # No Chrome: Seam is Golem's only browser (the debloat, 2026-09-29). The
  # webapps (Chrome --app windows) come back when they move onto Seam.

  programs.foot = {
    enable = true;
    settings = {
      main = {
        # The colours are the PALETTE's (Controls → Colours): the dock writes
        # both variants there and switches running terminals between them
        # with a signal (waverunner palette.rs). Seeded empty below, so a
        # terminal opened before the dock's first write still starts.
        include = "~/.local/state/golem/theme/foot.ini";
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
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    plugins = with pkgs.vimPlugins; [
      mini-nvim   # mini.base16: THE PALETTE's colours (the dock's nvim.lua, below)
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
      -- THE PALETTE (Controls → Colours): the dock writes nvim.lua (mini.base16
      -- with its sixteen colours, at the look in use); read at each start.
      -- Without it, the old retrobox.
      local golem_theme = vim.fn.expand("~/.local/state/golem/theme/nvim.lua")
      if not (vim.fn.filereadable(golem_theme) == 1 and pcall(dofile, golem_theme)) then
        vim.opt.background = "dark"
        vim.cmd("colorscheme retrobox")
      end
      -- …and an open editor follows a change of palette, accent or look: the
      -- dock rewrites the file (a rename into place), so its folder is watched.
      local golem_watch = vim.uv.new_fs_event()
      if golem_watch then
        golem_watch:start(vim.fn.fnamemodify(golem_theme, ":h"), {}, vim.schedule_wrap(function(_, name)
          if name == "nvim.lua" and vim.fn.filereadable(golem_theme) == 1 then pcall(dofile, golem_theme) end
        end))
      end
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

    # THE PALETTE: the terminal's colour NAMES, not hex — foot's sixteen are
    # the palette's (the dock's foot.ini), so yazi follows Controls → Colours
    # and dark/light with no file of its own. (Was a fixed gruvbox.)
    theme = {
      mgr = {
        cwd = { fg = "yellow"; bold = true; };
        hovered = { fg = "black"; bg = "yellow"; bold = true; };
        selected = { fg = "black"; bg = "green"; bold = true; };
        border = { fg = "darkgray"; };
      };

      status = {
        mode_normal = { fg = "black"; bg = "blue"; bold = true; };
        mode_select = { fg = "black"; bg = "green"; bold = true; };
        mode_unset = { fg = "black"; bg = "magenta"; bold = true; };
        permissions_t = { fg = "blue"; };
        permissions_r = { fg = "yellow"; };
        permissions_w = { fg = "red"; };
        permissions_x = { fg = "green"; };
      };

      filetype = {
        rules = [
          { mime = "inode/directory"; fg = "yellow"; bold = true; }
          { mime = "image/*"; fg = "cyan"; }
          { mime = "video/*"; fg = "magenta"; }
          { mime = "audio/*"; fg = "magenta"; }
          { mime = "application/archive"; fg = "red"; }
          { mime = "application/zip"; fg = "red"; }
          { mime = "application/pdf"; fg = "yellow"; }
        ];
      };
    };
  };

  # Hyprland raw Lua file — the /etc/nixos copy's three homedir assumptions
  # rewritten at build time: waveview loads from its store path, waverunner
  # autostarts via its systemd unit, waverunner-ctl comes from PATH.
  # GUARD (release-checklist §2.6): replaceStrings never errors on a missed
  # needle — if hyprland.lua is edited so a needle no longer matches, a
  # stranger's machine would silently load the plugin from /home/max and come
  # up without the overview. So a missing needle is an EVAL failure, not a
  # silent ship.
  xdg.configFile."hypr/hyprland.lua".text =
    let
      raw = builtins.readFile ./hyprland.lua;

      # HiDPI from the census (golem.hardware.panelDpi — EDID width vs
      # native mode, eDP only): a generated monitor rule for the internal
      # panel lands right after the catch-all, so a 4K-13" stranger's
      # laptop doesn't boot at ant size while externals stay at the
      # catch-all's scale. Tiers calibrated against the one measured
      # point: the Slim Pro 9i's 260 DPI panel, hand-tuned to 1.60 (the
      # desc override below it — which still wins there, agreeing).
      # 0 (unknown) or ordinary panels: no rule, catch-all behavior —
      # the 1366x768 Acer lesson of 2026-09-02 stays fixed.
      panelDpi = osConfig.golem.hardware.panelDpi;
      edpScale =
        if panelDpi >= 280 then "2.0"
        else if panelDpi >= 210 then "1.6"
        else if panelDpi >= 170 then "1.25"
        else null;
      monitorNeedle =
        ''hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })'';

      # KEYBOARD, from the installer's one question (golem.keyboard).
      # Hyprland does NOT read services.xserver.xkb — it has its own input
      # block, so this is the sink that decides what the owner actually
      # types into. The other two (console.keyMap, services.xserver.xkb)
      # are set in system/configuration.nix; all three come from the same
      # option so they cannot drift.
      #
      # The literal below is what a dev checkout wants (us, no variant);
      # the needle swaps in the machine's real answer. A stranger who picked
      # Colemak gets layout us / variant colemak here, and a Russian gets
      # "ru,us" with grp:alt_shift_toggle so they can still type a URL.
      # Double-quoted, not ''-quoted: an indented string strips its common
      # leading whitespace, which would silently produce a needle that can
      # never match the eight-space indent inside hyprland.lua's input
      # block. The guard below caught exactly that; the pad is named once
      # so it cannot drift from the file.
      kb = osConfig.golem.keyboard;
      kbPad = "        ";
      kbNeedle = lib.concatStringsSep "\n" [
        "${kbPad}kb_layout  = \"us\","
        "${kbPad}kb_variant = \"\","
        "${kbPad}kb_model   = \"\","
        "${kbPad}kb_options = \"\","
      ];

      # SHELL follows the owner's REAL login shell. The literal in
      # hyprland.lua is the dev box's zsh; on a Golem install the login
      # shell is plain bash (base/shell.nix) and no system zsh exists, so
      # every bare `foot` (Super+E) exec'd a missing $SHELL and died
      # instantly — "failed to execute zsh: No such file" (thinkpad,
      # 2026-09-29). Derived from users.users.<owner>.shell, it stays zsh
      # wherever the owner's shell IS zsh.
      ownerShell =
        let s = osConfig.users.users.${osConfig.golem.owner}.shell; in
        if builtins.isString s then s else "/run/current-system/sw${s.shellPath}";
      shellNeedle = ''hl.env("SHELL",          "/run/current-system/sw/bin/zsh")'';

      # BLUETOOTH autostart only where there IS Bluetooth: the census turns
      # the stack off on a machine without an adapter (desktop/bluetooth.nix),
      # and the session still exec'd bluetoothctl — two
      # commands with no program (ASUS X550LC parity, 2026-10-02).
      btNeedle = lib.concatStringsSep "\n" [
        ''hl.exec_cmd("bluetoothctl power on")''
        ''hl.exec_cmd("sleep 2 && bluetoothctl devices Trusted | awk '{print $2}' | xargs -I {} bluetoothctl connect {}")''
      ];
      hasBluetooth = osConfig.hardware.bluetooth.enable or true;

      # The shell's three live-checkout paths become store paths / PATH bins
      # on an install; the dev box keeps them (golem.home.devCheckout), which
      # is its whole edit-build-restart loop. Built as conditional lists, so a
      # dev eval never forces the waveview input.
      shellNeedles = lib.optionals (!dev) [
        "hyprctl plugin load /home/max/waveview/result/lib/libwaveview.so"
        ''hl.exec_cmd("/home/max/launcher/waverunner-dev")''
        "/home/max/launcher/target/debug/waverunner-ctl"
      ];
      shellReplacements = lib.optionals (!dev) [
        "hyprctl plugin load ${waveview}/lib/libwaveview.so"
        "-- waverunner autostarts via systemd (programs.waverunner)"
        "waverunner-ctl"
      ];
      needles = shellNeedles ++ [
        monitorNeedle
        kbNeedle
        shellNeedle
        btNeedle
      ];
      replacements = shellReplacements ++ [
        (if edpScale == null then monitorNeedle else ''
          ${monitorNeedle}
          -- generated from the panelDpi fact (${toString panelDpi} DPI)
          hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = ${edpScale} })'')
        (lib.concatStringsSep "\n" [
          "${kbPad}-- generated from golem.keyboard (the installer's keyboard step)"
          "${kbPad}kb_layout  = \"${kb.layout}\","
          "${kbPad}kb_variant = \"${kb.variant}\","
          "${kbPad}kb_model   = \"${kb.model}\","
          "${kbPad}kb_options = \"${kb.options}\","
        ])
        ''hl.env("SHELL",          "${ownerShell}")''
        (if hasBluetooth then btNeedle else "-- no Bluetooth adapter on this machine (census): no Bluetooth autostart")
      ];
      missing = builtins.filter (n: !(lib.hasInfix n raw)) needles;
    in
    assert lib.assertMsg (missing == [ ]) ''
      hyprland.lua rewrite needle(s) no longer match — a built system would
      silently keep the /home/max path(s) and boot without the overview.
      Update the needles in system/home/home.nix to match hyprland.lua:
      ${lib.concatMapStrings (n: "  MISSING: " + n + "\n") missing}'';
    builtins.replaceStrings needles replacements raw
    # Weak GPU (golem.desktop.effects = "light", set by gpu/intel-legacy):
    # no compositor blur. Appended last, so it wins over the decoration block.
    # `or`: the fat profile doesn't declare the option and keeps full effects.
    + lib.optionalString ((osConfig.golem.desktop.effects or "full") == "light") ''

      ---- LIGHT EFFECTS (golem.desktop.effects = "light") ----
      -- Generated for a weak GPU: Hyprland's blur off. On the 2013 MacBook
      -- Air it held the 3D engine at 98% during video; the rest of the look
      -- (shadows, dimming, rounding) costs nothing measurable and stays.
      hl.config({ decoration = { blur = { enabled = false } } })
    ''
    # This machine's own Lua (golem.home.hyprlandExtra), after everything
    # Golem declares.
    + lib.optionalString (config.golem.home.hyprlandExtra != "") (
      "\n" + config.golem.home.hyprlandExtra)
    # The owner's LIVE SETTINGS, truly last: what was chosen in the control
    # panel wins over everything declared above (docs/system/LiveSettings.md).
    + ''

      ---- LIVE SETTINGS (the control panel) ----
      -- What the owner chose in the control panel (a screen's scale and
      -- resolution so far). The dock sets a choice live and saves it to
      -- ~/.config/golem/settings.json, with a copy as Lua beside it. That
      -- copy runs here, last: a choice wins over every default above, is on
      -- the screen from the compositor's first frame, and comes back on
      -- every reload, whether or not the dock is running.
      -- dofile, not require: a required file is watched, and each click in
      -- the panel would reload this whole config. A missing or broken file
      -- changes nothing.
      do
          local dir = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
          local path = dir .. "/golem/settings.lua"
          local file = io.open(path, "r")
          if file then
              file:close()
              local ok, err = pcall(dofile, path)
              if not ok then
                  print("golem: live settings not applied: " .. tostring(err))
              end
          end
      end
    '';

  # Waverunner config
  xdg.configFile."waverunner/config.toml".text = ''
    [theme]
    icon_theme = "Golem"
  ''
  # Weak GPU (golem.desktop.effects = "light"): the compositor does not blur
  # what is behind the shell, so the dock's glass (the dock, the apps card,
  # the box panels: all built from this one colour, 50% by default) showed
  # the raw page straight through its labels. Denser glass, still glass
  # (Max, 2026-10-01, picked on the MacBook: 90%). `or`: the fat profile
  # doesn't declare the option and keeps the default.
  # Every OPEN box (the menubox, group boxes, OPTIONS boxes) goes denser: at 90% a
  # page's titles read straight through it with nothing blurring them (ASUS
  # X550LC, 2026-10-02; tried live at 98 and 95 %, Max: "95 it is").
  + lib.optionalString ((osConfig.golem.desktop.effects or "full") == "light") ''
    background = "#050709e6"
    open_opacity = 0.95
  ''
  + ''

    [options]
    # Fetch each copied link's title + og:image over the network
    # (one request per copied URL) so link clips show a real miniature.
    link_unfurl = true
  '';

  # The webapps catalog: the dock's Install section offers these, and a webapp
  # runs in Seam (seam -golem-app <slug> <url>, the WEBAPPS module in
  # seam/golem-chrome.js). Seeded once and then the owner's to edit: the dock
  # owns the file after that. (Held back 2026-09-29..30 while webapps still
  # launched through Chrome, which Golem does not ship.)
  home.activation.seedWebappsList = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.config/webapps.list" ]; then
      $DRY_RUN_CMD install -Dm644 ${./webapps.list} "$HOME/.config/webapps.list"
    fi
  '';

  # The palette's files exist before the dock first writes them (it does at
  # every start): foot and hyprlock report an include that is not there as
  # a config error. Empty is fine — foot's own colours, hyprlock's defaults.
  home.activation.seedPaletteFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dir="$HOME/.local/state/golem/theme"
    $DRY_RUN_CMD mkdir -p "$dir"
    for f in foot.ini hyprlock.conf; do
      [ -e "$dir/$f" ] || $DRY_RUN_CMD touch "$dir/$f"
    done
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

  # XDG User Directories — localized, not hardcoded English.
  #
  # home-manager's xdg.userDirs writes fixed names ("$HOME/Downloads"), which
  # gave a Portuguese install English folders — the thing Max called out. The
  # names must follow the chosen language (Transferências, Documentos, …), and
  # for languages we don't want to hand-maintain a table for. So we DON'T let
  # home-manager own the file (a store symlink would also fight the update);
  # instead xdg-user-dirs-update generates ~/.config/user-dirs.dirs from the
  # session LANG using the tool's own authoritative translations, and creates
  # the folders. It respects a user's later renames (no --force), and on an
  # already-English machine (Max's) leaves the existing folders untouched.
  xdg.userDirs.enable = false;

  systemd.user.services.golem-user-dirs = {
    Unit = {
      Description = "Localize XDG user dirs to the session language";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      # Source /etc/locale.conf so LANG is the system's chosen locale even
      # before the user manager imports the session environment — that is what
      # picks the translation. gettext needs a non-C LC_MESSAGES, which LANG
      # provides.
      ExecStart = "${pkgs.writeShellScript "golem-user-dirs" ''
        set -a
        # shellcheck disable=SC1091
        [ -r /etc/locale.conf ] && . /etc/locale.conf
        # The owner's own language, when they have one (the control panel's
        # Language, or the installer's seed of it — see base/user-dirs.nix):
        # on a fresh install the session speaks it before the system does.
        chosen=$(${pkgs.gnused}/bin/sed -n 's/.*"language"[[:space:]]*:[[:space:]]*"\([A-Za-z_.@0-9-]*\)".*/\1/p' \
          "''${XDG_CONFIG_HOME:-$HOME/.config}/golem/settings.json" 2>/dev/null | ${pkgs.coreutils}/bin/head -n1)
        if [ -n "$chosen" ]; then
          LANG=$chosen
          LC_MESSAGES=$chosen
          unset LC_ALL LANGUAGE
        fi
        set +a
        exec ${pkgs.xdg-user-dirs}/bin/xdg-user-dirs-update
      ''}";
    };
    Install.WantedBy = [ "default.target" ];
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
      # Folders open in Golem Files — the shell's own file manager, whose
      # launcher the dock writes at its first start (launcher `filer.rs`);
      # Nautilus stays installed and is next in line.
      files = [
        "golem-files.desktop"
        "org.gnome.Nautilus.desktop"
      ];
      editor = [ "org.gnome.TextEditor.desktop" ];
      images = [ "org.gnome.Loupe.desktop" ];
      # mpv plays both (zsh.nix ships it with MPRIS); Showtime and Decibels
      # left with the debloat (2026-09-29).
      video = [ "mpv.desktop" ];
      audio = [ "mpv.desktop" ];
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

  # Golem's defaults sit BELOW the owner's choice (2026-10-13, the control
  # panel's "Default apps"). home-manager writes the table twice: as
  # ~/.config/mimeapps.list, and as ~/.local/share/applications/mimeapps.list.
  # The first is the file `xdg-mime default` and every "always open with" box
  # write to — as a read-only link of ours nobody could ever change a default
  # (the panel's pick failed in silence, so did Nautilus'). So only the
  # second is ours: the lookup reads the owner's file first and falls through
  # to it, type by type.
  xdg.configFile."mimeapps.list".enable = lib.mkForce false;
}
