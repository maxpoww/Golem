# base/freeze — a Golem that freezes comes back on its own.
#
# The 2013 MacBook Air froze at 14 s of a boot (the camera driver's probe
# after a quick warm reboot, 2026-10-29) and sat on the progress bar until
# the power button: the kernel's defaults leave a panic where it is
# (kernel.panic = 0) and a CPU stuck in the kernel is only reported. That
# machine has no watchdog device either. Max, 2026-10-30: "1 sí".
#
#   kernel.panic = 10          a panic reboots the machine ten seconds later
#                              (time for the oops to reach the journal/console)
#   kernel.softlockup_panic    a CPU stuck in the kernel for the watchdog's
#                              window (20 s) panics — and so reboots — instead
#                              of being only noted
#
# hung_task_panic stays OFF: a task two minutes in uninterruptible sleep is
# often a slow disk or a network mount, not a dead machine. The hardware
# watchdog (systemd's RuntimeWatchdogSec) is left as it is: most laptops
# here have none, and a machine with one gains nothing the two lines above
# do not give.
{ lib, ... }:

{
  boot.kernel.sysctl = {
    "kernel.panic" = lib.mkDefault 10;
    "kernel.softlockup_panic" = lib.mkDefault 1;
  };
}
