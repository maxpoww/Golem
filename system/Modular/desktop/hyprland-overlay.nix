# Golem's Hyprland: stock 0.55.4 plus eight patches, the same build Max's dev box
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
#                         exit in safe mode: stock config, no plugins, kitty on
#                         Super+Q, Hyprland's wallpaper and a "your last session
#                         crashed" dialog — not Golem (MacBook, a SIGSEGV'd
#                         compositor, 2026-10-02). A crash after the session ran
#                         a minute now comes back as the owner's desktop; only a
#                         crash within a minute of starting (a loop, likely the
#                         config) falls to safe mode. Golem's own; keep.
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
#   screenshare-exit      upstream SEGV on EVERY logout/shutdown with a live
#                         capture (the dock samples the screen): the screenshare
#                         manager dies in a static destructor after cleanup()
#                         freed the event manager, and a session's stop event
#                         went through the null pointer (parity P6 stack 1,
#                         core from the MacBook 2026-09-29). Drop once fixed
#                         upstream.
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
      ./hyprland-patches/hyprland-screenshare-exit.patch
      ./hyprland-patches/hyprland-subsurface-orphan.patch
      ./hyprland-patches/hyprland-vfr-hold.patch
      ./hyprland-patches/hyprland-window-square-top.patch
      ./hyprland-patches/hyprland-workspace-swipe-one-empty.patch
    ];
  });
}
