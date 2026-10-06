#!/usr/bin/env bash
# bench.sh — Seam vs stock Firefox, headless, same Mozilla binary, same measurement.
#   ./bench.sh [runs]        (default 5 runs per variant; prints medians)
# Variants:
#   stock  Mozilla firefox-bin 156.x as shipped: no policies, no prefs, no Golem layer
#   seam   the Seam build: policies (uBO, ATBC), user.js prefs, userChrome/Content, golem-chrome.js
# Both get the identical bench hook (bench-hook.js). Local corpus → no network noise.
# Each variant runs from a PRE-WARMED profile template (extensions installed once, untimed).
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd); seam=$(dirname "$here")
RUNS=${1:-5}
ver=$(grep -oE '"version": *"[^"]+"' "$seam/sources.json" | grep -oE '[0-9][0-9.]*[0-9]')
# default: the Seam this machine actually runs (its policies/prefs are what we measure); else the newest in the store
# (/etc/profiles on the host; from a toolbox the host's /etc is under /run/host/etc)
INSTALLED=""; for pf in /etc/profiles/per-user/$USER/bin/seam /run/host/etc/static/profiles/per-user/$USER/bin/seam; do
  d=$(readlink -f "$pf" 2>/dev/null || true); d=${d%/bin/seam}; [ -n "$d" ] && [ -f "$d/lib/firefox-bin-$ver/mozilla.cfg" ] && [ -x "$d/bin/firefox" ] && { INSTALLED=$d; break; }; done
