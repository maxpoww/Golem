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
    # Every link the generation holds, and where its twin in the home points
    # — read by ONE readlink. It was one process per file (74 on the Acer),
    # and since the live repair below that is every minute of every session.
    mapfile -d "" -t links < <(${pkgs.findutils}/bin/find . -type l -printf '%P\0')
    if [ "''${#links[@]}" -gt 0 ]; then
      mapfile -d "" -t points < <(cd "${home}" 2>/dev/null && ${pkgs.coreutils}/bin/readlink -z -- "''${links[@]}" 2>/dev/null)
      # A file that is gone, or no longer a link, prints nothing.
      [ "''${#points[@]}" -eq "''${#links[@]}" ] || exit 0
      for i in "''${!links[@]}"; do
        [ "''${points[i]}" = "$files/''${links[i]}" ] || exit 0
      done
    fi
    echo "home ${owner}: generation already applied, every link intact — skipping activation"
    exit 1
  '';
  # LIVE repair (night dogfood, Acer 2026-10-03): the owner deleted
  # ~/.config/hypr, ~/.config/waverunner and ~/.config/foot — Hyprland showed
  # "Your config has errors: cannot open …/hyprland.lua" in a red banner until
  # the next boot, when the condition above saw the missing links. A minute
  # is enough: the same check, run as the owner every minute, re-runs the
  # home activation when Golem's links are gone; and a deleted app list
  # comes back from the running system's own machine layer, so a dock
  # restart cannot read "no apps" and uninstall everything on the next
  # install.
  heal = pkgs.writeShellScript "golem-home-heal" ''
    list="${home}/.config/waverunner/packages.list"
    snap=/etc/golem/machine/apps.nix
    if [ ! -e "$list" ] && [ -f "$snap" ]; then
      mkdir -p "$(dirname "$list")"
      { echo "# waverunner declarative packages — one nixpkgs attr per line."
        ${pkgs.gnugrep}/bin/grep -oE '^    "[A-Za-z0-9._-]+"' "$snap" | ${pkgs.coreutils}/bin/tr -d ' "'
      } > "$list.golem-heal" && mv "$list.golem-heal" "$list"
      echo "golem-home-heal: the app list was missing — rebuilt from the running system"
    fi
    if ${check}; then
      echo "golem-home-heal: Golem's own files in the home are gone or replaced — putting them back"
      hypr_gone=0; dock_gone=0
      [ -e "${home}/.config/hypr/hyprland.lua" ] || hypr_gone=1
      [ -e "${home}/.config/waverunner/config.toml" ] || dock_gone=1
      ${hm.home.activationPackage}/activate
      # Re-linked is not re-read: Hyprland's watcher lost the deleted file
      # and kept its red "cannot open …/hyprland.lua" banner (Acer test).
      if [ "$hypr_gone" = 1 ] && [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        ${pkgs.hyprland}/bin/hyprctl reload >/dev/null 2>&1 || true
      fi
      if [ "$dock_gone" = 1 ]; then
        ${pkgs.systemd}/bin/systemctl --user try-restart waverunner.service || true
      fi
    fi
  '';
in
lib.mkIf (hm != null) {
  systemd.services."home-manager-${owner}".serviceConfig.ExecCondition = "${check}";

  systemd.user.services.golem-home-heal = {
    description = "Golem: put the home's own files back if they went missing";
    serviceConfig = { Type = "oneshot"; ExecStart = "${heal}"; };
  };
  systemd.user.timers.golem-home-heal = {
    wantedBy = [ "timers.target" ];
    timerConfig = { OnStartupSec = "2min"; OnUnitActiveSec = "1min"; };
  };
}
