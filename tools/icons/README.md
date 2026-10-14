# Golem's icons

Golem's own folders, files and devices (Max, 2026-10-14): the dock figures'
cast grey, a gloss and a bevel, and a round symbol engraved in the middle.
Apps are not here — the theme inherits Papirus-Dark for everything else.

- `make.py` — the folders (`places/`), and the shared machinery: the masks,
  `centred()` (every symbol centred on its measured box, sized to a keyline by
  its shape, its lines at one weight) and the size variants.
- `files.py` — the files (`mimetypes/`, a sheet with its corner folded) and the
  devices (`devices/`, the same card with no fold and a light). Names that mean
  the same thing are links to one icon.
- `center.py` — measures every symbol as resvg draws it → `centers.json`.
- `build-theme.sh` — writes the theme (`system/home/icons/Golem`): the
  scalable drawing plus 24 and 16 px versions (darker, heavier, no hairlines).

After adding or changing a symbol: `python3 center.py && ./build-theme.sh`.
