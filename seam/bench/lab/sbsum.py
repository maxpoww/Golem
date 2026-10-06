import json,sys
def summarize(v):
    r=json.load(open(f"result-{v}.json")); a=r["procs0"]; b=r["procs1"]; w=r["ms"]/1000
    per={}
    for k in b:
        d=(b[k]["cpu"]-(a[k]["cpu"] if k in a else 0))/1e6
        key=k.split(":")[0]; per[key]=per.get(key,0)+d
    tot=sum(per.values())
    try: hyp=int(open(f"hypr-{v}.txt").read().strip())
    except: hyp=-1
    t=r["title"]
    import re
    fps=re.search(r"fps=([\d.]+)",t).group(1); p99=re.search(r"p99=([\d.]+)",t).group(1); long=re.search(r"long=(\d+)",t).group(1); vlong=re.search(r"vlong=(\d+)",t).group(1); st=re.search(r"stalls=(\d+)",t).group(1); fr=re.search(r"frames=(\d+)",t).group(1)
    # composite cadence from the profile
    p=json.load(open(f"profile-{v}.json")); comp=""
    for th in p["threads"]:
        if th["name"]=="Compositor":
            st_=th["stringTable"]; M=th["markers"]; ms=M["schema"]; starts=sorted(rr[ms["startTime"]] for rr in M["data"] if st_[rr[ms["name"]]]=="CompositeToTarget" and rr[ms["startTime"]] is not None)
            gaps=sorted(b2-a2 for a2,b2 in zip(starts,starts[1:]) if 0.5<(b2-a2)<2000)
            if gaps: n=len(gaps); comp=f"composites {len(starts)} gap med {gaps[n//2]:.1f} p95 {gaps[int(n*.95)]:.1f} p99 {gaps[int(n*.99)]:.1f} >25ms {sum(1 for g in gaps if g>25)} >50ms {sum(1 for g in gaps if g>50)}"
    print(f"{v}: page rAF {fps} fps p99 {p99} ms long {long}/{vlong} stalls {st}/{fr} | {comp}")
    print(f"   CPU over {w:.1f}s: Firefox {tot/1000:.2f}s ({100*tot/1000/w:.0f}% of a core): parent {per.get('parent',0)/1000:.2f} ext {per.get('extension',0)/1000:.2f} content {sum(d for k,d in per.items() if k.startswith('web'))/1000:.2f} | Hyprland {hyp/1000:.2f}s ({100*hyp/1000/10.4:.0f}% during the 10.4 s wheel)")
for v in sys.argv[1:]: 
    try: summarize(v)
    except Exception as e: print(v,"ERR",e)
