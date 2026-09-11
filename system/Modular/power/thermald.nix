# power/thermald — chosen when chassis=laptop AND cpuVendor=intel.
# Intel's own thermal daemon: proactive throttling BEFORE the
# firmware's hard clamp. Every overheating story in this repo is an
# old Intel laptop cooking (the 95 °C VP9 measurements) — this is the
# daemon written for exactly that machine.
{ ... }:

{
  services.thermald.enable = true;
}
