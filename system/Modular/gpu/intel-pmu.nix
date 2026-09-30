# gpu/intel-pmu — lets the gear readout see an Intel iGPU's load.
#
# The GPU % comes from the i915 PMU, which only perf_event_open can read (i915
# has no sysfs busy counter, only a clock), and only system-wide: 0 is the
# level that allows that (1 already refuses it; the kernel default is 2). 0
# still refuses raw tracepoints. Without it the MacBook's gear had no GPU
# column (found 2026-09-30 by the P1 diff: the dev box set this, Golem never
# did). AMD needs nothing (amdgpu's gpu_busy_percent). Imported by both Intel
# leaves; imports dedupe by path, so it is defined once even if both land.
{ ... }:

{
  boot.kernel.sysctl."kernel.perf_event_paranoid" = 0;
}
