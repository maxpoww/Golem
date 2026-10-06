# What the gear box's machine pages ask of the system (the dock's
# gear_pages.rs / sys.rs / drives.rs). The pages run as the owner; these are
# the few things only root can do, each opened to the owner and to nobody
# else, and each one a named unit or a single file rather than a general key.
#
#   Erase empty space (SSD)   start fstrim.service now (it already runs weekly)
#   Clean up                  golem-clean-system: old system versions (keeps
#                             the last two), then the store, then old logs
#   Updates: check now        start golem-autoupdate.service
#   Stop charging at 80%      the battery's charge limit, writable by the owner
#                             on hardware that has one
#   Video playback            vainfo, so the page can say what the card decodes
#   Format a drive            exFAT and NTFS tools beside the ones already here,
#                             and the disk service built with the exFAT tools
#                             that can rename a drive
{ config, lib, pkgs, ... }:

let
  owner = config.golem.owner;
  nix = config.nix.package;

  # Under the rebuild lock: a clean-up must not delete a version a running
  # rebuild or install is about to make the default. The boot menu is written
  # again afterwards, so it never offers a version that is gone.
  cleanSystem = pkgs.writeShellScript "golem-clean-system" ''
    set -u
    exec 9>>/run/golem-rebuild.lock
    ${pkgs.util-linux}/bin/flock -w 600 9 || { echo "golem-clean-system: a rebuild is running" >&2; exit 1; }
    ${nix}/bin/nix-env --profile /nix/var/nix/profiles/system --delete-generations +2 || true
    ${nix}/bin/nix-collect-garbage || true
    if [ -x /nix/var/nix/profiles/system/bin/switch-to-configuration ]; then
      /nix/var/nix/profiles/system/bin/switch-to-configuration boot || true
    fi
    ${pkgs.systemd}/bin/journalctl --vacuum-time=7d || true
  '';

  startable = [ "fstrim.service" "golem-clean-system.service" "golem-autoupdate.service" ];
in
{
  systemd.services.golem-clean-system = {
    description = "Golem: remove old system versions and old logs (the gear's Clean up)";
    restartIfChanged = false;
    serviceConfig = { Type = "oneshot"; ExecStart = cleanSystem; };
  };

  # Only the owner, only these units, only "start".
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          ${builtins.toJSON startable}.indexOf(action.lookup("unit")) >= 0 &&
          action.lookup("verb") == "start" &&
          subject.user == "${owner}") {
        return polkit.Result.YES;
      }
    });
  '';

  # The charge limit is a kernel file only root may write. Where a battery
  # has one, hand that one file to the owner.
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="power_supply", ATTR{type}=="Battery", TEST=="charge_control_end_threshold", RUN+="${pkgs.coreutils}/bin/chown ${owner} /sys%p/charge_control_end_threshold"
  '';

  # The disk service looks for the exFAT tools in a path baked into its
  # package, and nixpkgs bakes the old FUSE `exfat` there: it can make an
  # exFAT drive but has no tool to rename one, so renaming failed with
  # "executable tune.exfat not found" while the tool sat on the system path
  # (MacBook, 2026-10-05). Bake the real tools in instead. Only the service
  # is rebuilt; nothing else depends on this copy.
  services.udisks2.package = pkgs.udisks.override { exfat = pkgs.exfatprogs; };

  environment.systemPackages = [ pkgs.libva-utils pkgs.exfatprogs pkgs.ntfs3g ];

  # Wi-Fi hotspot: the devices that join ask this computer for an address and
  # for names (NetworkManager runs dnsmasq on the shared interface). The
  # firewall let neither in. Nothing listens on these ports unless a hotspot
  # is on. ("wl+" = any wireless interface, whatever its name.)
  networking.firewall.interfaces."wl+" = {
    allowedUDPPorts = [ 53 67 ];
    allowedTCPPorts = [ 53 ];
  };
}
