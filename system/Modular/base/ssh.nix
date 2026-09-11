# base/ssh — reachable, key-only, stage 0.
# A stage-0 machine with no SSH is a machine the lab (and the owner's
# other machines) cannot reach — unreachable minimal is a dead end
# (Installing spec: boots, REACHABLE, rebuildable, recognizable).
# Key-only: with no key authorized this is effectively closed; the lab
# key arrives only when golem-install is asked (--lab-ssh → machine.nix)
# — GolemSecurity phase 3's "no lab keys on shipped images" holds.
{ lib, ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
}