SEAMBUILD=${SEAM_BUILD:-${INSTALLED:-$(for d in $(ls -dt /nix/store/*-seam-"$ver" /nix/store/*-firefox-"$ver" 2>/dev/null); do [ -f "$d/lib/firefox-bin-$ver/mozilla.cfg" ] && [ -x "$d/bin/firefox" ] && { echo "$d"; break; }; done)}}
STOCK=${STOCK_BUILD:-$(ls -d /nix/store/*-firefox-bin-unwrapped-"$ver" 2>/dev/null | head -1)}
[ -n "$SEAMBUILD" ] && [ -n "$STOCK" ] || { echo "need Seam + stock $ver builds in the store"; exit 2; }
LDP=$(strings "$SEAMBUILD/bin/firefox" | grep -oE "^LD_LIBRARY_PATH='[^']+'" | sed -E "s/^LD_LIBRARY_PATH='(.*)'/\1/" | sort -u | tr '\n' ':')
W=$(mktemp -d); trap 'for p in ${HTTPD:-} ${HTTPD2:-} ${PROXY:-}; do kill $p 2>/dev/null; done; chmod -R u+w "$W" 2>/dev/null; rm -rf "$W"' EXIT

# ---- corpus (deterministic) ----
C="$W/corpus"; mkdir -p "$C"
python3 - "$C" <<'PY'
import sys,os,random,zlib,struct
c=sys.argv[1]; random.seed(7)
def page(name,body,head=""): open(os.path.join(c,name),"w").write("<!doctype html><html><head><meta charset=utf-8>"+head+"</head><body>"+body+"</body></html>")
words=("lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore et dolore magna aliqua "*40).split()
para=lambda n:" ".join(random.choice(words) for _ in range(n))
page("p-text.html","".join("<p>"+para(120)+"</p>" for _ in range(400)))
page("p-dom.html","".join('<div class=c%d><span>%s</span><b>%d</b><i>x</i></div>'%(i%50,para(4),i) for i in range(12000)),
     "<style>"+"".join(".c%d{padding:%dpx;border:1px solid #%06x}"%(i,i%7,random.randrange(1<<24)) for i in range(50))+"</style>")
def png(w,h,rgb):
    raw=b"".join(b"\x00"+bytes(rgb)*w for _ in range(h))
    ch=lambda t,d: struct.pack(">I",len(d))+t+d+struct.pack(">I",zlib.crc32(t+d)&0xffffffff)
    return b"\x89PNG\r\n\x1a\n"+ch(b"IHDR",struct.pack(">IIBBBBB",w,h,8,2,0,0,0))+ch(b"IDAT",zlib.compress(raw))+ch(b"IEND",b"")
for k in range(60): open(os.path.join(c,"i%d.png"%k),"wb").write(png(160,120,(k*4%256,90,200-k*3%200)))
page("p-img.html","".join('<img src="i%d.png" width=160 height=120>'%k for k in range(60)))
page("p-css.html","".join('<div class=card>%s</div>'%para(30) for _ in range(1500)),
     "<style>.card{margin:8px;padding:12px;border-radius:12px;box-shadow:0 4px 18px rgba(0,0,0,.25);background:linear-gradient(135deg,#fafafa,#e0e7ff);transform:translateZ(0)}</style>")
page("p-long.html","<article>"+"".join("<h2>%s</h2><p>%s</p>"%(para(5),para(200)) for _ in range(250))+"</article>")
page("canary.html","<h1>ad/tracker canary</h1>"+"".join("<script async src='%s'></script>"%u for u in [
  "https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js","https://securepubads.g.doubleclick.net/tag/js/gpt.js",
  "https://www.googletagmanager.com/gtag/js?id=G-TEST123","https://www.google-analytics.com/analytics.js",
  "https://connect.facebook.net/en_US/fbevents.js","https://static.criteo.net/js/ld/publishertag.js",
  "https://c.amazon-adsystem.com/aax2/apstag.js","https://cdn.taboola.com/libtrc/test/loader.js",
  "https://widgets.outbrain.com/outbrain.js","https://sb.scorecardresearch.com/beacon.js"]))
page("c-src.html","<a id=l style='position:absolute;left:0;top:0;width:400px;height:200px;display:block;background:#ccd' href='#'>go</a><script>document.getElementById('l').href=new URLSearchParams(location.search).get('d')</script>")
# back-button corpus: kinds of pages that do / don't survive in the back-forward cache
page("b-plain.html","<h1>plain</h1>"+"".join("<p>"+para(80)+"</p>" for _ in range(60)))
page("b-unload.html","<h1>unload handler</h1>"+"".join("<p>"+para(80)+"</p>" for _ in range(60))+"<script>addEventListener('unload',function(){})</script>")
page("b-beforeunload.html","<h1>beforeunload handler</h1>"+"".join("<p>"+para(80)+"</p>" for _ in range(60))+"<script>addEventListener('beforeunload',function(){})</script>")
page("b-nostore.html","<h1>no-store</h1>"+"".join("<p>"+para(80)+"</p>" for _ in range(60)))
page("b-heavy.html","".join('<div class=c%d><span>%s</span><b>%d</b></div>'%(i%50,para(4),i) for i in range(20000))+"<script>addEventListener('unload',function(){})</script>",
     "<style>"+"".join(".c%d{padding:%dpx;border:1px solid #%06x}"%(i,i%7,random.randrange(1<<24)) for i in range(50))+"</style>")
page("b-next.html","<h1>next page</h1><p>"+para(40)+"</p>")
page("p-scroll.html","<header style='position:sticky;top:0;height:60px;background:#c02b3b'></header>"+
     "".join("<section style='height:420px;margin:10px;border-radius:14px;box-shadow:0 6px 24px rgba(0,0,0,.3);background:linear-gradient(%ddeg,#%06x,#%06x)'><p>%s</p></section>"%(i*7%360,random.randrange(1<<24),random.randrange(1<<24),para(60)) for i in range(160)))
PY
port=$(( 39000 + $$ % 900 ))
# realistic server: threaded + HTTP/1.1 keep-alive (python's default http.server is HTTP/1.0,
# one connection per request — not what real sites run; BENCH_SERVER=simple restores it)
if [ "${BENCH_SERVER:-keepalive}" = simple ]; then
  python3 -m http.server "$port" --bind 127.0.0.1 --directory "$C" >/dev/null 2>&1 & HTTPD=$!
else
  # click mode on a real interface (Firefox never preconnects to loopback): serve on all interfaces
  python3 - "$port" "$C" ${BENCH_CLICK_HOST:+dual} >/dev/null 2>&1 <<'PYS' & HTTPD=$!
import sys,functools,http.server
import re,time,os
class H(http.server.SimpleHTTPRequestHandler):
    protocol_version="HTTP/1.1"
    def log_message(self,*a): pass
    def do_GET(self):
        m=re.match(r"^/slow(\d+)(/.*)$",self.path)
        if m: time.sleep(int(m.group(1))/1000); self.path=m.group(2)
        return super().do_GET()
    def do_HEAD(self):
        m=re.match(r"^/slow(\d+)(/.*)$",self.path)
        if m: self.path=m.group(2)
        return super().do_HEAD()
    def end_headers(self):
        if "nostore" in self.path: self.send_header("Cache-Control","no-store")
        elif os.environ.get("BENCH_FRESH_S"): self.send_header("Cache-Control","max-age="+os.environ["BENCH_FRESH_S"])
        super().end_headers()
import socket
class S(http.server.ThreadingHTTPServer):
    address_family=socket.AF_INET6 if len(sys.argv)>3 else socket.AF_INET
    def server_bind(self):
        if self.address_family==socket.AF_INET6: self.socket.setsockopt(socket.IPPROTO_IPV6,socket.IPV6_V6ONLY,0)
        super().server_bind()
S(("::" if len(sys.argv)>3 else "127.0.0.1",int(sys.argv[1])),functools.partial(H,directory=sys.argv[2])).serve_forever()
PYS
fi
sleep 0.5; BASE="http://127.0.0.1:$port"
if [ -n "${BENCH_CLICK:-}" ]; then
  bport=$port; pxbase=$((port+10))   # the proxy's backend is the keep-alive server (it knows /slow<ms>/ think-time paths)
  NK=$(( $(echo "${BENCH_CLICK_KINDS:-hover,click}" | tr ',' '\n' | wc -l) )); python3 - "$pxbase" "$((BENCH_CLICK*NK))" "$bport" "${BENCH_PROXY_DELAY:-150}" "$W/proxy.log" >/dev/null 2>&1 <<'PYP' & PROXY=$!
import asyncio,sys,time
base,n,back,delay,log=int(sys.argv[1]),int(sys.argv[2]),int(sys.argv[3]),int(sys.argv[4])/1000,sys.argv[5]
async def pipe(r,w):
    try:
        while (d:=await r.read(65536)): w.write(d); await w.drain()
    except Exception: pass
    finally:
        try: w.close()
        except Exception: pass
def mk(p):
    async def h(cr,cw):
        cid=id(cw); open(log,"a").write(f"{time.time():.3f} accept {p} c{cid%1000}\n")
        await asyncio.sleep(delay)
        async def first():
            d=await cr.read(65536); open(log,"a").write(f"{time.time():.3f} data   {p} c{cid%1000} {d[:40]!r}\n"); return d
        d0=await first()
        br,bw=await asyncio.open_connection("127.0.0.1",back)
        if d0: bw.write(d0); await bw.drain()
        await asyncio.gather(pipe(cr,bw),pipe(br,cw))
    return h
async def main():
    ss=[await asyncio.start_server(mk(base+i),None,base+i) for i in range(n)]
    await asyncio.gather(*(s.serve_forever() for s in ss))
asyncio.run(main())
PYP
  sleep 0.5
fi

# ---- build a runnable copy of a variant's lib dir with our mozilla.cfg ----
mkfarm(){ # mkfarm <libdir> <out> <cfg-body-file|""> <needs-autoconfig>
  local L=$1 T=$2
  mkdir -p "$T"; cp -rs "$L/." "$T/"; chmod -R u+w "$T"
  rm -f "$T/firefox" "$T/firefox-bin" "$T/mozilla.cfg"; cp -L "$L/firefox" "$L/firefox-bin" "$T/"
  if [ "$4" = 1 ]; then mkdir -p "$T/defaults/pref"; rm -f "$T/defaults/pref/zz-bench.js"
    printf 'pref("general.config.filename","mozilla.cfg");\npref("general.config.obscure_value",0);\npref("general.config.sandbox_enabled",false);\n' > "$T/defaults/pref/zz-bench.js"; fi
  { if [ -n "$3" ]; then cat "$3"; else echo "// stock: bench hook only"; fi; cat "$here/bench-hook.js"; } > "$T/mozilla.cfg"
}
BL="$SEAMBUILD/lib/firefox-bin-$ver"; SL="$STOCK/lib/firefox-bin-$ver"
first=$(grep -n -m1 'GOLEM chrome script' "$BL/mozilla.cfg" | cut -d: -f1)
head -n $((first-2)) "$BL/mozilla.cfg" > "$W/seam.cfg"; cat "$seam/golem-chrome.js" >> "$W/seam.cfg"
SET=${BENCH_SET:-stock seam}
if [ -n "${BENCH_ALT_SCRIPT:-}" ]; then head -n $((first-2)) "$BL/mozilla.cfg" > "$W/seam-alt.cfg"; cat "$BENCH_ALT_SCRIPT" >> "$W/seam-alt.cfg"; fi
head -n $((first-2)) "$BL/mozilla.cfg" > "$W/seam-nocfg.cfg"   # wrapper header only, no Golem script
CHROME_BIN=${CHROME_BIN:-$(for d in /nix/store/*-google-chrome-1*/; do echo "$(basename "$d" | sed 's/.*google-chrome-//') $d"; done | sort -V | tail -1 | cut -d' ' -f2)bin/google-chrome-stable}
for v in $SET; do case $v in
  chrome) [ -x "$CHROME_BIN" ] || { echo "no Chrome found"; exit 2; }; echo "chrome=$CHROME_BIN" ;;
  stock) mkfarm "$SL" "$W/stock" "" 1 ;;
  seam|seam-noprefs|seam-nocss|seam-drop-*|seam-paint) mkfarm "$BL" "$W/$v" "$W/seam.cfg" 0 ;;
  seam-alt) mkfarm "$BL" "$W/$v" "$W/seam-alt.cfg" 0 ;;
  seam-noscript) mkfarm "$BL" "$W/$v" "$W/seam-nocfg.cfg" 0 ;;
  seam-prefetch|seam-alt-prefetch)
    # uBO's "Disable pre-fetching" (default ON) sets networkPredictionEnabled=false, i.e.
    # network.http.speculative-parallel-limit=0: no preconnect of ANY kind. This variant turns it off.
    if [ $v = seam-alt-prefetch ]; then mkfarm "$BL" "$W/$v" "$W/seam-alt.cfg" 0; else mkfarm "$BL" "$W/$v" "$W/seam.cfg" 0; fi
    rm -f "$W/$v/distribution/policies.json"
    python3 - "$BL/distribution/policies.json" "$W/$v/distribution/policies.json" <<'PY4'
