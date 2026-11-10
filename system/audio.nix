{ config, lib, pkgs, ... }:
{
  # Per-model speaker tunings, the TAS2781 amp reload, and the jack-aware
  # profile choice: the same leaf the modular desktop imports.
  imports = [ ./Modular/desktop/speakers ];

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

    wireplumber.extraConfig = {
      # (The old "never suspend any output" rule is gone: the TAS2781 amp it
      # was for reloads its program at every start, Modular/desktop/speakers.)

      # Disable automatic profile switching to headset (HFP) when mic is requested
      "51-bluez-no-autoswitch" = {
        "monitor.bluez.properties" = {
          "bluez5.autoswitch-profile" = false;
        };
      };

      # Force high-quality Bluetooth codecs & hardware volume syncing
      "52-bluez-codecs" = {
        "monitor.bluez.properties" = {
          "bluez5.enable-sbc-xq" = true;
          "bluez5.enable-msbc" = true;
          "bluez5.enable-hw-volume" = true;
          "bluez5.roles" = [ "a2dp_sink" "a2dp_source" "bap_sink" "bap_source" ];
          "bluez5.codecs" = [ "ldac" "aptx_hd" "aac" "sbc_xq" ];
        };
      };

      # Prevent PipeWire from pausing streams on disconnect/idle
      "54-disable-pause-on-disconnect" = {
        "wireplumber.settings" = {
          "node.pause-on-idle" = false;
          "linking.pause-playback" = false;
        };
      };
    };
  };

  # NOTE: the TAS2781 keepalive (a permanent silent ffplay stream, 2–3 % of a
  # core forever) is gone (2026-11-10). It lived host-side because it was one
  # laptop's workaround; the amp now reloads its program at every sound start
  # instead (Modular/desktop/speakers/tas2781.nix, gated on the chip).
}
