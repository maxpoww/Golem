# A phone on the desk: what the DESKTOP's menu for a plugged-in Android
# needs (launcher `desktop.rs`: "Mirror screen", "Use as camera").
#
#   • scrcpy shows the phone's screen in a window, and feeds its camera into
#     the loopback camera device (configuration.nix: v4l2loopback, "Android
#     WebCam", /dev/video10).
#   • adb (android-tools) is how the dock asks the phone whether it lets this
#     computer in, and its screen's shape.
#   • golem-camera-relay hands that camera on to the apps (below).
#
# scrcpy and adb left the distro with the debloat (2026-09-29) as one
# machine's toolchain; they are back as parts of the shell (Max, 2026-10-09:
# "make it permanent").
{ pkgs, lib, ... }:

let
  gst = pkgs.gst_all_1;
  # The loopback device lends an app TWO frames. An app that keeps two while
  # it draws (GNOME Snapshot) got every other frame; one that keeps three got
  # none (measured 2026-10-09) — the phone's camera was never smooth, though
  # scrcpy's own window was. Raising the device's pool is not the way: at 8
  # buffers PipeWire's own reader of the device segfaulted, taking the
  # session's sound with it.
  #
  # So the relay reads the device and offers the frames, in buffers of its
  # OWN, to PipeWire as a camera under the phone's name: an app keeping six
  # still gets all sixty a second. The device has one reader at a time, and
  # the relay is it — apps take cameras from PipeWire (Seam does: seam/home.nix).
  #
  #   • YUY2, not the device's I420: one block of memory a frame. I420 went
  #     out as three, and a browser (libwebrtc) reads only the first — Seam
  #     connected and showed nothing.
  #   • drop-allocation: the converter must not draw on the sink's buffers
  #     (every converted format stalled until it did not).
  #   • run again while the device is fed: one app that cannot agree a format
  #     with it ends the pipeline, and that must not take the camera away
  #     from the others. (The dock ends the relay with SIGTERM.)
  #
  # usage: golem-camera-relay <device> <name>
  cameraRelay = pkgs.writeShellApplication {
    name = "golem-camera-relay";
    runtimeInputs = [ gst.gstreamer pkgs.coreutils ];
    text = ''
      export GST_PLUGIN_SYSTEM_PATH_1_0=${lib.makeSearchPath "lib/gstreamer-1.0" [
        gst.gstreamer
        gst.gst-plugins-base   # videoconvert
        gst.gst-plugins-good   # v4l2src
        pkgs.pipewire          # pipewiresink
      ]}
      export GST_REGISTRY="''${XDG_CACHE_HOME:-$HOME/.cache}/golem-camera-relay.registry"
      device="$1" name="$2"
      state="/sys/class/video4linux/$(basename "$device")/state"
      pid=""
      trap 'if [ -n "$pid" ]; then kill "$pid" 2>/dev/null || true; fi; exit 0' TERM INT
      while [ ! -e "$state" ] || [ "$(cat "$state")" = capture ]; do
        gst-launch-1.0 -q \
          v4l2src device="$device" ! video/x-raw,format=I420 ! \
          queue max-size-buffers=3 leaky=downstream ! \
          videoconvert ! video/x-raw,format=YUY2 ! identity drop-allocation=true ! \
          pipewiresink mode=provide "stream-properties=\"props,media.class=Video/Source,media.role=Camera,node.name=golem-phone-cam,node.description=(string)\\\"$name\\\",node.nick=(string)\\\"$name\\\"\"" &
        pid=$!
        wait "$pid" || true
        sleep 0.7
      done
    '';
  };
in
{
  home.packages = [
    pkgs.scrcpy
    pkgs.android-tools
    cameraRelay
  ];
}