import json,sys
p=json.load(open(sys.argv[1]))
# uBO managed storage: "userSettings" is a TOP-LEVEL key of its policy (not inside adminSettings)
e=p["policies"].setdefault("3rdparty",{}).setdefault("Extensions",{}).setdefault("uBlock0@raymondhill.net",{})
e.setdefault("userSettings",[]).append(["prefetchingDisabled","false"])
json.dump(p,open(sys.argv[2],"w"))
PY4
    ;;
  seam-ubolite)
    # uBO with "Ignore generic cosmetic filters" (uBO docs: reduces CPU + memory; network blocking unchanged)
    mkfarm "$BL" "$W/$v" "$W/seam.cfg" 0; rm -f "$W/$v/distribution/policies.json"
    python3 - "$BL/distribution/policies.json" "$W/$v/distribution/policies.json" <<'PY3'
import json,sys
p=json.load(open(sys.argv[1]))
e=p["policies"].setdefault("3rdparty",{}).setdefault("Extensions",{}).setdefault("uBlock0@raymondhill.net",{}).setdefault("adminSettings",{})
us=e.setdefault("userSettings",[]); us.append(["ignoreGenericCosmeticFilters","true"])
json.dump(p,open(sys.argv[2],"w"))
PY3
    ;;
  seam-noatbc|seam-noubo|seam-noext)
    mkfarm "$BL" "$W/$v" "$W/seam.cfg" 0
    drop=""; case $v in seam-noatbc) drop='"ATBC@EasonWong"';; seam-noubo) drop='"uBlock0@raymondhill.net"';; seam-noext) drop='"ATBC@EasonWong","uBlock0@raymondhill.net"';; esac
    rm -f "$W/$v/distribution/policies.json"
    python3 - "$BL/distribution/policies.json" "$W/$v/distribution/policies.json" "$drop" <<'PY2'
