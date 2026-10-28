#!/usr/bin/env python3
# rows-selftest.py: EACH WINDOW ITS OWN ROW (golem-chrome.js, the lock), headless, against a
# real Seam build and the real Dark Reader. Run through webapps-selftest.sh rows (it builds the
# farm). One site open twice: in a Seam tab (the web's switch and the drop) and as a webapp
# (the apps' switch and its row on the Apps page); every switch is turned through the theme
# file or the drop's pref, and each page is read from inside: Dark Reader's colours on it or
# not, the lock on it or not, in the page and in its frame. (Max, 2026-10-28: "si el usuario
# desactiva webs pero tiene apps activadas, youtube en seam no tiene que tener color".)
import json, os, socket, subprocess, sys, time, threading, http.server, functools, shutil, tempfile
FARM = os.environ["FARM"]; LDP = os.environ["LDP"]; CHROME = os.environ["CHROMEDIR"]
PORT = 38418; MPORT = 28291
W = tempfile.mkdtemp(prefix="rows-www-")
open(f"{W}/page.html", "w").write("<html><head><title>Rows</title></head><body style='background:#fff;color:#000'><h1>Rows</h1>"
                                  "<iframe src='frame.html'></iframe></body></html>")
open(f"{W}/frame.html", "w").write("<html><head><title>Frame</title></head><body style='background:#fff;color:#000'>frame</body></html>")
open(f"{W}/next.html", "w").write("<html><head><title>Next</title></head><body style='background:#fff;color:#000'>next</body></html>")
class Q(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a): pass
threading.Thread(target=http.server.ThreadingHTTPServer(("127.0.0.1", PORT), functools.partial(Q, directory=W)).serve_forever, daemon=True).start()
U = lambda n: f"http://127.0.0.1:{PORT}/{n}.html"
PROF = tempfile.mkdtemp(prefix="rows-prof-"); os.makedirs(f"{PROF}/chrome"); os.makedirs(f"{PROF}/.config")
for f in ("userChrome.css", "userContent.css"): shutil.copy(f"{CHROME}/{f}", f"{PROF}/chrome/{f}")
open(f"{PROF}/user.js", "w").write("\n".join([
 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);', f'user_pref("marionette.port", {MPORT});',
 'user_pref("browser.shell.checkDefaultBrowser", false);', 'user_pref("browser.aboutwelcome.enabled", false);',
 'user_pref("browser.startup.homepage_override.mstone", "ignore");', 'user_pref("datareporting.policy.dataSubmissionEnabled", false);', '']))
STATE = f"{PROF}/.local/state"; os.makedirs(f"{STATE}/golem/theme")
def theme(**rows):   # the dock's theme file: Golem's dark pair, the site is a webapp's
    c = dict(dark=True, base01="#1d2026", base05="#e6e3dd", webapp_hosts=["127.0.0.1"]); c.update(rows)
    t = f"{STATE}/golem/theme/colors.json.tmp"; open(t, "w").write(json.dumps(c)); os.replace(t, f"{STATE}/golem/theme/colors.json")
theme(web=False, apps=True)
RUN = tempfile.mkdtemp(prefix="rows-run-")
ENV = dict(os.environ, HOME=PROF, XDG_CONFIG_HOME=f"{PROF}/.config", XDG_STATE_HOME=STATE, XDG_RUNTIME_DIR=RUN, LD_LIBRARY_PATH=LDP,
           MOZ_HEADLESS="1", MOZ_CRASHREPORTER_DISABLE="1", MOZ_LEGACY_PROFILES="1")
# SEAM_ROWS_WAYLAND=<socket path>: on a real compositor (a nested rig) instead of headless
WL = os.environ.get("SEAM_ROWS_WAYLAND", "")
if WL: ENV.pop("MOZ_HEADLESS"); ENV.update(WAYLAND_DISPLAY=WL, MOZ_ENABLE_WAYLAND="1", FONTCONFIG_FILE=os.environ.get("FONTCONFIG_FILE", ""))
class M:
    def __init__(s):
        for _ in range(360):   # (a fresh profile installs its extensions first)
            try: s.k = socket.create_connection(("127.0.0.1", MPORT), timeout=90); break
            except OSError: time.sleep(0.25)
        s.i = 0; s.recv()
        for t in range(40):   # (the port opens before the first window has its browser)
            try: s.cmd("WebDriver:NewSession", {"capabilities": {}}); break
            except RuntimeError:
                if t == 39: raise
                try: s.cmd("WebDriver:DeleteSession")   # (a failed start may still count as a session)
                except RuntimeError: pass
                time.sleep(0.5)
        s.cmd("Marionette:SetContext", {"value": "chrome"})
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
    def js(s, body):
        return s.cmd("WebDriver:ExecuteAsyncScript", {"script": "let done = arguments[arguments.length - 1];\n(async () => {\n" + body + "\n})().catch(e => done('ERR ' + e));", "args": [], "scriptTimeout": 60000})["value"]
    def quit(s):
        try: s.cmd("Marionette:Quit", {"flags": ["eAttemptQuit"]})
        except Exception: pass
