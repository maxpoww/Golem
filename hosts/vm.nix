# Hardware-free Golem for the S7 test loop:
#   nixos-rebuild build-vm --flake .#golem-vm && ./result/bin/run-Golem-vm
# No nvidia, virtio graphics; greetd autologs max straight into Hyprland.
{ lib, ... }:

{
  nixpkgs.hostPlatform = "x86_64-linux";

  # Dummy root so the config evaluates standalone; the vm builder overrides
  # every filesystem with its own image (mkVMOverride).
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

  # A stranger's first login (greetd autologin makes this rarely needed).
  users.users.max.initialPassword = "golem";

  # Dev-loop access from the host: ssh -p 2222 max@localhost (key below is
  # the host's ~/.ssh key; forward is loopback-only). VM-only — the real
  # golem host ships no sshd.
  services.openssh.enable = true;
  users.users.max.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILn4GLtnQEthtkhvWmcPpl7Y1GtMlBVUyTAJrNcHcX5K golem-vm-loop"
  ];

  virtualisation.vmVariant.virtualisation = {
    # 8G: waverunner's cold-start package index runs `nix search nixpkgs ^`
    # (~3GB eval) — at 4G the OOM killer crash-looped the daemon (2026-08-30).
    # Real fix filed in todo7: ship a prebuilt index with the flake.
    memorySize = 8192;
    cores = 4;
    forwardPorts = [
      { from = "host"; host.address = "127.0.0.1"; host.port = 2222; guest.port = 22; }
    ];
    qemu.options = [
      "-device virtio-vga-gl"
      "-display gtk,gl=on"
    ];
  };
}