import json,sys
p=json.load(open(sys.argv[1])); drop=json.loads("["+sys.argv[3]+"]")
es=p["policies"].get("ExtensionSettings",{})
for d in drop: es.pop(d,None)
json.dump(p,open(sys.argv[2],"w"))
PY2
    ;;
esac; done

# ---- profile templates ----
python3 - "$seam/home.nix" "$W/seam-user.js" <<'PY'
import sys,re
s=open(sys.argv[1]).read(); a=s.index('user.js".text = \'\'')+len('user.js".text = \'\'')
b=s.index("\n  '';",a); body=s[a:b].strip("\n")
# display/GPU prefs are tuned for the real 165Hz Wayland panel; headless has no GPU (SWGL),
# they break its framebuffer and 165Hz makes frame times incomparable to stock's 60Hz.
# Stripped HERE ONLY — reported as "tuned on real hardware, not measured by this harness".
HW=("layout.frame_rate","gfx.webrender.picture-tile-height","widget.wayland.fractional-scale.enabled","widget.wayland.vsync.enabled","gfx.webrender.max-partial-present-rects")
lines=[l[4:] if l.startswith("    ") else l for l in body.split("\n")]
open(sys.argv[2],"w").write("\n".join(l for l in lines if not any('"'+p+'"' in l for p in HW))+"\n")
PY
prefgroup(){ case $1 in   # regex of pref names per group (for seam-drop-<group>)
  scroll) echo '"(general\.smoothScroll|apz\.|mousewheel\.)';;
  media) echo '"media\.(ffmpeg|eme|gmp|hevc)';;
  cache) echo '"(accessibility\.force_disabled|browser\.cache\.|browser\.sessionstore\.interval|browser\.sessionhistory\.|media\.memory_cache)';;
  net) echo '"network\.(http|dns|connectivity)';;
  net-conn) echo '"network\.http\.max-persistent-connections-per-server';;
  net-pacing) echo '"network\.http\.pacing';;
  net-dnsent) echo '"network\.dnsCacheEntries';;
  net-dnsexp) echo '"network\.dnsCacheExpiration';;
  net-connsvc) echo '"network\.connectivity-service';;
  ui) echo '"(identity\.|browser\.uiCustomization|sidebar\.|browser\.toolbars|browser\.download\.autohide)';;
  etp) echo '"(browser\.contentblocking|network\.cookie|privacy\.)';;
  https) echo '"dom\.security\.https_only';;
  misc) echo '"(media\.peerconnection|toolkit\.telemetry|datareporting|browser\.newtabpage|app\.shield|browser\.discovery|browser\.urlbar\.suggest|extensions\.pocket|browser\.startup|browser\.sessionstore\.resume)';;
