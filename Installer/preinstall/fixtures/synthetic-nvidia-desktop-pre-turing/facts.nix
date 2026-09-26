# SYNTHETIC fixture (2026-09-26) — NOT captured from metal. A plausible
# NVIDIA-only desktop (pre-turing, the nvidia GPU drives the screen, no iGPU),
# written to exercise the primary-nvidia leaves + gpu/nvidia/vaapi.nix in the
# effect matrix until a real nvidia-only machine is captured. Replace with a
# golem-hw-detect capture when one exists.
{ ... }:
{
  golem.hardware = {
    cpuModel = "AMD Ryzen 7 5800X 8-Core Processor";
    cores = 8;
    threads = 16;
    ramMB = 32041;
    gpu = "nvidia";
    intelLegacy = false;
    firmware = "uefi";
    nvidiaGen = "pre-turing";
    nvidiaBusId = "PCI:1:0:0";
    hasBluetooth = false;
    cpuVendor = "amd";
    chassis = "desktop";
  };
}
