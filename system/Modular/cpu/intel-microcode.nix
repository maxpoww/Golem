# cpu/intel-microcode — chosen when the census says cpuVendor=intel.
# Free correctness/security once the vendor is known.
{ ... }:

{
  hardware.cpu.intel.updateMicrocode = true;
}
