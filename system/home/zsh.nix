{ pkgs, config, ... }:

{
  # System utilities
  home.packages = with pkgs; [
    eza
    bat
    ripgrep
    fd
    fzf
    zoxide
    mpv
    lf
  ];

  # Starship Prompt
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    
    settings = {
      "$schema" = "https://starship.rs/config-schema.json";
      add_newline = true;
      format = "$directory$os$git_branch$git_status$nodejs$rust$golang$php $character";

      os = {
        disabled = false;
        format = "[$symbol](#blue) ";
        symbols.NixOS = "";
      };

      directory = {
        format = "[$path](cyan) ";
        truncation_length = 4;
        truncate_to_repo = true;
      };

      git_branch = {
        symbol = "";
        format = "[$symbol $branch](bold purple) ";
      };

      git_status = {
        format = "($ahead_behind$staged$modified$untracked$deleted$conflicted)";
        ahead = "[⇡$count ](bold cyan)";
        behind = "[⇣$count ](bold cyan)";
        diverged = "[⇡$ahead_count⇣$behind_count ](bold cyan)";
        staged = "[+$count ](bold green)";
        modified = "[●$count ](bold yellow)";
        untracked = "[?$count ](bold white)";
        deleted = "[✘$count ](bold red)";
        conflicted = "[⚡$count ](bold red)";
      };

      nodejs.format = "[$symbol $version](green) ";
      rust.format = "[$symbol $version](red) ";
      golang.format = "[$symbol $version](cyan) ";
      php.format = "[$symbol $version](purple) ";

      character = {
        success_symbol = "[❯](green)";
        error_symbol = "[❯](red)";
        vimcmd_symbol = "[❮](blue)";
      };
    };
  };

  # Integrations
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --strip-cwd-prefix";
    fileWidgetCommand = "fd --type f --hidden --strip-cwd-prefix";
    defaultOptions = [
      "--height=60%"
      "--layout=reverse"
      "--border=rounded"
      "--prompt=  "
      "--pointer=  "
      "--preview-window=right:65%:wrap:border-left"
    ];
    fileWidgetOptions = [
      "--preview 'bat --color=always --style=plain,numbers --line-range=:500 {}'"
    ];
  };


  # Main Zsh Configuration
  programs.zsh = {
    enable = true;

    # Dedicated module integrations for plugins
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;

    history = {
      size = 100000;
      save = 100000;
      path = "${config.xdg.stateHome}/zsh/history";
      append = true;
      share = true;
      ignoreDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
    };

    autocd = true;

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      MANPAGER = "bat -l man -p";
      GPG_TTY = "$(tty)";
      VIRTUAL_ENV_DISABLE_PROMPT = "1";
      _FZF_PREVIEW_CMD = "bat --color=always --style=plain,numbers --line-range=:500 {}";
      LF_ICONS = "di=📁:fi=📄:ln=🔗:or=❌:ex=⚡"; 
    };

    shellAliases = {
      # Nixos 
      build = "rebuild-golem && hyprctl reload";
      update = "sudo nixos-rebuild switch --upgrade && hyprctl reload"; 

      # Better ls
      ls = "eza --icons";
      ll = "eza -lh --icons --git";
      la = "eza -lah --icons --git";
      tree = "eza --tree --icons";

      # Core utilities
      cat = "bat";
      grep = "rg --color=auto";
      diff = "diff --color=auto";
      df = "df -h";

      # Navigation
      "-" = "cd -";

      # Editor
      edit  = "sudo -E nvim";

      # Git
      glog = "PAGER=\"less -F -X\" git log";
      gadog = "PAGER=\"less -F -X\" git log --all --decorate --oneline --graph";
      dotfiles = "git --git-dir=$HOME/.dotfiles --work-tree=$HOME";

      # Video
      stream = "mpv av://v4l2:/dev/video4 --fullscreen --demuxer-lavf-o=input_format=mjpeg,framerate=30 --profile=low-latency --untimed";
    };

    # Nix-native plugins (zsh-vi-mode fixed using store path string interpolation)
    plugins = [
      {
        name = "zsh-vi-mode";
        src = "${pkgs.zsh-vi-mode}/share/zsh-vi-mode";
      }
    ];

    # Updated to initContent (Home Manager 26.05+)
    initContent = ''
      # Shell options
      setopt NOBEEP
      setopt NUMERIC_GLOB_SORT

      # Completion setup
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
      compdef eza=ls

      # Custom lf wrapper function
      lf() {
        tmp="$(mktemp)"
        command lf -last-dir-path="$tmp" "$@"
        if [ -f "$tmp" ]; then
          dir="$(cat "$tmp")"
          rm -f "$tmp"
          [ -d "$dir" ] && [ "$dir" != "$(pwd)" ] && cd "$dir"
        fi
      }

      # Custom fzf file picker (no hidden files)
      _fzf_file_no_hidden() {
        local cmd result
        cmd="fd --type f --strip-cwd-prefix"
        result=$(eval "$cmd" | fzf --preview "$_FZF_PREVIEW_CMD") && LBUFFER+="$result"
        zle reset-prompt
      }
      zle -N _fzf_file_no_hidden

      # zsh-vi-mode Configuration
      ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM
      ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
      ZVM_VISUAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK

      ZVM_VI_HIGHLIGHT_BACKGROUND=none
      ZVM_VI_HIGHLIGHT_FOREGROUND=none
      ZVM_VI_HIGHLIGHT_EXTRASTYLE=none

      zvm_after_init() {
        bindkey '^[[1;5C' forward-word
        bindkey '^[[1;5D' backward-word
        bindkey '^F' _fzf_file_no_hidden
        bindkey '^\' autosuggest-toggle
        bindkey '^[[A' history-substring-search-up
        bindkey '^[[B' history-substring-search-down
      }
    '';
  };
}
