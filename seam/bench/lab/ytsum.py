#!/usr/bin/env python3
"""ytsum.py — one-line-per-fact summary of a video measurement.

    ytsum.py seam  result.json  [presses.txt]   (ytprobe.js output + pauses.sh log)
    ytsum.py chrome out.json    [presses.txt]   (chrome-video.py output + pauses.sh log)

Prints the window's CPU per process (Seam: requestProcInfo deltas), the video size / frames / drops,
time to first frame, and for each 'k' press the latency until the page saw video.paused flip.
"""
import json, sys


def presses(path):
    out = []
    try:
        for line in open(path):
            p = line.split()
            if len(p) == 2 and p[0] == "press": out.append(int(p[1]))
    except Exception:
        pass
    return out


def latencies(press_ts, flips):
    rows = []
    for t in press_ts:
        after = [f for f in flips if f["t"] >= t]
        rows.append(f"{after[0]['t'] - t} ms→{'paused' if after[0]['paused'] else 'playing'}" if after else "no flip")
    return rows


kind, path = sys.argv[1], sys.argv[2]
pr = presses(sys.argv[3]) if len(sys.argv) > 3 else []
o = json.load(open(path))
if kind == "seam":
    a, b = o.get("procs0", {}), o.get("procs1", {})
    d = {k: round((b[k]["cpu"] - a.get(k, {"cpu": 0})["cpu"]) / 1e6) for k in b}
    top = dict(sorted(d.items(), key=lambda x: -x[1])[:7])
    print(f"CPU ms in the window: {top} TOTAL {sum(d.values())}")
    c = o.get("content", {}); v = c.get("video") or {}; w = c.get("watch") or {}
    print(f"video {v.get('w')}x{v.get('h')} t={v.get('t')} frames={v.get('total')} dropped={v.get('dropped')} decoder={(c.get('decoder') or {}).get('video')} hw={(c.get('decoder') or {}).get('hw')}")
    ff = w.get("firstFrame"); st = w.get("started")
    print(f"first frame: {ff - st if ff and st else None} ms after the watcher started; flips={w.get('pauses')}")
    print("press latencies:", latencies(pr, w.get("pauses") or []))
    ks=w.get("keys") or []; print("key seen by the page after:", [ (min([k["t"] for k in ks if k["t"]>=t], default=None) and min([k["t"] for k in ks if k["t"]>=t])-t) for t in pr ], "ms")
else:
    print(f"{o.get('browser')} first frame {o.get('first_frame_ms')} ms after navigate; size {o.get('size')}; frames {o.get('frames')}")
    print(f"flips={o.get('flips')}")
    print("press latencies:", latencies(pr, o.get("flips") or []))
    ks=o.get("keys") or []; print("key seen by the page after:", [ (min([k["t"] for k in ks if k["t"]>=t], default=None) and min([k["t"] for k in ks if k["t"]>=t])-t) for t in pr ], "ms")
