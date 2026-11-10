{ config, lib, pkgs, ... }:
{
  # Per-model speaker tunings, the one model whose amp is kept awake, and the
  # jack-aware profile choice: the same leaf the modular desktop imports.
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
      # (The old "never suspend any output" rule moved to
      # Modular/desktop/speakers, scoped to the TAS2781 laptop's analog outputs.)

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

  # NOTE: the TAS2781 keepalive (a permanent silent ffplay stream) is NOT here
  # — it lives in hosts/golem/audio-keepalive.nix, because it is a workaround
  # for ONE laptop's amp, not part of the distro. It cost 2–3 % of a core,
  # forever, per session on every machine that booted Golem — measured on the
  # 2013 MacBook Air, where the chip it works around does not exist (Max,
  # 2026-09-02: "that is for this particular pc … we don't want to bloat Golem
  # up"). If another machine turns out to need it, gate it on the codec being
  # present the way system/hardware-runtime.nix gates the VA-API driver.
}
