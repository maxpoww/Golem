# devbox — the aging dataset (Max's daily driver)

> Slim Pro 9i · i9-13905H · 32 GB · NVMe · Vulkan renderer. Months of
> real usage. Append census runs below; the series is the aging record.

Known history: apps-order.json shredded incident 2026-09-03 (backup
kept beside it); last local waverunner-apply failed with an eval error
(dev box config is a moving target — not a distro signal).

## census 2026-09-09 21:37:49 · Golem · 6.18.49

```
== totals ==
2,4G	/home/max/.local/share/waverunner

== stores (name size mtime) ==
apps-order.json	4993	2026-09-08
apps-order.json.bak-20260903-shredded	5029	2026-09-03
clipboard-history.json	131789	2026-09-09
clipboard-history.json.bak	69881	2026-08-20
dictionary-es.json	14984829	2026-08-21
dictionary.json	22458933	2026-08-21
groups.json	570	2026-09-07
managed.json	1752	2026-08-31
managed-webapps.json	197	2026-08-23
notif-apps.json	602	2026-08-15
notif-history.json	31630	2026-09-09
notif-state.json	91	2026-09-09
pins.json	819	2026-09-08
trash-pinned	2	2026-07-29
ui_state.json	1	2026-09-09
usage.json	2916	2026-09-09

== side dirs (files / size) ==
clipboard-images	0 files	4,0K
clipboard-previews	2 files	96K
notif-images	153 files	4,0M
webapp-chrome	38418 files	2,4G

== hygiene ==
tmp leftovers: 0   corrupt rescues: 0   pending-installs: absent

== store entry counts ==
apps-order.json	4993 bytes
usage.json	2916 bytes
notif-history.json	31630 bytes
clipboard-history.json	131789 bytes
managed.json	1752 bytes

== daemon ==
daemon not under systemd --user (dev box runs it from Hyprland) or not running
306900 /home/max/launcher/target/debug/waverunner

== apply ==
{"phase":"done","ok":false,"started":1788928527.637752422,"finished":1788928535.975486608,"error":"building the system configuration...\nerror:\n       … while calling the 'derivationStrict' builtin
packages.list: 16 attrs
```
