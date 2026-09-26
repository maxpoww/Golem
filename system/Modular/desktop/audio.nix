# desktop/audio — pipewire, stage 1. Ported verbatim from system/audio.nix:
# pulseaudio off, rtkit, pipewire (alsa/pulse/jack) + the wireplumber tuning
# (no-suspend, bluez codecs + no-autoswitch, no pause-on-idle). The per-laptop
# TAS2781 keepalive is deliberately NOT here (it lives host-side — see the note
# in the original file; it bloats every other machine).
{ ... }:

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
      "10-no-suspend-tas2781" = {
        "monitor.alsa.rules" = [{
          matches = [{ "node.name" = "~alsa_output.*"; }];
          actions.update-props = {
            "session.suspend-timeout-seconds" = 0;
          };
        }];
      };
      "51-bluez-no-autoswitch" = {
        "monitor.bluez.properties" = {
          "bluez5.autoswitch-profile" = false;
        };
      };
      "52-bluez-codecs" = {
        "monitor.bluez.properties" = {
          "bluez5.enable-sbc-xq" = true;
          "bluez5.enable-msbc" = true;
          "bluez5.enable-hw-volume" = true;
          "bluez5.roles" = [ "a2dp_sink" "a2dp_source" "bap_sink" "bap_source" ];
          "bluez5.codecs" = [ "ldac" "aptx_hd" "aac" "sbc_xq" ];
        };
      };
      "54-disable-pause-on-disconnect" = {
        "wireplumber.settings" = {
          "node.pause-on-idle" = false;
          "linking.pause-playback" = false;
        };
      };
    };
  };
}