esac; }
mkprof(){ # mkprof <variant> <dir>
  mkdir -p "$2"; case $1 in stock) return;; esac
  case $1 in seam-drop-*) g=${1#seam-drop-}; grep -vE "$(prefgroup "$g")" "$W/seam-user.js" > "$2/user.js";; seam-noprefs) ;; *) cp "$W/seam-user.js" "$2/user.js";; esac
  [ -n "${BENCH_THUMBS:-}" ] && cp "$BENCH_THUMBS" "$2/golem-thumbs.json"
  [ "$1" = seam-paint ] && printf '%s\n' "${BENCH_PAINT_PREFS:-}" >> "$2/user.js"
  # click mode on public (IPv6) test addresses: the local server speaks plain http, so HTTPS-only
  # would upgrade and fail; off for BOTH variants of this test only
  [ -n "${BENCH_CLICK_HOST:-}" ] && echo 'user_pref("dom.security.https_only_mode", false);' >> "$2/user.js"
  [ "$1" = seam-nocss ] || { mkdir -p "$2/chrome"; cp "$seam/userChrome.css" "$seam/userContent.css" "$2/chrome/"; } }
run(){ # run <variant> <profile> <out|"">  (out empty = warm-up)
  local farm="$W/$1" out=${3:-}
  if [ "$1" = chrome ]; then   # Chrome driven over CDP, same sequence as the hook's sites mode
    local port=$(( 9600 + RANDOM % 300 ))
    HOME="$2" timeout ${BENCH_TIMEOUT:-120} "$CHROME_BIN" --headless=new --no-first-run --no-default-browser-check --user-data-dir="$2/ud" --remote-debugging-port=$port about:blank >"$2.log" 2>&1 & local cpid=$!
    for i in $(seq 50); do curl -s "http://127.0.0.1:$port/json/version" >/dev/null && break; sleep 0.2; done
    [ -n "$out" ] && SEAM_BENCH_SETTLE="${BENCH_SETTLE:-}" /usr/bin/node "$here/cdp-driver.mjs" $port "$out" "$here/proctree.py" $cpid "${BENCH_URLS//@LOCAL@/$BASE}" >>"$2.log" 2>&1 || sleep 8
    kill $cpid 2>/dev/null || true; wait $cpid 2>/dev/null || true; return 0
  fi
  if [ -n "${BENCH_URLS:-}" ] && [ -n "$out" ]; then   # Seam/stock in sites mode: same external meter as Chrome
    HOME="$2" XDG_CACHE_HOME="$2/.cache" LD_LIBRARY_PATH="$LDP" MOZ_HEADLESS=1 MOZ_CRASHREPORTER_DISABLE=1 MOZ_LEGACY_PROFILES=1 \
    SEAM_BENCH="$out" SEAM_BENCH_HTTP="$BASE" SEAM_BENCH_URLS="${BENCH_URLS//@LOCAL@/$BASE}" SEAM_BENCH_SETTLE="${BENCH_SETTLE:-}" \
      timeout ${BENCH_TIMEOUT:-120} "$farm/firefox" --headless --no-remote -profile "$2" about:blank >"$2.log" 2>&1 & local fpid=$!
    local p0="" p1=""
    while kill -0 $fpid 2>/dev/null; do
      st=$(grep -o '"stage":"[a-z-]*"' "$out" 2>/dev/null | tail -1 || true)
      if [ -z "$p0" ] && [ "$st" = '"stage":"sites-start"' ]; then p0=$(python3 "$here/proctree.py" $fpid); fi
      if [ -z "$p1" ] && [ "$st" = '"stage":"measure"' ]; then p1=$(python3 "$here/proctree.py" $fpid); fi
      sleep 0.1
    done
    if [ -n "$p0" ] && [ -n "$p1" ]; then python3 - "$out" "$p0" "$p1" <<'PYE'
import json,sys
r=json.load(open(sys.argv[1])); a=json.loads(sys.argv[2]); b=json.loads(sys.argv[3])
r["ext"]={"cpuMs":b["cpuMs"]-a["cpuMs"],"anonMB":b["anonMB"],"rssMB":b["rssMB"],"procs":b["procs"]}
json.dump(r,open(sys.argv[1],"w"))
PYE
    fi
    return 0
  fi
  HOME="$2" XDG_CACHE_HOME="$2/.cache" LD_LIBRARY_PATH="$LDP" MOZ_HEADLESS=1 MOZ_CRASHREPORTER_DISABLE=1 MOZ_LEGACY_PROFILES=1 \
  SEAM_BENCH="$out" SEAM_BENCH_HTTP="$BASE" SEAM_BENCH_RESTORE="${SEAM_BENCH_RESTORE:-}" SEAM_BENCH_BACK="${BENCH_BACK:-}" SEAM_BENCH_QUICK="${BENCH_QUICK:-}" SEAM_BENCH_URLS="${BENCH_URLS:+${BENCH_URLS//@LOCAL@/$BASE}}" SEAM_BENCH_SWITCH="${BENCH_SWITCH:-}" SEAM_BENCH_CLICK="${BENCH_CLICK:-}" SEAM_BENCH_SLOW_MS="${BENCH_SLOW_MS:-}" SEAM_BENCH_HOVER_MS="${BENCH_HOVER_MS:-}" SEAM_BENCH_CLICK_KINDS="${BENCH_CLICK_KINDS:-}" SEAM_BENCH_PROXY="${pxbase:-}" SEAM_BENCH_CLICKHOST="${BENCH_CLICK_HOST:-}" SEAM_BENCH_CLICKHOST2="${BENCH_CLICK_HOST2:-}" \
    timeout ${BENCH_TIMEOUT:-120} "$farm/firefox" --headless --no-remote -profile "$2" ${out:+about:blank} >"$2.log" 2>&1 || true
  [ -n "${BENCH_DEBUG:-}" ] && [ -n "$out" ] && { echo "--- $1 partial: $(cat "$out" 2>/dev/null || echo none)"; } || true
  [ -n "${BENCH_DEBUG:-}" ] && { echo "--- $1 stderr tail ---"; grep -vE "Fontconfig|^\s*$" "$2.log" | tail -15; } || true
}
for v in $SET; do
  if [ $v = chrome ]; then mkdir -p "$W/tpl-chrome"; run chrome "$W/tpl-chrome" ""; echo "chrome template ready"; continue; fi
  mkprof $v "$W/tpl-$v"
  # warm-up: first run installs policy extensions etc.; quit after 25s (untimed)
  ( HOME="$W/tpl-$v" LD_LIBRARY_PATH="$LDP" MOZ_HEADLESS=1 MOZ_CRASHREPORTER_DISABLE=1 MOZ_LEGACY_PROFILES=1 \
    timeout ${BENCH_WARMUP:-25} "$W/$v/firefox" --headless --no-remote -profile "$W/tpl-$v" about:blank >/dev/null 2>&1 || true )
  echo "$v template extensions: $(ls "$W/tpl-$v/extensions" 2>/dev/null | tr '\n' ' ')"
