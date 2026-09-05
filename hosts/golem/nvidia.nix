# Max's machine only: Lenovo Slim Pro 9i — nvidia prime offload.
# The driver config itself now lives in system/hardware/gpu-nvidia.nix
# (keyed on golem.hardware facts), so a stranger's nvidia box gets the
# same treatment. This host file just states the facts detection would
# otherwise find: an Ada (RTX 4050 → turing+) dGPU alongside the Intel
# iGPU, with these PRIME bus ids.
{ ... }:

{
  golem.hardware = {
    gpu = "nvidia";
    nvidiaGen = "turing+";
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
    # The rest of the census, from golem-hw-detect run on this machine
    # 2026-09-04 (byte-identical to the values above — the probe's first
    # live nvidia verification). Wakes the memory tiers (32GB → zram 25%)
    # and the laptop power family (upower/ppd, lid suspend-then-hibernate
    # riding the existing swap partition).
    ramMB = 31816;
    cores = 20;
    hasBluetooth = true;
    cpuVendor = "intel";
    chassis = "laptop";
    # 3200px / 34cm (EDID byte 21) = 239 DPI → the home layer generates
    # eDP scale 1.6 — the same value the desc-matched hand rule in
    # hyprland.lua has always set. Detection agreeing with the owner's
    # tuning is the calibration point for the tier table.
    panelDpi = 239;
  };
}
