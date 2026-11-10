#!/usr/bin/env bash
# check.sh — Golem's own messages against their catalogues, and golem-say's
# own behaviour. Needs bash, GNU grep (-P) and jq; builds nothing, so it runs
# anywhere the repo is (a toolbox without nix: put a store jq on PATH).
#
#   bash system/i18n/check.sh
#
# 1. The messages: every `golem-say "…"` / `say "…"` literal in a file that
#    speaks through golem-say (system/, seam/). Each catalogue must hold
#    exactly those keys — a key no script says is stale, a message a
#    catalogue lacks shows in English — and each translation the same holes
#    ({0} {1} …) as its English.
# 2. golem-say itself, run on real inputs: the language found in the order
#    the shell finds it, holes filled, and its fallbacks.
#
# Exits non-zero on any failure.

set -u
here=$(cd "${BASH_SOURCE[0]%/*}" && pwd)
root=$(cd "$here/../.." && pwd)
command -v jq >/dev/null || { echo "check.sh: needs jq on PATH" >&2; exit 2; }

fails=0
bad() { echo "FAIL $*"; fails=$((fails + 1)); }

# ------------------------------------------------------------ 1. catalogues
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

mapfile -t files < <(grep -rlE --include='*.nix' --include='*.sh' 'golem-say|golemSay' \
  "$root/system" "$root/seam" | grep -vF "$here/" | sort)

