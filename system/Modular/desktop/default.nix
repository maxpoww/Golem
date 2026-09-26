# The DESKTOP STAGE (stage 1) — everything a machine gains climbing from the
# minimal base to the Golem desktop, added BY REBUILD, never by reinstall
# (Installer/installing/spec.md, the stage ladder). Attached via the
# `golem-desktop` flake attr (base composition + this bundle); a machine climbs
# by setting golem.flakeAttr = "golem-desktop" and running rebuild-golem — the
# existing self-rebuild loop (base/loop.nix, base/selfrebuild.nix), no new
# mechanism.
#
# A plain import list, exactly like base/composition.nix: membership, not
# opinions. It grows ONE leaf per concern as each lands (spec's growth rule),
# and each leaf is a faithful port of the fat system/configuration.nix desktop
# block (or a new leaf for a hole the fat path never filled).
{ ... }:

{
  imports = [
    ./hyprland.nix          # the Wayland compositor (system half)
    ./greeter.nix           # greetd → the owner's Hyprland session
    ./audio.nix             # pipewire   (from system/audio.nix)
    ./bluetooth.nix         # bluez + blueman, census-gated (from system/bluetooth.nix)
    ./fonts.nix             # JetBrains Mono Nerd + DejaVu (from configuration.nix)
    # Phase B, still to land (see the plan):
    #   waverunner.nix   the OPTIONS bar + dock (the body of OPTIONS)
    #   waveview.nix     the Hyprland overview/spread plugin
    #   session.nix      gvfs/GIO, dconf, udisks2
    #   apps.nix         the app set          (from golem-apps.nix + systemPackages)
    #   portals.nix      xdg-desktop-portal   (NEW — absent everywhere today)
    #   ime.nix          fcitx5 + engines     (NEW — the global-input hole)
    #   printing.nix     CUPS                 (NEW — absent everywhere today)
    #   + the home layer (home-manager: hyprland.lua, waverunner, foot, neovim)
    # NOTE: desktop/test-chrome.nix is TEST-ONLY and deliberately NOT here —
    # it is composed only into the golem-desktop-test cut.
  ];
}
