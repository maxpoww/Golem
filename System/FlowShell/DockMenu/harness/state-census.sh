#!/usr/bin/env bash
# state-census.sh — harvest a machine's dock/menubox state for the
# DockMenu aging record. Run LOCALLY on the target machine (or via:
#   ssh user@host 'bash -s' < state-census.sh
# ). Output is markdown; append it to machines/<machine>.md.
set -euo pipefail

D="${XDG_DATA_HOME:-$HOME/.local/share}/waverunner"
C="${XDG_CONFIG_HOME:-$HOME/.config}/waverunner"

echo "## census $(date +%F' '%T) · $(hostname) · $(uname -r)"
echo
echo '```'
echo "== totals =="
du -sh "$D" 2>/dev/null || echo "no data dir"
echo
echo "== stores (name size mtime) =="
if [ -d "$D" ]; then
  find "$D" -maxdepth 1 -type f -printf "%f\t%s\t%TY-%Tm-%Td\n" | sort
fi
echo
echo "== side dirs (files / size) =="
for sub in clipboard-images clipboard-previews notif-images webapp-chrome; do
  if [ -d "$D/$sub" ]; then
    printf "%s\t%s files\t%s\n" "$sub" \
      "$(find "$D/$sub" -type f 2>/dev/null | wc -l)" \
      "$(du -sh "$D/$sub" 2>/dev/null | cut -f1)"
  fi
done
echo
echo "== hygiene =="
tmp=$(find "$D" "$C" -maxdepth 1 -name "*.tmp" 2>/dev/null | wc -l)
corrupt=$(find "$D" "$C" -maxdepth 1 -name "*.corrupt-*" 2>/dev/null | wc -l)
pending=$([ -f "$D/pending-installs.json" ] && echo present || echo absent)
echo "tmp leftovers: $tmp   corrupt rescues: $corrupt   pending-installs: $pending"
echo
echo "== store entry counts =="
for f in apps-order.json usage.json notif-history.json clipboard-history.json managed.json; do
  if [ -f "$D/$f" ]; then
    # crude but dependency-free: count of '"' pairs ~ scale indicator; plus bytes
    printf "%s\t%s bytes\n" "$f" "$(wc -c < "$D/$f")"
  fi
done
echo
echo "== daemon =="
PID=$(systemctl --user show waverunner -p MainPID --value 2>/dev/null || true)
if [ -n "${PID:-}" ] && [ "$PID" != "0" ] && [ -d "/proc/$PID" ]; then
  echo "rss: $(awk "/VmRSS/{print \$2, \$3}" /proc/$PID/status)"
  echo "exe: $(readlink /proc/$PID/exe)"
  echo "started: $(systemctl --user show waverunner -p ExecMainStartTimestamp --value)"
else
  echo "daemon not under systemd --user (dev box runs it from Hyprland) or not running"
  pgrep -x waverunner >/dev/null && ps -o rss=,args= -p "$(pgrep -x waverunner | head -1)"
fi
echo
echo "== apply =="
[ -f "$C/apply-status.json" ] && head -c 200 "$C/apply-status.json" && echo
[ -f "$C/packages.list" ] && echo "packages.list: $(grep -cvE '^\s*(#|$)' "$C/packages.list") attrs"
echo '```'
