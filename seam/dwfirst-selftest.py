#!/usr/bin/env python3
# dwfirst-selftest.py: Dark Reader on a FIRST START (golem-chrome.js, the dw section), headless,
# against a real Seam build. Run through webapps-selftest.sh dwfirst (it builds the farm). N new
# profiles, one after another: each must get our palette into Dark Reader within 60 s and keep
# it 8 s more. A first start is a race (Dark Reader installs, migrates its settings and restarts
# once, so the first write always fails): before 2026-10-28 the pause before the next try could
# be collected and never end, and that session kept Dark Reader's own defaults (6 of 20 on 158,
# 1 of 20 on 159). Env: DWN = how many starts (default 20).
import json, os, signal, socket, subprocess, sys, time, shutil, tempfile
FARM = os.environ["FARM"]; LDP = os.environ["LDP"]; CHROME = os.environ["CHROMEDIR"]
MPORT = 28292
N = int(os.environ.get("DWN", "20"))
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
        while b":" not in b:
            c = s.k.recv(1)
            if not c: raise RuntimeError("marionette socket closed")
            b += c
        n, d = b.split(b":", 1); n = int(n)
        while len(d) < n:
            c = s.k.recv(n - len(d))
            if not c: raise RuntimeError("marionette socket closed")
            d += c
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
DR = r"""
  const out = {};
  const { AddonManager } = ChromeUtils.importESModule("resource://gre/modules/AddonManager.sys.mjs");
  const a = await AddonManager.getAddonByID("addon@darkreader.org"); out.addon = a ? { active: a.isActive, userDisabled: a.userDisabled } : null;
  try { const pol = WebExtensionPolicy.getByID("addon@darkreader.org"); const SI = ChromeUtils.importESModule("resource://gre/modules/ExtensionStorageIDB.sys.mjs").ExtensionStorageIDB;
    const db = await SI.open(SI.getStoragePrincipal(pol.extension), pol.extension.hasPermission("unlimitedStorage"));
    const v = await db.get(null); db.close();
    out.keys = Object.keys(v).length; out.byDefault = v.enabledByDefault; out.bg = v.theme && v.theme.darkSchemeBackgroundColor; out.sync = v.syncSettings; out.scheme = v.schemeVersion; out.for = (v.enabledFor || []).length;
  } catch (e) { out.err = String(e).slice(0, 120); }
  done(out);
"""
def gone(prof):
    for pid in [d for d in os.listdir("/proc") if d.isdigit()]:
        try:
            if prof.encode() in open(f"/proc/{pid}/cmdline", "rb").read(): os.kill(int(pid), 15)
        except Exception: pass
fails = 0
for it in range(N):
    PROF = tempfile.mkdtemp(prefix="dwf-prof-"); os.makedirs(f"{PROF}/chrome"); os.makedirs(f"{PROF}/.config")
    for f in ("userChrome.css", "userContent.css"): shutil.copy(f"{CHROME}/{f}", f"{PROF}/chrome/{f}")
    open(f"{PROF}/user.js", "w").write("\n".join([
     'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);', f'user_pref("marionette.port", {MPORT});',
     'user_pref("browser.shell.checkDefaultBrowser", false);', 'user_pref("browser.aboutwelcome.enabled", false);',
     'user_pref("browser.startup.homepage_override.mstone", "ignore");', 'user_pref("datareporting.policy.dataSubmissionEnabled", false);', '']))
    STATE = f"{PROF}/.local/state"; os.makedirs(f"{STATE}/golem/theme")
    open(f"{STATE}/golem/theme/colors.json", "w").write(json.dumps(dict(dark=True, base01="#1d2026", base05="#e6e3dd", webapp_hosts=["127.0.0.1"], web=False, apps=True)))
    RUN = tempfile.mkdtemp(prefix="dwf-run-")
    ENV = dict(os.environ, HOME=PROF, XDG_CONFIG_HOME=f"{PROF}/.config", XDG_STATE_HOME=STATE, XDG_RUNTIME_DIR=RUN, LD_LIBRARY_PATH=LDP,
               MOZ_HEADLESS="1", MOZ_CRASHREPORTER_DISABLE="1", MOZ_LEGACY_PROFILES="1")
    t0 = time.time()
    p = subprocess.Popen([f"{FARM}/firefox", "--headless", "--name", "dwfirst", "--profile", PROF, "--marionette", "about:blank"],
                         env=ENV, stdout=subprocess.DEVNULL, stderr=open(f"{RUN}/ff.log", "a"))
    def _alarm(*_): raise TimeoutError("a start over 120 s")
    signal.signal(signal.SIGALRM, _alarm); signal.alarm(120)
    got = None; last = None; m = None
    try:
      m = M()
      while time.time() - t0 < 60:
        last = m.js(DR)
        if isinstance(last, dict) and last.get("bg") == "#1d2026" and (last.get("addon") or {}).get("active"): got = time.time() - t0; break
        time.sleep(0.5)
      # (a run that settled: does it hold? Dark Reader may write its own settings later)
      if got:
        time.sleep(8); last = m.js(DR)
        if not (isinstance(last, dict) and last.get("bg") == "#1d2026"): got = None
    except Exception as e:
      last = f"TEST: {e}"; got = None
    signal.alarm(0)
    ok = got is not None
    fails += not ok
    print(f"RUN {it+1}/{N} {'OK  ' if ok else 'FAIL'} settled={got and round(got,1)} final={json.dumps(last)}", flush=True)
    if m: m.quit()
    try: p.wait(timeout=20)
    except Exception: pass
    gone(PROF)
    for _ in range(40):   # (the next start must not meet this one's port)
        try: socket.create_connection(("127.0.0.1", MPORT), timeout=1).close(); time.sleep(0.5)
        except OSError: break
    shutil.rmtree(PROF, ignore_errors=True); shutil.rmtree(RUN, ignore_errors=True)
print(f"RESULT {N - fails}/{N} settled", flush=True)
sys.exit(1 if fails else 0)
