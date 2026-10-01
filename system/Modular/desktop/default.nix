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
{ lib, ... }:

{
  imports = [
    ./hyprland.nix          # the Wayland compositor (system half)
    ./greeter.nix           # greetd → the owner's Hyprland session
    ./audio.nix             # pipewire   (from system/audio.nix)
    ./bluetooth.nix         # bluez + blueman, census-gated (from system/bluetooth.nix)
    ./fonts.nix             # JetBrains Mono Nerd + DejaVu (from configuration.nix)
    ../../../seam           # Seam, Golem's browser (system half: build + policies +
                            # update lane). Its home half (seam/home.nix) needs the
                            # golem-seam overlay this module provides — without it the
                            # home layer fails to evaluate (pkgs.golem-seam missing).
    ../../golem-brightness.nix  # the brightness keys' helper: finds the backlight of the
                            # connected panel (was only in the fat profile → the keys
                            # ran a missing program on every install; golem-parity
                            # finding, thinkpad 2026-09-29)
    ./apps.nix              # the file-opening core (Nautilus, Loupe, Papers, Text Editor,
                            # File Roller) + system-wide emoji input — from golem-apps.nix
    ./session.nix           # gvfs, dconf, udisks2, gsettings: what those apps assume
    ./idle.nix              # hyprlock's PAM service (the idle daemon is the home layer's)
    ./ups.nix               # `ups`: bleeding-edge upstream apps in rootless containers,
                            # an overlay on the stock app (ups erase brings it back)
    ../../waverunner-apply.nix  # drag-to-install: the root helper that turns
                            # waverunner's packages.list into hosts/target/apps.nix
                            # and rebuilds (without it installs fail silently —
                            # Brave on the thinkpad, 2026-09-29)
    # Phase B, still to land (see the plan):
    #   waverunner.nix   the OPTIONS bar + dock (the body of OPTIONS)
    #   waveview.nix     the Hyprland overview/spread plugin
    #   portals.nix      xdg-desktop-portal   (NEW — absent everywhere today)
    #   ime.nix          fcitx5 + engines     (NEW — the global-input hole)
    #   printing.nix     CUPS                 (NEW — absent everywhere today)
    #   + the home layer (home-manager: hyprland.lua, waverunner, foot, neovim)
    # NOTE: desktop/test-chrome.nix is TEST-ONLY and deliberately NOT here —
    # it is composed only into the golem-desktop-test cut.
  ];

  # The machine's own app list lives beside its other per-machine files.
  golem.appsFile = "hosts/target/apps.nix";

  # A machine running the desktop REBUILDS ITSELF AS the desktop. Every
  # self-rebuild (first-boot, autoupdate, rebuild-golem, waverunner-apply)
  # targets golem.flakeAttr, and base/loop.nix defaults it to golem-minimal.
  # Left there, a desktop machine rebuilt itself WITHOUT the desktop: on the
  # thinkpad (2026-09-29) a drag-install of Brave switched live to stage 0,
  # took Hyprland down mid-session and killed the install; first-boot had
  # already staged the desktop-less generation as the boot default.
  # 900: beats base/loop.nix's mkDefault (1000); an explicit setting (a test
  # cut, machine.nix) still wins.
  golem.flakeAttr = lib.mkOverride 900 "golem-desktop";
}
