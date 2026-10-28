#!/usr/bin/env python3
# recents-selftest.py: the recents' kitchen's COVERS FROM BEFORE (golem-chrome.js), headless,
# against a real Seam build. Run through `./webapps-selftest.sh recents` (it builds the farm).
# A throwaway profile and state dir; the history is written through Places; the pictures are
# YouTube's own (this test goes on the network: i.ytimg.com).
import json, os, shutil, socket, subprocess, sys, time, tempfile
FARM = os.environ["FARM"]; LDP = os.environ["LDP"]
MPORT = 28291
PROF = tempfile.mkdtemp(prefix="rk-prof-"); RUN = tempfile.mkdtemp(prefix="rk-run-")
STATE = f"{PROF}/state"; KITCHEN = f"{STATE}/golem/seam/recents"; LOG = f"{RUN}/recents.log"
open(f"{PROF}/user.js", "w").write("\n".join([
 f'user_pref("marionette.port", {MPORT});', 'user_pref("browser.shell.checkDefaultBrowser", false);',
 'user_pref("browser.aboutwelcome.enabled", false);', 'user_pref("browser.startup.homepage_override.mstone", "ignore");',
 'user_pref("datareporting.policy.dataSubmissionEnabled", false);', '']))
ENV = dict(os.environ, HOME=PROF, XDG_CONFIG_HOME=f"{PROF}/.config", XDG_STATE_HOME=STATE, XDG_RUNTIME_DIR=RUN, LD_LIBRARY_PATH=LDP,
           MOZ_HEADLESS="1", MOZ_CRASHREPORTER_DISABLE="1", MOZ_LEGACY_PROFILES="1", SEAM_RECENTS_LOG=LOG)
p = subprocess.Popen([f"{FARM}/firefox", "--headless", "--name", "seamtest", "--profile", PROF, "--marionette", "-remote-allow-system-access", "about:blank"],
                     env=ENV, stdout=subprocess.DEVNULL, stderr=open(f"{RUN}/ff.log", "a"))
class M:
    def __init__(s):
        for _ in range(80):
            try: s.k = socket.create_connection(("127.0.0.1", MPORT), timeout=60); break
            except OSError: time.sleep(0.25)
        s.i = 0; s.recv(); s.cmd("WebDriver:NewSession", {"capabilities": {}}); s.cmd("Marionette:SetContext", {"value": "chrome"})
    def recv(s):
        b = b""
        while b":" not in b: b += s.k.recv(1)
        n, d = b.split(b":", 1); n = int(n)
        while len(d) < n: d += s.k.recv(n - len(d))
        return json.loads(d)
    def cmd(s, name, params=None):
        s.i += 1; m = json.dumps([0, s.i, name, params or {}]).encode(); s.k.sendall(str(len(m)).encode() + b":" + m); r = s.recv()
        if r[2]: raise RuntimeError(f"{name}: {r[2].get('message', r[2])}")
        return r[3]
    def js(s, body):  # async chrome script; body calls done(x)
        return s.cmd("WebDriver:ExecuteAsyncScript", {"script": "let done = arguments[arguments.length - 1];\n(async () => {\n" + body + "\n})().catch(e => done('ERR ' + e));", "args": [], "scriptTimeout": 60000})["value"]
    def quit(s):
        try: s.cmd("Marionette:Quit", {"flags": ["eAttemptQuit"]})
        except Exception: pass
R = {}
def check(name, ok, detail): R[name] = ok; print(f"{'PASS' if ok else 'FAIL'}  {name}: {json.dumps(detail)[:300]}", flush=True)
def kitchen():
    try: return json.load(open(f"{KITCHEN}/recents.json"))
    except Exception: return {"pages": {}, "plays": []}
def log(): return open(LOG).read() if os.path.exists(LOG) else ""
def jpeg_size(path):  # (w, h) from a JPEG's frame header
    b = open(path, "rb").read(); i = 2
    while i < len(b) - 9:
        if b[i] != 0xFF: i += 1; continue
        mk, ln = b[i + 1], int.from_bytes(b[i + 2:i + 4], "big")
        if mk in (0xC0, 0xC1, 0xC2): return int.from_bytes(b[i + 7:i + 9], "big"), int.from_bytes(b[i + 5:i + 7], "big")
        i += 2 + ln
    return None

