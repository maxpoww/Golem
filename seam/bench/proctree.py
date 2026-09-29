#!/usr/bin/env python3
"""proctree.py <root-pid>: CPU and memory of a browser's WHOLE process tree, read from
/proc the same way for every browser (Seam and Chrome alike) — one JSON line.
cpuMs = utime+stime of every live process in the tree; rssMB = sum RSS (overcounts shared
libraries); anonMB = sum RssAnon (private heap/JS/DOM — the fairer "what the browser holds").
/proc/<pid>/status stays readable even for sandboxed (non-dumpable) processes."""
import os,sys,json
root=int(sys.argv[1]); hz=os.sysconf("SC_CLK_TCK")
kids={}
for p in os.listdir("/proc"):
    if not p.isdigit(): continue
    try:
        st=open(f"/proc/{p}/stat").read(); pp=int(st[st.rindex(")")+2:].split()[1]); kids.setdefault(pp,[]).append(int(p))
    except Exception: pass
tree=[]; todo=[root]
while todo:
    x=todo.pop(); tree.append(x); todo+=kids.get(x,[])
cpu=0; rss=0; anon=0; n=0
for p in tree:
    try:
        st=open(f"/proc/{p}/stat").read(); f=st[st.rindex(")")+2:].split(); cpu+=int(f[11])+int(f[12])
        for line in open(f"/proc/{p}/status"):
            if line.startswith("VmRSS:"): rss+=int(line.split()[1])
            elif line.startswith("RssAnon:"): anon+=int(line.split()[1])
        n+=1
    except Exception: pass
print(json.dumps({"cpuMs":round(cpu*1000/hz),"rssMB":round(rss/1024),"anonMB":round(anon/1024),"procs":n}))
