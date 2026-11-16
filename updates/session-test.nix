# updates/session-test — the first minute of a Golem session, as a person
# meets it, in the same VM the boot test uses (boot-test.nix).
#
# boot-test proves the desktop comes up. This goes on from there:
#   1. the lock screen is the first screen (the login), and the owner's
#      password opens it;
#   2. the password just typed opened the keyring too (Secret Service);
#   3. Shift+Print leaves a picture in Pictures/Screenshots;
#   4. a desktop that crashes comes back LOCKED, and the password opens it.
#
# NOT a flake check: the lane runs every check before it publishes, and a
# test that types on a software-rendered screen is the kind that can fail
# for its own reasons. Run by hand before a merge that touches the session:
#   nix build .#session-test -L
{ pkgs, modules, specialArgs }:

pkgs.testers.runNixOSTest {
  name = "golem-session";
  node.pkgsReadOnly = false;
  node.specialArgs = specialArgs;

  nodes.machine = { lib, ... }: {
    imports = modules;
    virtualisation.graphics = false;
    virtualisation.qemu.options = [ "-vga none" "-device virtio-gpu-pci" ];
    virtualisation.forwardPorts = lib.mkForce [ ];
    networking.hostName = lib.mkForce "machine";
    boot.consoleLogLevel = lib.mkForce 7;
  };

  testScript = { nodes, ... }:
    let
      owner = nodes.machine.golem.owner;
      password = nodes.machine.users.users.${owner}.initialPassword;
    in ''
      hyprland = "pgrep -u ${owner} -f '/bin/Hyprland( |$)'"
      socket = "ls /run/user/$(id -u ${owner})/hypr/*/.socket.sock"
      lock = "pgrep -u ${owner} -x 'hyprlock|\\.hyprlock-wrapp'"
      asowner = "su - ${owner} -c 'export XDG_RUNTIME_DIR=/run/user/$(id -u); export DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus; %s'"

      def unlock():
          # The lock screen takes a moment to listen (its fade in).
          machine.sleep(8)
          machine.send_chars("${password}\n")
          machine.wait_until_fails(lock, timeout=60)

      machine.wait_for_unit("greetd.service")
      machine.wait_until_succeeds(hyprland, timeout=300)
      machine.wait_until_succeeds(socket, timeout=120)

      with subtest("the login: the lock screen is the first screen, the password opens it"):
          machine.wait_until_succeeds(lock, timeout=120)
          unlock()
          machine.succeed(hyprland)

      with subtest("the password opened the keyring"):
          machine.wait_until_succeeds(asowner % "busctl --user list | grep -q org.freedesktop.secrets", timeout=60)

      with subtest("Shift+Print leaves a picture in Pictures/Screenshots"):
          machine.send_key("shift-print")
          machine.wait_until_succeeds("ls /home/${owner}/*/Screenshots/*.png", timeout=60)
          print(machine.succeed("ls -la /home/${owner}/*/Screenshots/"))

      with subtest("a desktop that crashes comes back locked"):
          old = machine.succeed(hyprland).split()[0]
          machine.succeed("kill -SEGV " + old)
          machine.wait_until_succeeds(hyprland + " | grep -v -x " + old, timeout=120)
          machine.wait_until_succeeds(lock, timeout=120)
          unlock()
          machine.fail("test -e /run/golem/rollback-pending")

      print(machine.succeed("systemctl --failed --no-legend --plain || true"))
    '';
}
