# The keyboard table — the installer's keyboard step as DATA, not as code
# inside a surface.
#
# The step asks a stranger ONE question ("is this your keyboard") and every
# setting an installed machine needs falls out of the row behind the answer.
# That derivation lives here rather than in the installer because it has two
# consumers who must never disagree: the install surface, which writes the
# answer into machine.nix, and CI, which proves every row is real.
#
#   nix build .#checks.x86_64-linux.keyboard-table
#   nix eval  .#lib.golem.keyboards.derive --apply 'f: f "colemak"'
#
# THREE NAMESPACES, THREE COLUMNS. These used to be one field used as all of
# them, which was wrong in a way that ships broken installs: console keymaps
# (kbd) and XKB layouts (xkeyboard-config) are different vocabularies that
# agree on some names and not others. The ones that disagree:
#
#   UK        xkb gb      console uk
#   Latin Am. xkb latam   console la-latin1
#   Brasil    xkb br      console br-abnt2
#   Japan     xkb jp      console jp106
#   Turkey    xkb tr      console trq  (and `f` → trf)
#   Hungary   xkb hu      console hu101
#   Portugal  xkb pt      console pt-latin1
#   Slovenia  xkb si      console slovene
#   Croatia   xkb hr      console croat
#   Serbia    xkb rs      console sr-cy
#
# AN EMPTY `console` IS A DELIBERATE ANSWER, NOT A HOLE. kbd ships no keymap
# at all for Arabic, Persian, Thai, Korean or the Indic scripts, so those
# rows leave it blank and derive falls back to `us`. That is right twice
# over: the TTY has no font for those scripts anyway, and a rescue console
# you cannot type Latin on is a brick.
#
# THE CORRESPONDENCE RULE, and it is the one the CI check CANNOT enforce:
# a console keymap must have the SAME LETTER POSITIONS and the SAME ACCENT
# MECHANISM as the xkb layout+variant beside it. When kbd has nothing that
# close, the row leaves `console` empty and takes `us`.
#
# A NEAR MISS IS WORSE THAN QWERTY. QWERTY is what is printed on the keys
# and what every rescue console has always been — a predictable surprise.
# A layout that is almost the chosen one is an unpredictable one: the user
# types confidently and six letters come out wrong. Four rows were doing
# exactly that before 2026-09-05, all of them "close enough" at a glance:
#
#   workman     had console colemak — a completely different layout
#   colemak-dh  had console colemak — the DH mod moves six keys
#   us-altgr    had console us-acentos — that keymap IS dead keys, which
#               is precisely what altgr-intl exists to avoid
#   al          had console croat — Albanian is ë ç, Croatian is č ć ž đ
#
# The check validates that every name EXISTS; it cannot know that the name
# is the right one. That judgement lives here, in this comment and in the
# blank columns below it.
#
# VARIANTS ARE THEIR OWN ROWS. Colemak is not a layout, it is `us` with
# variant `colemak` — but nobody searches for "us"; they search for
# "colemak". So every variant people actually name by name gets a row.
#
# THERE IS NO "keys worth trying" COLUMN, and there was one until
# 2026-09-05. It listed the characters that distinguish a layout — ñ ¿ ç for
# Español — so the installer could invite you to press them and compare what
# came out against your keycaps. It CONFIGURED NOTHING: picking the row's
# name is what configures the machine, and this was only ever a way to check
# that the name was picked right (Max: "selecting english (US), or español
# (latinoamérica) — is that enough? that is the thing." It is.)
#
# It came out because people know what keyboard they own. "It is a Spanish
# keyboard" is not a hard question, so the check earned its column only for
# the few typing on a board they cannot read, and cost everyone else a
# column of punctuation to scroll past. If a passphrase screen ever wants to
# verify the layout where a mistake actually costs something, this is the
# data it would need back.
{ lib }:

