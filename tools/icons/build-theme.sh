#!/bin/sh
# Writes the Golem icon themes into $1 (default system/home/icons, what
# home.nix installs): each the scalable drawing plus the 24 and 16 px
# versions, and its index.theme (index.theme here, named and inherited per
# tone). Golem's own icons (folders, files, devices) only; everything else —
# apps above all — comes from Papirus / Papirus-Dark, which they inherit.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${1:-$HERE/../../system/home/icons}
# Two tones (Max, 2026-10-14): Golem (silver) for the light look, Golem-Dark
# (graphite) for the dark one; Golem's dark mode switches between them.
for tone in light dark; do
  if [ $tone = light ]; then name=Golem; inherits=Papirus,hicolor; else name=Golem-Dark; inherits=Papirus-Dark,hicolor; fi
  DEST=$ROOT/$name
  rm -rf "$DEST"; mkdir -p "$DEST"
  for size in scalable 24 16; do
    dir=$size; [ "$size" = scalable ] || dir=${size}x${size}
    GOLEM_ICON_TONE=$tone GOLEM_ICON_SIZE=$size GOLEM_ICON_OUT="$DEST/$dir" python3 "$HERE/make.py" >/dev/null
    GOLEM_ICON_TONE=$tone GOLEM_ICON_SIZE=$size GOLEM_ICON_OUT="$DEST/$dir" python3 "$HERE/files.py" >/dev/null
  done
  sed -e "s/^Name=Golem$/Name=$name/" -e "s/^Inherits=.*/Inherits=$inherits/" "$HERE/index.theme" > "$DEST/index.theme"
  echo "$name: $(find "$DEST" -name '*.svg' | wc -l) names"
done