done
echo "note: seam display/GPU prefs (frame_rate 165, wayland vsync/fractional-scale, webrender tiling) are stripped — headless has no GPU; they are tuned on real hardware"
echo "stock=$STOCK"; echo "seam=$SEAMBUILD (script: $seam/golem-chrome.js)"
: > "$W/results.jsonl"
if [ -n "${BENCH_RESTORE:-}" ]; then   # seed a session, quit normally, restart the SAME profile, see what loaded
  for v in $SET; do P="$W/p-$v-rs"; cp -r "$W/tpl-$v" "$P"
    BENCH_TIMEOUT=60 SEAM_BENCH_RESTORE=seed run $v "$P" "$W/rs-seed-$v.json"
    SEAM_BENCH_RESTORE=check run $v "$P" "$W/rs-$v.json"
    echo "== $v after restart (20s):"; python3 -c "
import json,sys
r=json.load(open(sys.argv[1]))
for t in sorted(r.get('restore',[]),key=lambda t:-t['lastAccessed']): print('   %-16s %s' % (t['url'][-16:], 'SELECTED' if t['selected'] else ('unloaded' if t['pending'] else 'LOADED')))
" "$W/rs-$v.json" 2>/dev/null || echo "   no result: $(cat "$W/rs-$v.json" 2>/dev/null | head -c 300)"
  done; exit 0
fi
for r in $(seq 1 "$RUNS"); do for v in $SET; do
  P="$W/p-$v-$r"; cp -r "$W/tpl-$v" "$P"; run $v "$P" "$W/r-$v-$r.json"
  [ -f "$W/r-$v-$r.json" ] && { printf '{"variant":"%s","run":%d,"r":' $v $r; cat "$W/r-$v-$r.json"; echo '}'; } >> "$W/results.jsonl" || echo "  $v run $r: NO RESULT"
  [ -n "${BENCH_DEBUG:-}" ] || rm -rf "$P"
done; done
python3 - "$W/results.jsonl" <<'PY'
import json,sys,statistics as st
rows=[json.loads(l) for l in open(sys.argv[1]) if l.strip()]
def med(v,f):
    xs=[f(r["r"]) for r in rows if r["variant"]==v]; xs=[x for x in xs if x is not None]
    return round(st.median(xs),1) if xs else None
