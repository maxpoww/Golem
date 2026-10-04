import json,sys,re,collections
p=json.load(open(sys.argv[1])); cats=[c["name"] for c in p["meta"]["categories"]]
interval=p["meta"]["interval"]
def analyze(t,label):
    st=t["stringTable"]; S=t["samples"]; ss=S["schema"]; sd=S["data"]
    stk=t["stackTable"]; ks=stk["schema"]; kd=stk["data"]; fr=t["frameTable"]; fs=fr["schema"]; fd=fr["data"]
    ci=ss.get("threadCPUDelta"); 
    tot=0; bycat=collections.Counter(); incl=collections.Counter(); inclfile=collections.Counter(); root=collections.Counter(); leaf=collections.Counter(); labels=collections.Counter()
    cache={}
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
        frames=chain(s)
        lf=fd[frames[0]]; cat=lf[fs["category"]] if fs["category"]<len(lf) and lf[fs["category"]] is not None else None
        cname=cats[cat] if cat is not None else "?"
        if cname=="Idle": continue
        tot+=w; bycat[cname]+=w
        seen=set(); seenf=set(); jsroot=None
        for f in frames:
            loc=st[fd[f][fs["location"]]]
            m=re.search(r"\(([^()]*?):\d+:\d+\)(\[\d+\])?$",loc)
            if m:
                jsroot=loc
                if loc not in seen: seen.add(loc); incl[loc]+=w
                fl=m.group(1)
                if fl not in seenf: seenf.add(fl); inclfile[fl]+=w
            else:
                if loc not in seen and not loc.startswith("0x"): seen.add(loc); labels[loc]+=w
        if jsroot: root[jsroot]+=w
        leaf[st[lf[fs["location"]]]]+=w
    print("\n=====",label,"non-idle CPU ms:",round(tot))
    print("-- by category:",[(k,round(v)) for k,v in bycat.most_common(12)])
    for name,c,n in (("inclusive by JS file",inclfile,28),("JS entry points (outermost JS frame)",root,22),("inclusive by JS function",incl,30),("labels (inclusive)",labels,45)):
        print("--",name)
        for k,v in c.most_common(n): print("   %7.0f ms %5.1f%%  %s"%(v,100*v/tot if tot else 0,k[-150:]))
for t in p["threads"]:
    if t["name"]=="GeckoMain": analyze(t,"PARENT main thread")
if len(sys.argv)>2:
    for sp in p.get("processes",[]):
        for t in sp["threads"]:
            if t["name"]=="GeckoMain": print("child",t.get("processType"),t.get("processName"),t.get("eTLD+1"),len(t["samples"]["data"]))
