#!/usr/bin/env python3
"""Seam's icon (Max, 2026-10-16, the Dock Motion Lab): a COMPASS in the dock
figures' cast — a plate with a fine graduation and a ring grooved in it, a
wind rose on it made of light alone (eight points, each a lit face and a
shaded one, the long four out to the plate's edge), and a needle on Safari's
45° slant, its north half red, its south half blue. The dock draws the same
figure itself (waverunner compass_icon.rs), swings the needle on hover (the
plate the other way) and turns it round on a click; this is the icon
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


def at(a, r):
    return f"{50 + r * math.sin(a):.2f} {50 - r * math.cos(a):.2f}"


def ticks(c):
    """The grooves: the ring, and a tick every 15°, a longer one every 45°."""
    h = f'<circle cx="50" cy="50" r="33" fill="none" stroke="{c}" stroke-width="2.2"/>'
    for k in range(24):
        a = math.radians(SLANT) + k * math.pi / 12
        major = k % 3 == 0
        r0, r1 = (34.4 if major else 35.4), 38
        h += (f'<line x1="{50 + r0 * math.sin(a):.2f}" y1="{50 - r0 * math.cos(a):.2f}" x2="{50 + r1 * math.sin(a):.2f}" '
              f'y2="{50 - r1 * math.cos(a):.2f}" stroke="{c}" stroke-width="{1.2 if major else 0.7}" stroke-linecap="round"/>')
    return h


def rose():
    """The wind rose, short points first (under), slim as the needle."""
    h = ""
    for long in (False, True):
        for k in range(0 if long else 1, 8, 2):
            a = math.radians(SLANT) + k * math.pi / 4
            tip, r0 = (40, 9) if long else (34, 7.5)
            w = math.pi / 4
            t, l, r = at(a, tip), at(a - w, r0), at(a + w, r0)
            h += (f'<path d="M50 50 L{t} L{l} Z" fill="#fff" opacity=".5"/>'
                  f'<path d="M50 50 L{t} L{r} Z" fill="#000" opacity=".38"/>')
    return h


def svg():
    stops, gloss, hi = ((["#9a9fa8", "#8d929b", "#757a83", "#666a73"], 0.12, 0.25) if DARK
                        else (["#fefefe", "#fafafa", "#eeeeee", "#e6e6e6"], 0.22, 0.5))
    lit = min(hi * 3, 0.95)
    tint = 0.78 if DARK else 0.62
    bx = 'maskUnits="userSpaceOnUse" x="-20" y="-20" width="140" height="140"'
    disc = '<circle cx="50" cy="50" r="40"/>'
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="256" height="256"><defs>
<linearGradient id="c" x1=".44" y1="0" x2=".56" y2="1"><stop offset="0" stop-color="{stops[0]}"/><stop offset=".38" stop-color="{stops[1]}"/><stop offset=".72" stop-color="{stops[2]}"/><stop offset="1" stop-color="{stops[3]}"/></linearGradient>
<linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="{gloss}"/><stop offset=".55" stop-color="#fff" stop-opacity="0"/></linearGradient>
<linearGradient id="cr" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#e3685a"/><stop offset="1" stop-color="#a8372d"/></linearGradient>
<linearGradient id="cb" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="#5a8de3"/><stop offset="1" stop-color="#2d58a8"/></linearGradient>
<clipPath id="cl"><circle cx="50" cy="50" r="40"/></clipPath>
{lit_filter("ce", 1, 0.7, lit, True)}{lit_filter("cd", 1, 0.95, lit, False)}{lit_filter("cn", 0.8, 0.7, lit, True)}
<mask id="cut" {bx}><rect x="-20" y="-20" width="140" height="140" fill="#fff"/>{ticks("#000")}</mask>
<mask id="pl" {bx}><circle cx="50" cy="50" r="40" fill="#fff"/>{ticks("#000")}</mask>
<mask id="op" {bx}>{ticks("#fff")}</mask></defs>
<g opacity=".8"><g transform="translate(5 5) scale(.9)">
<g mask="url(#cut)"><g filter="url(#ce)"><g fill="url(#c)">{disc}</g></g><g fill="url(#g)">{disc}</g></g>
<g mask="url(#op)"><g filter="url(#cd)"><rect mask="url(#pl)" fill="#000" x="-20" y="-20" width="140" height="140"/></g></g>
<g clip-path="url(#cl)">{rose()}</g>
<g filter="url(#cn)"><g transform="rotate({SLANT:.2f} 50 50)">
<path d="M50 17 L56.5 50 L43.5 50 Z" fill="url(#c)"/><path d="M50 17 L56.5 50 L43.5 50 Z" fill="url(#cr)" opacity="{tint}"/><path d="M50 17 L56.5 50 L50 50 Z" fill="#000" opacity=".22"/>
<path d="M50 83 L56.5 50 L43.5 50 Z" fill="url(#c)"/><path d="M50 83 L56.5 50 L43.5 50 Z" fill="url(#cb)" opacity="{tint}"/><path d="M50 83 L56.5 50 L50 50 Z" fill="#000" opacity=".22"/>
<circle cx="50" cy="50" r="4.2" fill="url(#c)"/></g></g>
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
