# The keyboard table's proof — GolemInstall.md §8's leg for the one part of
# the install that CANNOT be checked by evaluating a NixOS config.
#
#   nix build .#checks.x86_64-linux.keyboard-table
#
# WHY THIS EXISTS AS A SEPARATE CHECK. facts-matrix proves that a config
# built from a set of facts says what we meant. It cannot prove that the
# STRINGS in that config are real: `console.keyMap = "gb"` and
# `xkb.variant = "deva"` both evaluate perfectly, build perfectly, and then
# fail silently at first boot — leaving a stranger with a keyboard that does
# not match their keys, which is the exact outcome the keyboard step exists
# to prevent. Nothing in Nix's type system catches that; only the packages
# that consume the strings know.
#
# So this check reads kbd's keymap tree and xkeyboard-config's evdev.lst and
# asserts every id, variant, model, keymap, font and option in the table is
# a name those packages actually know. It is what turns "these values look
# right" into "these values are right", and it runs in seconds.
#
# It has already earned its place: it is how `in`+`deva` was found (deva is
# the DEFAULT group of the Indian layout, present in symbols/in but absent
# from the advertised variant list, so the correct spelling is a bare `in`),
# and it is the only reason the gb/uk and latam/la-latin1 splits are known
# to be right rather than believed to be.
{ lib, pkgs, keyboards }:

let
  derived = map (l: { inherit (l) id script; d = keyboards.derive l.id; }) keyboards.layouts;

  # One line per row, so the checker is a plain text pass over data rather
  # than a shell loop that re-derives anything.
  #
  # EVERY OPTIONAL FIELD CARRIES "-" RATHER THAN BEING EMPTY, and the
  # separator is a tab only because the reader below never sees two in a
  # row. Bash treats tab as IFS *whitespace*, so `read` collapses runs of
  # it into one delimiter: an empty variant silently shifted every later
  # column left and the check reported nonsense like "xkb model 'us' does
  # not exist". Loud nonsense rather than a silent pass, but nonsense.
  dash = s: if s == "" || s == null then "-" else s;

  rows = lib.concatMapStrings
    (r: lib.concatStringsSep "\t" [
      r.id
      (lib.elemAt (lib.splitString "," r.d.layout) 0)
      (dash (lib.elemAt (lib.splitString "," r.d.variant) 0))
      r.d.model
      r.d.consoleKeyMap
      (dash r.d.consoleFont)
      (dash r.d.options)
      (toString (lib.length (lib.splitString "," r.d.layout)))
      (toString (lib.length (lib.splitString "," r.d.variant)))
      r.script
    ] + "\n")
    derived;
