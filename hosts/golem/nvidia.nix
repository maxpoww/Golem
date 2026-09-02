# Max's machine only: Lenovo Slim Pro 9i — nvidia prime offload.
# The driver config itself now lives in system/hardware.nix (keyed on
# golem.hardware.gpu), so a stranger's nvidia box gets the same treatment.
# This host file just states the fact detection would otherwise find: an
# nvidia dGPU alongside the Intel iGPU, with these PRIME bus ids.
{ ... }:

{
  golem.hardware = {
    gpu = "nvidia";
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };
}
