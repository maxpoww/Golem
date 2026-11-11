# golem-say — one of Golem's own messages, in the owner's language.
#
#   golem-say "Only {0} GB left. …" "$avail"
#
# prints the line as the owner reads it. The English text IS the key, as in
# the shell's catalogues (the waverunner daemon's assets/i18n/): each
# <tag>.json beside this file is a flat {"English": "translation"}. Holes are
# {0} {1} …, filled with the values in order: a hole with no value stays as
# written, a value with no hole is unused. No catalogue, no key, an empty
# translation, a file that does not parse: the English. It never fails its
# caller, and never says an empty line for a message.
#
# The language, found as the shell finds it: the owner's choice in
# settings.json ("language": "es_BO.UTF-8"), then LC_ALL → LC_MESSAGES →
# LANG. A tag is tried whole (pt_PT), then as its language (pt); the first
# catalogue there is the one used. C, POSIX and English need none.
#
# GOLEM_SETTINGS: the settings file. Defaults to the caller's own
#   (~/.config/golem/settings.json); a root service speaking to the owner
#   names the owner's.
# GOLEM_SAY_DIR: the catalogues. The package sets it; run from the repo
#   (`bash system/i18n/golem-say.sh 'Printer ready'`), the ones beside this.
#
# The body of the `golem-say` command (golem-say.nix). Every message a script
# says this way is checked against the catalogues by check.sh.

if [ "$#" -eq 0 ]; then
  echo "usage: golem-say ENGLISH-TEXT [VALUE…]" >&2
  exit 2
fi
template=$1
shift
# Nothing here reads input: a caller's `while read` loop keeps all of its own.
exec </dev/null

case ${BASH_SOURCE[0]} in
  */*) here=${BASH_SOURCE[0]%/*} ;;
  *) here=. ;;
esac
dir=${GOLEM_SAY_DIR:-$here}
settings=${GOLEM_SETTINGS:-${XDG_CONFIG_HOME:-${HOME:-}/.config}/golem/settings.json}

# The values reach jq as named strings v0 v1 …, never as its own arguments
# (a value may start with "-").
values=()
i=0
for v in "$@"; do
  values+=(--arg "v$i" "$v")
  i=$((i + 1))
done
# One pass over the text: a value that itself holds "{1}" stays as it is.
fill='def fill: gsub("\\{(?<n>[0-9]+)\\}"; $ARGS.named["v" + .n] // "{\(.n)}");'

chosen=
# A regular file only: a root caller reads a path its owner can write, and a
# FIFO there would hang it (waverunner-apply holds the rebuild lock).
if [ -f "$settings" ] && [ -r "$settings" ]; then
  chosen=$(jq -r 'if type == "object" and (.language | type) == "string" then .language else empty end' \
    "$settings" 2>/dev/null) || chosen=
fi
locale=
for v in "$chosen" "${LC_ALL-}" "${LC_MESSAGES-}" "${LANG-}"; do
  if [ -n "$v" ]; then
    locale=$v
    break
  fi
done
tag=${locale%%[.@]*}   # es_BO.UTF-8 → es_BO
lang=${tag%%_*}        # es_BO → es

tags=()
case $lang in
  '' | C | POSIX | en) ;;
  *)
    # Only a tag's shape names a file: a settings file written by its owner
    # never sends a root caller reading elsewhere.
    if [[ $tag =~ ^[A-Za-z]{2,3}(_[A-Za-z0-9]{2,8})?$ ]]; then
      tags+=("$tag")
      if [ "$lang" != "$tag" ]; then tags+=("$lang"); fi
    fi
    ;;
esac

for t in "${tags[@]}"; do
  f=$dir/$t.json
  [ -f "$f" ] && [ -r "$f" ] || continue
  if said=$(jq -r --arg k "$template" "${values[@]}" \
    "$fill"' if type == "object" and (.[$k] | type) == "string" and .[$k] != "" then .[$k] else $k end | fill' \
    "$f" 2>/dev/null); then
    printf '%s\n' "$said"
    exit 0
  fi
done

jq -nr --arg k "$template" "${values[@]}" "$fill"' $k | fill' 2>/dev/null \
  || printf '%s\n' "$template"
