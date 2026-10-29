#!/usr/bin/env python3
# recents-selftest.py: the recents' kitchen's COVERS FROM BEFORE (golem-chrome.js), headless,
# against a real Seam build. Run through `./webapps-selftest.sh recents` (it builds the farm).
# A throwaway profile and state dir; the history is written through Places; the pictures are
# YouTube's own (this test goes on the network: i.ytimg.com, YouTube's oEmbed).
import json, os, shutil, socket, subprocess, sys, time, tempfile, urllib.parse, urllib.request
FARM = os.environ["FARM"]; LDP = os.environ["LDP"]
MPORT = 28293   # its own (webapps 28290, rows 28291, dwfirst 28292): two tests at once must not meet
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
CHARROS = MU + "J5iFix-1FJw&list=RDAMVM5ZkLJ25zGCA"   # a song with no video: its cover, padded; named without its artist
TECHNO = MU + "iqmTWg0z9v0"                            # no big picture: the smaller one
THUNDER = MU + "9ssQKlLxBdQ"                           # the history calls it only "YouTube Music": named
NOWHERE = MU + "zzzzzzzzzz0"                           # no such video: tried, not asked again
GONE = MU + "V2SVRJ6dcE4"                              # taken out of the history during the round
VIDEO = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"  # not a music site's
OLD = MU + "U1vGosMScjM"                               # visited too long ago
PL = "https://music.youtube.com/playlist?list="
LIST, LIST_SHARE = PL + "UU_x5XG1OV2P6uZZ5FSM9Ttw", PL + "UU_x5XG1OV2P6uZZ5FSM9Ttw&feature=share"   # a list at two addresses, nameless
NOLIST = PL + "PLzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"     # no such list: tried, its name left
# What YouTube says of the list now (its first video changes with the channel's uploads).
said = json.load(urllib.request.urlopen("https://www.youtube.com/oembed?format=json&url=" + urllib.parse.quote("https://www.youtube.com/playlist?list=UU_x5XG1OV2P6uZZ5FSM9Ttw", safe=""), timeout=20))
LIST_NAME, FIRST = said["title"], said["thumbnail_url"].split("/vi/")[1].split("/")[0]
FIRSTSONG = MU + FIRST                                 # the list's first video, a song of the history too
DAY = 86400 * 1000
m = M(); time.sleep(2)
YTM = "YouTube Music"
visits = [(ROBOT, 2, "Robot Rock | YouTube Music"), (ROBOT_LIST, 3, YTM), (NOWHERE, 4, YTM), (CHARROS, 5, "Amores Como El Nuestro | YouTube Music"),
          (TECHNO, 6, "Daft Punk - Technologic | YouTube Music"), (THUNDER, 6.5, YTM), (GONE, 7, YTM), (VIDEO, 2, YTM), (OLD, 200, YTM),
          (LIST, 8, YTM), (LIST_SHARE, 8.5, YTM), (NOLIST, 9, "My list | YouTube Music"), (FIRSTSONG, 9.5, "First | YouTube Music")]
ins = m.js("""
  const { PlacesUtils } = ChromeUtils.importESModule("resource://gre/modules/PlacesUtils.sys.mjs");
  await PlacesUtils.history.insertMany(%s.map(([url, days, title]) => ({ url, title, visits: [{ date: new Date(Date.now() - days * %d) }] })));
  done(1);""" % (json.dumps(visits), DAY))
check("setup: the history written", ins == 1, ins)
m.js('Services.obs.notifyObservers(null, "golem:recents-backfill"); done(1);')
time.sleep(1.5)
m.js("""const { PlacesUtils } = ChromeUtils.importESModule("resource://gre/modules/PlacesUtils.sys.mjs");
  await PlacesUtils.history.remove(%s); done(1);""" % json.dumps(GONE))
for _ in range(60):
    k = kitchen()["pages"]
    if all(k.get(u, {}).get("pic") for u in (ROBOT, CHARROS, TECHNO, THUNDER, LIST, FIRSTSONG)) and k.get(THUNDER, {}).get("title") and k.get(CHARROS, {}).get("title") and k.get(NOWHERE, {}).get("tried") and k.get(NOLIST, {}).get("tried") and "to fetch" in log(): break
    time.sleep(1)
