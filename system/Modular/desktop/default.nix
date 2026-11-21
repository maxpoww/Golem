# The DESKTOP STAGE (stage 1) — everything a machine gains climbing from the
# minimal base to the Standard desktop, added BY REBUILD, never by reinstall
# (Installer/installing/spec.md, the stage ladder). Attached via the
# `standard-desktop` flake attr (base composition + this bundle); a machine climbs
# by setting standard.flakeAttr = "standard-desktop" and running rebuild-golem — the
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
    ../../../seam           # Seam, Standard's browser (system half: build + policies +
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
    ./home-boot.nix         # home-manager activates only when something changed
    ./whats-new.nix         # what each update changed, written by hand (Controls → Updates reads it)
    ./update-notice.nix     # "Golem has an update ready" after 2 days waiting for a restart
    ./crash-recovery.nix    # a crash loop → back to the previous version; never Hyprland's safe mode
    ../../modules           # THE MODULES (Gaming, Development, Music Production…): the dock's
                            #   Modules as options, and the system each installed program needs
                            #   (Steam's 32-bit graphics, rootless Docker, LocalSend's port…);
                            #   was desktop/app-setup.nix until 2026-11-19
    ./disk-care.nix         # the home cleans itself (old Trash, stale build caches, old pins)
    ./printing.nix          # plug a printer or a scanner in and it works: CUPS + drivers +
                            # driverless (IPP/AirPrint/eSCL), the queue made by itself
                            #   + a warning when the disk is nearly full
    ./care.nix              # what the gear box's machine pages ask of the system: trim, clean-up,
                            #   update check, charge limit, the format tools
    ./idle.nix              # hyprlock's PAM service (the idle daemon is the home layer's)
    ./keyring.nix           # where apps keep their passwords (Secret Service), opened
                            #   by the owner's password at the login (the lock screen)
    ./phone.nix             # the loopback camera device a plugged-in phone's camera is fed into
    ./portals.nix           # the desktop portal said out loud: Hyprland's for the screen,
                            #   GTK's for the rest (file chooser, look), nobody for Secret
    ./ups.nix               # `ups`: bleeding-edge upstream apps in rootless containers,
                            # an overlay on the stock app (ups erase brings it back)
    ../../postinstall.nix       # the post-install questions (F2.3): what Standard left for the
                                #   owner to judge (the ASUS's failing second GPU) is asked
                                #   once at the desktop, and the answer applied by a rebuild
                                #   of root's own copy; the answers file is read as data
    ../../waverunner-apply.nix  # drag-to-install: the root helper that turns
                            # waverunner's packages.list into hosts/target/apps.nix
                            # and rebuilds (without it installs fail silently —
                            # Brave on the thinkpad, 2026-09-29)
    # Phase B, still to land (see the plan):
    #   waverunner.nix   the OPTIONS bar + dock (the body of OPTIONS)
    #   waveview.nix     the Hyprland overview/spread plugin
    #   ime.nix          fcitx5 + engines     (NEW — the global-input hole)
    #   + the home layer (home-manager: hyprland.lua, waverunner, foot, neovim)
    # NOTE: desktop/test-chrome.nix is TEST-ONLY and deliberately NOT here —
    # it is composed only into the standard-desktop-test cut.
  ];

  # The machine's own app list lives beside its other per-machine files.
  standard.appsFile = "hosts/target/apps.nix";

  # A machine running the desktop REBUILDS ITSELF AS the desktop. Every
  # self-rebuild (first-boot, autoupdate, rebuild-golem, waverunner-apply)
  # targets standard.flakeAttr, and base/loop.nix defaults it to standard-minimal.
  # Left there, a desktop machine rebuilt itself WITHOUT the desktop: on the
  # thinkpad (2026-09-29) a drag-install of Brave switched live to stage 0,
  # took Hyprland down mid-session and killed the install; first-boot had
  # already staged the desktop-less generation as the boot default.
  # 900: beats base/loop.nix's mkDefault (1000); an explicit setting (a test
  # cut, machine.nix) still wins.
  standard.flakeAttr = lib.mkOverride 900 "standard-desktop";
}