: > "$scratch/sites"
for f in "${files[@]}"; do
  rel=${f#"$root"/}
  # A say() in a file that speaks must be golem-say's (other scripts log with one).
  while IFS= read -r l; do
    bad "$rel:${l%%:*}: a say() that is not golem-say's"
  done < <(grep -nP '(?<![\w-])say\(\)' "$f" | grep -v 'golem-say')
  # Each message: the quoted literal right after golem-say / say, one a line
  # (comment lines blanked first, their numbers kept).
  sed 's/^[[:space:]]*#.*$//' "$f" \
    | grep -noP '(?:golem-say|(?<![\w-])say)\s+\K(["'\''])(?:(?!\1).)*\1' \
    | while IFS= read -r hit; do
        line=${hit%%:*}
        lit=${hit#*:}
        msg=${lit:1:${#lit}-2}
        case $msg in '$'*) continue ;; esac   # say() { … golem-say "$@"; }
        printf '%s\t%s\n' "$rel:$line" "$msg"
      done >> "$scratch/sites"
done
cut -f2 "$scratch/sites" | sort -u > "$scratch/messages"
echo "messages: $(wc -l < "$scratch/messages") distinct, at $(wc -l < "$scratch/sites") call sites in ${#files[@]} files"

holes() { grep -oE '\{[0-9]+\}' <<< "$1" | sort -u | tr -d '\n'; }

for cat in "$here"/*.json; do
  tag=$(basename "$cat" .json)
  if ! jq -e 'type == "object" and all(.[]; type == "string")' "$cat" >/dev/null 2>&1; then
    bad "$tag.json: not a flat object of strings"
    continue
  fi
  jq -r 'keys_unsorted[]' "$cat" | sort > "$scratch/keys"
  if [ "$(sort -u "$scratch/keys" | wc -l)" != "$(wc -l < "$scratch/keys")" ]; then
    bad "$tag.json: a key written twice"
  fi
  while IFS= read -r k; do
    bad "$tag.json: no script says \"$k\""
  done < <(comm -23 "$scratch/keys" "$scratch/messages")
  while IFS= read -r k; do
    bad "$tag.json: missing \"$k\" ($(grep -F -- "	$k" "$scratch/sites" | head -1 | cut -f1))"
  done < <(comm -13 "$scratch/keys" "$scratch/messages")
  n=0
  while IFS= read -r -d '' k && IFS= read -r -d '' v; do
    n=$((n + 1))
    if [ "$(holes "$k")" != "$(holes "$v")" ]; then
      bad "$tag.json: \"$k\" has holes $(holes "$k"), its translation $(holes "$v")"
    fi
  done < <(jq --raw-output0 'to_entries[] | .key, .value' "$cat")
  echo "$tag.json: $n keys"
done

# -------------------------------------------------- 2. golem-say on real inputs
say_sh=$here/golem-say.sh
home=$scratch/home
mkdir -p "$home/.config/golem"
settings() {   # settings <json>: the owner's settings.json
  printf '%s\n' "$1" > "$home/.config/golem/settings.json"
}
# expect <name> <wanted> [VAR=value …] -- [golem-say arguments …]
# golem-say runs in a clean environment: only PATH, HOME and what is named.
runner=(bash "$say_sh")
expect() {
  local name=$1 want=$2 got
  shift 2
  local vars=()
  while [ "$1" != -- ]; do vars+=("$1"); shift; done
  shift
  got=$(cd / && env -i PATH="$PATH" HOME="$home" "${vars[@]}" "${runner[@]}" "$@")
  if [ "$got" == "$want" ]; then
    echo "ok   $name"
  else
    bad "$name"
    echo "       wanted: $want"
    echo "       got:    $got"
  fi
}

cases() {
  rm -f "$home/.config/golem/settings.json"
  expect "no settings, LANG=pt_PT.UTF-8: Portugal's wording" \
    "O seu disco está cheio. Esvazie a Reciclagem ou remova as apps que não usa e tente de novo." \
    LANG=pt_PT.UTF-8 -- "Your disk is full. Empty the Trash or remove apps you don't use, then try again."
  expect "LANG=pt_BR.UTF-8: no pt_BR catalogue, so pt (Brazil's)" \
    "Seu disco está cheio. Esvazie a Lixeira ou remova apps que você não usa e tente de novo." \
    LANG=pt_BR.UTF-8 -- "Your disk is full. Empty the Trash or remove apps you don't use, then try again."
  expect "LANG=de_AT: German" "Drucker bereit" LANG=de_AT -- "Printer ready"
  expect "LANG=it_IT.UTF-8@euro: Italian" "Stampante pronta" LANG=it_IT.UTF-8@euro -- "Printer ready"
  expect "LANG=en_US.UTF-8: English" "Printer ready" LANG=en_US.UTF-8 -- "Printer ready"
  expect "LANG=C: English" "Printer ready" LANG=C -- "Printer ready"
  expect "no locale at all: English" "Printer ready" -- "Printer ready"
  expect "a language with no catalogue (ja_JP): English" "Printer ready" LANG=ja_JP.UTF-8 -- "Printer ready"
  expect "a key no catalogue has: the English, holes filled" "Nothing like 7 here" \
    LANG=es_ES.UTF-8 -- "Nothing like {0} here" 7
  expect "holes filled, in the translation's order (fr)" \
    "3 fichiers que vous avez modifiés dans ~/Golem ont été copiés dans /home/ana/Golem-local-edits/2026-11-10 pour que Golem puisse se mettre à jour." \
    LANG=fr_FR.UTF-8 -- "{0} files you changed in ~/Golem were copied to {1} so Golem could update." 3 /home/ana/Golem-local-edits/2026-11-10
  expect "a value starting with - is never taken for an option" \
    'Imprimante prête' LANG=fr_FR.UTF-8 -- "Printer ready" -n
  expect "a value goes in as it is (-n, &, \\1, {1}, \$HOME), in one pass" \
    '-n & \1 {1} $HOME : vous pouvez imprimer depuis n'"'"'importe quelle app.' \
    LANG=fr_FR.UTF-8 -- "{0}: you can print from any app." '-n & \1 {1} $HOME' extra
  expect "a hole with no value stays as written" \
    "Nur noch {0} GB frei. Einstellungen → Aufräumen entfernt alte Systemversionen; den Papierkorb und große Ordner schaust du dir selbst an." \
    LANG=de_DE.UTF-8 -- "Only {0} GB left. Controls → Clean up frees old system versions; the Trash and big folders are yours to check."

  settings '{"language": "es_BO.UTF-8", "dark": true}'
  expect "settings es_BO.UTF-8 wins over LANG=en_US: Spanish (es_BO → es)" \
    "Solo quedan 4 GB. Panel de control → Limpiar quita las versiones viejas del sistema; la Papelera y las carpetas grandes las revisas tú." \
    LANG=en_US.UTF-8 -- "Only {0} GB left. Controls → Clean up frees old system versions; the Trash and big folders are yours to check." 4
  expect "settings wins over LC_ALL too" "Impresora lista" LC_ALL=de_DE.UTF-8 LANG=de_DE.UTF-8 -- "Printer ready"
  settings '{"language": "pt_PT.UTF-8"}'
  expect "settings pt_PT.UTF-8: Portugal's" "O Golem tem uma atualização pronta" LANG=es_ES.UTF-8 -- "Golem has an update ready"
  settings '{"language": "en_US.UTF-8"}'
  expect "settings English over LANG=es: English" "Printer ready" LANG=es_ES.UTF-8 -- "Printer ready"
  settings '{"dark": true}'
  expect "settings without a language: LANG" "Stampante pronta" LANG=it_IT.UTF-8 -- "Printer ready"
  settings '{"language": ""}'
  expect "an empty language: LANG" "Stampante pronta" LANG=it_IT.UTF-8 -- "Printer ready"
  settings 'not json {'
  expect "a settings file that does not parse: LANG" "Drucker bereit" LANG=de_DE.UTF-8 -- "Printer ready"
  settings '{"language": "../../../etc/passwd"}'
  expect "a language that is not a tag names no file: English" "Printer ready" LANG=de_DE.UTF-8 -- "Printer ready"
  rm -f "$home/.config/golem/settings.json"

  expect "LC_ALL beats LANG" "Imprimante prête" LC_ALL=fr_FR.UTF-8 LANG=de_DE.UTF-8 -- "Printer ready"
  expect "LC_MESSAGES beats LANG" "Imprimante prête" LC_MESSAGES=fr_FR.UTF-8 LANG=de_DE.UTF-8 -- "Printer ready"
  expect "an empty LC_ALL falls through" "Drucker bereit" LC_ALL= LANG=de_DE.UTF-8 -- "Printer ready"

  # Root naming the owner's settings: its own HOME has none.
  mkdir -p "$scratch/owner/.config/golem"
  printf '{"language": "it_IT.UTF-8"}\n' > "$scratch/owner/.config/golem/settings.json"
  expect "GOLEM_SETTINGS (a root service naming the owner's)" "Stampante pronta" \
    HOME=/root LANG=en_US.UTF-8 "GOLEM_SETTINGS=$scratch/owner/.config/golem/settings.json" -- "Printer ready"
  expect "XDG_CONFIG_HOME is where the settings are, when set" "Stampante pronta" \
    "XDG_CONFIG_HOME=$scratch/owner/.config" LANG=en_US.UTF-8 -- "Printer ready"

  local got
  got=$(printf 'a\nb\n' | while IFS= read -r l; do
    env -i PATH="$PATH" HOME="$home" LANG=es_ES.UTF-8 "${runner[@]}" "Printer ready" >/dev/null
    printf '%s' "$l"
  done)
  if [ "$got" = ab ]; then echo "ok   a caller's while-read loop keeps its input"; else bad "stdin: got '$got'"; fi
  if env -i PATH="$PATH" "${runner[@]}" >/dev/null 2>&1; then bad "no arguments should be an error"; else echo "ok   no arguments: usage, exit $?"; fi
}

echo "-- golem-say.sh, run as is:"
cases

# The command as golem-say.nix builds it: writeShellApplication's strict
# options and the catalogue directory set in front (here a copy, elsewhere).
mkdir -p "$scratch/store/bin" "$scratch/store/catalogues"
cp "$here"/*.json "$scratch/store/catalogues/"
{
  printf '#!%s\n' "$(command -v bash)"
  printf 'set -o errexit\nset -o nounset\nset -o pipefail\n'
  printf 'GOLEM_SAY_DIR=${GOLEM_SAY_DIR:-%s}\n' "$scratch/store/catalogues"
  cat "$say_sh"
} > "$scratch/store/bin/golem-say"
chmod +x "$scratch/store/bin/golem-say"
bash -n "$scratch/store/bin/golem-say" || bad "the built command does not parse"
runner=("$scratch/store/bin/golem-say")
echo "-- golem-say as built (errexit, nounset, pipefail; catalogues elsewhere):"
cases

if [ "$fails" -gt 0 ]; then
  echo "$fails failure(s)"
  exit 1
fi
echo "all good"
