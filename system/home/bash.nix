# The owner's shell on a Golem install is BASH (effect-matrix #108: plain
# bash, not zsh). Until 2026-09-30 everything the terminal was meant to have
# lived only in zsh.nix — the prompt, zoxide, fzf, `EDITOR=nvim`, and the
# OPTIONS app-bridge that tells the Brain what the terminal is doing — so an
# install got a bare bash, `EDITOR=nano`, and a Brain that never heard from
# the terminal (deep debug, parity P12). This file gives bash the same.
#
# starship, zoxide and fzf are declared in zsh.nix and integrate into bash on
# their own once bash is enabled (home-manager's enable*Integration defaults).
{ lib, pkgs, ... }:

{
  programs.bash = {
    enable = true;
    # The OPTIONS app-bridge, bash edition (the zsh original is in zsh.nix):
    # after every command, its text, exit code and cwd go to the engine's
    # bridge socket, so OPTIONS can sense terminal context (a failed build →
    # "search the error"). bash has no unix sockets of its own, so socat does
    # the one-line send, in a subshell so the prompt never waits and no job
    # notice is printed. Silent and best-effort: no socket, nothing happens.
    initExtra = lib.mkAfter ''
      # For every interactive shell, login or not: NixOS's own
      # /etc/set-environment says EDITOR=nano first, and home.sessionVariables
      # below only reach login shells (~/.profile).
      export EDITOR=nvim VISUAL=nvim TERMINAL=foot
      source ${pkgs.bash-preexec}/share/bash/bash-preexec.sh
      _golem_bridge_last=""
      _golem_bridge_send() {
        local sock="''${XDG_RUNTIME_DIR:-/run/user/$UID}/options/bridge.sock"
        [[ -S "$sock" ]] || return 0
        ( printf '%s\n' "$1" | ${pkgs.socat}/bin/socat -T1 - "UNIX-CONNECT:$sock" >/dev/null 2>&1 & )
      }
      preexec() { _golem_bridge_last="$1"; }
      precmd() {
        local ec=$?
        [[ -n "$_golem_bridge_last" ]] || return 0
        local c="''${_golem_bridge_last//\\/\\\\}"; c="''${c//\"/\\\"}"; c="''${c//$'\n'/ }"
        local d="''${PWD//\\/\\\\}"; d="''${d//\"/\\\"}"
        _golem_bridge_send "{\"v\":1,\"kind\":\"shell\",\"last_cmd\":\"$c\",\"exit_code\":$ec,\"cwd\":\"$d\"}"
        _golem_bridge_last=""
      }
    '';
  };

  # The editor and the terminal every app should use. Set here for the
  # shell's own environment; hyprland.lua sets the same for apps launched
  # from a keybind (a .desktop entry with Terminal=true needs $TERMINAL).
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERMINAL = "foot";
  };
}
