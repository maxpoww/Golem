# The timezone step's data — the installer's step 2.
#
# THE ZONE LIST IS NOT HERE, AND THAT IS THE POINT. tzdata already ships
# every zone (506 of them on the current pin) and the medium already carries
# it at /etc/zoneinfo. Copying that list into this repo would mean a second
# copy to keep in step with the world's politics — Kyiv renamed, Istanbul
# leaving DST, a new zone splitting off — and a CI check to prove the copy
# still matches. So the surface reads the zones from tzdata at runtime and
# there is nothing to drift.
#
# WHAT IS HERE is the only part that needs a human decision: the DEFAULT a
# language implies. That is a small hand-written map, and the one thing CI
# must prove about it is that every zone named below is a zone that exists.
#
#   nix build .#checks.x86_64-linux.timezone-defaults
#   nix eval  .#lib.golem.timezones.forLanguage --apply 'f: f "pt-BR"'
#
# THE DEFAULT IS A GUESS AND THE STEP EXISTS TO CONFIRM IT. Some languages
# map cleanly — ja is Asia/Tokyo and nothing else. Others do not: English is
# spoken across eleven zones, Spanish across a dozen, Arabic across nine.
# For those the entry is the most populous zone of the largest speaking
# population, which is a guess that is right often and wrong visibly. That
# is the right shape of wrong: the step shows the CLOCK in the proposed
# zone, so a wrong guess is caught by looking at it rather than by knowing
# your own IANA zone name.
#
# A REGIONAL LANGUAGE CODE IS THE STRONGEST SIGNAL WE GET. pt-BR is
# América/São_Paulo where pt is Europe/Lisbon; es-419 is Mexico City where
# es is Madrid; zh-TW is Taipei where zh-CN is Shanghai. Picking the
# regional variant in step 1 therefore fixes the timezone too, which is
# most of why those rows exist in the language table at all.
{ lib }:

