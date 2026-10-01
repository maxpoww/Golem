# desktop/ups — the UPSTREAM LANE (ported from the dev box's /etc/nixos/ups.nix,
# 2026-10-01: it had never shipped in Golem; Max: "test the ups workflow on both pcs").
#
# The UPSTREAM LANE — the OPTION to run bleeding-edge upstream apps on Golem.
#
# `ups` installs upstream apps into per-app rootless containers, DELIBERATELY
# OUTSIDE Golem's declarative system. The Nix world stays reproducible and
# rollback-able; the containers ups spawns are the mutable, bleeding-edge part.
# An app takes its REAL name (`ups add opencode` -> `opencode`), shares your real
# home, and — if it has an icon — lands on the app-box automatically. It's an
# overlay: a shim in ~/.local/bin shadows the Nix command and a .desktop override
# shadows the Nix icon, so `ups erase` brings the stock app straight back. The
# base is never modified — the whole feature is reversible by construction.
#
# The design split: the TOOL is declarative (this module, shipped + reproducible);
# the APPS it creates are not. See ./ups.sh for the CLI itself.

{ pkgs, ... }:

let
  ups = pkgs.writeShellScriptBin "ups" (builtins.readFile ./ups.sh);
in
{
  # Rootless container runtime. distrobox drives podman directly — no daemon,
  # no docker socket. (Normal users get /etc/subuid + /etc/subgid ranges by default on NixOS,
  # which is all rootless podman needs.)
  virtualisation.podman.enable = true;

  # ups exports app commands into ~/.local/bin; put that on PATH for all users.
  # (It already sits AHEAD of the Nix profile dirs on PATH, so an upstream command
  # shadows the stock one — that's how "take over `claude`" works, reversibly.)
  environment.localBinInPath = true;

  environment.systemPackages = [
    pkgs.distrobox
    ups
  ];

  # Make a freshly-added command usable in the SAME terminal, immediately.
  # The `ups` script is a subprocess — it can't refresh its parent shell's
  # command hash, so a new ~/.local/bin/<app> stays invisible to zsh (which
  # caches PATH at startup) until the next `rehash` or a new terminal. Wrapping
  # `ups` in a zsh function lets `rehash` run in the interactive shell itself,
  # right after ups returns. (bash re-scans PATH on not-found, so it's fine.)
  programs.zsh.interactiveShellInit = ''
    ups() { command ups "$@"; local __rc=$?; rehash; return $__rc; }
  '';

  # Built-in recipe catalog (read-only, shipped). A user recipe at
  # ~/.config/ups/recipes.d/<name>.sh overrides the same-named built-in.
  environment.etc."ups/recipes.d/claudecode.sh".text = ''
    UPS_IMAGE="registry.fedoraproject.org/fedora-toolbox:latest"
    UPS_DESC="Anthropic Claude Code CLI — latest from npm"
    UPS_SETUP='sudo dnf install -y nodejs npm && sudo npm install -g @anthropic-ai/claude-code'
    UPS_BINS="claude"
    # No UPS_DATA on purpose: ~/.claude is your SHARED host Claude Code data
    # (login, projects, history). 'erase --purge' must never touch it.
  '';

  # opencode — terminal AI coding agent. NOTE: the npm package is `opencode-ai`
  # (plain `opencode` is a different, wrong package); the binary is `opencode`,
  # so this exports `uopencode`.
  environment.etc."ups/recipes.d/opencode.sh".text = ''
    UPS_IMAGE="registry.fedoraproject.org/fedora-toolbox:latest"
    UPS_DESC="opencode — terminal AI coding agent (latest from npm)"
    UPS_SETUP='sudo dnf install -y nodejs npm && sudo npm install -g opencode-ai'
    UPS_BINS="opencode"
    # opencode's own settings/auth/cache — safe for 'erase --purge' to remove
    # (opencode has no stock Golem build, so nothing here is shared).
    UPS_DATA="~/.config/opencode ~/.local/share/opencode ~/.local/state/opencode ~/.cache/opencode"
  '';
}
