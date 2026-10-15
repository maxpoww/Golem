#!/usr/bin/env python3
"""Golem's folder icons (Max, 2026-10-14): the simple folder in the dock
figures' cast grey, and the owner's own folders with their symbol ENGRAVED on
the front. Writes places/<freedesktop name>.svg; run again after any change.

The symbols are ROUND (Max: "los símbolos son muy cuadrados, no tienen armonía
con la carpeta"; then a little lighter and bigger on the folder): each is drawn as a MASK whose shapes are filled AND stroked
with round joins and caps, so every corner and end is rounded; holes are drawn
the same way in black."""
import os, re

HERE = os.path.dirname(os.path.abspath(__file__))

# THE SIZES (Max, 2026-10-14): the drawing above is for 32 px and up; at 24 and
# 16 a pixel is a big part of the icon, so those are drawn apart — the symbol
# darker and its lines heavier, no hairline gloss or engraved edge (they smear
# into grey), and at 16 the folder's front lower so its tab still shows.
# GOLEM_ICON_SIZE = scalable | 24 | 16; GOLEM_ICON_OUT = where to write
# (the theme's size directory; by default this folder, for the mockup).
SIZE = os.environ.get("GOLEM_ICON_SIZE", "scalable")
OUT = os.environ.get("GOLEM_ICON_OUT", HERE)
VARIANT = {
    "scalable": dict(sym="#a1a6af", edge=".6", line=2.55, detail=1.45, gloss=True, front=8),
    "24": dict(sym="#8e939c", edge="0", line=3.0, detail=1.8, gloss=False, front=8.5),
    "16": dict(sym="#7b8089", edge="0", line=3.4, detail=2.2, gloss=False, front=10.5),
}[SIZE]

# THE TONE (Max, 2026-10-14: "make them darker when dark mode is on"): the
# same cast metal in GRAPHITE for a dark desktop — a darker front and back, the
# symbol engraved darker still, the gloss and the light edges quieter.
# GOLEM_ICON_TONE = light | dark.
TONE = os.environ.get("GOLEM_ICON_TONE", "light")
DARK = {
    "#eef0f3": "#737882", "#c2c6cd": "#4f535c",   # front
    "#b3b8c0": "#50545d", "#8f949e": "#3b3e46",   # folder's back
    "#d9dce1": "#888d97", "#a7acb5": "#5d616a",   # a sheet's fold
    'stop-opacity=".35"': 'stop-opacity=".16"',    # gloss
    'flood-color="#fff" flood-opacity=".5"': 'flood-color="#fff" flood-opacity=".22"',
    'flood-color="#000" flood-opacity=".45"': 'flood-color="#000" flood-opacity=".6"',
    'fill="#fff" opacity=".55"': 'fill="#fff" opacity=".22"',  # the top's hairline
}
DARK_SYM = {"scalable": ("#3c4048", ".18"), "24": ("#353840", "0"), "16": ("#2f3239", "0")}

def variant(svg):
    """This size's and tone's version of a finished icon."""
    v = dict(VARIANT)
    if TONE == "dark":
        for a, b in DARK.items():
            svg = svg.replace(a, b)
        v["sym"], v["edge"] = DARK_SYM[SIZE]
    svg = svg.replace('fill="#a1a6af" mask', f'fill="{v["sym"]}" mask').replace('opacity=".6" mask', f'opacity="{v["edge"]}" mask')
    if not v["gloss"]:
        svg = re.sub(r'\n\s*<rect fill="#fff" opacity=".55"[^>]*/>', "", svg)
    if v["front"] != 8:  # the folder's front, lower
        f = v["front"]
        svg = svg.replace('x="0" y="8" width="52" height="37" rx="4.5"', f'x="0" y="{f}" width="52" height="{45 - f}" rx="4.5"')
    return svg

