#!/usr/bin/env python3
"""Seam's icon (Max, 2026-10-16, the Dock Motion Lab): a COMPASS in the dock
figures' cast — a bezel, its rose grooved in the face (a ring, the four
cardinal ticks long, the four between short) turned with the needle, and a
two-tone needle on Safari's 45° slant. The dock draws the same figure itself
(waverunner compass_icon.rs) and swings the needle on hover; this is the icon
everything else shows. Silver, or graphite for Golem-Dark (GOLEM_ICON_TONE).
build-theme.sh runs it. (It must not import make.py: that import writes.)"""
import math
import os

OUT = os.environ.get("GOLEM_ICON_OUT", os.path.dirname(os.path.abspath(__file__)))
DARK = os.environ.get("GOLEM_ICON_TONE") == "dark"
SLANT = 45.0


def lit_filter(fid, k, shade, lit, source):
    merge = '<feMergeNode in="SourceGraphic"/>' if source else ""
    return (f'<filter id="{fid}" filterUnits="userSpaceOnUse" x="-20" y="-20" width="140" height="140">'
            f'<feOffset in="SourceAlpha" dy="{3 * k:.2f}" result="down"/><feGaussianBlur in="down" stdDeviation="{1.3 * k:.2f}" result="soft"/>'
            f'<feFlood flood-color="#000" flood-opacity="{shade * k:.2f}"/><feComposite in2="soft" operator="in" result="shade"/>'
            f'<feOffset in="SourceAlpha" dy="{-1.5 * k:.2f}" result="up"/><feFlood flood-color="#fff" flood-opacity="{lit * k:.2f}"/>'
            f'<feComposite in2="up" operator="in" result="lit"/><feMerge><feMergeNode in="shade"/><feMergeNode in="lit"/>{merge}</feMerge></filter>')


def ticks(c):
    h = f'<circle cx="50" cy="50" r="33" fill="none" stroke="{c}" stroke-width="2.2"/>'
    for k in range(8):
        a = math.radians(SLANT + 45 * k)
        long = k % 2 == 0
        r0, r1 = (20 if long else 26), 30
        h += (f'<line x1="{50 + r0 * math.sin(a):.2f}" y1="{50 - r0 * math.cos(a):.2f}" x2="{50 + r1 * math.sin(a):.2f}" '
              f'y2="{50 - r1 * math.cos(a):.2f}" stroke="{c}" stroke-width="{2.8 if long else 1.8}" stroke-linecap="round"/>')
    return h


def svg():
    stops, gloss, hi = ((["#9a9fa8", "#8d929b", "#757a83", "#666a73"], 0.12, 0.25) if DARK
                        else (["#fefefe", "#fafafa", "#eeeeee", "#e6e6e6"], 0.22, 0.5))
    lit = min(hi * 3, 0.95)
    bx = 'maskUnits="userSpaceOnUse" x="-20" y="-20" width="140" height="140"'
    disc = '<circle cx="50" cy="50" r="40"/>'
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="256" height="256"><defs>
<linearGradient id="c" x1=".44" y1="0" x2=".56" y2="1"><stop offset="0" stop-color="{stops[0]}"/><stop offset=".38" stop-color="{stops[1]}"/><stop offset=".72" stop-color="{stops[2]}"/><stop offset="1" stop-color="{stops[3]}"/></linearGradient>
<linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="{gloss}"/><stop offset=".55" stop-color="#fff" stop-opacity="0"/></linearGradient>
{lit_filter("ce", 1, 0.7, lit, True)}{lit_filter("cd", 1, 0.95, lit, False)}{lit_filter("cn", 0.8, 0.7, lit, True)}
<mask id="cut" {bx}><rect x="-20" y="-20" width="140" height="140" fill="#fff"/>{ticks("#000")}</mask>
<mask id="pl" {bx}><circle cx="50" cy="50" r="40" fill="#fff"/>{ticks("#000")}</mask>
<mask id="op" {bx}>{ticks("#fff")}</mask></defs>
<g opacity=".8"><g transform="translate(5 5) scale(.9)">
<g mask="url(#cut)"><g filter="url(#ce)"><g fill="url(#c)">{disc}</g></g><g fill="url(#g)">{disc}</g></g>
<g mask="url(#op)"><g filter="url(#cd)"><rect mask="url(#pl)" fill="#000" x="-20" y="-20" width="140" height="140"/></g></g>
<g filter="url(#cn)"><g transform="rotate({SLANT:.2f} 50 50)">
<path d="M50 17 L56.5 50 L43.5 50 Z" fill="url(#c)"/><path d="M50 17 L56.5 50 L50 50 Z" fill="#000" opacity=".22"/>
<path d="M50 83 L56.5 50 L43.5 50 Z" fill="url(#c)" opacity=".72"/><circle cx="50" cy="50" r="4.2" fill="url(#c)"/></g></g>
</g></g></svg>
'''


def main():
    os.makedirs(os.path.join(OUT, "apps"), exist_ok=True)
    path = os.path.join(OUT, "apps", "seam.svg")
    with open(path + ".tmp", "w") as f:
        f.write(svg())
    os.replace(path + ".tmp", path)


if __name__ == "__main__":
    main()
