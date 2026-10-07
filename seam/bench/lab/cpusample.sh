#!/bin/sh
# cpusample.sh <pattern> <seconds> — CPU seconds used by every process whose cmdline matches <pattern>
# over <seconds>, from /proc (utime+stime), grouped by process kind. Same method for any browser.
P=$1; T=${2:-20}; HZ=$(getconf CLK_TCK)
snap(){ for pid in $(pgrep -f "$P"); do [ -r /proc/$pid/stat ] || continue; k=$(tr "\0" " " < /proc/$pid/cmdline | grep -o -- "--type=[a-z-]*\|-contentproc\|-parentBuildID" | head -1); [ -z "$k" ] && k=main; case "$(tr "\0" " " < /proc/$pid/cmdline)" in *" tab "*|*"isForBrowser"*) k=tab;; *" extension "*) k=extension;; *" rdd "*) k=rdd;; *" utility "*) k=utility;; *" socket "*) k=socket;; *" forkserver "*) k=forkserver;; *" gpu "*) k=gpu;; esac; [ "$k" = "-contentproc" ] && k=content; [ "$k" = "-parentBuildID" ] && k=content; echo "$pid $k $(awk "{print \$14+\$15}" /proc/$pid/stat)"; done; }
snap > /tmp/cpus.0; sleep "$T"; snap > /tmp/cpus.1
awk -v hz=$HZ 'NR==FNR{a[$1]=$3; k[$1]=$2; next} ($1 in a){d[$2]+=($3-a[$1])/hz; tot+=($3-a[$1])/hz} END{for(x in d) printf "%s=%.2f ", x, d[x]; printf "TOTAL=%.2f cpu-s in '"$T"' s\n", tot}' /tmp/cpus.0 /tmp/cpus.1
