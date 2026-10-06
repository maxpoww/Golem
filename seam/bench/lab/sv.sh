#!/bin/sh
# sv.sh start|stop — the bench page server on the laptop (pidfile, so stopping it never matches another shell)
D=/home/max/.cache/seam-lab; P=/nix/store/a3bvdzgck2984wm26r9x7pc991h7a64l-python3-3.13.15/bin/python3
case "$1" in
  start) [ -f $D/sv.pid ] && kill $(cat $D/sv.pid) 2>/dev/null; sleep 0.3; cd $D && nohup $P $D/serve.py 38555 $D/www < /dev/null > $D/serve.log 2>nohup $P $D/serve.py 38555 $D/www > $D/serve.log 2>&1 &1 & echo $! > $D/sv.pid; sleep 1.5; cat $D/serve.log | tail -2; curl -s -m 5 -o /dev/null -w "bench page: %{http_code} %{size_download}B\n" http://127.0.0.1:38555/scroll/index.html;;
  stop) [ -f $D/sv.pid ] && kill $(cat $D/sv.pid) 2>/dev/null; rm -f $D/sv.pid; echo stopped;;
esac
