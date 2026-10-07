#!/usr/bin/env python3
"""between.py PROFILE.json T0 T1 [T0 T1 ...] — what the YouTube tab's main thread ran between two wall-clock
instants (ms since epoch, e.g. a keydown and the pause event it caused): JS files / functions / labels by sample
count inside each window. Profile sample times are relative to meta.startTime (ms since epoch)."""
import json, sys, re, collections
p = json.load(open(sys.argv[1])); start = p["meta"]["startTime"]
def pick():
    best = None
    for sp in p.get("processes", []):
        if sp["meta"].get("processType") != 2: continue
        for t in sp["threads"]:
            if t["name"] != "GeckoMain": continue
            n = len(t["samples"]["data"]) + (10**9 if "youtube" in str(t.get("eTLD+1") or "") else 0)
            if best is None or n > best[0]: best = (n, t)
    return best[1]
t = pick(); st = t["stringTable"]; S = t["samples"]; ss = S["schema"]; sd = S["data"]
stk = t["stackTable"]; ks = stk["schema"]; kd = stk["data"]; fr = t["frameTable"]; fs = fr["schema"]; fd = fr["data"]
def chain(s):
    out = []; cur = s
    while cur is not None:
        row = kd[cur]; out.append(row[ks["frame"]]); cur = row[ks["prefix"]]
    return out
args = [float(x) for x in sys.argv[2:]]
for i in range(0, len(args) - 1, 2):
    a, b = args[i] - start, args[i + 1] - start
    js = collections.Counter(); lab = collections.Counter(); n = 0
    for row in sd:
        tm = row[ss["time"]]
        if tm < a or tm > b or row[ss["stack"]] is None: continue
        n += 1; seenj = set(); seenl = set()
        for f in chain(row[ss["stack"]]):
            loc = st[fd[f][fs["location"]]]
            m = re.search(r"\(([^()]*?):\d+:\d+\)", loc)
            if m:
                k = re.sub(r"^.*/", "", m.group(1))[:40] + " " + loc.split(" (")[0][:30]
                if k not in seenj: seenj.add(k); js[k] += 1
            elif not loc.startswith("0x") and loc not in seenl: seenl.add(loc); lab[loc] += 1
    print("window %.0f..%.0f ms (%d samples)" % (args[i], args[i + 1], n))
    for k, v in js.most_common(6): print("   JS %3d  %s" % (v, k))
    for k, v in lab.most_common(6): print("   L  %3d  %s" % (v, k[:70]))
