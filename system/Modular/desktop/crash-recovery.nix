# desktop/crash-recovery — Golem's own answer to a desktop that keeps crashing.
#
# Hyprland's watchdog (start-hyprland) used to relaunch a crashed compositor in
# STOCK SAFE MODE: Hyprland's config and wallpaper, a "your last session
# crashed" dialog, a "Load config" button that gives a bare Hyprland — the
# owner was no longer on Golem and had no way back (MacBook, 2026-10-02). Max:
# "i dont want that crash stock mode … a user will get stuck in there and run
# back to windows or macos". The watchdog is patched (hyprland-patches/
# hyprland-crash-restart-normal.patch) and this module is the rest:
#
#   one crash          the desktop restarts by itself (the patch).
#   a crash LOOP       two crashes in a row, each within a minute of starting:
#                      the watchdog runs golem-crash-loop → golem-rollback
#                      (root): the crashing revision is HELD, the boot default
#                      goes to the newest earlier generation not held, the
#                      ~/Golem checkout moves back to match, and the machine
#                      reboots into it. After the boot a notification says so.
#                      golem-autoupdate will not pull or build a held revision
#                      (base/autoupdate.nix) — only a newer upstream one.
#   nothing to go back to
#                      Golem's last-resort screen: black, the Golem pointer,
#                      one Restart button. Never Hyprland's safe mode.
{ config, lib, pkgs, ... }:

let
  owner = config.golem.owner;
  dir = toString config.golem.flakeDir;
  held = "/var/lib/golem/held-revisions";
  # NOT in /var/lib/golem (root-only: it holds the owner's password hash) —
  # the owner's notice has to read it (MacBook test, 2026-10-03).
  note = "/var/lib/golem-notices/rolled-back";
  kb = config.golem.keyboard;
  dialog = "${pkgs.hyprland-qtutils}/bin/hyprland-dialog";

  rollback = pkgs.writeShellApplication {
    name = "golem-rollback";
    runtimeInputs = [ pkgs.coreutils pkgs.gnugrep pkgs.findutils pkgs.git pkgs.util-linux config.nix.package pkgs.systemd ];
    text = ''
      profiles=/nix/var/nix/profiles
      rev_of() { local r; r=$("$1/sw/bin/nixos-version" --configuration-revision 2>/dev/null || true); echo "''${r%-dirty}"; }
      booted=$(readlink -f /run/booted-system)
      bad=$(rev_of "$booted")
      mkdir -p "$(dirname ${held})"; touch ${held}
      if [ -n "$bad" ] && ! grep -qx "$bad" ${held}; then echo "$bad" >> ${held}; fi
      echo "golem-rollback: the desktop crashed in a loop on revision ''${bad:-unknown} — holding it"

      cur=""
      for l in "$profiles"/system-*-link; do
        [ "$(readlink -f "$l")" = "$booted" ] && cur=$(basename "$l" | cut -d- -f2)
      done
      target=""; target_rev=""
      for n in $(find "$profiles" -maxdepth 1 -name 'system-*-link' -printf '%f\n' | cut -d- -f2 | sort -rn); do
        p=$(readlink -f "$profiles/system-$n-link")
        [ "$p" = "$booted" ] && continue
        if [ -n "$cur" ] && [ "$n" -ge "$cur" ]; then continue; fi
        r=$(rev_of "$p")
        if [ -n "$r" ] && grep -qx "$r" ${held}; then continue; fi
        target=$n; target_rev=$r; break
      done
      if [ -z "$target" ]; then
        echo "golem-rollback: no earlier working version to go back to" >&2
        exit 1
      fi

      echo "golem-rollback: going back to generation $target (''${target_rev:-unknown})"
      nix-env -p "$profiles/system" --switch-generation "$target"
      "$profiles/system/bin/switch-to-configuration" boot
      # The source follows: code AND machine layer exactly as they built the
      # version we go back to, so the machine can rebuild again (golem-recover,
      # base/recover.nix).
      ${config.golem.recover}/bin/golem-recover "$profiles/system" \
        || echo "golem-rollback: golem-recover could not reset the source (it stays where it is)" >&2
      install -d -m 755 "$(dirname ${note})"
      printf 'from=%s\nto=%s\nat=%s\n' "''${bad:-unknown}" "''${target_rev:-unknown}" "$(date -Is)" > ${note}
      chmod 644 ${note}
      mkdir -p /run/golem; touch /run/golem/rollback-pending
      systemd-run --on-active=6 --unit=golem-rollback-reboot systemctl reboot
    '';
  };

  crashLoop = pkgs.writeShellScriptBin "golem-crash-loop" ''
    # Called by the patched start-hyprland when the desktop crash-loops.
    # 0 = a rollback reboot is under way; anything else = nothing to go back to.
    exec ${pkgs.systemd}/bin/systemctl start golem-rollback.service
  '';

  lastResort = pkgs.writeShellScript "golem-last-resort" ''
    if [ -e /run/golem/rollback-pending ]; then
      ${dialog} --apptitle Golem --title "Golem" \
        --text "Golem had a problem starting the desktop. It is going back to the previous version and will restart in a moment." \
        --buttons "OK"
    else
      choice=$(${dialog} --apptitle Golem --title "Golem" \
        --text "Golem can't start the desktop right now. Restart the computer to try again." \
        --buttons "Restart")
      case "$choice" in *Restart*) ${pkgs.systemd}/bin/systemctl reboot ;; esac
    fi
  '';

  notice = pkgs.writeShellScript "golem-rollback-notice" ''
    [ -f ${note} ] || exit 0
    seen="''${XDG_STATE_HOME:-$HOME/.local/state}/golem/rollback-seen"
    if [ -f "$seen" ] && [ "$seen" -nt ${note} ]; then exit 0; fi
    ${pkgs.libnotify}/bin/notify-send -a Golem "Golem went back to the previous version" \
      "The desktop kept crashing after an update, so Golem restarted on the version before it. It will update again when a fixed version is out."
    mkdir -p "$(dirname "$seen")"; touch "$seen"
  '';