in
pkgs.runCommand "golem-keyboard-table"
  {
    nativeBuildInputs = [ pkgs.gnused pkgs.gnugrep pkgs.findutils pkgs.gawk pkgs.gzip ];
    passAsFile = [ "rows" "countries" ];
    countries = keyboards.countryTable;
    inherit rows;
    kbd = pkgs.kbd;
    xkb = pkgs.xkeyboard_config;
  }
  ''
    set -euo pipefail
    lst="$xkb/share/X11/xkb/rules/evdev.lst"

    # The vocabularies, as the packages define them.
    find "$kbd/share/keymaps" -name '*.map.gz' -printf '%f\n' | sed 's/\.map\.gz$//' | sort -u > keymaps
    # NOTE: one -printf binds only to the LAST -o branch, so match broadly
    # and strip after. Doing it the other way silently reports every font
    # missing, which is how this checker was wrong before it was right.
    find "$kbd/share/consolefonts" -name '*.gz' -printf '%f\n' \
      | sed -e 's/\.gz$//' -e 's/\.psfu\?$//' | sort -u > fonts
    awk '/^! layout/,/^! variant/'  "$lst" | awk 'NF>1 && $1!="!"{print $1}' | sort -u > layouts
    awk '/^! model/,/^! layout/'    "$lst" | awk 'NF>1 && $1!="!"{print $1}' | sort -u > models
    awk '/^! option/,0'             "$lst" | awk 'NF>1 && $1!="!"{print $1}' | sort -u > options
    awk '/^! variant/,/^! option/'  "$lst" \
      | awk 'NF>2 && $1!="!"{gsub(/:$/,"",$2); print $2"/"$1}' | sort -u > variants

    # Our own row ids, for the country map to be checked against.
    cut -f1 "$rowsPath" | sort -u > ids

    bad=0
    fail() { echo "keyboard-table: $*" >&2; bad=1; }
    known() { grep -qxF "$2" "$1"; }

    n=0
    while IFS=$'\t' read -r id xkbl var model keymap font opts ngroup nvar script; do
      n=$((n+1))
      # `[ cond ] && fail ...` is NOT used below, deliberately. Under the
      # `set -e` at the top of this script that idiom aborts the whole
      # checker the moment cond is false — which is the common case — and
      # the run dies mid-loop with no message and a bare exit 1. It cost a
      # confusing debugging round; every test here is a plain `if`.
      known layouts "$xkbl" || fail "$id: xkb layout '$xkbl' does not exist"
      if [ "$var" != - ]; then
        known variants "$xkbl/$var" || fail "$id: '$var' is not a variant of '$xkbl'"
      fi
      known models  "$model"  || fail "$id: xkb model '$model' does not exist"
      known keymaps "$keymap" || fail "$id: console keymap '$keymap' does not exist"
      if [ "$font" != - ]; then
        known fonts "$font" || fail "$id: console font '$font' does not exist"
      fi
      if [ "$opts" != - ]; then
        for o in ''${opts//,/ }; do
          known options "$o" || fail "$id: xkb option '$o' does not exist"
        done
      fi
      # XKB reads variants positionally: a two-group layout with one variant
      # slot applies the wrong variant to the wrong group, silently.
      if [ "$nvar" -lt "$ngroup" ]; then
        fail "$id: $ngroup layout groups but only $nvar variant slots"
      fi

      # THE RESCUE-SHELL RULE. A non-Latin keymap must still type Latin on
      # its BASE layer, with its own script on AltGr — that is how ru, gr,
      # il and the rest are built, and it is what makes a TTY usable for
      # commands, paths and a passphrase. `fa` is not built that way: 11
      # base-layer keys against 104 AltGr ones, so the unshifted alphabet is
      # empty and the console types nothing. That row now falls back to us.
      #
      # Only checked for non-Latin scripts. A Latin keymap gets its letters
      # from an include rather than an inline keycode 30, so the same test
      # would report `us` itself as broken — it is a question about keymaps
      # that must carry TWO alphabets, and nothing else.
      if [ "$script" != latin ] && [ "$keymap" != us ]; then
        km=$(find "$kbd/share/keymaps" -name "$keymap.map.gz" | head -1)
        # `|| true` is load-bearing under `set -o pipefail`: NO MATCH IS THE
        # ANSWER WE ARE LOOKING FOR, but an empty grep returns 1, the
        # pipeline returns 1, and the assignment kills the script before it
        # can report anything. That is how this check first "failed" with a
        # bare exit 1 and no message — the very shape of silent failure it
        # was written to catch.
        base=$(zcat "$km" | sed 's/#.*//' \
          | grep -E '^[[:space:]]*keycode[[:space:]]+30[[:space:]]*=' \
          | head -1 | sed 's/.*=[[:space:]]*//' | awk '{print $1}' || true)
        if ! printf '%s' "$base" | grep -qE '^\+?[a-zA-Z]$'; then
          fail "$id: console keymap '$keymap' has no latin base layer — a rescue shell could not type a command or a passphrase"
        fi
      fi
    done < "$rowsPath"

    # Every country's layout must be a real row. A typo here does not fail
    # loudly — it falls back to the language's layout and looks like the
    # feature simply not firing, which is the hardest kind of wrong to
    # notice in a bug report.
    while IFS='|' read -r cc id; do
      [ -n "$cc" ] || continue
      grep -qxF "$id" ids || fail "country $cc maps to layout '$id', which is not a row"
    done < "$countriesPath"

    [ "$bad" = 0 ] || { echo "keyboard-table: FAILED" >&2; exit 1; }
    echo "keyboard-table: $n layouts verified against kbd + xkeyboard-config" >&2
    cp "$rowsPath" $out
  ''