FOLDER = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <defs>
    <linearGradient id="front" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#eef0f3"/><stop offset="1" stop-color="#c2c6cd"/></linearGradient>
    <linearGradient id="back" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#b3b8c0"/><stop offset="1" stop-color="#8f949e"/></linearGradient>
    <linearGradient id="gloss" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".35"/><stop offset=".55" stop-color="#fff" stop-opacity="0"/></linearGradient>
    <filter id="bevel" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="-.6" stdDeviation="0" flood-color="#fff" flood-opacity=".5"/>
      <feDropShadow dx="0" dy="1.6" stdDeviation="1" flood-color="#000" flood-opacity=".45"/>
    </filter>{mask}
  </defs>
  <g transform="translate(6 9.5)">
    <path fill="url(#back)" filter="url(#bevel)" d="M0,4.5A4.5,4.5 0 0 1 4.5,0H17.5C20,0 21.2,.9 22.6,2.6L24,4.3C24.6,5 25.2,5.3 26.2,5.3H47.5A4.5,4.5 0 0 1 52,9.8V40H0Z"/>
    <rect fill="url(#front)" filter="url(#bevel)" x="0" y="8" width="52" height="37" rx="4.5"/>
    <rect fill="url(#gloss)" x="0" y="8" width="52" height="37" rx="4.5"/>
    <rect fill="#fff" opacity=".55" x="4.5" y="8" width="43" height=".7" rx=".35"/>
  </g>{mark}
