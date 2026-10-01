#!/usr/bin/env python3
# webapps-selftest.py: the WEBAPPS module (golem-chrome.js), headless, against a real Seam build.
# Run through webapps-selftest.sh (it builds the farm). No display, no user profile touched:
# a throwaway profile, a local http server, Marionette in chrome context. Headless Firefox
# does no remoting, so a second launch is dispatched in-process through the same
# command-line handlers (the remote path itself was proven live on 2026-09-30).
import json, os, socket, subprocess, sys, time, threading, http.server, functools, shutil, tempfile
FARM = os.environ["FARM"]; LDP = os.environ["LDP"]; CHROME = os.environ["CHROMEDIR"]
PORT = 38417; MPORT = 28290
W = tempfile.mkdtemp(prefix="wa-www-")
for n, t in [("app", "Spike App"), ("other", "Other Page"), ("two", "Second App"), ("plain", "Plain Page")]:
    open(f"{W}/{n}.html", "w").write(f"<html><head><title>{t}</title></head><body><h1>{t}</h1></body></html>")
# a page that shows its own visibility in its title (the focus-to-visibility bridge test)
open(f"{W}/slow.html", "w").write("<html><head><title>Slow Site Title</title></head><body>slow</body></html>")
open(f"{W}/vis.html", "w").write("<html><head><title>vis</title><script>function s(){document.title='vis:'+document.visibilityState}document.addEventListener('visibilitychange',s);s()</script></head><body>vis</body></html>")
class Q(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_GET(self):   # /slow*: a site that takes its time (the window must be named before it answers)
        if self.path.startswith("/slow"): time.sleep(3)
        return super().do_GET()
threading.Thread(target=http.server.ThreadingHTTPServer(("127.0.0.1", PORT), functools.partial(Q, directory=W)).serve_forever, daemon=True).start()
U = lambda n: f"http://127.0.0.1:{PORT}/{n}.html"
PROF = tempfile.mkdtemp(prefix="wa-prof-"); os.makedirs(f"{PROF}/chrome"); os.makedirs(f"{PROF}/.config")
open(f"{PROF}/.config/webapps.list", "w").write("# Name | URL | icon\n*Slow  App (Beta) | http://example.invalid | x\n")   # the dock's catalog: slug slow-app-beta
for f in ("userChrome.css", "userContent.css"): shutil.copy(f"{CHROME}/{f}", f"{PROF}/chrome/{f}")
open(f"{PROF}/user.js", "w").write("\n".join([
 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);', f'user_pref("marionette.port", {MPORT});',
 'user_pref("browser.shell.checkDefaultBrowser", false);', 'user_pref("browser.aboutwelcome.enabled", false);',
 'user_pref("browser.startup.homepage_override.mstone", "ignore");', 'user_pref("datareporting.policy.dataSubmissionEnabled", false);',
 'user_pref("browser.startup.page", 3);', 'user_pref("browser.sessionstore.resume_from_crash", true);', '']))
RUN = tempfile.mkdtemp(prefix="wa-run-")
ENV = dict(os.environ, HOME=PROF, XDG_CONFIG_HOME=f"{PROF}/.config", XDG_RUNTIME_DIR=RUN, LD_LIBRARY_PATH=LDP, MOZ_HEADLESS="1", MOZ_CRASHREPORTER_DISABLE="1", MOZ_LEGACY_PROFILES="1")
def ff(*args, wait=False):
    cmd = [f"{FARM}/firefox", "--headless", "--name", "seamtest", "--profile", PROF, *args]
    p = subprocess.Popen(cmd, env=ENV, stdout=subprocess.DEVNULL, stderr=open(f"{RUN}/ff.log", "a"))
    if wait: p.wait(timeout=30)
    return p
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
WINS = """
  let rows = [];
  for (let w of Services.wm.getEnumerator("navigator:browser")) {
    let r = w.document.documentElement, tb = w.document.getElementById("navigator-toolbox"), ts = w.document.getElementById("TabsToolbar");
    let id = r.getAttribute("taskbartab") || "";
    rows.push({ app: id.startsWith("golem-") ? id.slice(6) : null, cls: r.getAttribute("windowclass"), title: w.document.title,
                url: w.gBrowser.currentURI.spec, tabs: w.gBrowser.tabs.length,
                mode: w.gBrowser.selectedBrowser.browsingContext.displayMode,
                toolboxShown: !!(tb && tb.getBoundingClientRect().height > 0), tabstripShown: !!(ts && ts.getBoundingClientRect().height > 0) });
  }
"""
def wins(m): return m.js(WINS + "done(rows);")
TABS = """
  let tabs = [];
  for (let w of Services.wm.getEnumerator("navigator:browser")) for (let t of w.gBrowser.tabs) tabs.push({ app: (w.document.documentElement.getAttribute("taskbartab") || "").slice(6) || null, url: t.linkedBrowser.currentURI.spec });
"""
def tabs(m): return m.js(TABS + "done(tabs);")
APPWIN = 'let appw = s => [...Services.wm.getEnumerator("navigator:browser")].find(x => x.document.documentElement.getAttribute("taskbartab") == "golem-" + s);\n'
def appsjson():
    try: return json.load(open(f"{RUN}/seam/apps.json"))
    except Exception as e: return f"(none: {e.__class__.__name__})"
