#!/bin/sh
# Writes the Golem icon theme into $1 (default system/home/icons/Golem, what
# home.nix installs): the scalable
# drawing plus the 24 and 16 px versions, and its index.theme. Golem's own
# icons (folders, files, devices) only; everything else — apps above all —
# comes from Papirus-Dark, which it inherits.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
DEST=${1:-$HERE/../../system/home/icons/Golem}
rm -rf "$DEST"; mkdir -p "$DEST"
for size in scalable 24 16; do
  dir=$size; [ "$size" = scalable ] || dir=${size}x${size}
  GOLEM_ICON_SIZE=$size GOLEM_ICON_OUT="$DEST/$dir" python3 "$HERE/make.py" >/dev/null
  GOLEM_ICON_SIZE=$size GOLEM_ICON_OUT="$DEST/$dir" python3 "$HERE/files.py" >/dev/null
done
cat > "$DEST/index.theme" <<'THEME'
[Icon Theme]
Name=Golem
Comment=Golem's folders, files and devices; everything else from Papirus
Inherits=Papirus-Dark,Papirus,hicolor
Directories=16x16/places,16x16/mimetypes,16x16/devices,24x24/places,24x24/mimetypes,24x24/devices,scalable/places,scalable/mimetypes,scalable/devices

[16x16/places]
Context=Places
Size=16
MinSize=16
MaxSize=19
Type=Scalable

[16x16/mimetypes]
Context=MimeTypes
Size=16
MinSize=16
MaxSize=19
Type=Scalable

[16x16/devices]
Context=Devices
Size=16
MinSize=16
MaxSize=19
Type=Scalable

[24x24/places]
Context=Places
Size=24
MinSize=20
MaxSize=31
Type=Scalable

[24x24/mimetypes]
Context=MimeTypes
Size=24
MinSize=20
MaxSize=31
Type=Scalable

[24x24/devices]
Context=Devices
Size=24
MinSize=20
MaxSize=31
Type=Scalable

[scalable/places]
Context=Places
Size=64
MinSize=32
MaxSize=512
Type=Scalable

[scalable/mimetypes]
Context=MimeTypes
Size=64
MinSize=32
MaxSize=512
Type=Scalable

[scalable/devices]
Context=Devices
Size=64
MinSize=32
MaxSize=512
Type=Scalable
THEME
echo "theme in $DEST: $(find "$DEST" -name '*.svg' | wc -l) names"
