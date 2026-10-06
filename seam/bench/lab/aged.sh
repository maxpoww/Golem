#!/bin/sh
# aged.sh — the returning-user launch, A/B: two equally aged copies of one profile (uBO's lists last
# written >317 min ago), one with the installed policies (agedold), one with new.policies.json
# (agednew: differentialUpdate=false, selfieDelayInSeconds=20). Same clip page, 20 s window,
# 60 s linger so an update batch can finish; cumulative process CPU (procs1) = cost since launch.
D=/tmp/seam-sb; export PATH=/etc/profiles/per-user/max/bin:/run/current-system/sw/bin:$PATH
cd $D || exit 1
for V in agedold agednew; do
  stat -c "%y %s %n" prof-yt-$V/storage/default/moz-extension+++*/idb/*.files/* 2>/dev/null | sed "s|.*idb/||" > aged-$V-blobs-before.txt
  YT_URL=http://127.0.0.1:38555/video/index.html YT_THREADS="*" YT_INTERVAL=4 YT_LINGER=60 sh ./yt.sh $V > aged-$V.log 2>&1
  cp yt-$V/result.json aged-$V.json 2>/dev/null; cp yt-$V/profile.json aged-$V-profile.json 2>/dev/null
  stat -c "%y %s %n" prof-yt-$V/storage/default/moz-extension+++*/idb/*.files/* 2>/dev/null | sed "s|.*idb/||" > aged-$V-blobs-after.txt
  echo "$V: $(head -c 120 aged-$V.json 2>/dev/null) | blobs changed: $(diff aged-$V-blobs-before.txt aged-$V-blobs-after.txt | grep -c '^[<>]')"
  sleep 5
done
