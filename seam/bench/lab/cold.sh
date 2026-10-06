#!/bin/sh
# cold.sh <variant> — run AS ROOT: drop the page cache, then one blank start of the lab variant (first paint / session restored, CPU) = a cold start from the disk.
PATH=/etc/profiles/per-user/max/bin:/run/current-system/sw/bin:$PATH
V=${1:-base}; cd /home/max/.cache/seam-lab || exit 1
sync; echo 3 > /proc/sys/vm/drop_caches; sleep 2
runuser -u max -- env CLEAN_SESSION=1 MS=25000 ./lab.sh "$V" keep 2>&1 | grep "PSS\|NO RESULT"
runuser -u max -- jq -c '{fp:.startup.firstPaint,sr:.startup.sessionRestored,main:.startup.main,delayed:.notes,parentcpu:([.procs[]|select(.type=="parent")|.cpu]|add),allcpu:([.procs[]|.cpu]|add)}' out-$V-keep.json
