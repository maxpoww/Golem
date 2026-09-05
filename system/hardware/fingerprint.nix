# Fingerprint stack — the `fingerprint` fact's consumer (spec §4's "15
# hours to get the fingerprint reader going", ended). fprintd + its PAM
# wiring come up when detection saw a reader; enrollment stays the
# owner's explicit act (fprintd-enroll), so a false positive is an idle
# daemon, never surprise biometrics.
{ config, lib, ... }:

{
  config = lib.mkIf config.golem.hardware.fingerprint {
    services.fprintd.enable = lib.mkDefault true;
  };
}
