# ── LAB DOOR — TEMPORARY. Remove at the first FINISHED Golem ISO. ─────────
#
# Max, 2026-09-24: "an installed Golem should let you go in via ssh and test —
# that is the whole idea of the lab. from here, ALL the isos should do that; we
# close the ssh only when we finish, on the first finished Golem ISO."
#
# So every installed Golem — including the baked gen-1, since the 8e install is a
# DIRECT COPY of a baked toplevel and never sees machine.nix's --lab-ssh — comes
# up reachable: sshd (base/ssh.nix) key-only with the dev box's keys authorized,
# and auto-joining the open lab wifi. The dev box can then SSH in the moment a
# fresh install boots and diagnose/iterate directly (e.g. the BIOS+Intel Plymouth
# bar, the comodore/HP boots) instead of reading the console by hand.
#
# This DELIBERATELY overrides base/ssh.nix's "no lab keys on shipped images"
# (GolemSecurity phase 3) for the lab period — Max's explicit call. DELETE this
# file and its composition.nix import at the finish line to restore that rule.
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
  # The lab meets every new version first (wave 0, updates/client.nix). This
  # file goes at the finish line, and with it installs spread over the week.
  golem.update.wave = lib.mkDefault 0;
  users.users.${config.golem.owner}.openssh.authorizedKeys.keys = devKeys;
  users.users.root.openssh.authorizedKeys.keys = devKeys;

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
  # is in home/home.nix, which knows a lab machine by the heartbeat below: ahead
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
}
