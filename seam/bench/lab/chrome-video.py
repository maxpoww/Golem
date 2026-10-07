#!/usr/bin/env python3
"""chrome-video.py — the Chrome half of the YouTube comparison (yt.sh + ytprobe.js is the Seam half).

Drives a running Chrome (remote debugging, via an ssh tunnel to the laptop) to one video page,
records time-to-first-frame, then at WARM seconds after the navigation writes a window-start marker
on the laptop (its own clock) and watches video.paused every 50 ms for 20 s. pauses.sh on the laptop
waits for that marker, samples the browser's CPU for the same 20 s and presses 'k' four times; the
pause latency is each press time minus the time the page saw .paused flip.

    MARKER_SSH="ssh root@laptop" python3 chrome-video.py localhost:9222 https://www.youtube.com/watch?v=…
"""
import json, os, subprocess, sys, time, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from importlib import import_module
WS = import_module("chrome-loads").WS   # the minimal websocket client

HOST = sys.argv[1]; URL = sys.argv[2]
WARM = float(os.environ.get("WARM", "45")); WINDOW = float(os.environ.get("WINDOW", "20"))
MARKER_SSH = os.environ.get("MARKER_SSH", ""); MARKER = os.environ.get("MARKER", "/tmp/seam-sb/chrome-window-start")
POLL = ("(function(){var v=document.querySelector('video');if(!v)return null;"
        "return {t:v.currentTime,paused:v.paused,now:Date.now(),w:v.videoWidth,h:v.videoHeight,"
        "q:(function(){try{var q=v.getVideoPlaybackQuality();return {totalVideoFrames:q.totalVideoFrames,droppedVideoFrames:q.droppedVideoFrames};}catch(e){return {};}})(),rs:v.readyState};})()")


def ev(ws, expr):
    try:
        return (ws.call("Runtime.evaluate", returnByValue=True, expression=expr).get("result", {}) or {}).get("value")
    except RuntimeError:   # "Inspected target navigated or closed": the context is being replaced — poll again
        return None


def main():
    base = f"http://{HOST}"
    ver = json.load(urllib.request.urlopen(base + "/json/version", timeout=10))
    out = {"browser": ver.get("Browser"), "url": URL}
    tab = json.loads(urllib.request.urlopen(urllib.request.Request(base + "/json/new?about:blank", method="PUT"), timeout=10).read())
    ws = WS(tab["webSocketDebuggerUrl"]); ws.call("Page.enable")
    t_nav = time.time(); ws.call("Page.navigate", url=URL)
    first = None
    while time.time() - t_nav < WARM:
        v = ev(ws, POLL)
        if v and v.get("t", 0) > 0 and not v.get("paused") and first is None:
            first = round((time.time() - t_nav) * 1000); out["first_frame_ms"] = first; out["size"] = [v.get("w"), v.get("h")]
            PIN = os.environ.get("PIN", "hd720")
            out["pinned"] = ev(ws, "(function(){var p=document.getElementById('movie_player'); if(p&&p.setPlaybackQualityRange){p.setPlaybackQualityRange('%s','%s'); return '%s';} return null;})()" % (PIN, PIN, PIN)) if PIN != "0" else "auto"
        time.sleep(0.25)
    if first is None: out["first_frame_ms"] = None
    # keyboard to the player (a CDP-opened tab leaves the omnibox focused; the real 'k' must reach the page)
    try:
        ws.call("Page.bringToFront")
    except RuntimeError:
        pass
    ev(ws, "(function(){var p=document.getElementById('movie_player')||document.querySelector('video'); if(p){p.setAttribute('tabindex','-1'); p.focus();} else document.body.focus(); return document.activeElement&&document.activeElement.id;})()")
    # window start: marker on the laptop's clock
    if MARKER_SSH:
        subprocess.run(MARKER_SSH.split() + [f"date +%s%3N > {MARKER}"], check=False)
    ev(ws, "(function(){if(window.__golemEv)return 1;var E=window.__golemEv={keys:[],flips:[]};window.addEventListener('keydown',function(e){E.keys.push({t:Date.now(),key:e.key});},true);"
           "var v=document.querySelector('video');if(v){var f=function(e){E.flips.push({t:Date.now(),paused:v.paused,ev:e.type});};v.addEventListener('pause',f);v.addEventListener('play',f);}return 2;})()")
    t0 = time.time(); q0 = (ev(ws, POLL) or {}).get("q", {})
    flips = []; last = None
    while time.time() - t0 < WINDOW:
        v = ev(ws, POLL)
        if v:
            if last is None: last = v["paused"]
            if v["paused"] != last:
                last = v["paused"]; flips.append({"t": v["now"], "paused": v["paused"]})
        time.sleep(0.05)
    q1 = (ev(ws, POLL) or {}).get("q", {})
    evs = ev(ws, "window.__golemEv") or {}
    out["flips"] = evs.get("flips") or flips      # event-driven when available (no poll delay in the latency)
    out["keys"] = evs.get("keys") or []
    out["flips_polled"] = flips
    out["frames"] = {"total": (q1.get("totalVideoFrames", 0) - q0.get("totalVideoFrames", 0)), "dropped": (q1.get("droppedVideoFrames", 0) - q0.get("droppedVideoFrames", 0))}
    out["final"] = ev(ws, POLL)
    print(json.dumps(out), flush=True)
    try: urllib.request.urlopen(base + "/json/close/" + tab["id"], timeout=5).read()
    except Exception: pass


if __name__ == "__main__":
    main()
