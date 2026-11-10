# TI TAS2781 smart amps behind an HDA codec (Lenovo Yoga / Slim Pro 9i and
# Legion family): reload the amps' program at every sound start.
#
# The known Linux issue on these laptops: once the sound card has gone to
# sleep and wakes again, the speakers come back quiet, thin and harsh ("low
# and like shit" — the owner, Slim Pro 9i 16IRP8, kernel 6.18.62). The driver
# reloads the amp's DSP program, configuration and calibration only when it
# believes they changed; across a runtime suspend it believes nothing did
# (tas2781_runtime_resume → tasdevice_prmg_load skips an unchanged program),
# so the amp plays on without them.
#
# The fix used to be keeping the card awake forever: a silent ffplay stream
# plus a WirePlumber rule that never suspended ANY output, on every Golem
# (pipewire 0 → 23 wakeups/s after the first sound, the codec and DSP never
# powered down). Instead, the driver's own "Speaker Force Firmware Load"
# switch makes every stream start reload program + configuration +
# calibration (tasdevice_select_tuningprm_cfg). Verified on the 16IRP8,
# 2026-11-10: card asleep 45 s (amp, codec and DSP suspended) without the
# switch → bad; with it → "suena bien". The reload runs while the stream
# opens, before any sample reaches the amp, so nothing at the start is lost.
#
# Gated at runtime on the ACPI device: every Golem carries the unit, only a
# machine with the amp runs it.
{ pkgs, ... }:

{
  systemd.services.golem-tas2781-reload = {
    description = "TAS2781 speaker amps: reload their program at every sound start";
    wantedBy = [ "multi-user.target" ];
    after = [ "sound.target" ];
    unitConfig.ConditionPathExistsGlob = "/sys/bus/acpi/devices/TIAS2781:*";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ pkgs.alsa-utils ];
    # The control appears when the amp firmware has loaded, which the driver
    # does asynchronously after boot; wait for it rather than race it.
    script = ''
      for i in $(seq 90); do
        for c in /proc/asound/card[0-9]*; do
          n=''${c##*card}
          if amixer -q -c "$n" cset iface=CARD,name='Speaker Force Firmware Load' on 2>/dev/null; then
            echo "golem-tas2781-reload: card $n, the amps reload their program at every sound start"
            exit 0
          fi
        done
        sleep 1
      done
      echo "golem-tas2781-reload: no 'Speaker Force Firmware Load' control after 90 s" >&2
    '';
  };
}
