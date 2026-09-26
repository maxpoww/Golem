# base/locale — language and timezone, data-driven from golem.locale
# (the installer's first two answers). LC_* deliberately unset: every
# category follows defaultLocale — the split case (English interface,
# local formats) is a preference for OPTIONS, not a setup question.
#
# supportedLocales is a FIXED set (the languages the installer offers), NOT
# derived from the one chosen locale. That is deliberate and load-bearing for
# first-boot convergence: the baked generic gen-1 and the converged system
# generate the SAME locale-archive, so switching the language on first boot is
# a pure re-point of LANG — the archive is already in the copied closure and
# nothing has to be BUILT on a machine that may have no network. (Derive it
# from defaultLocale, as before, and pt_PT's archive is absent on the generic
# system → the convergence rebuild tries to build it offline and dies.) The
# list MUST stay a superset of every locale the language step can return.
{ config, lib, ... }:

let
  loc = config.golem.locale.defaultLocale;      # e.g. pt_PT.UTF-8
  base = lib.removeSuffix ".UTF-8" loc;         # pt_PT
  lang = lib.head (lib.splitString "_" base);   # pt

  # The offered languages — one source of truth shared with flake.nix's
  # bakeLocales and the installer's language step (system/golem-locales.nix).
  # Each "xx_XX.UTF-8" becomes a supportedLocales "xx_XX.UTF-8/UTF-8"; C is added.
  golemLocales = map (l: "${l}/UTF-8") (import ../../golem-locales.nix).all
    ++ [ "C.UTF-8/UTF-8" ];
in
{
  i18n.defaultLocale = lib.mkDefault loc;
  # unique keeps golemLocales' order (a chosen locale already in the set is a
  # dropped dup), so generic and converged hash to the SAME archive. The
  # `++ [loc]` is only a safety net for a locale outside the set — which then
  # DOES need one build, so the offered set should always contain it.
  i18n.supportedLocales = lib.mkDefault (lib.unique (golemLocales ++ [ "${loc}/UTF-8" ]));

  # gettext's language priority for apps. i18n.defaultLocale sets LANG (hence
  # LC_MESSAGES), but a lot of software localizes off LANGUAGE — and this lets
  # a language fall back sensibly (pt_PT → pt), so an app that ships only "pt"
  # still comes up localized instead of English. NOT extraLocaleSettings (that
  # stays {}, per the regression guard) — it is a session env var.
  environment.sessionVariables.LANGUAGE = lib.mkDefault "${base}:${lang}";

  time.timeZone = lib.mkDefault config.golem.locale.timeZone;
}
