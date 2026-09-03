# Hardware-free Golem for the S7 test loop:
#   nixos-rebuild build-vm --flake .#golem-vm && ./result/bin/run-Golem-vm
# No nvidia, virtio graphics; greetd autologs the owner straight into
# Hyprland. Everything owner-shaped derives from golem.owner — this file is
# "the shape" the S9 installer cribs (see hosts/iso.nix), so it must not
# re-hardcode the name the core just un-hardcoded.
{ config, lib, pkgs, golemSrc, modulesPath, ... }:

let
  owner = config.golem.owner;
  ownerHome = "/home/${owner}";
in
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
  golem.flakeDir = "${ownerHome}/Golem";
  golem.flakeAttr = "golem-vm";

  # The VM's own hardware profile — what golem-hw-detect would find inside
  # it (see system/hardware.nix): 8 GB, virtio graphics. Proves the
  # detected-facts path end to end without a physical target.
  golem.hardware = {
    ramMB = 8192;
    cores = 8;
    gpu = "virtio";
  };

  # Seed the checkout once from the image's own source. After "users" so
  # chown works on first boot.
  system.activationScripts.seedGolemFlake = {
    deps = [ "users" ];
    text = ''
      if [ ! -e ${ownerHome}/Golem ]; then
        mkdir -p ${ownerHome}
        cp -r ${golemSrc} ${ownerHome}/Golem
        chmod -R u+w ${ownerHome}/Golem
        (
          cd ${ownerHome}/Golem
          ${pkgs.git}/bin/git init -q -b main
          ${pkgs.git}/bin/git add -A
          ${pkgs.git}/bin/git -c user.name=golem -c user.email=golem@golem \
            commit -qm "seeded from the VM image"
        )
        chown -R ${owner}:users ${ownerHome}/Golem
      elif ! ${pkgs.diffutils}/bin/cmp -s ${golemSrc}/flake.lock ${ownerHome}/Golem/flake.lock; then
        # Keep the checkout in lockstep with the image (preserving the
        # VM's own package list): a stale lock made an in-VM install
        # rebuild SWAP the running daemon to the old pinned build —
        # shell restarted mid-install, pending-install UI lost.
        keep=$(${pkgs.coreutils}/bin/mktemp)
        cp ${ownerHome}/Golem/system/home/waverunner-packages.nix "$keep" || true
        cp -r --no-preserve=mode,ownership ${golemSrc}/. ${ownerHome}/Golem/
        cp "$keep" ${ownerHome}/Golem/system/home/waverunner-packages.nix || true
        rm -f "$keep"
        (
          cd ${ownerHome}/Golem
          ${pkgs.git}/bin/git add -A
          ${pkgs.git}/bin/git -c user.name=golem -c user.email=golem@golem \
            commit -qm "sync from image" || true
        )
        chown -R ${owner}:users ${ownerHome}/Golem
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
  # One merged set: Nix forbids two dynamic `users.users.${owner}` attrs in
  # the same attrset, so the password and the dev-loop ssh key live together.
  users.users.${owner} = {
    initialPassword = "golem";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILn4GLtnQEthtkhvWmcPpl7Y1GtMlBVUyTAJrNcHcX5K golem-vm-loop"
    ];
  };

  # Dev-loop access from the host: ssh -p 2222 max@localhost (key below is
  # the host's ~/.ssh key; forward is loopback-only). VM-only — the real
  # golem host ships no sshd.
  services.openssh.enable = true;

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
