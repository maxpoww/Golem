# base/journal — cap the systemd journal, stage 0.
#
# The default persistent journal grows to 10 % of the filesystem — on the
# lab's small/old disks (the HP's spinning HDD, the 2 GB boxes) that is a lot
# of space spent on logs nobody reads. A firm cap keeps logs useful for
# diagnosis (a month, which covers "what changed last week") without letting
# them eat the disk. Small, always-on, breaks nothing.
{ ... }:

{
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    SystemMaxFileSize=50M
    MaxRetentionSec=1month
  '';
}