R = {}
DM = None   # the driver, for diag() on a failure
def check(name, ok, detail):
    R[name] = ("PASS" if ok else "FAIL", detail); print(f"{'PASS' if ok else 'FAIL'}  {name}: {json.dumps(detail)[:900]}", flush=True)
    if not ok and DM: print("      chrome side: " + json.dumps(diag(DM))[:700], flush=True)
# Each page read from inside (a one-off frame script): Dark Reader's mark on it, its lock, the
# ground it shows — for the page and its frame; and the scheme the window tells it.
READ = r"""
  const FS = "data:application/javascript," + encodeURIComponent("(function(){function one(d){if(!d||!d.documentElement)return null;var b=d.body;return {mode:d.documentElement.getAttribute('data-darkreader-mode'),lock:!!d.querySelector('meta[name=\"darkreader-lock\"][data-golem]'),styles:d.querySelectorAll('.darkreader').length,bg:b?d.defaultView.getComputedStyle(b).backgroundColor:null,url:d.location.href};}var f=null;try{f=one(content.frames[0].document);}catch(e){}var sd=null,kd=null;try{sd=Services.cpmm.sharedData.get('golem:dw-rules');}catch(e){sd='ERR '+e;}try{kd=sendSyncMessage('golem:dw-kind');}catch(e){kd='ERR '+e;}sendAsyncMessage('rows:read',{page:one(content.document),frame:f,sd:sd,kind:kd});})();");
  const read = b => new Promise(res => { const mm = b.messageManager, l = { receiveMessage(m) { mm.removeMessageListener("rows:read", l); res(m.data); } };
    mm.addMessageListener("rows:read", l); mm.loadFrameScript(FS, false); setTimeout(() => res(null), 5000); });
  const out = {};
  for (let w of Services.wm.getEnumerator("navigator:browser")) {
    const k = w.document.documentElement.hasAttribute("taskbartab") ? "app" : "web", b = w.gBrowser.selectedBrowser;
    out[k] = await read(b);
    // (and the page as painted: a pixel of its ground, far from the text and the frame)
    if (out[k]) try { const bm = await b.browsingContext.currentWindowGlobal.drawSnapshot(new DOMRect(700, 400, 2, 2), 1, "rgb(255,0,255)");
      const c = w.document.createElementNS("http://www.w3.org/1999/xhtml", "canvas"); c.width = 2; c.height = 2; const x = c.getContext("2d"); x.drawImage(bm, 0, 0);
      const d = x.getImageData(0, 0, 1, 1).data; out[k].px = `rgb(${d[0]}, ${d[1]}, ${d[2]})`; } catch (e) { out[k].px = "ERR " + e; }
    if (out[k]) { out[k].scheme = b.browsingContext.prefersColorSchemeOverride; out[k].active = b.browsingContext.isActive; out[k].focused = Services.focus.activeWindow === w; }
  }
  done(out);
"""
def read(m): return m.js(READ)
# What the chrome side did (when a check fails): the rules shared with the pages, Dark Reader's state and stored sites.
DIAG = r"""
  const out = { rate: Services.prefs.getIntPref("layout.frame_rate", -9), shared: Services.ppmm.sharedData.get("golem:dw-rules") || null, fs: Services.mm.getDelayedFrameScripts().map(x => decodeURIComponent(x[0]).slice(40, 120)) };
  const { AddonManager } = ChromeUtils.importESModule("resource://gre/modules/AddonManager.sys.mjs");
  const a = await AddonManager.getAddonByID("addon@darkreader.org"); out.addon = a ? { active: a.isActive, userDisabled: a.userDisabled } : null;
  try { const pol = WebExtensionPolicy.getByID("addon@darkreader.org"); const SI = ChromeUtils.importESModule("resource://gre/modules/ExtensionStorageIDB.sys.mjs").ExtensionStorageIDB;
    const db = await SI.open(SI.getStoragePrincipal(pol.extension), pol.extension.hasPermission("unlimitedStorage"));
    const v = await db.get(["enabledByDefault", "enabledFor", "disabledFor", "theme"]); db.close();
    out.dr = { byDefault: v.enabledByDefault, for: (v.enabledFor || []).filter(h => h.indexOf("127.") === 0 || h.indexOf("open.") === 0), off: v.disabledFor, bg: v.theme && v.theme.darkSchemeBackgroundColor };
  } catch (e) { out.drErr = String(e); }
  done(out);
"""
def diag(m):
    try: return m.js(DIAG)
    except Exception as e: return f"(diag: {e})"
