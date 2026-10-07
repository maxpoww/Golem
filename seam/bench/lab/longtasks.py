#!/usr/bin/env python3
# longtasks.py PROFILE.json [minms] — the content process main thread's BUSY STRETCHES (runs of consecutive
# non-idle samples), longest first, with the dominant JS file / label in each: what blocks input.
import json,sys,re,collections
p=json.load(open(sys.argv[1])); minms=float(sys.argv[2]) if len(sys.argv)>2 else 80
cats=[c["name"] for c in p["meta"]["categories"]]
def pick(proc):
    best=None
    for sp in proc:
        if sp["meta"].get("processType")!=2: continue
        for t in sp["threads"]:
            if t["name"]!="GeckoMain": continue
            site=str(t.get("eTLD+1") or "")
            n=len(t["samples"]["data"])+(10**9 if "youtube" in site else 0)
            if best is None or n>best[0]: best=(n,t)
    return best[1] if best else None
t=pick(p.get("processes",[])); 
if not t: sys.exit("no content main thread")
st=t["stringTable"]; S=t["samples"]; ss=S["schema"]; sd=S["data"]; stk=t["stackTable"]; ks=stk["schema"]; kd=stk["data"]; fr=t["frameTable"]; fs=fr["schema"]; fd=fr["data"]
ti=ss["time"]; si=ss["stack"]; ci=ss.get("threadCPUDelta")
def chain(s):
    out=[]; cur=s
    while cur is not None:
        row=kd[cur]; out.append(row[ks["frame"]]); cur=row[ks["prefix"]]
    return out
def idle(row):
    s=row[si]
    if s is None: return True
    if ci is not None and ci<len(row) and row[ci] is not None and row[ci]<300000: return True   # < 0.3 ms of CPU since the last sample
    lf=fd[chain(s)[0]]; c=lf[fs["category"]] if fs["category"]<len(lf) else None
    if c is not None and cats[c]=="Idle": return True
    return st[lf[fs["location"]]] in ("PollWrapper","ThreadEventQueue::GetEvent::Wait","nsThreadPool::Run::Wait")
def desc(s):
    js=None; lab=None
    for f in chain(s):
        loc=st[fd[f][fs["location"]]]
        m=re.search(r"\(([^()]*?):\d+:\d+\)",loc)
        if m and js is None: js=re.sub(r".*/","",m.group(1))[:40]
        if not m and lab is None and not loc.startswith("0x") and loc not in("(root)","XRE_InitChildProcess","js::RunScript","promise callback"): lab=loc[:50]
    return (js or "-")+" | "+(lab or "-")
runs=[]; cur=None
for row in sd:
    tm=row[ti]; s=row[si]
    if idle(row):
        if cur: runs.append(cur); cur=None
        continue
    d=desc(s)
    if cur is None: cur={"t0":tm,"t1":tm,"n":0,"d":collections.Counter()}
    cur["t1"]=tm; cur["n"]+=1; cur["d"][d]+=1
if cur: runs.append(cur)
runs=[r for r in runs if r["t1"]-r["t0"]>=minms]
runs.sort(key=lambda r:-(r["t1"]-r["t0"]))
tot=sum(r["t1"]-r["t0"] for r in runs)
print("busy stretches >= %d ms: %d, total %.0f ms"%(minms,len(runs),tot))
for r in runs[:14]:
    top=r["d"].most_common(2)
    print("  %5.0f ms  %s"%(r["t1"]-r["t0"], " ;; ".join("%s (%d%%)"%(k,100*v/r["n"]) for k,v in top)))
