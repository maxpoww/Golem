# Golem's Hyprland: stock 0.55.4 plus five patches, the same build Max's dev box
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
#   gesture-null-deref    upstream SEGV when libinput morphs a swipe into a
#                         pinch (ITrackpadGesture::distance). Drop once fixed
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
      ./hyprland-patches/hyprland-gesture-null-deref.patch
      ./hyprland-patches/hyprland-subsurface-orphan.patch
      ./hyprland-patches/hyprland-vfr-hold.patch
      ./hyprland-patches/hyprland-window-square-top.patch
      ./hyprland-patches/hyprland-workspace-swipe-one-empty.patch
    ];
  });
}
