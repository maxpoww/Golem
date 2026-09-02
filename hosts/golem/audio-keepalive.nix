# This machine only: keep the TAS2781 amp awake (Lenovo Slim Pro 9i).
#
# The amp drops the first fraction of a second of audio after it goes idle, so
# a permanently-playing silent stream holds it open. It is a workaround for one
# piece of hardware, and it is not free: the ffplay loop costs 2–3 % of a core
# forever, per logged-in session (measured 2026-09-02 — two sessions on the
# 2013 MacBook Air were burning ~5 % of a core between them, for a chip that
# machine does not even have).
#
# So it lives HERE, in this host's config, and not in system/audio.nix: Golem
# ships to strangers' machines, and a stranger's laptop should not pay this.
# Max, 2026-09-02: "that is for this particular pc … it was not there out of
# the box when i installed nixos … we don't want to bloat Golem up."
#
# If another machine needs it later, the right shape is a runtime gate on the
# codec actually being present (see system/hardware-runtime.nix, which picks
# the VA-API driver per GPU the same way), not an unconditional service.
{ pkgs, ... }:

{
  systemd.user.services.audio-keepalive = {
    description = "TAS2781 audio keepalive — Slim Pro 9i (this host only)";
    wantedBy = [ "default.target" ];
    after = [ "pipewire.service" "pipewire-pulse.service" ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "2s";
      ExecStart = "${pkgs.ffmpeg-full}/bin/ffplay -nodisp -autoexit -f lavfi -i anullsrc=r=44100:cl=mono -loglevel quiet";
    };
  };
}
