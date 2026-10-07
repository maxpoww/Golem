#!/bin/sh
# chrome-loads-run.sh <url>… — from the DEV BOX: fresh Chrome on the MacBook, the pages one after another
# (chrome-loads.py over an ssh tunnel), then close it. Output: $S/acer/mb-chrome-loads.jsonl
S=/tmp/claude-1000/-home-max/01022959-a2fa-4209-b76f-5af45660221d/scratchpad; MB="ssh -o UserKnownHostsFile=$S/kh root@192.168.1.242"
$MB 'sh /tmp/seam-sb/chrome.sh start' | cut -c1-120
ssh -o UserKnownHostsFile=$S/kh -N -L 9222:127.0.0.1:9222 root@192.168.1.242 & T=$!; sleep 2
$MB 'sh /tmp/seam-sb/cpusample.sh chrome-bench 1 >/dev/null; : > /tmp/cpus.start; for pid in $(pgrep -f chrome-bench); do awk "{print \$14+\$15}" /proc/$pid/stat; done | awk "{s+=\$1} END{print s}" > /tmp/cpus.start'
MS=${MS:-40000} python3 ~/.cache/golem-wt/seam-debloat/seam/bench/lab/chrome-loads.py localhost:9222 "$@" | tee $S/acer/mb-chrome-loads.jsonl
$MB 'for pid in $(pgrep -f chrome-bench); do awk "{print \$14+\$15}" /proc/$pid/stat; done | awk -v a=$(cat /tmp/cpus.start) "{s+=\$1} END{printf \"chrome cpu-s during the loads (live processes only): %.1f\n\", (s-a)/100}"'
$MB 'sh /tmp/seam-sb/chrome.sh stop' | tail -1; kill $T 2>/dev/null; wait
