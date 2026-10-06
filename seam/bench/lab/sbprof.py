import json,sys,collections,statistics
p=json.load(open(sys.argv[1])); want=sys.argv[2] if len(sys.argv)>2 else None
def threads(p):
    for t in p["threads"]: yield p["meta"].get("product",""),t
    for sp in p.get("processes",[]):
        for t in sp["threads"]: yield sp["meta"].get("processType",""),t
for ptype,t in threads(p):
    st=t["stringTable"]; M=t["markers"]; ms=M["schema"]; md=M["data"]
    names=collections.Counter(st[r[ms["name"]]] for r in md)
    if not want:
        print(f"[{ptype}] {t['name']} pid={t.get('pid')} samples={len(t['samples']['data'])} markers={len(md)}: {names.most_common(14)}")
    else:
        rows=[r for r in md if st[r[ms["name"]]]==want]
        if not rows: continue
        starts=sorted(r[ms["startTime"]] for r in rows if r[ms["startTime"]] is not None)
        gaps=[b-a for a,b in zip(starts,starts[1:]) if b-a>0.5]
        if len(gaps)<5: print(f"[{ptype}] {t['name']}: {len(rows)} {want} markers, too few gaps"); continue
        gaps.sort(); n=len(gaps); dur=(starts[-1]-starts[0])/1000
        long=sum(1 for g in gaps if g>25); vlong=sum(1 for g in gaps if g>50)
        print(f"[{ptype}] {t['name']}: {want} x{len(rows)} over {dur:.1f}s = {len(rows)/dur:.1f}/s; gap med {gaps[n//2]:.1f} p95 {gaps[int(n*.95)]:.1f} p99 {gaps[int(n*.99)]:.1f} max {gaps[-1]:.1f} ms; >25ms:{long} >50ms:{vlong}")
