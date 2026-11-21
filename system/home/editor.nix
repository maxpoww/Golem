# The editor: neovim.
{ pkgs, ... }:

{
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

      -- OPTIONS app-bridge: tell Standard's Brain the file/language/diagnostics of
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
}
