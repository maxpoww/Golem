# gpu/intel-legacy — pre-Skylake Intel iGPU (Haswell/Ivy and older).
# Chosen when the census says gpu=intel and intelLegacy=true. iHD gives
# these parts NO hardware decode (measured: 2013 HD 5000 CPU-decoding
# VP9 at 95 °C vs 74 °C on i965) — LIBVA pins i965. And because these
# chips decode H.264 only, the enhanced-h264ify Chrome policy makes
# YouTube serve what the silicon can chew. Lifted from hardware.nix's
# intel+intelLegacy branch.
{ pkgs, lib, ... }:

let
  gst = pkgs.gst_all_1;

  # A phone's camera, decoded by the GRAPHICS chip. The dock runs this in
  # scrcpy's place (same arguments, see GOLEM_CAMERA_FEED below): it starts
  # scrcpy's own server on the phone, takes the H.264 it sends as it is, and
  # has the chip decode it (VA-API) into the loopback camera device — where
  # scrcpy itself decodes on the processor, one core's work. Measured on the
  # 2013 MacBook Air with a Pixel 8 Pro, 1080p at 16M (2026-10-10):
  #   scrcpy        60 asked → 23 pictures a second, 107 % of a core
  #   this          60 asked → 60 pictures a second,  13 % of a core
  # It ends as the pipeline ends (the last step is an exec, so the dock's
  # signal reaches the pipeline itself); the server on the phone ends when
  # its connection closes. Anything missing → it exits at once and the dock
  # falls back to scrcpy.
  cameraFeed = pkgs.writeShellApplication {
    name = "golem-camera-feed";
    runtimeInputs = [ gst.gstreamer pkgs.android-tools pkgs.coreutils pkgs.gnugrep ];
    text = ''
      export GST_PLUGIN_SYSTEM_PATH_1_0=${lib.makeSearchPathOutput "out" "lib/gstreamer-1.0" [
        gst.gstreamer
        gst.gst-plugins-base
        gst.gst-plugins-good   # v4l2sink
        gst.gst-plugins-bad    # h264parse, vah264dec, vapostproc
      ]}
      export GST_REGISTRY="''${XDG_CACHE_HOME:-$HOME/.cache}/golem-camera-feed.registry"
      gst-inspect-1.0 --exists vah264dec
      gst-inspect-1.0 --exists vapostproc

      serial="" device="" asks=()
      for a in "$@"; do
        case "$a" in
          --serial=*) serial="''${a#*=}" ;;
          --v4l2-sink=*) device="''${a#*=}" ;;
          --video-bit-rate=*)
            rate="''${a#*=}"; rate="''${rate/M/000000}"; rate="''${rate/K/000}"
            asks+=("video_bit_rate=$rate") ;;
          --video-source=*|--camera-*=*|--max-size=*)
            key="''${a%%=*}"; key="''${key#--}"
            asks+=("''${key//-/_}=''${a#*=}") ;;
        esac
      done
      [ -n "$device" ]
      adb=(adb)
      if [ -n "$serial" ]; then adb+=(-s "$serial"); fi

      # The port the last one was given is given back (it ends by a signal
      # to the pipeline, with no chance to do it then).
      note="''${XDG_RUNTIME_DIR:-/tmp}/golem-camera-feed.port"
      if [ -r "$note" ]; then
        "''${adb[@]}" forward --remove "tcp:$(cat "$note")" > /dev/null 2>&1 || true
      fi
      scid=$(printf '%08x' $(( (RANDOM << 16 | RANDOM) & 0x7fffffff )))
      "''${adb[@]}" push ${pkgs.scrcpy}/share/scrcpy/scrcpy-server /data/local/tmp/golem-camera-feed.jar > /dev/null
      port=$("''${adb[@]}" forward tcp:0 "localabstract:scrcpy_$scid")
      echo "$port" > "$note"
      "''${adb[@]}" shell CLASSPATH=/data/local/tmp/golem-camera-feed.jar app_process / \
        com.genymobile.scrcpy.Server ${pkgs.scrcpy.version} "scid=$scid" log_level=warn \
        tunnel_forward=true audio=false control=false cleanup=false raw_stream=true \
        "''${asks[@]}" > /dev/null 2>&1 &
      # The server is there once its socket is (a connection made before
      # that is closed at once).
      for _ in $(seq 40); do
        if "''${adb[@]}" shell cat /proc/net/unix 2> /dev/null | grep -q "scrcpy_$scid"; then break; fi
        sleep 0.1
      done
      exec gst-launch-1.0 -q \
        tcpclientsrc host=127.0.0.1 port="$port" do-timestamp=true ! h264parse ! \
        vah264dec ! vapostproc ! video/x-raw,format=I420 ! \
        v4l2sink device="$device" sync=false
    '';
  };
in
{
  imports = [ ./intel-pmu.nix ]; # the gear's GPU % (the i915 PMU)

  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    intel-vaapi-driver
    libvdpau-va-gl
  ];
  environment.sessionVariables.LIBVA_DRIVER_NAME = "i965";

  # GTK 4 apps draw with OpenGL here, not Vulkan. GTK prefers Vulkan, and
  # Mesa's Vulkan driver for these chips (hasvk: "Haswell Vulkan support is
  # incomplete") takes it: on the 2013 MacBook Air the camera app showed the
  # built-in camera with 130 % of a processor (three worker threads and the
  # main one), the picture visibly not smooth; with the OpenGL renderer the
  # same view costs 10 % (measured 2026-10-10). Every GTK 4 app on such a
  # machine is drawn this way — Files, Text Editor, the viewers.
  environment.sessionVariables.GSK_RENDERER = "ngl";

  # A phone as the camera ("Use as camera"). These processors cannot keep up
  # with decoding 1080p at 60 (MacBook Air 2013 + a Pixel: 23 pictures a
  # second, slow motion), but their graphics chip decodes H.264 with ease.
  # Here — and only here — the dock feeds the camera through golem-camera-feed
  # (above) instead of scrcpy, at the same best quality every other machine
  # gets. Should that fail (no VA-API on a machine of this kind), the dock
  # goes back to scrcpy and, here only (GOLEM_CAMERA_ADAPTIVE), may step the
  # bit rate and frame rate down until the picture arrives whole (launcher
  # desktop.rs). On every other machine nothing of this exists.
  environment.systemPackages = [ cameraFeed ];
  environment.sessionVariables.GOLEM_CAMERA_FEED = "golem-camera-feed";
  environment.sessionVariables.GOLEM_CAMERA_ADAPTIVE = "1";

  # These iGPUs can't afford the compositor's blur: on the 2013 MacBook Air
  # the 3D engine sat at 98% during YouTube and the video stuttered; blur off
  # freed 13-17 points (options.nix, golem.desktop.effects).
  golem.desktop.effects = "light";

  environment.etc."opt/chrome/policies/managed/golem-legacy-video.json".text =
    builtins.toJSON {
      ExtensionInstallForcelist = [
        "omkfmpieigblcllmkgbflkikinpkodlk;https://clients2.google.com/service/update2/crx"
      ];
    };

}
