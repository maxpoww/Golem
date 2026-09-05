# Laptop power stack — the `chassis` fact's first consumer (the fact
# landed with lab row 1, recorded "consumer-free until the power module
# lands" — this is that module landing).
#
# Gated on a confident "laptop" verdict (DMI chassis type, battery as the
# fallback tell — system/hardware-detect.nix). "unknown" and "desktop" get
# nothing: a desktop gains nothing from battery plumbing, and the
# conservatism rule (GolemInstall.md §4) keeps undetected machines at
# today's behavior. Anti-over-gating note (§5): this gate exists because
# the cost is real on the wrong machine class, and it stays SMALL on
# purpose — v1 is battery visibility and a profile switch, not a tuning
# suite. tlp is deliberately absent (it fights power-profiles-daemon and
# needs per-model curation); lid behavior stays logind's default
# (suspend), which is already correct.
{ config, lib, ... }:

{
  config = lib.mkIf (config.golem.hardware.chassis == "laptop") (lib.mkMerge [
    {
      # Battery state on DBus — what any battery pill/indicator reads.
      services.upower.enable = lib.mkDefault true;

      # power-saver / balanced / performance via powerprofilesctl and the
      # desktop surfaces that speak its DBus API.
      services.power-profiles-daemon.enable = lib.mkDefault true;
    }

    # Hibernation is a locked decision (2026-09-04) and this is its
    # payoff: a closed lid suspends, and two hours later the image goes
    # to disk — a laptop forgotten in a bag wakes up with the session
    # intact instead of a dead battery and lost work. Gated on disk swap
    # actually existing (hardware/memory.nix wires resume from it): on a
    # swapless machine suspend-then-hibernate's second leg fails, so
    # those keep plain suspend.
    (lib.mkIf (config.swapDevices != [ ]) {
      services.logind.settings.Login.HandleLidSwitch =
        lib.mkDefault "suspend-then-hibernate";
      systemd.sleep.settings.Sleep.HibernateDelaySec = lib.mkDefault "120min";
    })

    # thermald: Intel's own thermal daemon — proactive throttling BEFORE
    # the firmware's hard clamp. Every overheating story in this repo is
    # an old Intel laptop cooking (the 95 °C VP9 measurements); this is
    # the daemon written for exactly that. Intel-only by design, laptop-
    # gated because that's where thermal headroom is the whole game.
    (lib.mkIf (config.golem.hardware.cpuVendor == "intel") {
      services.thermald.enable = lib.mkDefault true;
    })
  ]);
}
