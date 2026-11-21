# (A test fixture: an owner replacing one of Standard's modules with their own —
# the journal's size policy here, because it is small and visible.)
{ standardSource, ... }:
{
  disabledModules = [ "${standardSource}/system/Modular/base/journal.nix" ];
  services.journald.extraConfig = "SystemMaxUse=42M";
}
