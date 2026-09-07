# Max's machine: language, formats and clock.
#
# These lived in system/configuration.nix until 2026-09-05, which meant one
# owner's settings were shipped to every Golem ever installed — a stranger
# picking Français in the installer still got Bolivian dates, money, paper
# size and a La Paz clock. Nothing detected it because it looked completely
# normal on the machine it was written for.
#
# They are correct HERE: this file is one machine's facts, the same way
# nvidia.nix and hardware-configuration.nix beside it are. An installed
# stranger's machine gets golem.locale from the installer instead, and the
# LC_* split below is exactly the preference the distro deliberately does
# not ask about (see the note in system/configuration.nix).
{ ... }:

{
  golem.locale = {
    defaultLocale = "en_US.UTF-8";
    timeZone = "America/La_Paz";
  };

  # English interface, Bolivian formats. The distro leaves LC_* unset so
  # every category follows the chosen language; this machine wants them
  # split, which is why it says so itself.
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_BO.UTF-8";
    LC_IDENTIFICATION = "es_BO.UTF-8";
    LC_MEASUREMENT = "es_BO.UTF-8";
    LC_MONETARY = "es_BO.UTF-8";
    LC_NAME = "es_BO.UTF-8";
    LC_NUMERIC = "es_BO.UTF-8";
    LC_PAPER = "es_BO.UTF-8";
    LC_TELEPHONE = "es_BO.UTF-8";
    LC_TIME = "es_BO.UTF-8";
  };

  # es_BO is only referenced by the LC_* block above, so it is not implied
  # by defaultLocale and has to be asked for or it will not be generated.
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "es_BO.UTF-8/UTF-8"
    "C.UTF-8/UTF-8"
  ];
}
