# quirks/fingerprint — a USB fingerprint reader. Chosen when
# fingerprint=true (additive). fprintd + its PAM wiring come up;
# enrollment stays the owner's explicit act (fprintd-enroll), so a false
# positive is an idle daemon, never surprise biometrics. Ported from
# system/hardware/fingerprint.nix (2026-09-10).
{ lib, ... }:

{
  services.fprintd.enable = lib.mkDefault true;
}
