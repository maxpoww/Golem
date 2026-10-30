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
    # Headless: no window, no GL (hosts/vm.nix adds its GTK display only
    # with graphics). Mesa renders in software, as on a machine without a
    # working GPU driver. Never mkForce qemu.options: qemu-vm puts the
    # kernel, initrd and command line there (it booted nothing, 2026-10-29).
    virtualisation.graphics = false;
    virtualisation.qemu.options = [ "-vga none" "-device virtio-gpu-pci" ];
    virtualisation.forwardPorts = lib.mkForce [ ];
    networking.hostName = lib.mkForce "machine";   # the test network's name for it
    boot.consoleLogLevel = lib.mkForce 7;           # the test driver reads the console
  };

  testScript = { nodes, ... }:
    let owner = nodes.machine.golem.owner; in ''
      machine.wait_for_unit("multi-user.target")
      machine.wait_for_unit("greetd.service")
      # The owner's desktop, up and still up a while later: a crash loop
      # would roll the machine back, a dead desktop would leave Golem's
      # last-resort screen (desktop/crash-recovery.nix).
      # By its command line: nixpkgs wraps the binary, so the process is
      # named .Hyprland-wrapped. Its IPC socket says it is really serving.
      hyprland = "pgrep -u ${owner} -f '/bin/Hyprland( |$)'"
      socket = "ls /run/user/$(id -u ${owner})/hypr/*/.socket.sock"
      machine.wait_until_succeeds(hyprland, timeout=300)
      machine.wait_until_succeeds(socket, timeout=120)
      machine.sleep(30)
      machine.succeed(hyprland)
      machine.succeed(socket)
      machine.fail("test -e /run/golem/rollback-pending")
      print(machine.succeed("systemctl --failed --no-legend --plain || true"))
    '';
}
