# desktop/home-boot — home-manager's activation runs only when there is
# something to activate.
#
# WHY (ASUS X550LC, spinning disk, 2026-10-02): home-manager-<owner>.service
# sat on the boot's critical path to the greeter (Before=systemd-user-sessions)
# for 13 s on EVERY boot, re-checking and re-linking a home that had not
# changed since the last one — most of it cold-loading nix and the activation
# tools from the disk. The generation it applies is the one already applied
# (~/.local/state/home-manager/gcroots/current-home) on every boot after the
# first; a rebuild that changes the home restarts the unit with a new one.
#
# The condition (ExecCondition: exit 0 = run, 1 = skip, not a failure): run
# unless the applied generation IS this one AND every file it manages still
# links into it. A deleted or replaced link, a first boot, an update — all
# still get the full activation, so the home keeps healing itself.
{ config, lib, pkgs, ... }:

let
  owner = config.golem.owner;
  home = config.users.users.${owner}.home;
  hm = config.home-manager.users.${owner} or null;
  check = pkgs.writeShellScript "golem-home-needs-activation" ''
    gen=${hm.home.activationPackage}
    cur=$(${pkgs.coreutils}/bin/readlink -f ${home}/.local/state/home-manager/gcroots/current-home 2>/dev/null)
    [ "$cur" = "$gen" ] || exit 0
    files=$(${pkgs.coreutils}/bin/readlink -f "$gen/home-files")
    cd "$files" || exit 0
    while IFS= read -r -d "" f; do
      f=''${f#./}
      [ "$(${pkgs.coreutils}/bin/readlink "${home}/$f")" = "$files/$f" ] || exit 0
    done < <(${pkgs.findutils}/bin/find . -type l -print0)
    echo "home ${owner}: generation already applied, every link intact — skipping activation"
    exit 1
  '';
in
lib.mkIf (hm != null) {
  systemd.services."home-manager-${owner}".serviceConfig.ExecCondition = "${check}";
}
