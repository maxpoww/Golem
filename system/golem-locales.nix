# Golem's languages — split into two lists because they cost very differently.
#
#   all   → i18n.supportedLocales (base/locale.nix). This is ONE locale-archive
#           derivation covering every language: cheap, built once, shared by every
#           baked toplevel. Keep it broad — it's the future-ready set and the
#           safety net (a chosen locale here is at least GENERATED, never C).
#
#   baked → bakeLocales (flake.nix). Each entry is a FULL NixOS system eval, and
#           the ISO holds them all in ONE nix process — so N here multiplies eval
#           RAM (~3 GB each). 16 baked ≈ 50 GB → swap-thrashed a 32 GB box
#           (2026-09-25). So `baked` is deliberately SMALL: the console-usable
#           languages actually in play now (Latin + Cyrillic — CJK/Indic can't
#           render on a tty anyway, so they wait for the Stage-1 desktop, when a
#           BATCHED build — eval each locale in its own process — lets the whole
#           `all` set be baked without the RAM blowup).
#
# A chosen language in `all` but not `baked` installs the en_US variant of the
# same hardware (boots English) until it's baked. The installer's language step
# should offer `baked` to avoid that surprise.
{
  all = [
    "en_US.UTF-8" "en_GB.UTF-8"
    "es_ES.UTF-8" "es_MX.UTF-8"
    "pt_PT.UTF-8" "pt_BR.UTF-8"
    "fr_FR.UTF-8" "de_DE.UTF-8" "it_IT.UTF-8"
    "ru_RU.UTF-8"
    "zh_CN.UTF-8" "zh_TW.UTF-8" "ja_JP.UTF-8" "ko_KR.UTF-8"
    "hi_IN" "en_IN"          # glibc names these WITHOUT .UTF-8 (codeset defaults to UTF-8)
    "ar_SA.UTF-8"
  ];

  # Memory-safe core baked now. Grow this (toward `all`) once the batched build
  # lands. Everything here renders + types on a plain console today.
  baked = [
    "en_US.UTF-8"
    "es_ES.UTF-8"
    "pt_PT.UTF-8" "pt_BR.UTF-8"
    "ru_RU.UTF-8"
  ];
}