WHITE = "rgb(255, 255, 255)"
def summ(r):   # one line a window: page and frame (DR mode, lock, DR styles, ground), scheme, kind
    if not isinstance(r, dict): return r
    f = lambda p: p and f"{p['mode'] or '-'}/{'L' if p['lock'] else '-'}/{p['styles']}/{p['bg']}"
    return {k: f"page {f(v['page'])} frame {f(v['frame'])} painted {v.get('px')} scheme {v.get('scheme')} kind {v.get('kind')} active {v.get('active')}" for k, v in r.items() if v}
def coloured(p): return bool(p) and p["mode"] == "dynamic" and p["bg"] != WHITE and not p["lock"]
def plain(p): return bool(p) and p["mode"] is None and p["bg"] == WHITE and p["styles"] == 0
def both(r, kind, fn): return bool(r.get(kind)) and fn(r[kind]["page"]) and fn(r[kind]["frame"])
def until(m, want, secs=40):   # the state a change should end in, read until it holds (or the last read)
    t0 = time.time(); r = None
    while time.time() - t0 < secs:
        r = read(m)
        if isinstance(r, dict) and want(r): return r, round(time.time() - t0, 1)
        time.sleep(0.5)
    return r, None
def remote(m, *args):
    return m.js("""
  let cl = Cu.createCommandLine(%s, null, Ci.nsICommandLine.STATE_REMOTE_EXPLICIT);
  let ents = [...Services.catMan.enumerateCategory("command-line-handler")].sort((a, b) => a.entry < b.entry ? -1 : 1);
  for (let e of ents) { try { Cc[e.value].getService(Ci.nsICommandLineHandler).handle(cl); } catch (x) {} }
  done(1);""" % json.dumps(list(args)))
def sites(m, off, on):
    return m.js("Services.prefs.setStringPref('golem.seam.sites', %s); done(1);" % json.dumps(json.dumps({"off": off, "on": on})))

import atexit
@atexit.register
def _gone():   # every process on this profile goes (Firefox may have restarted itself into a new one)
    for pid in [d for d in os.listdir("/proc") if d.isdigit()]:
        try:
            if PROF.encode() in open(f"/proc/{pid}/cmdline", "rb").read(): os.kill(int(pid), 15)
        except Exception: pass
p = subprocess.Popen([f"{FARM}/firefox", *([] if WL else ["--headless"]), "--name", "seamrows", "--profile", PROF, "--marionette", "about:blank"],
                     env=ENV, stdout=subprocess.DEVNULL, stderr=open(f"{RUN}/ff.log", "a"))
m = M(); DM = m
# Dark Reader installs at a fresh profile's first start and colours with its own defaults until
# Seam has written the theme and restarted it: the pages load once that is done.
for _ in range(120):
    d = diag(m)
    if isinstance(d, dict) and (d.get("dr") or {}).get("bg") == "#1d2026" and (d.get("addon") or {}).get("active"): break
    time.sleep(0.5)
