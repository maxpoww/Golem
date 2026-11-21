# ── LAB DOOR — lab machines only (2026-11-12). ───────────────────────────
#
# Max, 2026-09-24: "an installed Standard should let you go in via ssh and test —
# that is the whole idea of the lab." Until 2026-11-12 the door was in the BASE:
# every installed Standard, a stranger's too, came up with sshd taking the dev
# box's keys for root and the owner, and joining the lab Wi-Fi (the privacy
# study's first gap). Max, 2026-11-12, approved "remove the lab door from
# normal installs": it is now a machine's own choice, standard.lab.door, set by
# hosts/target/lab.nix (`{ standard.lab.door = true; }`) on the lab's machines.
#
#  - Lab laptops already installed: the file is put in their machine layer by
#    the deploy (and sealed with it). Without it a machine loses the door at
#    its next update — what every other install does now.
#  - A new lab install: build the lab medium with GOLEM_LAB=1 (impure, like the
#    lab Wi-Fi secret in Installer/preinstall/iso.nix):
#        GOLEM_LAB=1 nix build --impure .#iso
#    Its baked systems carry the door from the first boot (the 8e install is a
#    DIRECT COPY of a baked toplevel and never sees machine.nix), and
#    golem-install writes hosts/target/lab.nix when the system it copies has
#    /etc/golem/lab-door, so the door survives the machine's own rebuilds.
#  - A pure build (the update lane, every machine's own rebuild) reads
#    GOLEM_LAB as "": no door unless the machine's layer asks for one.
{ config, lib, pkgs, ... }:

let
  # The dev box's keys. dev-lab is THIS box's ~/.ssh/id_ed25519 (what an ssh from
  # here presents); golem-vm-loop is the medium's existing anchor (iso.nix) — both
  # authorized so either half of the loop reaches an install.
  devKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPGzyAbOC4icrUkntYWzPhKN0hjZ3J12FV0HOjZrEI70 dev-lab"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILn4GLtnQEthtkhvWmcPpl7Y1GtMlBVUyTAJrNcHcX5K golem-vm-loop"
  ];
in
{
  options.standard.lab.door = lib.mkOption {
    type = lib.types.bool;
    default = builtins.getEnv "GOLEM_LAB" == "1";
    description = "This machine is a lab testbed: the dev box's SSH keys, the lab Wi-Fi, wave 0 (hosts/target/lab.nix).";
  };

  config = lib.mkIf config.standard.lab.door {
    # What golem-install reads to know it is copying a lab system.
    environment.etc."golem/lab-door".text = "This machine is a lab testbed (system/Modular/lab/lab-door.nix).\n";
    # The lab meets every new version first (wave 0, updates/client.nix);
    # installs spread over the week.
    standard.update.wave = lib.mkDefault 0;
    users.users.${config.standard.owner}.openssh.authorizedKeys.keys = devKeys;
    users.users.root.openssh.authorizedKeys.keys = devKeys;
    # The lab's machines keep their real Wi-Fi address (base/network.nix gives
    # installs a private one): the lab reaches each machine at the address its
    # real one was given.
    networking.networkmanager.wifi.macAddress = "permanent";

    # Auto-join the open lab wifi so a fresh install is reachable on boot. Baked
    # HERE (not via --lab-wifi → machine.nix) because the direct-copied gen-1 runs
    # the baked toplevel, not machine.nix. retries=0 (infinite) so a slow dongle/AP
    # at boot can't exhaust NM's default 4 and strand the machine (#63).
    # No Wi-Fi power save on a lab machine (powersave = 2: off): after a reboot
    # the 2013 MacBook Air (broadcom wl) answered no ARP from the dev box for
    # ~20 min although it had associated and had its address at 24 s — a
    # dozing client that said nothing (2026-10-29). And a heartbeat below.
    networking.networkmanager.ensureProfiles.profiles.golem-lab = {
      connection = { id = "golem-lab"; type = "wifi"; autoconnect = true; "autoconnect-retries" = 0; };
      wifi = { mode = "infrastructure"; ssid = "HOLA"; powersave = 2; };
    };

    # The lab's Hyprland keeps its full log, with times (Hyprland's default
    # drops its own lines once the config is in; only aquamarine's remain):
    # a start's 3.4 s on the 2013 MacBook Air can be read. In /run, tmpfs. The line
    # is home/hypr/standard/lab.lua's, on when home/hyprland.nix's facts say so (it
    # knows a lab machine by the heartbeat below): ahead
    # of the owner's live settings, which stay last (desktop-matrix holds it).

    # THE HEARTBEAT: a ping to the gateway every 20 s keeps the lab machine
    # known to the access point (its tables learn from frames the client sends).
    systemd.services.golem-lab-heartbeat = {
      description = "Keep the lab machine known on the Wi-Fi (a ping to the gateway)";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "golem-lab-heartbeat" ''
          gw=$(${pkgs.iproute2}/bin/ip route show default 2>/dev/null | ${pkgs.gawk}/bin/awk '{ print $3; exit }')
          [ -n "$gw" ] && ${pkgs.iputils}/bin/ping -c 1 -W 1 "$gw" >/dev/null 2>&1 || true
        '';
      };
    };
    systemd.timers.golem-lab-heartbeat = {
      wantedBy = [ "timers.target" ];
      timerConfig = { OnBootSec = "15s"; OnUnitActiveSec = "20s"; AccuracySec = "5s"; };
    };
  };
}
