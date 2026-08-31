# Hardware-free Golem for the S7 test loop:
#   nixos-rebuild build-vm --flake .#golem-vm && ./result/bin/run-Golem-vm
# No nvidia, virtio graphics; greetd autologs max straight into Hyprland.
{ lib, pkgs, golemSrc, modulesPath, ... }:

{
  # qemu-vm imported DIRECTLY (not via vmVariant): the toplevel this config
  # evaluates to IS the running VM system — so an in-VM `nixos-rebuild
  # switch --flake ...#golem-vm` (waverunner-apply) activates a
  # like-for-like config. Switching to the plain toplevel tried to stop
  # nix-store.mount out from under the running system (exit 4).
  imports = [ (modulesPath + "/virtualisation/qemu-vm.nix") ];

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
  # to install a bootloader (grub off too — it re-defaults to enabled the
  # moment systemd-boot is disabled, then asserts on missing devices).
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub.enable = lib.mkForce false;
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

  virtualisation = {
    # The writable-store overlay defaults to tmpfs: everything installed
    # inside the VM evaporates on reboot while the nix db (persistent
    # root) keeps listing it — ghost paths, broken evals. An installed
    # machine's store persists; so does this one's.
    writableStoreUseTmpfs = false;

    # …and a persistent store needs a real disk: the default image is
    # 1GB, which one brave+gimp install fills ("No space left on
    # device"). Sparse qcow2 — 20G costs nothing until used.
    diskSize = 20480;

    # 8G: a nixos-rebuild eval inside the VM wants 2-3GB on top of the
    # desktop (zram helps, but don't make the test loop suffer).
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
