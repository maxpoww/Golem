# (A test fixture: an owner replacing one of Golem's modules with their own —
# the journal's size policy here, because it is small and visible.)
{ golemSource, ... }:
{
  disabledModules = [ "${golemSource}/system/Modular/base/journal.nix" ];
  services.journald.extraConfig = "SystemMaxUse=42M";
}