in
{
  environment.systemPackages = [ crashLoop ];

  # The last-resort screen: a compositor and nothing else of the desktop.
  environment.etc."golem/last-resort.lua".text = ''
    -- Golem's last-resort screen (desktop/crash-recovery.nix): never Hyprland's safe mode.
    hl.env("XCURSOR_THEME", "phinger-cursors-light")
    hl.env("XCURSOR_SIZE", "24")
    hl.env("HYPRCURSOR_THEME", "phinger-cursors-light")
    hl.env("HYPRCURSOR_SIZE", "24")
    hl.config({
        misc = {
            force_default_wallpaper = 0,
            disable_hyprland_logo   = true,
            disable_splash_rendering = true,
            background_color = 0xff000000,
        },
        input = {
            kb_layout  = "${kb.layout}",
            kb_variant = "${kb.variant}",
            kb_model   = "${kb.model}",
            kb_options = "${kb.options}",
        },
    })
    hl.on("hyprland.start", function()
        hl.exec_cmd("hyprctl setcursor phinger-cursors-light 24")
        hl.exec_cmd("${lastResort}")
    end)
  '';

  systemd.services.golem-rollback = {
    description = "Golem: go back to the previous version after a desktop crash loop";
    serviceConfig = { Type = "oneshot"; ExecStart = "${rollback}/bin/golem-rollback"; };
  };

  # Only the owner, and only this one unit.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          action.lookup("unit") == "golem-rollback.service" &&
          action.lookup("verb") == "start" &&
          subject.user == "${owner}") {
        return polkit.Result.YES;
      }
    });
  '';

  systemd.user.services.golem-rollback-notice = {
    description = "Golem: say so after going back to the previous version";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = { Type = "oneshot"; ExecStartPre = "${pkgs.coreutils}/bin/sleep 15"; ExecStart = "${notice}"; };
  };
}
