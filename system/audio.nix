{ config, lib, pkgs, ... }:
{
 
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

    wireplumber.extraConfig = {
      # Prevent ALSA nodes (like your TAS2781 amp) from suspending
      "10-no-suspend-tas2781" = {
        "monitor.alsa.rules" = [{
          matches = [{ "node.name" = "~alsa_output.*"; }];
          actions.update-props = {
            "session.suspend-timeout-seconds" = 0;
          };
        }];
      };

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
  
  systemd.user.services.audio-keepalive = {
    description   = "TAS2781 audio keepalive — Slim Pro 9i";
    wantedBy      = [ "default.target" ];
    after         = [ "pipewire.service" "pipewire-pulse.service" ];
    serviceConfig = {
      Type       = "simple";
      Restart    = "always";
      RestartSec = "2s";
      ExecStart  = "${pkgs.ffmpeg-full}/bin/ffplay -nodisp -autoexit -f lavfi -i anullsrc=r=44100:cl=mono -loglevel quiet";
    };
  };
}
