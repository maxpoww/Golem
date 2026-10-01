# FITS — an app the owner installs works the moment it lands.
#
# Golem does not ship these apps; the owner installs them from the dock
# (packages.list → hosts/target/apps.nix → home.packages). Some apps arrive
# unable to do the one thing they are installed for until someone who already
# knows the app has set it up. A fit is the small piece of first-run state
# that closes that gap, laid down ONCE, when the app is among the installed
# packages and has never been set up. After that the app's config is the
# owner's: a fit never touches it again (the marker under
# ~/.local/state/golem/fits says it has been done).
#
# Max, 2026-10-01: "obs is not gonna come installed on Golem. but it have to
# work out of the box as soon as a user install it."
#
# ---- OBS Studio ------------------------------------------------------------
# Stock OBS opens on an empty scene: a black preview, and Record writes a
# black video (the ThinkPad's first recording, 2026-10-01). On Wayland a
# screen can only be captured through the portal, after the owner picks it,
# and OBS asks for that only once a "Screen Capture (PipeWire)" source exists
# — which a new user has to know to add.
#
# The fit seeds a scene that already holds that source. First launch: the
# "what to share" picker comes up by itself, the owner picks the screen, the
# preview is live and Record records it. It also marks OBS's first-run wizard
# as done (it asks about streaming versus recording and adds no source).
#
# The seeded collection also names desktop audio and the microphone: OBS
# adds those two only to a collection it creates itself, and a seeded one
# without them records in silence (found by running it).
#
# The scene is OBS's version-2 (relative) form, so it does not depend on the
# screen: the source sits on the canvas centre and is fitted to the canvas
# height, whatever the canvas (OBS's own default is the screen up to
# 1920×1080). Checked against OBS 32.1.2's loader (libobs/obs-scene.c:
# pos_rel / scale_rel / scale_ref / bounds_rel) and by running it.
#
# Seeded when OBS has no config at all, or only its untouched default (a
# scene collection named Untitled with nothing in it — kept beside the seed
# as Untitled.json.before-golem). Never while OBS is running: it writes its
# scene on exit.
{ config, lib, pkgs, ... }:

let
  installed = name: lib.any (p: lib.getName p == name) config.home.packages;
  obs = ./fits/obs-studio;
in
{
  config = lib.mkIf (installed "obs-studio") {
    home.activation.fitObsStudio = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      fit_done="''${XDG_STATE_HOME:-$HOME/.local/state}/golem/fits/obs-studio"
      obs_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/obs-studio"
      if [ ! -e "$fit_done" ] && ! ${pkgs.procps}/bin/pgrep -u "$(id -u)" -x 'obs|\.obs-wrapped' >/dev/null; then
        scene="$obs_dir/basic/scenes/Untitled.json"
        if [ ! -e "$obs_dir" ]; then
          # Never opened: the whole first-run state.
          $DRY_RUN_CMD install -Dm644 ${obs}/user.ini "$obs_dir/user.ini"
          $DRY_RUN_CMD install -Dm644 ${obs}/basic.ini "$obs_dir/basic/profiles/Untitled/basic.ini"
          $DRY_RUN_CMD install -Dm644 ${obs}/Untitled.json "$scene"
        elif [ -e "$scene" ] && ! grep -qs '"source_uuid"' "$obs_dir"/basic/scenes/*.json; then
          # Opened, nothing ever added: the empty default scene gets the source.
          $DRY_RUN_CMD cp -p "$scene" "$scene.before-golem"
          $DRY_RUN_CMD install -m644 ${obs}/Untitled.json "$scene"
        fi
        # Either way this was the one time: from here the config is the owner's.
        $DRY_RUN_CMD install -Dm644 /dev/null "$fit_done"
      fi
    '';
  };
}
