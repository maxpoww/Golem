#!/usr/bin/env python3
"""Golem Files' own icon (Max, 2026-10-14: "vamos a usar la ventana"): a Golem
window — its bar with the three discs — holding four of Golem's folders, the
first selected. Written into the theme's apps/ (both tones wear the same: an
app's icon stands on the dock's plate, not on the page). build-theme.sh runs it."""
import os, re, sys, io, contextlib
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
with contextlib.redirect_stdout(io.StringIO()):
    import make

OUT = os.environ.get("GOLEM_ICON_OUT", HERE)

def folder(name):
    """One of the folders' finished drawing (light tone, scalable), as a
    nested picture; its ids made its own."""
    with open(os.path.join(HERE, "..", "..", "system", "home", "icons", "Golem", "scalable", "places", name + ".svg")) as f:
        svg = f.read()
    tag = name.replace("-", "")
    svg = re.sub(r'id="([^"]+)"', lambda m: f'id="{tag}{m.group(1)}"', svg)
    svg = re.sub(r'url\(#([^)]+)\)', lambda m: f'url(#{tag}{m.group(1)})', svg)
    return svg

def nested(svg, x, y, size):
    inner = re.sub(r'<svg[^>]*>', '', svg, count=1).rsplit("</svg>", 1)[0]
    return f'<svg x="{x}" y="{y}" width="{size}" height="{size}" viewBox="0 0 64 64">{inner}</svg>'

ICON = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <defs>
    <linearGradient id="win" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#343a46"/><stop offset="1" stop-color="#262b34"/></linearGradient>
    <filter id="lift" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="1.6" stdDeviation="1.2" flood-color="#000" flood-opacity=".45"/>
    </filter>
  </defs>
  <rect fill="url(#win)" filter="url(#lift)" x="5" y="7" width="54" height="50" rx="8"/>
  <path fill="#3d4451" d="M13,7H51A8,8 0 0 1 59,15V18H5V15A8,8 0 0 1 13,7Z"/>
  <path fill="#fff" opacity=".12" d="M13,7H51A8,8 0 0 1 59,15V15.8A8,8 0 0 0 51,7.8H13A8,8 0 0 0 5,15.8V15A8,8 0 0 1 13,7Z"/>
  <circle cx="11.6" cy="12.5" r="2.2" fill="#ff453a"/><circle cx="18" cy="12.5" r="2.2" fill="#ff9f0a"/><circle cx="24.4" cy="12.5" r="2.2" fill="#30d158"/>
  <rect fill="#fff" opacity=".1" x="8.5" y="20.5" width="23" height="17" rx="3.5"/>
  {folders}
</svg>
"""

def main():
    picks = [("folder-download", 9, 19.5), ("folder-pictures", 32, 19.5), ("folder-music", 9, 37), ("folder", 32, 37)]
    body = "".join(nested(folder(n), x, y, 21) for n, x, y in picks)
    os.makedirs(os.path.join(OUT, "apps"), exist_ok=True)
    path = os.path.join(OUT, "apps", "golem-files.svg")
    with open(path + ".tmp", "w") as f:
        f.write(ICON.replace("{folders}", body))
    os.replace(path + ".tmp", path)

if __name__ == "__main__":
    main()
