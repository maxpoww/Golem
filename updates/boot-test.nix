# updates/boot-test — a version must BOOT, not only build.
#
# The gate (gate.nix) builds every Golem system, but a build proves nothing
# about a kernel that panics, an initrd that cannot find its disk, or a
# desktop that never comes up; and the lab meets a version first only when
# its laptops are on (audit, 2026-10-29). This boots Golem's desktop stage
# (golem-desktop-vm: the composition and desktop every install runs, on a
# QEMU machine) and waits for the owner's desktop to come up and stay up.
# It is a flake check, so the lane runs it before every publish; installs
# never run it.
{ pkgs, modules, specialArgs }:

pkgs.testers.runNixOSTest {
  name = "golem-boot";
  node.pkgsReadOnly = false;   # Golem's modules set nixpkgs.config and overlays
  node.specialArgs = specialArgs;

  nodes.machine = { lib, ... }: {
    imports = modules;
    # Headless: no GTK window, no GL. Mesa renders in software, as on a
    # machine without a working GPU driver.
    virtualisation.qemu.options = lib.mkForce [ "-vga none" "-device virtio-gpu-pci" ];
    virtualisation.forwardPorts = lib.mkForce [ ];
  };

  testScript = { nodes, ... }:
    let owner = nodes.machine.golem.owner; in ''
      machine.wait_for_unit("multi-user.target")
      machine.wait_for_unit("greetd.service")
      # The owner's desktop, up and still up a while later: a crash loop
      # would roll the machine back, a dead desktop would leave Golem's
      # last-resort screen (desktop/crash-recovery.nix).
      machine.wait_until_succeeds("pgrep -u ${owner} -x Hyprland", timeout=300)
      machine.sleep(30)
      machine.succeed("pgrep -u ${owner} -x Hyprland")
      machine.fail("test -e /run/golem/rollback-pending")
      print(machine.succeed("systemctl --failed --no-legend --plain || true"))
    '';
}
