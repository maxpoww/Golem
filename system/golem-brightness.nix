# golem-brightness — the backlight that follows the panel, not a hardcoded name.
#
# Max hit this for years: brightness worked with `intel_backlight`, then a stint
# where he had to use `nvidia_0`, then back — and swapped the name by hand in
# hyprland.lua each time. Root cause (studied on his lenovo, 2026-09-24): on a
# hybrid laptop the internal panel's backlight is owned by whichever GPU is
# DRIVING the panel. `intel_backlight` → `card2-eDP-1` (connected, on the iGPU)
# today; `nvidia_0` → the dGPU (its eDP disconnected now) — which is why it stopped
# working. A fixed device name is wrong by construction, and `brightnessctl`'s own
# auto-pick ignores which connector is live (so the keys can hit a dead backlight
# and look broken "out of the box").
#
# So Golem doesn't store a name — it FINDS the backlight tied to the connected
# internal panel at press time and drives that. Adapts to the mux with zero config,
# on any machine. The brightness keys call `golem-brightness` instead of
# `brightnessctl -d <guess>`. Permissions come from the owner being in `video` +
# brightnessctl's own udev rule (already set) — no setuid, no root.
{ pkgs, ... }:

let
  golem-brightness = pkgs.writeShellApplication {
    name = "golem-brightness";
    runtimeInputs = [ pkgs.brightnessctl pkgs.coreutils ];
    # shellcheck: the /sys globs are intentional and guarded.
    text = ''
      # Pick the backlight driving the ACTIVE internal panel: a connected eDP/LVDS
      # connector, then the /sys/class/backlight entry pointing at that connector
      # (or its GPU). Falls back to the first raw-type backlight, then anything.
      pick() {
        for con in /sys/class/drm/card*-eDP-* /sys/class/drm/card*-LVDS-*; do
          [ -e "$con/status" ] || continue
          [ "$(cat "$con/status" 2>/dev/null)" = connected ] || continue
          conpath=$(readlink -f "$con")
          gpu=$(readlink -f "$con/../device")
          for bl in /sys/class/backlight/*; do
            [ -e "$bl" ] || continue
            bld=$(readlink -f "$bl/device")
            case "$bld" in
              "$conpath"|"$gpu"|"$gpu"/*) basename "$bl"; return 0 ;;
            esac
          done
        done
        for bl in /sys/class/backlight/*; do
          [ -e "$bl" ] || continue
          [ "$(cat "$bl/type" 2>/dev/null)" = raw ] && { basename "$bl"; return 0; }
        done
        for bl in /sys/class/backlight/*; do [ -e "$bl" ] && { basename "$bl"; return 0; }; done
        return 1
      }
      dev=$(pick) || { echo "golem-brightness: no backlight device found" >&2; exit 1; }
      # -e4 exponential curve, -n2 floor (never fully black) — Max's tuned feel.
      exec brightnessctl -e4 -n2 -d "$dev" "$@"
    '';
  };
in
{
  environment.systemPackages = [ golem-brightness pkgs.brightnessctl ];

  # brightnessctl's udev rule: the backlight becomes group-`video` writable, and
  # the owner is in `video`. Without it the keys fail with "Operation not
  # permitted": the logind fallback refuses because under uwsm the session's
  # apps belong to the systemd-user MANAGER session, which has no seat
  # (golem-parity, thinkpad 2026-09-29: the helper existed, the write didn't).
  services.udev.packages = [ pkgs.brightnessctl ];
}
