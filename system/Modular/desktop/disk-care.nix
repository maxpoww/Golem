# desktop/disk-care — the owner's side of never filling the disk.
#
# WHY (dev box, 2026-10-16): the disk reached 99 % with nobody told. The
# store's gc ran every night (base/store-gc.nix), but the space was elsewhere:
# the Trash never emptied, Rust build folders of finished work (110 GB),
# build results under /tmp and ~/.cache still pinning the store. Golem should
# need no upkeep, so the home side cleans itself too:
#
#   daily      the Trash: what has sat there 30 days goes
#              build output: cargo target/ folders and Gradle's caches
#              untouched for 14 days, unless a running program uses them
#              old pins: build results (gc roots) under /tmp or ~/.cache
#              older than 14 days, so the next gc can take their closures
#   every 30 min  a notification when the disk is nearly full, at most once
#              every 6 hours
{ pkgs, ... }:

let
  clean = pkgs.writeShellApplication {
    name = "golem-disk-care";
    runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.gnugrep ];
    text = ''
      cache="''${XDG_CACHE_HOME:-$HOME/.cache}"

      # The Trash: an item's .trashinfo is written when it is binned.
      trash="''${XDG_DATA_HOME:-$HOME/.local/share}/Trash"
      if [ -d "$trash/info" ]; then
        find "$trash/info" -maxdepth 1 -name '*.trashinfo' -mtime +30 -print0 |
          while IFS= read -r -d "" info; do
            name=$(basename "$info" .trashinfo)
            rm -rf -- "$trash/files/$name" "$info"
            echo "golem-disk-care: emptied from the Trash: $name"
          done
      fi

      # Build output: a cargo target/ (it carries CACHEDIR.TAG and
      # .rustc_info.json) or Gradle's caches, untouched for 14 days. Never
      # one a running program was started from or has loaded (the dock can
      # run out of a worktree's target/release; Hyprland loads its plugin
      # straight from a build).
      running=$(for p in /proc/[0-9]*; do
          readlink "$p/exe" 2>/dev/null || true
          cut -c74- "$p/maps" 2>/dev/null | grep '^/' || true
        done | sort -u)
      {
        find "$HOME" -xdev -maxdepth 6 \
            \( -path "$HOME/.local/share" -o -path "$cache" \) -prune -o \
            -name .rustc_info.json -type f -print 2>/dev/null |
          while IFS= read -r info; do
            dir=$(dirname "$info")
            [ -f "$dir/CACHEDIR.TAG" ] && echo "$dir"
          done
        # the worktrees Golem's own development keeps under ~/.cache
        find "$cache" -mindepth 3 -maxdepth 3 -name .rustc_info.json -type f -printf '%h\n' 2>/dev/null
        for d in "$HOME/.gradle/caches" "$HOME/.gradle/daemon"; do [ -d "$d" ] && echo "$d"; done
      } | while IFS= read -r dir; do
          # Anything inside touched in the last 14 days: still in use.
          [ -z "$(find "$dir" -newermt '-14 days' -print -quit 2>/dev/null)" ] || continue
          if printf '%s\n' "$running" | grep -qF -- "$dir/"; then continue; fi
          size=$(du -sh "$dir" 2>/dev/null | cut -f1)
          rm -rf -- "$dir"
          echo "golem-disk-care: removed the build output $dir ($size)"
        done

      # Old pins on the store: links this user left under /tmp or ~/.cache.
      for root in /nix/var/nix/gcroots/auto/*; do
        link=$(readlink "$root" 2>/dev/null) || continue
        case "$link" in /tmp/*|"$cache"/*) ;; *) continue ;; esac
        [ -L "$link" ] && [ -O "$link" ] || continue
        [ -n "$(find "$link" -maxdepth 0 -mtime +14 2>/dev/null)" ] || continue
        rm -f -- "$link"
        echo "golem-disk-care: unpinned $link"
      done
    '';
  };

  warn = pkgs.writeShellApplication {
    name = "golem-disk-warn";
    runtimeInputs = [ pkgs.coreutils pkgs.libnotify ];
    text = ''
      state="''${XDG_STATE_HOME:-$HOME/.local/state}/golem/disk-warn"
      now=$(date +%s)
      if [ -f "$state" ] && [ $(( now - $(stat -c %Y "$state") )) -lt $(( 6 * 3600 )) ]; then
        exit 0
      fi
      for mount in "$HOME" /nix; do
        read -r avail pct < <(df --output=avail,pcent -B1G "$mount" | tail -1 | tr -d '%')
        # Under 10 GB left or over 95 % used.
        if [ "$avail" -lt 10 ] || [ "$pct" -ge 95 ]; then
          mkdir -p "$(dirname "$state")"
          notify-send -a Golem -u critical "The disk is almost full" \
            "Only $avail GB left. Controls → Clean up frees old system versions; the Trash and big folders are yours to check."
          touch "$state"
          exit 0
        fi
      done
    '';
  };
in
{
  systemd.user.services.golem-disk-care = {
    description = "Golem: empty old Trash, stale build caches and old store pins";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${clean}/bin/golem-disk-care";
      Nice = 19;
      IOSchedulingClass = "idle";
    };
  };
  systemd.user.timers.golem-disk-care = {
    description = "Golem: daily home clean-up";
    wantedBy = [ "timers.target" ];
    timerConfig = { OnCalendar = "daily"; Persistent = true; RandomizedDelaySec = "1h"; };
  };

  systemd.user.services.golem-disk-warn = {
    description = "Golem: say when the disk is nearly full";
    serviceConfig = { Type = "oneshot"; ExecStart = "${warn}/bin/golem-disk-warn"; };
  };
  systemd.user.timers.golem-disk-warn = {
    description = "Golem: check the free disk space";
    wantedBy = [ "timers.target" ];
    timerConfig = { OnStartupSec = "5min"; OnUnitActiveSec = "30min"; };
  };
}
