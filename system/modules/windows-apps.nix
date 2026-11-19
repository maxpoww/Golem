# modules/windows-apps — Windows Apps: run Windows programs (Wine, Bottles),
# or a whole Windows in a virtual machine.
#
# PLUMBING (the module is on): 32-bit graphics — most Windows programs still
# are 32-bit, or start through a 32-bit installer.
#
# PROGRAM SETUP: machines run in the OWNER'S OWN libvirt session
# (qemu:///session, as GNOME Boxes always has). The system libvirtd stays for
# what the session uses from it (UEFI firmware paths, the bridge helper);
# nobody is in its group — `libvirtd` is root (a machine given the host's
# disk). /dev/kvm is what the session's machines need, and it is not root.
#
# WinBoat is in the catalog but does not evaluate in today's nixpkgs: it is
# skipped with a warning. (It also asks for the `docker` group, which Golem
# does not give: it will need its own answer when it builds.)
{ config, lib, ... }:

let
  m = import ./lib.nix { inherit lib; };
  inherit (m.scope config) owner has any on;

  machines = [ "virt-manager" "gnome-boxes" ];
in
{
  imports = [
    (m.mkModule {
      id = "windows-apps";
      description = "Windows Apps: run Windows programs (Wine, Bottles), or a whole Windows in a virtual machine.";
    })
  ];

  config = lib.mkMerge [
    (lib.mkIf (on "windows-apps") {
      hardware.graphics.enable32Bit = true;
    })

    {
      # Wine alone (dragged in, or under PlayOnLinux and winetricks): 32-bit
      # Windows programs draw through 32-bit graphics.
      hardware.graphics.enable32Bit = lib.mkIf (any [ "wine" "wine-wow64" "winetricks" "playonlinux" ]) true;

      virtualisation.libvirtd.enable = lib.mkIf (any machines) true;
      programs.virt-manager.enable = lib.mkIf (has "virt-manager") true;
      home-manager.users.${owner}.dconf.settings."org/virt-manager/virt-manager/connections" =
        lib.mkIf (has "virt-manager") {
          autoconnect = [ "qemu:///session" ];
          uris = [ "qemu:///session" ];
        };

      # /dev/kvm: not root (it runs machines, nothing else), and the session's
      # machines need it. Quickemu starts QEMU itself and needs it the same.
      users.users.${owner}.extraGroups = lib.optional (any (machines ++ [ "quickemu" ])) "kvm";
    }
  ];
}