R = {}
def check(name, ok, detail): R[name] = ("PASS" if ok else "FAIL", detail); print(f"{'PASS' if ok else 'FAIL'}  {name}: {json.dumps(detail)[:300]}", flush=True)

MF = ["--marionette", "-remote-allow-system-access"]
def remote(m, *args):
    return m.js("""
  let cl = Cu.createCommandLine(%s, null, Ci.nsICommandLine.STATE_REMOTE_EXPLICIT);
  let ents = [...Services.catMan.enumerateCategory("command-line-handler")].sort((a, b) => a.entry < b.entry ? -1 : 1);
  for (let e of ents) { try { Cc[e.value].getService(Ci.nsICommandLineHandler).handle(cl); } catch (x) {} }
  done(ents.map(e => e.entry).slice(0, 4));""" % json.dumps(list(args)))

# 0) a browser session to defer: one normal window with the plain page
p = ff(*MF, U("plain")); m = M(); time.sleep(3)
w0 = wins(m); check("setup: one normal window", len(w0) == 1 and w0[0]["app"] is None, w0)
m.quit(); p.wait(timeout=30); time.sleep(1)

# 1) COLD START through the flag: the webapp alone, Firefox's web-app window, the session waits
p = ff(*MF, "-golem-app", "spikeapp", U("app")); m = M(); time.sleep(5)
w1 = wins(m); apps = [w for w in w1 if w["app"] == "spikeapp"]; a = apps[0] if apps else {}
check("cold start opens the webapp window (Firefox's taskbartab)", len(apps) == 1 and a["cls"] == "webapp-spikeapp" and a["url"] == U("app") and a["tabs"] == 1, w1)
check("cold start: the browser session waits for a normal window", all(w["app"] for w in w1), w1)
lin = m.js(APPWIN + 'let w = appw("spikeapp"); done(!!w && w.document.documentElement.id == "taskbartab-golem-spikeapp");')
check("the class comes from Firefox's own Linux branch (browser-init)", lin is True, lin)
top0 = m.js(APPWIN + 'let w = appw("spikeapp"); done(w.gBrowser.selectedBrowser.getBoundingClientRect().top);')
check("webapp: the page starts at the window's very top (no 1px separator under the title bar)", top0 == 0, top0)
check("webapp: page title, no toolbox, no tab strip, minimal-ui", a.get("title") == "Spike App" and a.get("toolboxShown") is False and a.get("tabstripShown") is False and a.get("mode") == "minimal-ui", a)
time.sleep(1); check("apps.json reports the webapp url", isinstance(appsjson(), dict) and appsjson().get("spikeapp", {}).get("url") == U("app"), appsjson())

# 2) relaunch, and a link into the webapp
remote(m, "-golem-app", "spikeapp", U("app")); time.sleep(2)
w2 = wins(m); check("relaunch at its start URL: one window, its page kept", [w["url"] for w in w2 if w["app"] == "spikeapp"] == [U("app")], w2)
remote(m, "-golem-app", "spikeapp", U("other")); time.sleep(2)
w2b = wins(m); check("a link opened in the webapp loads in its window", [w["url"] for w in w2b if w["app"] == "spikeapp"] == [U("other")], w2b)
# the dock's "new instance" (a box launch, a right-click): another window of the webapp
remote(m, "-golem-new", "-golem-app", "spikeapp", U("app")); time.sleep(3)
w2c = wins(m); sp = [w for w in w2c if w["app"] == "spikeapp"]
check("-golem-new opens another window of the running webapp", len(sp) == 2 and all(w["cls"] == "webapp-spikeapp" for w in sp), w2c)
m.js('let ws = [...Services.wm.getEnumerator("navigator:browser")].filter(x => x.document.documentElement.getAttribute("taskbartab") == "golem-spikeapp" && x.gBrowser.currentURI.spec == %s); ws.forEach(x => x.close()); done(ws.length);' % json.dumps(U("app"))); time.sleep(1.5)
w2d = wins(m); check("closing the extra window leaves the first", [w["url"] for w in w2d if w["app"] == "spikeapp"] == [U("other")], w2d)

