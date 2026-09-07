# Every language's default timezone must be a zone tzdata actually has.
#
#   nix build .#checks.x86_64-linux.timezone-defaults
#
# The same class of proof as keyboard-table, and needed for the same reason:
# `time.timeZone = "Europe/Kiev"` evaluates, builds, and then fails at
# activation — tzdata renamed it to Europe/Kyiv, and a name that was right
# for twenty years silently stops being right. Nothing in Nix's type system
# knows; only tzdata does.
#
# It also catches the boring half: a typo in a hand-written map of sixty
# entries, which is exactly the kind of thing that survives review because
# every line looks like every other line.
{ lib, pkgs, timezones }:

pkgs.runCommand "golem-timezone-defaults"
  {
    nativeBuildInputs = [ pkgs.findutils pkgs.gnused pkgs.gnugrep ];
    passAsFile = [ "pairs" ];
    # One zone per line — every zone named anywhere in timezones.nix, both
    # the per-language ordered lists and the fallback defaults.
    pairs = lib.concatMapStrings (z: z + "\n") timezones.zones;
    tz = pkgs.tzdata;
  }
  ''
    set -euo pipefail
    zi="$tz/share/zoneinfo"

    # The zone names tzdata really provides, as `Area/City` paths. Etc/* and
    # the legacy single-word aliases (EST, GMT+0, …) are excluded on purpose:
    # they are compatibility fossils, not places anyone lives.
    find "$zi" -type f | sed "s|$zi/||" | grep -E '^[A-Z][A-Za-z_]+/' \
      | grep -vE '^(Etc|SystemV)/' | sort -u > zones

    bad=0
    n=0
    while read -r zone; do
      [ -n "$zone" ] || continue
      n=$((n + 1))
      if ! grep -qxF "$zone" zones; then
        echo "timezone-defaults: '$zone' is named in timezones.nix but tzdata does not have it" >&2
        bad=1
      fi
    done < "$pairsPath"

    [ "$bad" = 0 ] || { echo "timezone-defaults: FAILED" >&2; exit 1; }
    echo "timezone-defaults: $n zones verified against tzdata $(basename "$tz")" >&2
    cp "$pairsPath" $out
  ''
