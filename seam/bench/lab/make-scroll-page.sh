#!/usr/bin/env bash
# make-scroll-page.sh <out dir> — the scroll bench page (48 plasma JPEGs + text columns + a sticky header,
# with a rAF cadence recorder that reports in the title). Serve it on the laptop with sv.sh/serve.py
# (HTML no-store: a cached page once made a whole run test the previous page). Driven by sb.sh.
set -eu; out=${1:?out dir}; mkdir -p "$out/scroll"; cd "$out/scroll"
M=$(command -v magick || ls /nix/store/*-imagemagick-*/bin/magick | head -1)
for i in $(seq 1 48); do [ -f img$i.jpg ] || $M -size 480x320 plasma:fractal -quality 80 img$i.jpg; done
python3 - <<'PY'
import random
random.seed(7)
words="the quick brown fox jumps over a lazy dog while reading a long article about browsers rendering engines compositors frames and scrolling on weak laptops".split()
def para(n): return " ".join(random.choice(words) for _ in range(n))
rows=[f'<section class="row"><img src="img{i}.jpg" width="480" height="320" loading="eager" decoding="sync"><div class="txt"><h2>Section {i}</h2><p>{para(140)}</p><p>{para(110)}</p><ul><li>{para(12)}</li><li>{para(14)}</li><li>{para(9)}</li></ul></div></section>' for i in range(1,49)]
html='''<!doctype html><html><head><meta charset="utf-8"><title>scroll bench</title>
<style>body{margin:0;font:16px/1.5 sans-serif;color:#222;background:#fff}header{position:sticky;top:0;background:#1d2026;color:#fff;padding:12px 24px;font-weight:bold;z-index:2}
.row{display:flex;gap:24px;padding:24px;border-bottom:1px solid #ddd;max-width:1100px;margin:0 auto}.row img{flex:0 0 auto;border-radius:8px;box-shadow:0 2px 8px rgba(0,0,0,.2)}
.txt h2{margin:0 0 8px}.txt p{margin:0 0 10px}a{color:#2a6fdb}</style></head><body><header>Seam scroll bench</header>
'''+"\n".join(rows)+'''
<script>
(function(){
  var gaps=[], last=0, scrolls=0, stalls=0, lastY=window.scrollY, moving=false, quietSince=0, started=false, t0=0, done=false;
  function f(t){
    var y=window.scrollY;
    if(started){ if(last){ var g=t-last; gaps.push(g); } last=t; }
    if(!started){ if(y>5){ started=true; t0=t; last=t; moving=true; quietSince=t; } lastY=y; requestAnimationFrame(f); return; }
    if(y!==lastY){ scrolls++; moving=true; quietSince=t; }
    else if(moving && t-quietSince>1500){ moving=false; if(started && !done){ done=true; report(t); return; } }
    else if(moving){ stalls++; }
    lastY=y;
    requestAnimationFrame(f);
  }
  function report(t){
    var g=gaps.slice(), n=g.length; g.sort(function(a,b){return a-b});
    var med=g[Math.floor(n/2)]||0, p95=g[Math.floor(n*0.95)]||0, p99=g[Math.floor(n*0.99)]||0, long=g.filter(function(x){return x>25}).length, vlong=g.filter(function(x){return x>50}).length;
    var dur=(t-t0)/1000;
    document.title="BENCH frames="+n+" dur="+dur.toFixed(2)+" fps="+(n/dur).toFixed(1)+" med="+med.toFixed(1)+" p95="+p95.toFixed(1)+" p99="+p99.toFixed(1)+" long="+long+" vlong="+vlong+" stalls="+stalls+" scrollY="+window.scrollY;
  }
  window.addEventListener("load",function(){ document.title="READY"; requestAnimationFrame(f); });
})();
</script></body></html>'''
open("index.html","w").write(html)
PY
echo "$(ls | wc -l) files in $out/scroll"
