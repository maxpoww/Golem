# (A test fixture: an owner's own module, picked up from modules/.)
{ pkgs, ... }:
{
  environment.variables.GOLEM_TEST_DROPIN = "own";
  environment.systemPackages = [ pkgs.hello ];
}