</svg>
"""

# The symbol's mask, on a 24 grid placed in the middle of the front.
MASK = """
    <mask id="sym" maskUnits="userSpaceOnUse" x="-3" y="-3" width="30" height="30">{shapes}
    </mask>"""
# Engraved: a thin light edge under it, then the darker grey.
MARK = """
  <g transform="translate(17.12 21.12) scale(1.24)">
    <rect x="-3" y="-3" width="30" height="30" fill="#fff" opacity=".6" mask="url(#sym)" transform="translate(0 .75)"/>
    <rect x="-3" y="-3" width="30" height="30" fill="#a1a6af" mask="url(#sym)"/>
  </g>"""

W, B = "#fff", "#000"
R = 1.2  # the stroke every solid shape wears: its corners round by R/2

def shape(paint, el, width=R, fill=True):
    f = paint if fill else "none"
    return f'\n      <{el} fill="{f}" stroke="{paint}" stroke-width="{width}" stroke-linejoin="round" stroke-linecap="round"/>'

def line(paint, d, width):
    return shape(paint, f'path d="{d}"', width, fill=False).replace("<path ", '<path data-line="1" ', 1)

SYMBOLS = {
    "user-home": [
        shape(W, 'path d="M12 4.6 2.8 11.8h2.4v7a1.4 1.4 0 0 0 1.4 1.4h10.8a1.4 1.4 0 0 0 1.4-1.4v-7h2.4z"'),
        shape(B, 'path d="M10.3 15.4a1.7 1.7 0 0 1 3.4 0V22h-3.4z"', 1.2),
    ],
    "user-desktop": [
        shape(W, 'rect x="4" y="4.8" width="16" height="11" rx="2.2"'),
        shape(B, 'rect x="6.4" y="7.2" width="11.2" height="6.2" rx="1"', 1),
        shape(W, 'path d="M10.4 15.8h3.2l.5 3.2h-4.2z"', 1.1),
        line(W, "M8.2 19.8h7.6", 1.7),
    ],
    "folder-download": [
        line(W, "M12 5.8v10.4", 2.3),
        line(W, "M7.4 11.8 12 16.4l4.6-4.6", 2.3),
        line(W, "M5.6 19.6h12.8", 2.3),
    ],
    "folder-documents": [
        shape(W, 'path d="M7.2 3.2h6.4l5.2 5.2v11a1.6 1.6 0 0 1-1.6 1.6H7.2a1.6 1.6 0 0 1-1.6-1.6V4.8a1.6 1.6 0 0 1 1.6-1.6z"'),
        line(B, "M13.6 3.6v4.8h4.8", 1.1),
        line(B, "M8.8 12.6h6.4", 1.3),
        line(B, "M8.8 15.6h6.4", 1.3),
        line(B, "M8.8 18.4h3.6", 1.3),
    ],
    "folder-pictures": [
        shape(W, 'rect x="3.8" y="5" width="16.4" height="14" rx="2.6"'),
        shape(B, 'rect x="6.2" y="7.4" width="11.6" height="9.2" rx="1.2"', 1),
        shape(W, 'path d="M6.6 16.2 10 12.2l2.8 3 1.6-1.6 3 2.6z"', 1.1),
        shape(W, 'circle cx="15" cy="10" r="1.2"', 1),
    ],
    "folder-music": [
        shape(W, 'circle cx="7.6" cy="17.4" r="2.4"'),
        shape(W, 'circle cx="16.8" cy="15.4" r="2.4"'),
        line(W, "M9.9 17.2V6.6", 1.6),
        line(W, "M19.1 15.2V4.6", 1.6),
        line(W, "M9.9 6.6l9.2-2", 2.3),
    ],
    "folder-videos": [
        shape(W, 'rect x="3.6" y="5.8" width="16.8" height="12.4" rx="3.2"'),
        shape(B, 'path d="M10.4 9.4v5.2l4.4-2.6z"', 1.3),
    ],
    "folder-publicshare": [
        shape(W, 'circle cx="9" cy="8.2" r="2.8"'),
        shape(W, 'path d="M3.8 19a5.2 5.2 0 0 1 10.4 0z"'),
        shape(W, 'circle cx="16.4" cy="9" r="2.2"'),
        shape(W, 'path d="M15 14.2a4.2 4.2 0 0 1 5.4 4.8h-4.2c0-1.8-.4-3.4-1.2-4.8z"'),
    ],
    "folder-templates": [
        shape(W, 'rect x="4.4" y="4.4" width="15.2" height="4.4" rx="1.6"'),
        shape(W, 'rect x="4.4" y="11.4" width="6.4" height="8.2" rx="1.6"'),
        shape(W, 'rect x="13.2" y="11.4" width="6.4" height="8.2" rx="1.6"'),
    ],
    "folder-sync": [
        line(W, "M18.38 10.29A6.6 6.6 0 0 0 5.62 10.29", 1.9),
        line(W, "M7.76 8.79 5.62 10.29 4.52 7.92", 1.9),
        line(W, "M5.62 13.71A6.6 6.6 0 0 0 18.38 13.71", 1.9),
        line(W, "M16.24 15.21 18.38 13.71 19.48 16.08", 1.9),
    ],
    "folder-recordings": [
        shape(W, 'rect x="9" y="3" width="6" height="11" rx="3"'),
        line(W, "M6 11.2a6 6 0 0 0 12 0", 1.7),
        line(W, "M12 17.2v3", 1.7),
        line(W, "M8.8 20.6h6.4", 1.7),
    ],
    "folder-shared": [
        shape(W, 'circle cx="17" cy="6" r="2.4"'),
        shape(W, 'circle cx="7" cy="12" r="2.4"'),
        shape(W, 'circle cx="17" cy="18" r="2.4"'),
        line(W, "M9 10.9 15 7.2", 1.6),
        line(W, "M9 13.1 15 16.8", 1.6),
    ],
    "folder-remote": [
        shape(W, 'rect x="7" y="2.8" width="10" height="18.4" rx="2.2"'),
        line(B, "M9.4 7h5.2", 1.2),
        line(B, "M9.4 10.2h5.2", 1.2),
        shape(B, 'circle cx="12" cy="16.8" r=".9"', .6),
    ],
    "folder-computer": [
        shape(W, 'rect x="5" y="4.6" width="14" height="10.4" rx="1.8"'),
        shape(B, 'rect x="6.9" y="6.5" width="10.2" height="6.6" rx=".6"', .6),
        line(W, "M3.2 18.2h17.6", 2.4),
    ],
    "folder-calendar": [
        shape(W, 'rect x="3.8" y="5.2" width="16.4" height="15" rx="2.6"'),
        shape(B, 'rect x="5.8" y="10" width="12.4" height="8.4" rx="1"', .4),
        line(W, "M8.2 3.4v3.4", 1.8),
        line(W, "M15.8 3.4v3.4", 1.8),
    ] + [shape(W, f'circle cx="{x}" cy="{y}" r=".9"', .3) for x in (8.4, 12, 15.6) for y in (12.6, 15.8)],
    "folder-cloud": [
        shape(W, 'path d="M7.6 18.6a4.4 4.4 0 0 1-.7-8.75 5.8 5.8 0 0 1 11.1 1.65 3.6 3.6 0 0 1-.4 7.1z"'),
    ],
    "folder-games": [
        shape(W, 'path d="M7.2 7.4h9.6a4.8 4.8 0 0 1 4.6 6l-.9 3.4a2.5 2.5 0 0 1-4.2 1.1l-2-2.1H9.7l-2 2.1a2.5 2.5 0 0 1-4.2-1.1l-.9-3.4a4.8 4.8 0 0 1 4.6-6z"'),
        line(B, "M7.6 10.4v3.6", 1.2),
        line(B, "M5.8 12.2h3.6", 1.2),
        shape(B, 'circle cx="16" cy="11" r=".8"', .4),
        shape(B, 'circle cx="17.8" cy="13" r=".8"', .4),
    ],
    "folder-phone": [
        shape(W, 'rect x="5.6" y="3" width="12.8" height="18" rx="3.2"'),
        shape(B, 'rect x="7.6" y="5.6" width="8.8" height="10.6" rx="1.2"', 1),
        shape(B, 'circle cx="12" cy="18.4" r=".8"', 1),
    ],
}

# ONE SYSTEM for every symbol (Max, 2026-10-14: some sat high, some were thin
# beside others, the files' smaller than the devices'). center.py measures each
# symbol as resvg draws it and writes its real box to centers.json; here every
# symbol is
#  · SIZED by its shape — its longer side to KEY[shape]: a squarish symbol a
#    little smaller, a round one and a very thin one a little bigger, so all
#    weigh the same to the eye (the icon grids' keylines);
#  · CENTRED on its box, both ways;
#  · drawn with ONE WEIGHT: whatever its scale, a line ends LINE wide (a detail
#    line, drawn under 1.5, DETAIL wide).
CENTERS = os.path.join(HERE, "centers.json")
LINE, DETAIL = VARIANT["line"], VARIANT["detail"]
ROUND = {"file:web", "file:disc", "file:harddisk", "dir:folder-sync"}
KEY = {"square": 18.6, "round": 19.6, "long": 19.6, "thin": 20.4}

def keyline(key, w, h):
    lo, hi = min(w, h), max(w, h)
    if key in ROUND:
        return KEY["round"]
    if lo / hi < 0.62:
        return KEY["thin"]
    return KEY["square"] if lo / hi > 0.86 else KEY["long"]

def box(key):
    import json
    try:
        return json.load(open(CENTERS)).get(key)
    except (OSError, ValueError):
        return None

def weigh(shapes, scale):
    """The symbol's lines at one weight once scaled by `scale`."""
    def fix(m):
        w = float(m.group(2))
        return f'{m.group(1)}{(LINE if w >= 1.5 else DETAIL) / scale:.3f}"'
    return [re.sub(r'(data-line="1".*?stroke-width=")([0-9.]+)"', fix, x, flags=re.S) for x in shapes]

