# desktop/hyprland — the Wayland compositor, stage 1's floor (spec.md: the
# desktop stage, applied by rebuild). Ported from the fat system/configuration.nix
# desktop block: programs.hyprland (uwsm + xwayland), the xkb sinks XWayland
# clients read, uinput for the virtual gamepad, and the desktop-only groups the
# owner gains at this stage.
#
# THE SPLIT: this is the SYSTEM half of the compositor. Hyprland's own config —
# keybinds, monitors, the OPTIONS bar / plugin wiring — lives in the home layer's
# hyprland.lua (home-manager), which arrives with its own desktop leaf. Enabling
# the program here is what makes the uwsm session unit exist for greeter.nix.
{ config, lib, ... }:

{
  programs.hyprland = {
    enable = true;
    withUWSM = true;          # greetd launches hyprland-uwsm.desktop (see greeter.nix)
    xwayland.enable = true;   # X11 clients under XWayland
  };

  # THREE keyboard sinks, not interchangeable (fat config's lesson): the TTY
  # reads console.keyMap (base/console.nix), XWayland clients read
  # services.xserver.xkb (here), and Hyprland's native input reads NEITHER — it
  # has its own block in hyprland.lua. Setting only two leaves the session on us.
  # From the installer's one keyboard answer (golem.keyboard).
  services.xserver = {
    enable = true;
    xkb = {
      layout  = lib.mkDefault config.golem.keyboard.layout;
      variant = lib.mkDefault config.golem.keyboard.variant;
      options = lib.mkDefault config.golem.keyboard.options;
      model   = lib.mkDefault config.golem.keyboard.model;
    };
  };

  # A virtual gamepad: games read evdev directly (no Wayland gamepad protocol),
  # so uinput is how a controller reaches them. The owner joins uinput + adbusers
  # at the desktop stage — extraGroups MERGES with base/users.nix's stage-0 set
  # (networkmanager/wheel/video/input); membership is picked up on a fresh login.
  hardware.uinput.enable = true;
  users.users.${config.golem.owner}.extraGroups = [ "uinput" "adbusers" ];
}
