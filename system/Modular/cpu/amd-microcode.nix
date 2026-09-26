# cpu/amd-microcode — chosen when the census says cpuVendor=amd.
{ ... }:

{
  hardware.cpu.amd.updateMicrocode = true;

  # THE AMD CPU SCALING FIX (2026-09-26, thinkpad E15 Renoir): without this the
  # kernel falls back to the legacy `acpi-cpufreq` driver, which exposed the
  # 4700U's max as its 2.0 GHz BASE clock — the CPU never scaled up to its
  # ~4.1 GHz boost, and the whole desktop felt sluggish. amd_pstate=active hands
  # frequency to the CPU's own CPPC governor (the amd-pstate-epp driver): proper
  # per-core boost AND better idle power. Zen2+ only; harmless on older AMD
  # (the kernel ignores it and stays on acpi-cpufreq). A kernel param, so it
  # takes effect on the next boot.
  boot.kernelParams = [ "amd_pstate=active" ];
}
