# desktop/test-chrome — TEST-ONLY, NOT part of the real desktop.
#
# A driver / A-V / performance test vehicle: a MINIMAL Hyprland session (no
# OPTIONS bar, no waverunner — those are the real Phase-B desktop, still to
# land) that autostarts Chrome with the VA-API + native-Wayland flags. The
# whole point is to boot an installed machine straight to a running Chrome so
# GPU video decode, pipewire audio, and performance can be measured on metal
# over SSH — before the full desktop exists.
#
# This leaf is DELIBERATELY excluded from desktop/default.nix (the real desktop
# will run the OPTIONS bar, not auto-launch a browser). It is composed only into
# the `golem-desktop-test` cut. Delete-worthy the day the real desktop lands.
#
# Drive it over SSH: Chrome exposes CDP on 127.0.0.1:9222 — `ssh -L 9222:localhost:9222`
# then point a CDP client at it to load videos, read chrome://gpu, etc.
{ config, pkgs, ... }:

let
  owner = config.golem.owner;
in
{
  home-manager.users.${owner} = { ... }: {
    home.stateVersion = "26.05";

    # Chrome with the SAME VA-API flags the fat home.nix ships (truthful
    # per-codec hardware decode — see that file for the VaapiIgnoreDriverChecks
    # lesson), plus native Wayland and a localhost CDP port for SSH-driven tests.
    programs.chromium = {
      enable = true;
      package = pkgs.google-chrome;
      commandLineArgs = [
        "--enable-features=VaapiVideoDecoder"
        "--ozone-platform-hint=auto"
        "--disable-background-timer-throttling"
        "--disable-renderer-backgrounding"
        "--disable-backgrounding-occluded-windows"
        # SSH-drivable: CDP on localhost only (tunnel in to drive it).
        "--remote-debugging-port=9222"
        "--remote-debugging-address=127.0.0.1"
      ];
    };

    programs.foot.enable = true;

    # A minimal Hyprland config: autostart Chrome, a terminal, and the keys to
    # move/kill/exit — enough to test, nothing more. (The real session config
    # is hyprland.lua, arriving with the waverunner desktop leaf.)
    xdg.configFile."hypr/hyprland.conf".text = ''
      monitor = , preferred, auto, 1

      # Autostart the test browser (VA-API flags baked in by programs.chromium).
      exec-once = google-chrome-stable

      $mod = SUPER
      bind = $mod, Q, exec, foot
      bind = $mod, C, killactive,
      bind = $mod, M, exit,
      bind = $mod, F, fullscreen,
      bind = $mod, Return, exec, foot

      input {
        kb_layout = us
      }

      # LIGHT by design: this is a driver/A-V test rig, not the real OPTIONS
      # desktop. Hyprland's DEFAULT blur + shadows repaint the whole screen every
      # frame — brutal on a laptop iGPU (the "slow as fuck" the thinkpad Renoir
      # showed). Off here so the test measures the GPU/decode path, not compositor
      # effects. (The real desktop's effect-scaling by GPU class lives in
      # hyprland.lua, not this test leaf.)
      decoration {
        blur {
          enabled = false
        }
        shadow {
          enabled = false
        }
      }
      animations {
        enabled = false
      }

      # (No windowrule: a single Chrome window fills the workspace in a tiling
      # WM anyway, and $mod+F fullscreens it. A maximize rule only earned a
      # config-error overlay on 0.55.4 — dropped.)
    '';
  };
}