M=[("startup: first paint ms",lambda r:r["startup"].get("firstPaintMs")),
   ("startup: window ready ms",lambda r:r["startup"].get("delayedStartupMs")),
   ("load p-text ms",lambda r:next((l["ms"] for l in r["loads"] if l["page"]=="p-text"),None)),
   ("load p-dom ms",lambda r:next((l["ms"] for l in r["loads"] if l["page"]=="p-dom"),None)),
   ("load p-img ms",lambda r:next((l["ms"] for l in r["loads"] if l["page"]=="p-img"),None)),
   ("load p-css ms",lambda r:next((l["ms"] for l in r["loads"] if l["page"]=="p-css"),None)),
   ("load p-long ms",lambda r:next((l["ms"] for l in r["loads"] if l["page"]=="p-long"),None)),
   ("memory after loads MB",lambda r:r.get("memAfterLoads",{}).get("memMB")),
   ("processes",lambda r:r.get("memAfterLoads",{}).get("procs")),
   ("scroll frame p50 ms",lambda r:(r.get("scroll") or {}).get("p50")),
   ("scroll frame p95 ms",lambda r:(r.get("scroll") or {}).get("p95")),
   ("scroll janky frames (>25ms)",lambda r:(r.get("scroll") or {}).get("janky")),
   ("scroll CPU ms (all procs)",lambda r:(r.get("scroll") or {}).get("cpuMs")),
   ("scroll CPU ms: browser UI proc",lambda r:(r.get("scroll") or {}).get("parentMs")),
   ("scroll CPU ms: page procs",lambda r:(r.get("scroll") or {}).get("webMs")),
   ("scroll CPU ms: extension proc",lambda r:(r.get("scroll") or {}).get("extMs")),
   ("scroll: theme writes on UI",lambda r:(r.get("scroll") or {}).get("rootWrites")),
   ("scroll: UI thread blocked ms",lambda r:(r.get("scroll") or {}).get("uiBlockedMs"))]
V=[]; [V.append(r["variant"]) for r in rows if r["variant"] not in V]
print("\n"+f"{'metric (median)':30}"+"".join(f"{v:>13}" for v in V))
print(f"{'runs':30}"+"".join(f"{sum(1 for r in rows if r['variant']==v):>13}" for v in V))
for name,f in M:
    print(f"{name:30}"+"".join(f"{str(med(v,f)):>13}" for v in V))
PY
if [ -n "${BENCH_BACK:-}" ]; then python3 - "$W/results.jsonl" <<'PYB'
import json,sys,statistics as st
rows=[json.loads(l) for l in open(sys.argv[1]) if l.strip()]
V=[]; [V.append(r["variant"]) for r in rows if r["variant"] not in V]
kinds=[]; [kinds.append(b["page"]) for r in rows for b in r["r"].get("back",[]) if b["page"] not in kinds]
print("\n== BACK button: ms until the previous page is showing (median)  [c = served from the back-forward cache] ==\n"+f"{'page':22}"+"".join(f"{v:>16}" for v in V))
for k in kinds:
    cells=[]
    for v in V:
        bs=[b for r in rows if r["variant"]==v for b in r["r"].get("back",[]) if b["page"]==k and b["ms"]>=0]
        if not bs: cells.append(f"{'fail':>16}"); continue
        c=sum(1 for b in bs if b.get("persisted")); cells.append(f"{str(round(st.median([b['ms'] for b in bs])))+' ('+str(c)+'/'+str(len(bs))+'c)':>16}")
    print(f"{k:22}"+"".join(cells))
PYB
fi
if [ -n "${BENCH_CLICK:-}" ]; then python3 - "$W/results.jsonl" <<'PYC'
import json,sys,statistics as st
rows=[json.loads(l) for l in open(sys.argv[1]) if l.strip()]
V=[]; [V.append(r["variant"]) for r in rows if r["variant"] not in V]
print(f"\n== link click -> page loaded, ms (proxy delays every NEW connection) ==\n"+f"{'metric':40}"+"".join(f"{v:>12}" for v in V))
for kind,lab in (("hover","same-site link, hovered, click"),("click","cross-site link, instant click"),("visit","same-site, visited before, click"),("fetch","same-site, page fetch()ed it, click")):
    if not any(c["kind"]==kind for r in rows for c in r["r"].get("clicks",[])): continue
    for agg,f in (("median",st.median),("min",min),("max",max)):
        xs={v:[c["ms"] for r in rows if r["variant"]==v for c in r["r"].get("clicks",[]) if c["kind"]==kind and c["ms"]>=0] for v in V}
        print(f"{lab+' '+agg:40}"+"".join(f"{str(round(f(xs[v])) if xs[v] else None):>12}" for v in V))
    fails={v:sum(1 for r in rows if r["variant"]==v for c in r["r"].get("clicks",[]) if c["kind"]==kind and c["ms"]<0) for v in V}
    print(f"{lab+' failed':40}"+"".join(f"{fails[v]:>12}" for v in V))
    fc={v:[c.get("servedFromCache",0) for r in rows if r["variant"]==v for c in r["r"].get("clicks",[]) if c["kind"]==kind] for v in V}
    rq={v:[len([q for q in c.get("requests",[]) if q["t"]>=0 and not q["purpose"]]) for r in rows if r["variant"]==v for c in r["r"].get("clicks",[]) if c["kind"]==kind] for v in V}
    print(f"{lab+' served from cache (trials)':40}"+"".join(f"{sum(1 for x in fc[v] if x)}/{len(fc[v])}".rjust(12) for v in V))
    print(f"{lab+' network requests at click':40}"+"".join(f"{sum(rq[v])}".rjust(12) for v in V))
