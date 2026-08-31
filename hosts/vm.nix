# Hardware-free Golem for the S7 test loop:
#   nixos-rebuild build-vm --flake .#golem-vm && ./result/bin/run-Golem-vm
# No nvidia, virtio graphics; greetd autologs max straight into Hyprland.
{ lib, pkgs, golemSrc, ... }:

{
  nixpkgs.hostPlatform = "x86_64-linux";

  # The installed-machine shape (what the S9 installer will seed on real
  # hardware): a writable flake checkout, so OPTIONS installs
  # (waverunner-apply) and rebuild-golem work inside the VM. The VM
  # rebuilds itself as golem-vm — switching to #golem's nvidia config
  # in here would be nonsense.
  golem.flakeDir = "/home/max/Golem";
  golem.flakeAttr = "golem-vm";

  # Seed the checkout once from the image's own source. After "users" so
  # chown works on first boot.
  system.activationScripts.seedGolemFlake = {
    deps = [ "users" ];
    text = ''
      if [ ! -e /home/max/Golem ]; then
        mkdir -p /home/max
        cp -r ${golemSrc} /home/max/Golem
        chmod -R u+w /home/max/Golem
        (
          cd /home/max/Golem
          ${pkgs.git}/bin/git init -q -b main
          ${pkgs.git}/bin/git add -A
          ${pkgs.git}/bin/git -c user.name=golem -c user.email=golem@golem \
            commit -qm "seeded from the VM image"
        )
        chown -R max:users /home/max/Golem
      fi
    '';
  };

  # The VM direct-boots (qemu -kernel); a switch inside it must never try
  # to install a bootloader.
  boot.loader.systemd-boot.enable = lib.mkForce false;

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
    cores = 8;
    forwardPorts = [
      { from = "host"; host.address = "127.0.0.1"; host.port = 2222; guest.port = 22; }
    ];
    # Venus (Vulkan passthrough) TRIED AND REVERTED 2026-08-30: with
    # venus=true wgpu cannot create a surface at all → daemon dead → no
    # shell. Without it wgpu falls back to llvmpipe (CPU) — dock renders
    # softly, video can stutter. VM-only cosmetics; real hw is unaffected.
    qemu.options = [
      "-device virtio-vga-gl"
      "-display gtk,gl=on"
    ];
  };
}