time.sleep(2)
m.js("for (let w of Services.wm.getEnumerator('navigator:browser')) w.gBrowser.selectedBrowser.loadURI(Services.io.newURI(%s), {triggeringPrincipal: Services.scriptSecurityManager.getSystemPrincipal()}); done(1);" % json.dumps(U("page")))
remote(m, "-golem-app", "rowsapp", U("page"))
try:
    # 1) Max's case: the web off, the apps on — the app coloured, the same site in Seam not.
    r, t = until(m, lambda r: both(r, "app", coloured) and both(r, "web", plain), 90)
    check("web off, apps on: the app coloured, Seam's tab not (page and frame)", t is not None, {"r": summ(r), "s": t})
    check("web off, apps on: Seam's tab carries the lock, the app's not", t is not None and r["web"]["page"]["lock"] and r["web"]["frame"]["lock"] and not r["app"]["page"]["lock"], r)
    check("web off, apps on: Seam's tab told no scheme, the app the dark", t is not None and r["web"]["scheme"] == "none" and r["app"]["scheme"] == "dark", {k: (v or {}).get("scheme") for k, v in (r or {}).items()})
    # 2) the drop puts the site in, in Seam: Seam's tab coloured (a restart); the app untouched.
    sites(m, [], ["127.0.0.1"])
    r, t = until(m, lambda r: both(r, "web", coloured) and both(r, "app", coloured))
    check("drop on in Seam (web off): Seam's tab coloured too, the app still", t is not None, {"r": summ(r), "s": t})
    # 3) the drop takes it out again: Seam's tab plain at once (no reload), the app still coloured.
    sites(m, [], [])
    r, t = until(m, lambda r: both(r, "web", plain) and both(r, "app", coloured))
    check("drop off in Seam: Seam's tab back to its own colours, the app keeps the palette", t is not None, {"r": summ(r), "s": t})
    # 4) a new page in Seam's tab with the web off: never coloured, from its first read.
    m.js("for (let w of Services.wm.getEnumerator('navigator:browser')) if (!w.document.documentElement.hasAttribute('taskbartab')) w.gBrowser.selectedBrowser.loadURI(Services.io.newURI(%s), {triggeringPrincipal: Services.scriptSecurityManager.getSystemPrincipal()}); done(1);" % json.dumps(U("page") + "?again"))
    seen = []
    for _ in range(16):
        x = read(m); s = isinstance(x, dict) and x.get("web") and x["web"]["page"]
        if s and s["url"].endswith("?again"): seen.append(s)
        time.sleep(0.25)
    check("a new page in Seam's tab (web off) is never coloured, from its first read", bool(seen) and all(s["mode"] is None and s["lock"] and s["styles"] == 0 for s in seen), seen[:2] + seen[-1:])
    # 5) the web on, the apps off: the other way round.
    theme(web=True, apps=False)
    r, t = until(m, lambda r: both(r, "web", coloured) and both(r, "app", plain))
    check("web on, apps off: Seam's tab coloured, the app not", t is not None, {"r": summ(r), "s": t})
    check("web on, apps off: the app carries the lock", t is not None and r["app"]["page"]["lock"], r)
    # 6) both on, the Apps page keeps the app in its own colours: only the app plain.
    theme(web=True, apps=True, web_skip=["127.0.0.1"])
    r, t = until(m, lambda r: both(r, "web", coloured) and both(r, "app", plain))
    check("Apps page keeps the app in its own colours: Seam's tab still coloured", t is not None, {"r": summ(r), "s": t})
    # 7) both on, the drop takes the site out in Seam: the app keeps the palette.
    theme(web=True, apps=True); sites(m, ["127.0.0.1"], [])
    r, t = until(m, lambda r: both(r, "web", plain) and both(r, "app", coloured))
    check("both on, drop off in Seam: only Seam's tab plain", t is not None, {"r": summ(r), "s": t})
    # 8) both on, nothing taken out: both coloured, no lock anywhere.
    sites(m, [], [])
    r, t = until(m, lambda r: both(r, "web", coloured) and both(r, "app", coloured))
    check("both on: both coloured, no lock", t is not None, {"r": summ(r), "s": t})
    # 9) both off: nothing coloured, nothing locked.
    theme(web=False, apps=False)
    r, t = until(m, lambda r: both(r, "web", plain) and both(r, "app", plain) and not r["web"]["page"]["lock"] and not r["app"]["page"]["lock"])
    check("both off: nothing coloured, no lock", t is not None, {"r": summ(r), "s": t})
finally:
    m.quit()
    try: p.wait(timeout=30)
    except Exception: p.kill()
fails = [k for k, v in R.items() if v[0] != "PASS"]
print(json.dumps({"ok": not fails, "checks": len(R), "fails": fails}))
if fails:
    try: print(open(f"{RUN}/ff.log").read()[-3000:])
    except Exception: pass
sys.exit(1 if fails else 0)