# 3) another slug: its own window
remote(m, "-golem-app", "second", U("two")); time.sleep(3)
w3 = wins(m); check("a second webapp gets its own window + class", any(w["app"] == "second" and w["cls"] == "webapp-second" for w in w3), w3)
# the report keeps up after a webapp window closes (its debounce once ran on a window's
# timer, died with the closing window, and nothing was reported again)
m.js(APPWIN + 'appw("second").close(); done(1);'); time.sleep(1.5)
remote(m, "-golem-app", "third", U("two")); time.sleep(3)
rj = appsjson()
check("the report follows a close and the next webapp", isinstance(rj, dict) and "second" not in rj and "third" in rj and "spikeapp" in rj, rj)

# 4) a plain launch: a normal window, and the deferred session comes back into it
remote(m, U("other")); time.sleep(5)
t4 = tabs(m); w4 = wins(m)
check("a plain launch: a normal window with its toolbox", any(not w["app"] and w["toolboxShown"] for w in w4), w4)
check("the deferred session comes back in the normal window", any(t["url"] == U("plain") and not t["app"] for t in t4), t4)
top = m.js('const { BrowserWindowTracker } = ChromeUtils.importESModule("resource:///modules/BrowserWindowTracker.sys.mjs"); let t = BrowserWindowTracker.getTopWindow(); done(t ? t.document.documentElement.getAttribute("taskbartab") : "none");')
check("the top window for links is a normal window", top is None, top)
fromapp = m.js(APPWIN + 'let w = appw("spikeapp"); w.openTrustedLinkIn("' + U("two") + '?from-app", "tab"); await new Promise(z => w.setTimeout(z, 2500));'
               ' let inapp = w.gBrowser.tabs.length, elsewhere = 0;'
               ' for (let x of Services.wm.getEnumerator("navigator:browser")) if (x !== w) for (let t of x.gBrowser.tabs) if (t.linkedBrowser.currentURI.spec.includes("from-app")) elsewhere++;'
               ' done({ inapp, elsewhere });')
check("a new tab from a webapp opens in a normal window", isinstance(fromapp, dict) and fromapp["inapp"] == 1 and fromapp["elsewhere"] == 1, fromapp)

# 5) kill switch: the flag is consumed and the URL opens as a plain tab
m.js('Services.prefs.setBoolPref("golem.seam.apps", false); done(1);')
remote(m, "-golem-app", "killed", U("plain")); time.sleep(3)
w5 = wins(m); tb = tabs(m); plainTabs = sum(1 for t in tb if t["url"] == U("plain") and not t["app"])
check("kill switch: no webapp window, the URL opens as a normal tab", not any(w["app"] == "killed" for w in w5) and plainTabs >= 2, {"wins": w5, "plainTabs": plainTabs})
m.js('Services.prefs.clearUserPref("golem.seam.apps"); done(1);')

