# desktop/idle — the system half of "something happens on idle" (parity P11).
#
# The idle daemon (hypridle) and the lock screen (hyprlock) are the owner's,
# in the home layer (system/home/idle.nix): lock at 5 min, screen off at 6,
# suspend at 15, lock before any sleep. hyprlock authenticates the owner's
# password through PAM, so the system must know it as a PAM service — without
# this entry the lock screen can never be unlocked.
{ ... }:

{
  security.pam.services.hyprlock = { };
}
