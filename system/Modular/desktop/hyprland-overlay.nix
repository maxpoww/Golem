# Golem's Hyprland: stock 0.55.4 plus twelve patches, the same build Max's dev box
# runs (/etc/nixos/configuration.nix). One overlay, used in TWO places that
# must agree: the system's Hyprland (desktop/hyprland.nix) and the `pkgs`
# the waveview plugin is compiled against (flake.nix). A plugin built against
# different Hyprland headers than the compositor it loads into reads memory at
# the wrong offsets: vfr-hold adds a CMonitor member and square-top changes
# render-data layouts.
#
# Shipped 2026-09-30: without it, the laptops ran stock Hyprland and the
# titlebar's straight top edge never applied (Max: "we had fixed the top of
# the windows to be flat when the titlebars are on… not applying on the
# thinkpad and macbook"); parity.md P3.
#
#   crash-restart-normal  start-hyprland (the watchdog) restarted EVERY unclean
#                         exit in stock safe mode — Hyprland's config, wallpaper
#                         and "your session crashed" dialog, not Golem (MacBook,
#                         2026-10-02). Now: a crash restarts the desktop; two in
#                         a row, each within a minute of starting, run
#                         golem-crash-loop (back to the previous version, see
#                         desktop/crash-recovery.nix) and show Golem's
#                         last-resort screen (/etc/golem/last-resort.lua) —
#                         never the stock safe mode. Golem's own; keep.
#   floating-resize-limits  a floating window's box never goes below its own
#                         min (or past its max): a scripted resize (the resize
#                         dispatcher, the OPTIONS pill's pinch) and every placement
#                         of the box (a drag frame, a move) clamp, as a hand
#                         resize always did. Below its minimum the client and the
#                         layout fought: the pinch threw YouTube off-screen, and
#                         on the laptops (float size 704 < YouTube's 804) a drag
#                         narrowed the window and shook it (Max, 2026-09-30).
#   gesture-null-deref    upstream SEGV when libinput morphs a swipe into a
#                         pinch (ITrackpadGesture::distance). Drop once fixed
#                         upstream.
#   keep-work-buffers     debug:invalidate_work_buffers (default OFF, baked into the
#                         patch; on = stock). Stock invalidates its render work
#                         buffers after every frame, and an invalidated buffer is
#                         cleared WHOLE at its next use: the frame's buffer and
#                         the two the blur works in, every frame, whatever the
#                         damage. On a GPU that cannot sample a fast-cleared
#                         surface (Intel before gen 9) each is a clear plus a
#                         full-screen resolve: ~4 ms of GPU per frame on the Acer
#                         (HD 5500, 1366x768), for the whole desktop and not just
#                         the shell. Without it the buffers keep what the last
#                         frames drew, and every reader only reads what this
#                         frame drew. The real screen was compared with a full
#                         redraw after runs of partial frames: identical.
#   layer-commit-damage   a layer surface's commit damages what the client said
#                         changed, not the layer's whole box. Stock damaged the
#                         box on EVERY commit: the dock and the OPTIONS bar are
#                         surfaces far larger than what they draw, so each of
#                         their frames had Hyprland redraw, and blur again, about
#                         half the screen. The box is still damaged whole on a
#                         layer-shell state change, a viewport/opaque-region
#                         change, a size change, and a buffer that arrives with
#                         no damage at all (a client that never posts any); a
#                         commit that draws nothing (an input region, a frame
#                         request) damages nothing. Pairs with waverunner
#                         presenting real damage (VK_KHR_incremental_present).
#   screenshare-exit      upstream SEGV on EVERY logout/shutdown with a live
#                         capture (the dock samples the screen): the screenshare
#                         manager dies in a static destructor after cleanup()
#                         freed the event manager, and a session's stop event
#                         went through the null pointer (parity P6 stack 1,
#                         core from the MacBook 2026-09-29). Drop once fixed
#                         upstream.
#   screenshare-region-session  upstream bug, any monitor whose scale is not 1: a
#                         region capture's session keeps its box in pixels and
#                         is looked up by the client's logical box, so it is
#                         never found again and EVERY captured frame makes a new
#                         session that is never freed. Each one redraws the whole
#                         monitor ("first frame"), announces a screencast start
#                         and stop on the event socket, and stays in the list
#                         every texture draw walks. wf-recorder captures by
#                         region, always: on the Acer one 11 s recording left
#                         Hyprland 12 % dearer per frame for the rest of its
#                         life, eight left it 2-3x (round 3, 2026-10-05). Drop
#                         once fixed upstream.
#   subsurface-orphan     upstream SEGV when a client dies with its subsurface
#                         tree mapped (CWLSubsurfaceResource::posRelativeToParent
#                         walked a dead parent): SIGKILL a Seam webapp window
#                         and the whole session went with it (2026-09-30). The
#                         walk stops at the first dead link. Drop once fixed
#                         upstream.
#   vfr-hold              misc:vfr_hold_ms (default 2000, baked into the
#                         patch): keeps the frame clock alive after damage on
#                         VRR outputs, the episodic VRR brightness flicker.
#                         Inert without VRR.
#   visible-region-damage  hyprland-surface-v1's visible region (the shell tells
#                         Hyprland where each of its surfaces has anything to
#                         show, so nothing is drawn or blurred behind the rest:
#                         waverunner's visible.rs). Upstream never resets its
#                         "region changed" flag: after a client's first
#                         set_visible_region EVERY commit of that surface
#                         damaged its whole box; and a change of region damaged
#                         the whole box although it can only matter where
#                         something was, or now is, visible. The flag is reset;
#                         a change damages the old and the new region. Drop
#                         the first half once fixed upstream.
#   window-square-top     a window tagged `square-top` renders its top two
#                         corners square (surface, border, blur). The waveview
#                         titlebar sets the tag while a floating window wears
#                         its bar, so content meets the strip on a straight
#                         seam. Untagged windows are stock.
#   workspace-swipe-one-empty  gestures:workspace_swipe_one_empty (opt-in):
#                         swipe steps onto ONE empty workspace, then jumps to
#                         the next occupied one.
#
# Alphabetical on purpose, like the dev box's list: the same patch list in the
# same order gives the same Hyprland derivation, so the plugin and the system
# share one compile. If a Hyprland bump rejects a patch, the build fails loudly
# and the running system is untouched: rebase the hunks.
final: prev: {
  hyprland = prev.hyprland.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./hyprland-patches/hyprland-crash-restart-normal.patch
      ./hyprland-patches/hyprland-floating-resize-limits.patch
      ./hyprland-patches/hyprland-gesture-null-deref.patch
      ./hyprland-patches/hyprland-keep-work-buffers.patch
      ./hyprland-patches/hyprland-layer-commit-damage.patch
      ./hyprland-patches/hyprland-screenshare-exit.patch
      ./hyprland-patches/hyprland-screenshare-region-session.patch
      ./hyprland-patches/hyprland-subsurface-orphan.patch
      ./hyprland-patches/hyprland-vfr-hold.patch
      ./hyprland-patches/hyprland-visible-region-damage.patch
      ./hyprland-patches/hyprland-window-square-top.patch
      ./hyprland-patches/hyprland-workspace-swipe-one-empty.patch
    ];
    # Hyprland's own pictures — three anime wallpapers (48 MB) and the
    # "lock screen died" images — are drawn whenever Golem's config is not in
    # charge. Max (2026-10-03): "get rid of them, i hate them". Deleted, they
    # would show Hyprland's missing-texture pattern instead, so: plain black.
    postInstall = (old.postInstall or "") + ''
      for f in wall0.png wall1.png wall2.png lockdead.png lockdead2.png; do
        if [ -e "$out/share/hypr/$f" ]; then
          rm -f "$out/share/hypr/$f"
          ${final.imagemagick}/bin/magick -size 16x16 xc:black "PNG32:$out/share/hypr/$f"
        fi
      done
    '';
  });
}
