#!/usr/bin/env python3
# profall.py PROFILE.json [minms] — every process/thread: CPU ms, top JS files, top labels (self-contained Gecko profile reader)
import json,sys,re,collections
p=json.load(open(sys.argv[1])); cats=[c["name"] for c in p["meta"]["categories"]]; interval=p["meta"]["interval"]
minms=float(sys.argv[2]) if len(sys.argv)>2 else 150
def analyze(t):
    st=t["stringTable"]; S=t["samples"]; ss=S["schema"]; sd=S["data"]
    stk=t["stackTable"]; ks=stk["schema"]; kd=stk["data"]; fr=t["frameTable"]; fs=fr["schema"]; fd=fr["data"]
    ci=ss.get("threadCPUDelta"); tot=0; bycat=collections.Counter(); inclfile=collections.Counter(); labels=collections.Counter(); incl=collections.Counter(); cache={}
    def chain(s):
        if s in cache: return cache[s]
        out=[]; cur=s
        while cur is not None:
            row=kd[cur]; out.append(row[ks["frame"]]); cur=row[ks["prefix"]]
        cache[s]=out; return out
    for row in sd:
        s=row[ss["stack"]]
        w=(row[ci] if ci is not None and ci<len(row) and row[ci] is not None else interval*1000)/1e6
        if s is None: continue
        frames=chain(s); lf=fd[frames[0]]
        cat=lf[fs["category"]] if fs["category"]<len(lf) and lf[fs["category"]] is not None else None
        cname=cats[cat] if cat is not None else "?"
        if cname=="Idle": continue
        tot+=w; bycat[cname]+=w; seen=set(); seenf=set()
        for f in frames:
            loc=st[fd[f][fs["location"]]]
            m=re.search(r"\(([^()]*?):\d+:\d+\)(\[\d+\])?$",loc)
            if m:
                fl=m.group(1)
                if loc not in seen: seen.add(loc); incl[loc]+=w
                if fl not in seenf: seenf.add(fl); inclfile[fl]+=w
            elif loc not in seen and not loc.startswith("0x"): seen.add(loc); labels[loc]+=w
    return tot,bycat,inclfile,labels,incl
def show(ptag,t):
    tot,bycat,inclfile,labels,incl=analyze(t)
    if tot<minms: return
    print("\n===== %s / %s : %d ms"%(ptag,t["name"],tot))
    print("  cats:",[(k,round(v)) for k,v in bycat.most_common(8)])
    for name,c,n in (("JS files",inclfile,8),("JS functions",incl,10),("labels",labels,12)):
        rows=[(k,v) for k,v in c.most_common(n) if v>=max(20,tot*0.03)]
        if rows:
            print("  --",name)
            for k,v in rows: print("   %6.0f ms %5.1f%%  %s"%(v,100*v/tot,k[-140:]))
for t in p["threads"]: show("parent",t)
for i,sp in enumerate(p.get("processes",[])):
    m=sp["meta"]; tag="child%d(type%s)"%(i,m.get("processType"))
    for t in sp["threads"]: show(tag,t)