time.sleep(3)
k = kitchen(); pages = k["pages"]
check("the round wanted the window's seven songs and two lists: every song (none says who sings it) and the nameless list named (one fetch each)", "covers from before: 7 songs, 2 playlists, 9 pictures, 8 names to fetch" in log(), log()[-400:])
pics = {u: pages.get(u, {}).get("pic") for u in (ROBOT, ROBOT_LIST, CHARROS, TECHNO, THUNDER, FIRSTSONG)}
check("each song of the history gets its picture", all(pics.values()), pics)
check("a song at two addresses: one picture for both", pics[ROBOT] and pics[ROBOT] == pics[ROBOT_LIST], pics)
files = {u: f"{KITCHEN}/pics/{f}" for u, f in pics.items() if f}
check("the pictures are in the kitchen's pics/", all(os.path.getsize(f) > 2000 for f in files.values() if os.path.exists(f)) and all(os.path.exists(f) for f in files.values()), {u[-20:]: os.path.exists(f) for u, f in files.items()})
sizes = {u[-24:]: jpeg_size(f) for u, f in files.items() if os.path.exists(f)}
check("the biggest picture there is: 1280×720, else YouTube's 480×360", sizes.get(ROBOT[-24:]) == (1280, 720) and sizes.get(TECHNO[-24:]) == (480, 360), sizes)
check("the page keeps when it was visited", abs(pages.get(ROBOT, {}).get("at", 0) - (time.time() - 2 * 86400)) < 120, pages.get(ROBOT))
check("a song the history calls only \"YouTube Music\" gets its name, with its artist", pages.get(THUNDER, {}).get("title") == "Thunder \u2022 Imagine Dragons", pages.get(THUNDER))
check("a song the history names without who sings it gets its artist (the video is the artist's own)", pages.get(CHARROS, {}).get("title") == "Amores Como El Nuestro \u2022 Los Charros", pages.get(CHARROS))
check("a song with a name YouTube gives no artist for keeps the history's, and is not asked again", all("title" not in pages.get(u, {}) and pages.get(u, {}).get("noArtist") for u in (ROBOT, ROBOT_LIST, TECHNO, FIRSTSONG)), {u[-12:]: pages.get(u) for u in pics})
lp = {u: pages.get(u, {}).get("pic") for u in (LIST, LIST_SHARE, FIRSTSONG)}
check("a list gets its first video's picture, one for both its addresses, a file of its own (not its song's)",
      lp[LIST] and lp[LIST] == lp[LIST_SHARE] and lp[LIST] != lp[FIRSTSONG] and all(os.path.exists(f"{KITCHEN}/pics/{f}") for f in lp.values() if f), lp)
check("a list the history only calls \"YouTube Music\" gets its name", pages.get(LIST, {}).get("title") == LIST_NAME and pages.get(LIST_SHARE, {}).get("title") == LIST_NAME, (LIST_NAME, pages.get(LIST)))
check("a list that is not there: tried, no picture, its name left", pages.get(NOLIST, {}).get("tried") and not pages.get(NOLIST, {}).get("pic") and "nameTried" not in pages.get(NOLIST, {}) and "title" not in pages.get(NOLIST, {}), pages.get(NOLIST))
check("a video that is not there: tried, no picture, no name", pages.get(NOWHERE, {}).get("tried") and pages.get(NOWHERE, {}).get("nameTried") and not pages.get(NOWHERE, {}).get("pic") and "title" not in pages.get(NOWHERE, {}), pages.get(NOWHERE))
check("a page taken out of the history meanwhile is not kept", GONE not in pages, pages.get(GONE))
check("not another site's, not one visited too long ago", VIDEO not in pages and OLD not in pages, [u for u in pages])
n = log().count("covers from before:")
m.js('Services.obs.notifyObservers(null, "golem:recents-backfill"); done(1);'); time.sleep(3)
check("a second round asks for nothing (pictured and named, or tried this week)", log().count("covers from before: 0 songs, 0 playlists, 0 pictures, 0 names to fetch") == 1 and log().count("covers from before:") == n + 1, log()[-200:])
m.js("""const { PlacesUtils } = ChromeUtils.importESModule("resource://gre/modules/PlacesUtils.sys.mjs");
  await PlacesUtils.history.clear(); done(1);"""); time.sleep(3)
k = kitchen(); left = os.listdir(f"{KITCHEN}/pics") if os.path.isdir(f"{KITCHEN}/pics") else []
check("the history cleared whole: nothing kept, and when it was (the dock forgets its own then)",
      k.get("pages") == {} and k.get("plays") == [] and abs(k.get("cleared", 0) - time.time()) < 60 and not left, {"cleared": k.get("cleared"), "pages": len(k.get("pages", {})), "pics": left[:3]})
m.js('Services.prefs.setBoolPref("golem.seam.recents", false); Services.obs.notifyObservers(null, "golem:recents-backfill"); done(1);'); time.sleep(2)
check("the kill switch: no round", log().count("covers from before:") == n + 1, log()[-200:])
m.quit(); p.wait(timeout=30)
for d in (PROF, RUN): shutil.rmtree(d, ignore_errors=True)
bad = [n for n, ok in R.items() if not ok]
print(f"{len(R) - len(bad)}/{len(R)} passed" + (f"; FAILED: {bad}" if bad else ""))
sys.exit(1 if bad else 0)