def centred(key, shapes, bare=False):
    b = box(key)
    if not b:
        return "".join(shapes)
    cx, cy, w, h, scale = b
    if bare:  # for measuring: the weights it will wear, not yet moved
        return "".join(weigh(shapes, scale))
    return f'\n      <g transform="translate(12 12) scale({scale:.4f}) translate({-cx:.3f} {-cy:.3f})">{"".join(weigh(shapes, scale))}\n      </g>'

def write(name, svg):
    os.makedirs(os.path.join(OUT, "places"), exist_ok=True)
    path = os.path.join(OUT, "places", name + ".svg")
    svg = variant(svg)
    with open(path + ".tmp", "w") as f:
        f.write(svg)
    os.replace(path + ".tmp", path)

write("folder", FOLDER.replace("{mask}", "").replace("{mark}", ""))
for name, shapes in SYMBOLS.items():
    write(name, FOLDER.replace("{mask}", MASK.replace("{shapes}", centred("dir:" + name, shapes))).replace("{mark}", MARK))
# SYMBOLIC: each folder's symbol alone, flat, for where a folder is too small
# to carry it (Max, 2026-10-14: "the sidebar dirs become the symbols if I
# make them too small") — `<name>-symbolic`, the freedesktop way, in the
# tone's ink; the plain folder's is its outline. Drawn at the 16 px weight.
SYMBOLIC = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="16" height="16">
  <defs>{mask}
  </defs>
  <rect x="-3" y="-3" width="30" height="30" fill="{ink}" mask="url(#sym)"/>
