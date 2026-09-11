# base/locale — language and timezone, data-driven from golem.locale
# (the installer's first two answers). LC_* deliberately unset: every
# category follows defaultLocale — the split case (English interface,
# local formats) is a preference for OPTIONS, not a setup question.
# The chosen locale is GENERATED alongside en_US and C, or it silently
# falls back to C at first boot.
{ config, lib, ... }:

{
  i18n.defaultLocale = lib.mkDefault config.golem.locale.defaultLocale;
  i18n.supportedLocales = lib.mkDefault (lib.unique [
    "${config.golem.locale.defaultLocale}/UTF-8"
    "en_US.UTF-8/UTF-8"
    "C.UTF-8/UTF-8"
  ]);
  time.timeZone = lib.mkDefault config.golem.locale.timeZone;
}
