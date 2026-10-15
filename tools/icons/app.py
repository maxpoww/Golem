#!/usr/bin/env python3
"""Golem Files' own icon (Max, 2026-10-15: "we should use only the folder with
the folder symbol"): Golem's folder with a folder engraved on it. On the dock
its launcher draws it itself and two folders come out from behind it on hover
(waverunner's files_icon.rs). Written into the theme's apps/ (both tones
wear the same: an app's icon stands on the dock's plate). build-theme.sh runs it.
(It must not import make.py: that import WRITES the folders, in the light
tone — it once turned the dark theme silver.)"""
import os

OUT = os.environ.get("GOLEM_ICON_OUT", os.path.dirname(os.path.abspath(__file__)))


def mix(a, b, t):
    a = [int(a[i:i + 2], 16) for i in (1, 3, 5)]
    b = [int(b[i:i + 2], 16) for i in (1, 3, 5)]
    return "#" + "".join(f"{round(x + (y - x) * t):02x}" for x, y in zip(a, b))


def folder(n, k):
    """Golem's simple folder (52 x 45) in its silver, `k` of the way darker."""
    f0, f1 = mix("#eef0f3", "#9aa0aa", k), mix("#c2c6cd", "#7c828c", k)
    b0, b1 = mix("#b3b8c0", "#7d838d", k), mix("#8f949e", "#5e636c", k)
    return f'''<defs><linearGradient id="f{n}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{f0}"/><stop offset="1" stop-color="{f1}"/></linearGradient>
<linearGradient id="b{n}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{b0}"/><stop offset="1" stop-color="{b1}"/></linearGradient></defs>
<path fill="url(#b{n})" filter="url(#bev)" d="M0,4.5A4.5,4.5 0 0 1 4.5,0H17.5C20,0 21.2,.9 22.6,2.6L24,4.3C24.6,5 25.2,5.3 26.2,5.3H47.5A4.5,4.5 0 0 1 52,9.8V40H0Z"/>
<rect fill="url(#f{n})" filter="url(#bev)" x="0" y="8" width="52" height="37" rx="4.5"/>
<rect fill="url(#gl)" x="0" y="8" width="52" height="37" rx="4.5"/>
<rect fill="#fff" opacity=".55" x="4.5" y="8" width="43" height=".7" rx=".35"/>'''


HEAD = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64"><defs>
<linearGradient id="gl" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".35"/><stop offset=".55" stop-color="#fff" stop-opacity="0"/></linearGradient>
<filter id="bev" x="-20%" y="-20%" width="140%" height="140%"><feDropShadow dx="0" dy="-.6" stdDeviation="0" flood-color="#fff" flood-opacity=".5"/><feDropShadow dx="0" dy="1.2" stdDeviation=".9" flood-color="#000" flood-opacity=".45"/></filter></defs>'''

GLYPH = "M3.6 6.6a2 2 0 0 1 2-2h4.3l2 2.1h6.5a2 2 0 0 1 2 2v9.1a2 2 0 0 1-2 2H5.6a2 2 0 0 1-2-2z"


def main():
    # Golem's folder where it stands (6, 9.5), a folder engraved on it: a
    # light edge under it, then the darker grey (the lab's "símbolo").
    gx, gy = 26 - 12 * 1.15, 26.5 - 12.2 * 1.15
    sym = "".join(
        f'<path d="{GLYPH}" fill="{c}" stroke="{c}" stroke-width="1.2" stroke-linejoin="round" '
        f'opacity="{o}" transform="translate({gx:.2f} {gy + dy:.2f}) scale(1.15)"/>'
        for c, o, dy in (("#fff", 0.6, 0.75), ("#a1a6af", 1, 0)))
    body = '<g transform="translate(6 9.5)">' + folder(0, 0) + sym + "</g>"
    os.makedirs(os.path.join(OUT, "apps"), exist_ok=True)
    path = os.path.join(OUT, "apps", "golem-files.svg")
    with open(path + ".tmp", "w") as f:
        f.write(HEAD + body + "</svg>\n")
    os.replace(path + ".tmp", path)


if __name__ == "__main__":
    main()
