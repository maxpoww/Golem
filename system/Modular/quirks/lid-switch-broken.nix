# quirks/lid-switch-broken — a lid switch that LIES. No census fact
# chooses this yet (see changes.md #90 — ACPI only gives us the
# switch's word, so detection means catching it in a lie, e.g. reading
# "closed" during an interactive install); it arrives by an owner's
# deliberate edit to modules.nix.
#
# Found on the comodore, 2026-09-15: the switch stuck at "closed", and
# power/laptop's lid rule + logind's 30 s post-resume holdoff put the
# machine back to sleep half a minute after every wake, forever — a
# perfectly healthy machine unusable at the power button.
#
# Plain definition on purpose: it must beat power/laptop's mkDefault.
# Only the LID path is silenced — the power button, systemctl
# suspend/hibernate, and the bag timer all stay live.
{ ... }:

{
  services.logind.settings.Login.HandleLidSwitch = "ignore";
}