</svg>
"""
SYMBOLIC_INK = {"light": "#4f535b", "dark": "#cdd1d8"}[TONE]
FOLDER_GLYPH = [shape(W, 'path d="M3.6 6.6a2 2 0 0 1 2-2h4.3l2 2.1h6.5a2 2 0 0 1 2 2v9.1a2 2 0 0 1-2 2H5.6a2 2 0 0 1-2-2z"')]

def write_symbolic(name, key, shapes):
    global LINE, DETAIL
    keep = (LINE, DETAIL)
    LINE, DETAIL = 3.2, 2.0
    try:
        inner = centred(key, shapes)
    finally:
        LINE, DETAIL = keep
    os.makedirs(os.path.join(OUT, "places"), exist_ok=True)
    path = os.path.join(OUT, "places", name + "-symbolic.svg")
    with open(path + ".tmp", "w") as f:
        f.write(SYMBOLIC.replace("{mask}", MASK.replace("{shapes}", inner)).replace("{ink}", SYMBOLIC_INK))
    os.replace(path + ".tmp", path)

# The bin's own, so it stands with the others when they are symbols.
TRASH_GLYPH = [
    line(W, "M4.4 6.6h15.2", 2.2),
    line(W, "M9.4 6.2V4.6h5.2v1.6", 1.8),
    shape(W, 'path d="M6.4 8.8h11.2l-1 10a1.8 1.8 0 0 1-1.8 1.6H9.2a1.8 1.8 0 0 1-1.8-1.6z"'),
    line(B, "M10.2 11.4v5.8", 1.3),
    line(B, "M13.8 11.4v5.8", 1.3),
]
write_symbolic("folder", "dir:folder", FOLDER_GLYPH)
write_symbolic("user-trash", "dir:user-trash", TRASH_GLYPH)
# Up: the folder this one is in (Files' `..` once its places are symbols).
UP_GLYPH = [line(W, "M12 19.4V5.6", 2.4), line(W, "M6.6 11 12 5.6l5.4 5.4", 2.4)]
write_symbolic("go-up", "dir:go-up", UP_GLYPH)

# …and as FOLDERS too, for Files' places at a folder's size (Max, 2026-10-15:
# "create a dir with symbol for '..' and the recycle bin"): `folder-up` (the
# arrow up) and `user-trash` (the bin).
write("folder-up", FOLDER.replace("{mask}", MASK.replace("{shapes}", centred("dir:go-up", UP_GLYPH))).replace("{mark}", MARK))
write("user-trash", FOLDER.replace("{mask}", MASK.replace("{shapes}", centred("dir:user-trash", TRASH_GLYPH))).replace("{mark}", MARK))
for name, shapes in SYMBOLS.items():
    write_symbolic(name, "dir:" + name, shapes)

# Names that mean the same folder.
for alias, target in [("folder-network", "folder-remote"), ("folder-recent-calendar", "folder-calendar")][:1]:
    path = os.path.join(OUT, "places", alias + ".svg")
    if os.path.lexists(path):
        os.remove(path)
    os.symlink(target + ".svg", path)
if __name__ == "__main__":
    print("wrote", 1 + len(SYMBOLS), "icons to", os.path.join(HERE, "places"))