# 6) a permission prompt inside a webapp window (anchors to the address strip it hides)
perm = m.js(APPWIN + """
  let w = appw("spikeapp");
  w.focus(); await new Promise(r => w.setTimeout(r, 500));   // Firefox opens a prompt panel in the active window only
  w.gBrowser.selectedBrowser.messageManager.loadFrameScript("data:,content.navigator.geolocation.getCurrentPosition(function(){},function(){})", false);
  await new Promise(r => w.setTimeout(r, 2500));
  let pn = w.PopupNotifications, n = pn.getNotification("geolocation", w.gBrowser.selectedBrowser);
  let a = pn.panel.anchorNode, rect = a ? a.getBoundingClientRect() : null;
  done({ notification: !!n, panel: pn.panel.state, anchor: a ? (a.id || a.localName) : null, anchorSize: rect ? [Math.round(rect.width), Math.round(rect.height)] : null });
""")
check("a permission prompt opens in a webapp window", isinstance(perm, dict) and perm.get("notification") and perm.get("panel") in ("open", "showing"), perm)
after = m.js(APPWIN + """
  let w = appw("spikeapp");
  let r = w.document.documentElement, tb = () => w.document.getElementById("navigator-toolbox").getBoundingClientRect().height;
  let during = { attr: r.hasAttribute("golem-app-prompt"), toolboxH: tb() };
  let pnl = w.PopupNotifications.panel, n = pnl.firstElementChild;   // answer as a user would: Block
  (n.secondaryButton || n.querySelector(".popup-notification-secondary-button")).click(); await new Promise(z => w.setTimeout(z, 800));
  done({ during, after: { attr: r.hasAttribute("golem-app-prompt"), toolboxH: tb() } });
""")
check("the address strip shows during the prompt and hides after", isinstance(after, dict) and after["during"]["attr"] and after["during"]["toolboxH"] > 0 and not after["after"]["attr"] and after["after"]["toolboxH"] == 0, after)
# a notification shown DISMISSED is only the address bar's icon (Firefox's DRM notice on
# Spotify, Netflix...): no panel opens, so it must not raise the strip for good
dism = m.js(APPWIN + """
  let w = appw("spikeapp"), r = w.document.documentElement, b = w.gBrowser.selectedBrowser;
  w.PopupNotifications.show(b, "drmContentPlaying", "test", "eme-notification-icon", null, null, { dismissed: true, hideClose: true });
  await new Promise(z => w.setTimeout(z, 800));
  done({ shown: !!w.PopupNotifications.getNotification("drmContentPlaying", b), attr: r.hasAttribute("golem-app-prompt"),
         toolboxH: w.document.getElementById("navigator-toolbox").getBoundingClientRect().height });
""")
check("a dismissed notification (the DRM icon) leaves the strip hidden", isinstance(dism, dict) and dism["shown"] and not dism["attr"] and dism["toolboxH"] == 0, dism)

# 7) the focus-to-visibility bridge (Messenger's notifications): this test's host joins the list
m.js('Services.prefs.setStringPref("golem.seam.apps.visibilityHosts", "facebook.com messenger.com instagram.com 127.0.0.1"); done(1);')
remote(m, "-golem-app", "vis", U("vis")); time.sleep(3)
vis = m.js(APPWIN + """
  let w = appw("vis"), other = [...Services.wm.getEnumerator("navigator:browser")].find(x => !x.document.documentElement.hasAttribute("taskbartab"));
  let title = () => w.gBrowser.selectedBrowser.contentTitle;
  w.focus(); await new Promise(z => w.setTimeout(z, 1200)); let focusedT = title();
  other.focus(); await new Promise(z => w.setTimeout(z, 1200)); let blurredT = title();
  w.focus(); await new Promise(z => w.setTimeout(z, 1200)); let backT = title();
  done({ focusedT, blurredT, backT });
""")
check("a watched page reads hidden while its webapp is unfocused", isinstance(vis, dict) and vis["focusedT"] == "vis:visible" and vis["blurredT"] == "vis:hidden" and vis["backT"] == "vis:visible", vis)
m.js('Services.prefs.clearUserPref("golem.seam.apps.visibilityHosts"); done(1);')