let
  # ── language → the zones its speakers actually live in, in order ──────
  #
  # THERE IS NO SUGGESTED ZONE ANY MORE (Max, 2026-09-05). Proposing one
  # and asking "is this your time?" was the keyboard step's shape borrowed
  # where it does not fit: a keyboard has ONE right answer that the machine
  # can almost always guess, and a language does not. Spanish is spoken
  # across a dozen zones and Madrid is right for a tenth of its speakers,
  # so the guess was wrong most of the time and the confirm screen was a
  # ritual to get past.
  #
  # The list IS the answer instead, opened directly and ordered so the
  # zones of the countries that speak the chosen language come first. That
  # turns a wrong guess into a short list, and the filter is still there for
  # everyone else. Ordering within a language is by number of speakers, so
  # the top row is the single most likely answer without pretending to be
  # the only one.
  top = {
    en = [ "America/New_York" "America/Chicago" "America/Denver" "America/Los_Angeles"
           "Europe/London" "America/Toronto" "Australia/Sydney" "Pacific/Auckland"
           "Europe/Dublin" "Africa/Johannesburg" ];
    es = [ "Europe/Madrid" "America/Mexico_City" "America/Bogota"
           "America/Argentina/Buenos_Aires" "America/Lima" "America/Santiago"
           "America/Caracas" "America/Guatemala" "America/Havana" "America/Montevideo" ];
    "es-419" = [ "America/Mexico_City" "America/Bogota" "America/Argentina/Buenos_Aires"
                 "America/Lima" "America/Santiago" "America/Caracas" "America/Guatemala"
                 "America/La_Paz" "America/Montevideo" "America/Asuncion" ];
    pt = [ "Europe/Lisbon" "America/Sao_Paulo" "Africa/Luanda" "Africa/Maputo"
           "Atlantic/Azores" ];
    "pt-BR" = [ "America/Sao_Paulo" "America/Fortaleza" "America/Manaus"
                "America/Bahia" "America/Cuiaba" "Europe/Lisbon" ];
    fr = [ "Europe/Paris" "America/Montreal" "Europe/Brussels" "Africa/Abidjan"
           "Africa/Kinshasa" "Africa/Dakar" "Europe/Zurich" "Indian/Antananarivo" ];
    de = [ "Europe/Berlin" "Europe/Vienna" "Europe/Zurich" ];
    it = [ "Europe/Rome" "Europe/Zurich" ];
    nl = [ "Europe/Amsterdam" "Europe/Brussels" ];
    ar = [ "Africa/Cairo" "Asia/Riyadh" "Asia/Dubai" "Africa/Casablanca"
           "Africa/Algiers" "Asia/Baghdad" "Africa/Khartoum" "Asia/Amman"
           "Asia/Damascus" "Africa/Tunis" ];
    ru = [ "Europe/Moscow" "Asia/Yekaterinburg" "Asia/Novosibirsk" "Asia/Vladivostok"
           "Europe/Kaliningrad" "Asia/Almaty" "Asia/Tashkent" ];
    "zh-CN" = [ "Asia/Shanghai" "Asia/Urumqi" "Asia/Hong_Kong" "Asia/Macau"
                "Asia/Singapore" ];
    "zh-TW" = [ "Asia/Taipei" "Asia/Hong_Kong" ];
    en-IN = [ "Asia/Kolkata" ];
    sw = [ "Africa/Nairobi" "Africa/Dar_es_Salaam" "Africa/Kampala" ];
    tr = [ "Europe/Istanbul" ];
    fa = [ "Asia/Tehran" ];
    ur = [ "Asia/Karachi" ];
    ko = [ "Asia/Seoul" ];
    ja = [ "Asia/Tokyo" ];
    vi = [ "Asia/Ho_Chi_Minh" ];
    th = [ "Asia/Bangkok" ];
    id = [ "Asia/Jakarta" "Asia/Makassar" "Asia/Jayapura" ];
    ms = [ "Asia/Kuala_Lumpur" "Asia/Singapore" "Asia/Brunei" ];
    fil = [ "Asia/Manila" ];
    af = [ "Africa/Johannesburg" ];
    am = [ "Africa/Addis_Ababa" ];
    he = [ "Asia/Jerusalem" ];
    el = [ "Europe/Athens" "Asia/Nicosia" ];
    uk = [ "Europe/Kyiv" ];
    be = [ "Europe/Minsk" ];
    pl = [ "Europe/Warsaw" ];
    cs = [ "Europe/Prague" ];
    sk = [ "Europe/Bratislava" ];
    sl = [ "Europe/Ljubljana" ];
    hr = [ "Europe/Zagreb" ];
    sr = [ "Europe/Belgrade" ];
    bs = [ "Europe/Sarajevo" ];
    mk = [ "Europe/Skopje" ];
    sq = [ "Europe/Tirane" ];
    hu = [ "Europe/Budapest" ];
    ro = [ "Europe/Bucharest" "Europe/Chisinau" ];
    bg = [ "Europe/Sofia" ];
    lt = [ "Europe/Vilnius" ];
    lv = [ "Europe/Riga" ];
    et = [ "Europe/Tallinn" ];
    sv = [ "Europe/Stockholm" "Europe/Helsinki" ];
    da = [ "Europe/Copenhagen" ];
    nb = [ "Europe/Oslo" ];
    fi = [ "Europe/Helsinki" ];
    is = [ "Atlantic/Reykjavik" ];
    ga = [ "Europe/Dublin" ];
    cy = [ "Europe/London" ];
    ca = [ "Europe/Madrid" "Europe/Andorra" ];
    eu = [ "Europe/Madrid" ];
    gl = [ "Europe/Madrid" ];
    hi = [ "Asia/Kolkata" ];
    pa = [ "Asia/Kolkata" ];
    mr = [ "Asia/Kolkata" ];
    ta = [ "Asia/Kolkata" "Asia/Colombo" "Asia/Singapore" ];
    te = [ "Asia/Kolkata" ];
    bn = [ "Asia/Dhaka" "Asia/Kolkata" ];
  };

  # A regional code falls back to its base before it falls back to nothing,
  # so a language mapped only generally still opens somewhere sensible.
  topFor = code:
    top.${code} or top.${lib.head (lib.splitString "-" code)} or [ ];

  # language code → IANA zone
  defaults = {
    # Spoken across many zones; the entry is the largest speaking population.
    en = "America/New_York";
    es = "Europe/Madrid";
    "es-419" = "America/Mexico_City";
    pt = "Europe/Lisbon";
    "pt-BR" = "America/Sao_Paulo";
    ar = "Asia/Riyadh";
    ru = "Europe/Moscow";

    # One country, one zone — these are not guesses.
    fr = "Europe/Paris";
    de = "Europe/Berlin";
    it = "Europe/Rome";
    nl = "Europe/Amsterdam";
    pl = "Europe/Warsaw";
    sv = "Europe/Stockholm";
    da = "Europe/Copenhagen";
    nb = "Europe/Oslo";
    fi = "Europe/Helsinki";
    is = "Atlantic/Reykjavik";
    cs = "Europe/Prague";
    sk = "Europe/Bratislava";
    sl = "Europe/Ljubljana";
    hr = "Europe/Zagreb";
    sr = "Europe/Belgrade";
    bs = "Europe/Sarajevo";
    mk = "Europe/Skopje";
    sq = "Europe/Tirane";
    hu = "Europe/Budapest";
    ro = "Europe/Bucharest";
    bg = "Europe/Sofia";
    el = "Europe/Athens";
    uk = "Europe/Kyiv";
    be = "Europe/Minsk";
    lt = "Europe/Vilnius";
    lv = "Europe/Riga";
    et = "Europe/Tallinn";
    tr = "Europe/Istanbul";
    ga = "Europe/Dublin";
    cy = "Europe/London";
    he = "Asia/Jerusalem";
    fa = "Asia/Tehran";
    ur = "Asia/Karachi";
    bn = "Asia/Dhaka";
    "zh-CN" = "Asia/Shanghai";
    "zh-TW" = "Asia/Taipei";
    ja = "Asia/Tokyo";
    ko = "Asia/Seoul";
    vi = "Asia/Ho_Chi_Minh";
    th = "Asia/Bangkok";
    id = "Asia/Jakarta";
    ms = "Asia/Kuala_Lumpur";
    fil = "Asia/Manila";
    sw = "Africa/Nairobi";
    af = "Africa/Johannesburg";
    am = "Africa/Addis_Ababa";

    # The languages of one country that spans no zones worth splitting:
    # every Indian language is Asia/Kolkata, India having a single zone.
    hi = "Asia/Kolkata";
    pa = "Asia/Kolkata";
    mr = "Asia/Kolkata";
    ta = "Asia/Kolkata";
    te = "Asia/Kolkata";

    # Spain's other languages.
    ca = "Europe/Madrid";
    eu = "Europe/Madrid";
    gl = "Europe/Madrid";
  };

  # UTC rather than a neighbour's zone for an unmapped language: a clock
  # that is plainly wrong gets corrected, where a plausible-but-wrong one
  # gets trusted. Same reasoning as golem.locale.timeZone's own default.
  forLanguage = code: defaults.${code} or defaults.${lib.head (lib.splitString "-" code)} or "UTC";

  # `code|zone,zone,zone` — the surface reads this to order its list.
  table = lib.concatStrings
    (lib.mapAttrsToList (code: zs: "${code}|${lib.concatStringsSep "," zs}\n") top);
in
{
  inherit top topFor defaults forLanguage table;
  # Every zone named anywhere in this file, for the check to verify.
  zones = lib.unique (lib.flatten (lib.attrValues top) ++ lib.attrValues defaults);
}