let
  # id name aliases xkb variant console script form
  raw = [
    [ "us" "English (US)" "english us american qwerty" "us" "" "us" "latin" "ansi" ]
    [ "us-intl" "English (US) — international" "international intl deadkeys dead keys accents" "us" "intl" "us-acentos" "latin" "ansi" ]
    [ "us-altgr" "English (US) — AltGr international" "altgr international nodeadkeys" "us" "altgr-intl" "" "latin" "ansi" ]
    [ "colemak" "Colemak" "colemak ergonomic" "us" "colemak" "colemak" "latin" "ansi" ]
    [ "colemak-dh" "Colemak-DH" "colemak dh mod ergonomic" "us" "colemak_dh" "" "latin" "ansi" ]
    [ "dvorak" "Dvorak" "dvorak ergonomic" "us" "dvorak" "dvorak" "latin" "ansi" ]
    [ "dvorak-prog" "Dvorak (programmer)" "dvorak programmer prog" "us" "dvp" "dvorak-programmer" "latin" "ansi" ]
    [ "workman" "Workman" "workman ergonomic" "us" "workman" "" "latin" "ansi" ]
    [ "gb" "English (UK)" "english uk british" "gb" "" "uk" "latin" "iso" ]
    [ "gb-colemak" "English (UK) — Colemak" "colemak uk british" "gb" "colemak" "colemak" "latin" "iso" ]
    [ "gb-dvorak" "English (UK) — Dvorak" "dvorak uk british" "gb" "dvorak" "dvorak-uk" "latin" "iso" ]
    [ "ie" "Gaeilge" "irish ireland gaelic" "ie" "" "ie" "latin" "iso" ]
    [ "es" "Español" "spanish espanol espana" "es" "" "es" "latin" "iso" ]
    [ "es-dvorak" "Español — Dvorak" "dvorak spanish espanol" "es" "dvorak" "dvorak-es" "latin" "iso" ]
    [ "latam" "Español (Latinoamérica)" "spanish latam latin america" "latam" "" "la-latin1" "latin" "iso" ]
    [ "latam-colemak" "Español (Latinoamérica) — Colemak" "colemak latam latin america" "latam" "colemak" "colemak" "latin" "iso" ]
    [ "fr" "Français" "french azerty france" "fr" "" "fr-latin9" "latin" "iso" ]
    [ "fr-nodead" "Français — sans accents morts" "french nodeadkeys azerty" "fr" "nodeadkeys" "fr-latin1" "latin" "iso" ]
    [ "bepo" "Français — Bépo" "bepo french ergonomic dvorak" "fr" "bepo" "fr-bepo" "latin" "iso" ]
    [ "fr-dvorak" "Français — Dvorak" "dvorak french" "fr" "dvorak" "dvorak-fr" "latin" "iso" ]
    [ "be" "Français (Belgique)" "french belgian belgique" "be" "" "be-latin1" "latin" "iso" ]
    [ "ca" "Français (Canada)" "french canadian quebec" "ca" "" "cf" "latin" "ansi" ]
    [ "de" "Deutsch" "german deutsch qwertz" "de" "" "de-latin1" "latin" "iso" ]
    [ "de-nodead" "Deutsch — ohne Akzenttasten" "german nodeadkeys qwertz" "de" "nodeadkeys" "de-latin1-nodeadkeys" "latin" "iso" ]
    [ "neo" "Deutsch — Neo" "neo german ergonomic" "de" "neo" "neo" "latin" "iso" ]
    [ "de-dvorak" "Deutsch — Dvorak" "dvorak german" "de" "dvorak" "dvorak-de" "latin" "iso" ]
    [ "ch" "Deutsch (Schweiz)" "german swiss schweiz suisse" "ch" "" "sg-latin1" "latin" "iso" ]
    [ "it" "Italiano" "italian italia" "it" "" "it" "latin" "iso" ]
    [ "pt" "Português" "portuguese portugal" "pt" "" "pt-latin1" "latin" "iso" ]
    [ "br" "Português (Brasil)" "portuguese brazilian brasil abnt" "br" "" "br-abnt2" "latin" "abnt" ]
    [ "nl" "Nederlands" "dutch netherlands nederland" "nl" "" "nl" "latin" "iso" ]
    [ "pl" "Polski" "polish polska programisty" "pl" "" "pl" "latin" "ansi" ]
    [ "cz" "Čeština" "czech cesko ceska" "cz" "" "cz" "latin" "iso" ]
    [ "sk" "Slovenčina" "slovak slovensko" "sk" "" "sk-qwerty" "latin" "iso" ]
    [ "hu" "Magyar" "hungarian magyarorszag" "hu" "" "hu101" "latin" "iso" ]
    [ "ro" "Română" "romanian romania" "ro" "" "ro_std" "latin" "iso" ]
    [ "hr" "Hrvatski" "croatian hrvatska" "hr" "" "croat" "latin" "iso" ]
    [ "si" "Slovenščina" "slovenian slovenscina slovenija" "si" "" "slovene" "latin" "iso" ]
    [ "al" "Shqip" "albanian shqip shqiperi" "al" "" "" "latin" "iso" ]
    [ "ba" "Bosanski" "bosnian bosanski bosna" "ba" "" "croat" "latin" "iso" ]
    [ "dk" "Dansk" "danish danmark" "dk" "" "dk-latin1" "latin" "iso" ]
    [ "no" "Norsk" "norwegian norge norsk" "no" "" "no-latin1" "latin" "iso" ]
    [ "se" "Svenska" "swedish sverige" "se" "" "sv-latin1" "latin" "iso" ]
    [ "fi" "Suomi" "finnish suomi" "fi" "" "fi" "latin" "iso" ]
    [ "is" "Íslenska" "icelandic island" "is" "" "is-latin1" "latin" "iso" ]
    [ "ee" "Eesti" "estonian eesti" "ee" "" "et" "latin" "iso" ]
    [ "lv" "Latviešu" "latvian latvija" "lv" "" "lv" "latin" "iso" ]
    [ "lt" "Lietuvių" "lithuanian lietuva" "lt" "" "lt" "latin" "iso" ]
    [ "tr" "Türkçe" "turkish turkiye turkce q" "tr" "" "trq" "latin" "iso" ]
    [ "tr-f" "Türkçe — F" "turkish turkiye f klavye" "tr" "f" "trf" "latin" "iso" ]
    [ "rs" "Српски" "serbian srpski srbija" "rs" "" "sr-cy" "cyrillic" "iso" ]
    [ "mk" "Македонски" "macedonian makedonski" "mk" "" "mk-utf" "cyrillic" "iso" ]
    [ "bg" "Български" "bulgarian balgarski" "bg" "" "bg_bds-utf8" "cyrillic" "iso" ]
    [ "bg-pho" "Български — фонетична" "bulgarian phonetic" "bg" "phonetic" "bg_pho-utf8" "cyrillic" "iso" ]
    [ "ru" "Русский" "russian russkiy rossiya" "ru" "" "ru" "cyrillic" "iso" ]
    [ "ru-pho" "Русский — фонетическая" "russian phonetic" "ru" "phonetic" "ru-yawerty" "cyrillic" "iso" ]
    [ "ua" "Українська" "ukrainian ukrainska" "ua" "" "ua-utf" "cyrillic" "iso" ]
    [ "by" "Беларуская" "belarusian belaruskaya" "by" "" "by" "cyrillic" "iso" ]
    [ "gr" "Ελληνικά" "greek ellinika ellada" "gr" "" "gr" "greek" "iso" ]
    [ "il" "עברית" "hebrew ivrit israel" "il" "" "il" "hebrew" "iso" ]
    [ "il-pho" "עברית — פונטית" "hebrew phonetic ivrit" "il" "phonetic" "il-phonetic" "hebrew" "iso" ]
    [ "ara" "العربية" "arabic arabiyya" "ara" "" "" "arabic" "iso" ]
    # console is EMPTY on purpose, and it used to say "fa". A file named
    # fa.map.gz exists, which is not the same as being usable: it defines
    # 11 base-layer keys against 104 AltGr ones and includes only
    # linux-keys-bare, so the TTY's unshifted alphabet is EMPTY. Persian on
    # AltGr, nothing on base — no commands, no paths, no passphrase. The
    # check below now enforces what this row learned.
    [ "ir" "فارسی" "persian farsi iran" "ir" "" "" "arabic" "iso" ]
    [ "pk" "اردو" "urdu pakistan" "pk" "pak_urdu_phonetic" "" "arabic" "iso" ]
    # `deva` is the DEFAULT group of the Indian layout — defined in
    # symbols/in but deliberately absent from the advertised variant list,
    # so the correct spelling is a bare `in`. Naming it explicitly is how
    # this row was wrong before the check existed.
    [ "in" "हिन्दी" "indian india hindi devanagari" "in" "" "" "indic" "iso" ]
    [ "in-tam" "தமிழ்" "tamil india" "in" "tam" "" "indic" "iso" ]
    [ "in-tel" "తెలుగు" "telugu india" "in" "tel" "" "indic" "iso" ]
    [ "bd" "বাংলা" "bengali bangla bangladesh" "bd" "probhat" "" "indic" "iso" ]
    [ "th" "ไทย" "thai" "th" "" "" "thai" "iso" ]
    [ "jp" "日本語" "japanese nihongo jis kana" "jp" "" "jp106" "latin" "jis" ]
    [ "kr" "한국어" "korean hangul hangugeo" "kr" "kr104" "" "latin" "ansi" ]
  ];

  row = r: {
    id = builtins.elemAt r 0;
    name = builtins.elemAt r 1;
    aliases = builtins.elemAt r 2;
    xkb = builtins.elemAt r 3;
    variant = builtins.elemAt r 4;
    console = builtins.elemAt r 5;
    script = builtins.elemAt r 6;
    form = builtins.elemAt r 7;
  };

  layouts = map row raw;
  byId = lib.listToAttrs (map (l: lib.nameValuePair l.id l) layouts);

  # ── country → keyboard, and why the TIMEZONE is what asks ─────────────
  #
  # The language is a weak signal for a keyboard and the timezone is a
  # strong one (Max, 2026-09-05: "if the user enters Argentina/Buenos_Aires
  # → keyboard should suggest español (latinoamérica); europe/london →
  # english (UK)"). Spanish is spoken on two continents with two different
  # keyboards; English is typed on `us` in Chicago and `gb` in Manchester.
  # The zone knows which, because it names a PLACE, and where the machine is
  # standing is what decides which keyboard is plugged into it.
  #
  # THE ZONE→COUNTRY HALF IS NOT HERE. tzdata ships zone1970.tab, which maps
  # every zone to its ISO 3166 codes and is updated when the world changes —
  # so the surface reads that at runtime and only the country→layout half,
  # below, needs a human. Same division as the zone list itself.
  #
  # Only countries whose keyboard differs from the obvious are interesting,
  # but the map is written out in full anyway: a missing entry falls back to
  # the language's layout, and "it fell back" is indistinguishable from "we
  # meant us" when reading a bug report.
  byCountry = {
    US = "us"; CA = "ca"; GB = "gb"; IE = "ie"; AU = "us"; NZ = "us";
    ES = "es"; PT = "pt"; BR = "br"; FR = "fr"; BE = "be"; CH = "ch";
    DE = "de"; AT = "de"; IT = "it"; NL = "nl"; LU = "fr";
    # Latin America — every one of them is `latam`, not `es`. This is the
    # single biggest thing the timezone buys: a Spanish speaker in Bogotá
    # and one in Madrid want different keyboards, and only the zone knows.
    MX = "latam"; AR = "latam"; CO = "latam"; CL = "latam"; PE = "latam";
    VE = "latam"; EC = "latam"; BO = "latam"; PY = "latam"; UY = "latam";
    GT = "latam"; CR = "latam"; PA = "latam"; DO = "latam"; CU = "latam";
    HN = "latam"; NI = "latam"; SV = "latam"; PR = "latam";
    PL = "pl"; CZ = "cz"; SK = "sk"; SI = "si"; HR = "hr"; BA = "ba";
    RS = "rs"; MK = "mk"; AL = "al"; HU = "hu"; RO = "ro"; MD = "ro";
    BG = "bg"; GR = "gr"; CY = "gr";
    RU = "ru"; UA = "ua"; BY = "by"; KZ = "ru";
    LT = "lt"; LV = "lv"; EE = "ee";
    DK = "dk"; NO = "no"; SE = "se"; FI = "fi"; IS = "is";
    TR = "tr"; IL = "il"; IR = "ir"; PK = "pk";
    SA = "ara"; AE = "ara"; EG = "ara"; MA = "ara"; DZ = "ara"; TN = "ara";
    IQ = "ara"; JO = "ara"; SY = "ara"; LY = "ara"; KW = "ara"; QA = "ara";
    IN = "in"; BD = "bd"; LK = "in";
    JP = "jp"; KR = "kr"; TH = "th";
    CN = "us"; TW = "us"; HK = "us"; SG = "us"; MY = "us"; ID = "us";
    PH = "us"; VN = "us"; ZA = "us"; NG = "us"; KE = "us"; ET = "us";
  };

  # $1 is an ISO country code, possibly several comma-separated as
  # zone1970.tab writes them (Europe/London is "GB,GG,IM,JE"). The first is
  # the zone's principal country, which is the one that owns the keyboard.
  forCountry = codes:
    let first = lib.head (lib.splitString "," codes);
    in byCountry.${first} or null;

  # ── What one answer turns into ────────────────────────────────────────
  #
  # Four sinks, and they are not interchangeable:
  #
  #   console.keyMap + console.font   the TTY, and every rescue shell
  #   services.xserver.xkb.*          X11 and XWayland clients
  #   Hyprland input.kb_*             THE DESKTOP. Hyprland does not read
  #                                   the NixOS xkb option — it has its own
  #                                   input block, so setting only the
  #                                   NixOS one leaves the session on us.
  #
  # THE SECOND LAYOUT IS NOT A LUXURY. A row whose script is not Latin gets
  # `us` appended as a second group plus a toggle. Without it a Russian,
  # Greek, Hebrew, Arabic, Thai or Indic user has no way to type a URL, a
  # password or a shell command — the machine is not inconvenient, it is
  # unusable. Alt+Shift is the toggle because it is the one every such user
  # already has muscle memory for from every other OS.
  #
  # Japanese and Korean are Latin-capable layouts (JIS and 2-beolsik both
  # type ASCII directly; the script comes from an IME, not the layout), so
  # they are marked latin and get no second group — a toggle that toggled
  # nothing would be worse than none.
  derive = id:
    let
      l = byId.${id} or (throw "golem: no keyboard layout '${id}'");
      latin = l.script == "latin";
    in
    {
      layout = if latin then l.xkb else "${l.xkb},us";
      # XKB reads variants positionally, so a two-group layout needs its
      # second slot even when the first group has no variant.
      variant = if latin then l.variant else "${l.variant},";
      options = if latin then "" else "grp:alt_shift_toggle";

      # THE PHYSICAL BOARD. Not decoration: a JIS keyboard has henkan,
      # muhenkan and katakana keys that pc104 has no keycodes for, and
      # ABNT2 has the extra key beside the right shift.
      model = {
        jis = "jp106";
        abnt = "abnt2";
        iso = "pc105";
        ansi = "pc104";
      }.${l.form};

      # kbd has no keymap for some scripts; the TTY falls back to us.
      consoleKeyMap = if l.console == "" then "us" else l.console;

      # Picking a Cyrillic keymap and leaving the kernel's built-in Latin
      # font gives a TTY that types Russian and draws boxes — right keymap,
      # unreadable screen. Only the scripts that actually HAVE a console
      # keymap need this; the rest fell back to `us` above and the default
      # font is correct for them.
      consoleFont = {
        cyrillic = "LatArCyrHeb-16";
        hebrew = "LatArCyrHeb-16";
        greek = "iso07u-16";
      }.${l.script} or null;
    };

  # The table as the install surface consumes it: one pipe-separated row per
  # line, same column order as `raw`. Generated rather than duplicated, so
  # the surface cannot drift from what CI verifies.
  table = lib.concatMapStrings
    (l: "${l.id}|${l.name}|${l.aliases}|${l.xkb}|${l.variant}|${l.console}|${l.script}|${l.form}\n")
    layouts;
in
{
  inherit layouts byId derive table byCountry forCountry;
  ids = map (l: l.id) layouts;
  # `CC|layout`, for the surface to read the same map CI verifies.
  countryTable = lib.concatStrings
    (lib.mapAttrsToList (cc: id: "${cc}|${id}\n") byCountry);
}