# 7b) the window is named from its first frame: the catalog name until the page has a title,
# never Firefox's brand (Max, 2026-09-30: webapps opened as "Mozilla Firefox") nor "Seam"
named = m.js(APPWIN + """
  let seen = [], t0 = Date.now(), done2 = false;
  let rec = (w) => { let t = w.document.title; if (!seen.length || seen[seen.length - 1][1] !== t) seen.push([Date.now() - t0, t]); };
  // from the window's first painted frame: a title written before anything is on screen is never seen
  let obs = { observe(w) { w.addEventListener("MozAfterPaint", () => { rec(w); new w.MutationObserver(() => rec(w)).observe(w.document.documentElement, { subtree: true, childList: true, characterData: true }); }, { once: true }); } };
  Services.ww.registerNotification({ observe(s, topic) { if (topic === "domwindowopened" && !done2) obs.observe(s); } });
  let cl = Cu.createCommandLine(["-golem-app", "slow-app-beta", "%s"], null, Ci.nsICommandLine.STATE_REMOTE_EXPLICIT);
  for (let e of [...Services.catMan.enumerateCategory("command-line-handler")]) { try { Cc[e.value].getService(Ci.nsICommandLineHandler).handle(cl); } catch (x) {} }
  for (let i = 0; i < 60; i++) { let w = appw("slow-app-beta"); if (w) rec(w); await new Promise(r => setTimeout(r, 50)); }
  done2 = true;
  let other = [];   // a slug the catalog lacks: its words, capitalised
  let cl2 = Cu.createCommandLine(["-golem-app", "no-such-app", "%s?fresh"], null, Ci.nsICommandLine.STATE_REMOTE_EXPLICIT);
  for (let e of [...Services.catMan.enumerateCategory("command-line-handler")]) { try { Cc[e.value].getService(Ci.nsICommandLineHandler).handle(cl2); } catch (x) {} }
  await new Promise(r => setTimeout(r, 800)); let w2 = appw("no-such-app");
  let fb = w2 ? w2.document.title : null;
  let cl3 = Cu.createCommandLine(["-golem-app", "fast-app", "%s"], null, Ci.nsICommandLine.STATE_REMOTE_EXPLICIT);
  for (let e of [...Services.catMan.enumerateCategory("command-line-handler")]) { try { Cc[e.value].getService(Ci.nsICommandLineHandler).handle(cl3); } catch (x) {} }
  let early = [];
  for (let i = 0; i < 30; i++) { let w3 = appw("fast-app"); if (w3 && (!early.length || early[early.length - 1] !== w3.document.title)) early.push(w3.document.title); await new Promise(r => setTimeout(r, 50)); }
  done({ seen, fallback: fb, early });
""" % (U("slow"), U("slow"), U("two")))
titles = [t for _, t in (named or {}).get("seen", [])] if isinstance(named, dict) else []
check("a webapp window is named from its first frame, then takes the page's title", bool(titles) and titles[0] == "Slow App (Beta)" and titles[-1] == "Slow Site Title" and all(t in ("Slow App (Beta)", "Slow Site Title") for t in titles), named)
check("a titled page never reads 'Page — Mozilla Firefox' in a webapp window", isinstance(named, dict) and named.get("early") and not any("Firefox" in t or "Seam" in t for t in named["early"][1:]) and named["early"][-1] == "Second App", named)
check("a slug missing from the catalog is named from its words", isinstance(named, dict) and named.get("fallback") == "No Such App", named)

# 7c) a NORMAL window says Seam from its first painted frame, never Firefox (Max, 2026-09-30)
plainT = m.js("""
  let seen = [], t0 = Date.now(), watching = true, target = null;
  let rec = (w) => { let t = w.document.title; if (!seen.length || seen[seen.length - 1][1] !== t) seen.push([Date.now() - t0, t]); };
  Services.ww.registerNotification({ observe(w, topic) { if (topic !== "domwindowopened" || !watching || target) return; target = w;
    w.addEventListener("MozAfterPaint", () => { rec(w); new w.MutationObserver(() => rec(w)).observe(w.document.documentElement, { subtree: true, childList: true, characterData: true }); }, { once: true }); } });
  let top = [...Services.wm.getEnumerator("navigator:browser")].find(x => !x.document.documentElement.hasAttribute("taskbartab"));
  top.OpenBrowserWindow();
  await new Promise(r => setTimeout(r, 2500));
  watching = false; if (target) { rec(target); target.close(); }
  done({ seen });
""")
pt = [t for _, t in (plainT or {}).get("seen", [])] if isinstance(plainT, dict) else []
check("a normal window says Seam from its first painted frame, never Firefox", bool(pt) and not any("Firefox" in t for t in pt) and "Seam" in pt[0], plainT)

# 8) restart: webapps do not reopen (Firefox never saves a webapp window; Chrome's app
#    windows were not restored either); the browser's windows and tabs all come back
m.quit(); p.wait(timeout=30); time.sleep(1)
p = ff(*MF); m = M(); time.sleep(7)
w8 = wins(m); t8 = tabs(m)
check("after a restart no webapp window reopens", not any(w["app"] for w in w8), w8)
check("after a restart no browser tab is lost", sum(1 for t in t8 if t["url"] == U("plain")) >= 2 and any(t["url"] == U("other") for t in t8), t8)
m.quit(); p.wait(timeout=30)
fails = [k for k, v in R.items() if v[0] != "PASS"]
print("\nRESULT:", "ALL PASS" if not fails else f"{len(fails)} FAIL: {fails}")
sys.exit(1 if fails else 0)