PYC
[ -n "${BENCH_DEBUG:-}" ] && { echo "--- proxy log (full):"; cat "$W/proxy.log" 2>/dev/null; }
fi
if [ -n "${BENCH_SWITCH:-}" ]; then python3 - "$W/results.jsonl" <<'PYS'
import json,sys,statistics as st
rows=[json.loads(l) for l in open(sys.argv[1]) if l.strip()]
V=[]; [V.append(r["variant"]) for r in rows if r["variant"] not in V]
print("\n== tab switching (median over runs) ==\n"+f"{'metric':34}"+"".join(f"{v:>12}" for v in V))
for k,lab in (("n","switches measured"),("latP50","switch latency p50 ms"),("latP95","switch latency p95 ms"),("latMax","switch latency max ms"),
              ("stalls","UI stalls >6ms"),("stalls16","UI stalls >16ms"),("stalls50","UI stalls >50ms"),("stallMax","worst UI stall ms"),("blockedMs","UI blocked total ms"),("cpuMs","CPU ms (all procs)"),("memMB","memory MB")):
    xs={v:[r["r"]["switch"][k] for r in rows if r["variant"]==v and r["r"].get("switch") and r["r"]["switch"].get(k) is not None] for v in V}
    print(f"{lab:34}"+"".join(f"{str(round(st.median(xs[v]),1) if xs[v] else None):>12}" for v in V))
PYS
fi
if [ -n "${BENCH_URLS:-}" ]; then python3 - "$W/results.jsonl" <<'PYX'
import json,sys,statistics as st
rows=[json.loads(l) for l in open(sys.argv[1]) if l.strip()]
V=[]; [V.append(r["variant"]) for r in rows if r["variant"] not in V]
urls=[]; [urls.append(x["url"]) for r in rows for x in r["r"].get("sites",[]) if x["url"] not in urls]
def m(v,u,k):
    xs=[x.get(k) for r in rows if r["variant"]==v for x in r["r"].get("sites",[]) if x["url"]==u and x.get(k) not in (None,0) and not x.get("err") and x.get("wallMs",0)>0]
    return round(st.median(xs)) if xs else None
for k,lab in (("fcp","first contentful paint ms"),("dcl","DOMContentLoaded ms"),("load","load event ms"),("resp","responses received (all)"),("resp3p","3rd-party responses received"),("resp3pKB","3rd-party KB received")):
    print(f"\n== {lab} (median) ==\n{'site':44}"+"".join(f"{v:>13}" for v in V))
    for u in urls: print(f"{u.replace('https://','')[:43]:44}"+"".join(f"{str(m(v,u,k)):>13}" for v in V))
    ok=[u for u in urls if all(m(v,u,k) is not None for v in V)]
    print(f"{'SUM over '+str(len(ok))+' sites loaded by all':44}"+"".join(f"{sum(m(v,u,k) for u in ok):>13}" for v in V))
cpu={v:[r["r"].get("cpuMsTotal") for r in rows if r["variant"]==v and r["r"].get("cpuMsTotal")] for v in V}
mem={v:[r["r"].get("memEnd",{}).get("memMB") for r in rows if r["variant"]==v and (r["r"].get("memEnd") or {}).get("memMB") is not None] for v in V}
ext=lambda v,k:[ (r["r"].get("ext") or {}).get(k) for r in rows if r["variant"]==v and (r["r"].get("ext") or {}).get(k) is not None]
print("\n-- same external meter for every browser (/proc, whole process tree) --")
for k,lab in (("cpuMs","CPU ms over the page set"),("anonMB","memory: private (RssAnon) MB"),("rssMB","memory: RSS MB (overcounts shared)"),("procs","processes")):
    print(f"{lab:44}"+"".join(f"{str(round(st.median(ext(v,k))) if ext(v,k) else None):>13}" for v in V))
print("\n-- browser-internal meters (not comparable across engines) --")
print("\n"+f"{'total CPU ms (all sites, all procs)':44}"+"".join(f"{str(round(st.median(cpu[v])) if cpu[v] else None):>13}" for v in V))
print(f"{'memory at end MB':44}"+"".join(f"{str(round(st.median(mem[v])) if mem[v] else None):>13}" for v in V))
PYX
fi