MU = "https://music.youtube.com/watch?v="
ROBOT, ROBOT_LIST = MU + "sFZjqVnWBhc", MU + "sFZjqVnWBhc&list=RDAMVMsFZjqVnWBhc"   # a song at two addresses
CHARROS = MU + "J5iFix-1FJw&list=RDAMVM5ZkLJ25zGCA"   # a song with no video: its cover, padded
TECHNO = MU + "iqmTWg0z9v0"                            # no big picture: the smaller one
NOWHERE = MU + "zzzzzzzzzz0"                           # no such video: tried, not asked again
GONE = MU + "V2SVRJ6dcE4"                              # taken out of the history during the round
VIDEO = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"  # not a music site's
OLD = MU + "U1vGosMScjM"                               # visited too long ago
DAY = 86400 * 1000
m = M(); time.sleep(2)
visits = [(ROBOT, 2), (ROBOT_LIST, 3), (NOWHERE, 4), (CHARROS, 5), (TECHNO, 6), (GONE, 7), (VIDEO, 2), (OLD, 200)]
ins = m.js("""
  const { PlacesUtils } = ChromeUtils.importESModule("resource://gre/modules/PlacesUtils.sys.mjs");
  await PlacesUtils.history.insertMany(%s.map(([url, days]) => ({ url, title: "YouTube Music", visits: [{ date: new Date(Date.now() - days * %d) }] })));
  done(1);""" % (json.dumps(visits), DAY))
check("setup: the history written", ins == 1, ins)
m.js('Services.obs.notifyObservers(null, "golem:recents-backfill"); done(1);')
time.sleep(1.5)
m.js("""const { PlacesUtils } = ChromeUtils.importESModule("resource://gre/modules/PlacesUtils.sys.mjs");
  await PlacesUtils.history.remove(%s); done(1);""" % json.dumps(GONE))
for _ in range(60):
    k = kitchen()["pages"]
    if all(k.get(u, {}).get("pic") for u in (ROBOT, CHARROS, TECHNO)) and k.get(NOWHERE, {}).get("tried") and "to fetch" in log() and log().count("picture ") >= 3: break
    time.sleep(1)
time.sleep(3)
k = kitchen(); pages = k["pages"]
check("the round wanted the five songs of the window (one fetch a song)", "covers from before: 5 to fetch" in log(), log()[-400:])
pics = {u: pages.get(u, {}).get("pic") for u in (ROBOT, ROBOT_LIST, CHARROS, TECHNO)}
check("each song of the history gets its picture", all(pics.values()), pics)
check("a song at two addresses: one picture for both", pics[ROBOT] and pics[ROBOT] == pics[ROBOT_LIST], pics)
files = {u: f"{KITCHEN}/pics/{f}" for u, f in pics.items() if f}
check("the pictures are in the kitchen's pics/", all(os.path.getsize(f) > 2000 for f in files.values() if os.path.exists(f)) and all(os.path.exists(f) for f in files.values()), {u[-20:]: os.path.exists(f) for u, f in files.items()})
sizes = {u[-24:]: jpeg_size(f) for u, f in files.items() if os.path.exists(f)}
check("the biggest picture there is: 1280×720, else YouTube's 480×360", sizes.get(ROBOT[-24:]) == (1280, 720) and sizes.get(TECHNO[-24:]) == (480, 360), sizes)
check("the page keeps when it was visited", abs(pages.get(ROBOT, {}).get("at", 0) - (time.time() - 2 * 86400)) < 120, pages.get(ROBOT))
check("no title is made up (the history's stays)", all("title" not in pages.get(u, {}) for u in pics), {u[-12:]: pages.get(u) for u in pics})
check("a video that is not there: tried, no picture", pages.get(NOWHERE, {}).get("tried") and not pages.get(NOWHERE, {}).get("pic"), pages.get(NOWHERE))
check("a page taken out of the history meanwhile is not kept", GONE not in pages, pages.get(GONE))
check("not another site's, not one visited too long ago", VIDEO not in pages and OLD not in pages, [u for u in pages])
n = log().count("covers from before:")
m.js('Services.obs.notifyObservers(null, "golem:recents-backfill"); done(1);'); time.sleep(3)
check("a second round asks for nothing (pictured, or tried this week)", log().count("covers from before: 0 to fetch") == 1 and log().count("covers from before:") == n + 1, log()[-200:])
m.js('Services.prefs.setBoolPref("golem.seam.recents", false); Services.obs.notifyObservers(null, "golem:recents-backfill"); done(1);'); time.sleep(2)
check("the kill switch: no round", log().count("covers from before:") == n + 1, log()[-200:])
m.quit(); p.wait(timeout=30)
for d in (PROF, RUN): shutil.rmtree(d, ignore_errors=True)
bad = [n for n, ok in R.items() if not ok]
print(f"{len(R) - len(bad)}/{len(R)} passed" + (f"; FAILED: {bad}" if bad else ""))
sys.exit(1 if bad else 0)
