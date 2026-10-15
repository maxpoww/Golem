#!/usr/bin/env python3
"""Measure every symbol of make.py and files.py as resvg draws it and write
centers.json: its real box (centre, width, height) and the scale that brings
it to its keyline (make.keyline). The weights depend on the scale and the box on
the weights, so it is measured a few times over. Run it after adding or changing
a symbol, then make.py and files.py."""
import os, sys, zlib, struct, subprocess, json, io, contextlib, glob
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
with contextlib.redirect_stdout(io.StringIO()):
    import make, files
RESVG = sorted(glob.glob("/nix/store/*-resvg-*/bin/resvg"))[-1]
TMP = "/tmp/golem-icons-center"
os.makedirs(TMP, exist_ok=True)

def png_bbox(path):
    d = open(path, "rb").read(); i = 8; w = h = 0; idat = b""
    while i < len(d):
        n = struct.unpack(">I", d[i:i + 4])[0]; t = d[i + 4:i + 8]; c = d[i + 8:i + 8 + n]
        if t == b"IHDR": w, h = struct.unpack(">II", c[:8])
        if t == b"IDAT": idat += c
        i += 12 + n
    raw = zlib.decompress(idat); bpp = 4; stride = w * bpp; prev = bytearray(stride); p = 0
    x0, y0, x1, y1 = w, h, -1, -1
    for y in range(h):
        f = raw[p]; p += 1; line = bytearray(raw[p:p + stride]); p += stride
        for x in range(stride):
            a = line[x - bpp] if x >= bpp else 0; b = prev[x]; c = prev[x - bpp] if x >= bpp else 0
            if f == 1: line[x] = (line[x] + a) & 255
            elif f == 2: line[x] = (line[x] + b) & 255
            elif f == 3: line[x] = (line[x] + (a + b) // 2) & 255
            elif f == 4:
                pa = abs(b - c); pb = abs(a - c); pc = abs(a + b - 2 * c)
                line[x] = (line[x] + (a if pa <= pb and pa <= pc else (b if pb <= pc else c))) & 255
        for x in range(w):
            if line[x * 4 + 3] > 100:
                x0 = min(x0, x); x1 = max(x1, x); y0 = min(y0, y); y1 = max(y1, y)
        prev = line
    return x0, y0, x1 + 1, y1 + 1, w

def measure(key, inner):
    px = 360  # the viewBox is 30 units: 12 px a unit
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="-3 -3 30 30" width="{px}" height="{px}"><defs>'
           f'<mask id="m" maskUnits="userSpaceOnUse" x="-3" y="-3" width="30" height="30">{inner}</mask></defs>'
           f'<rect x="-3" y="-3" width="30" height="30" fill="#000" mask="url(#m)"/></svg>')
    f = os.path.join(TMP, key.replace(":", "-") + ".svg")
    open(f, "w").write(svg)
    subprocess.run([RESVG, f, f[:-4] + ".png"], check=True)
    x0, y0, x1, y1, w = png_bbox(f[:-4] + ".png")
    u = 30 / w
    return (x0 + x1) / 2 * u - 3, (y0 + y1) / 2 * u - 3, (x1 - x0) * u, (y1 - y0) * u

ALL = {"file:" + k: v for k, v in files.SYM.items()}
ALL.update({"dir:" + k: v for k, v in make.SYMBOLS.items()})
ALL["dir:folder"] = make.FOLDER_GLYPH  # (the plain folder's own symbolic)
ALL["dir:user-trash"] = make.TRASH_GLYPH
ALL["dir:go-up"] = make.UP_GLYPH
ALL["dir:folder-up"] = make.DOTS_GLYPH
data = {}
for _ in range(3):
    json.dump(data, open(make.CENTERS, "w"), indent=1)
    new = {}
    for key, shapes in ALL.items():
        cx, cy, w, h = measure(key, make.centred(key, shapes, bare=True) if key in data else "".join(shapes))
        new[key] = [round(cx, 3), round(cy, 3), round(w, 3), round(h, 3), round(make.keyline(key, w, h) / max(w, h), 4)]
    data = new
json.dump(data, open(make.CENTERS, "w"), indent=1)
for k, (cx, cy, w, h, s) in sorted(data.items(), key=lambda kv: kv[1][4]):
    print(f"{k:24s} box {w:5.2f} x {h:5.2f}  scale {s:.3f}")
