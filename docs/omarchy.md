# What Golem took from Omarchy

Omarchy (github.com/omacom/omarchy, read at 717175d4a on 2026-10-30) is the closest
thing to Golem: an opinionated Hyprland system. Max asked what it does for speed on fast
and slow machines, and to apply everything that serves us.

"They do X" is not "X is faster". Omarchy publishes numbers for its shell, almost none
for its kernel or sysctl. So each item below was measured here before it was kept. Where
a machine could not be used, the entry says so.

Machines: the **dev box** (Lenovo Slim Pro 9, i9-13905H, 32 GB, NVMe, on the charger).
The **MacBook Air** (i5-4250U, HD 5000, 3.8 GB, SATA SSD, dead battery), measured the same
evening once it was back. No machine with a spinning disk was available.

## Taken and applied

| What | Where | Result on the dev box |
|---|---|---|
| Power mode follows the charger, remembered per source | launcher `power_mode.rs` | see the table below: the largest gain of all |
| The cursor drawn by the display engine (Hyprland's default, which Omarchy keeps; ours was forced off with no reason recorded) | `system/home/hyprland.lua` | moving the pointer: GPU 24 → 1 %, see below |
| A dock at rest reacts to events, it does not poll | launcher (see below) | 100.7 → 12.6 wake-ups/s, 0.60 → 0.13 % of a CPU |
| Budget tests in counts, at rest and busy | launcher `tools/perf-guard/rest-check.py`, `churn-check.sh` | fail on a new timer, a poll or a stall |
| Writes capped in bytes, not percent | `Modular/memory/zram-tier{1,2,3}.nix` | worst stall halved, see below |
| Reclaim early, in the background (`watermark_boost_factor=0`, `watermark_scale_factor=125`) | `Modular/base/core.nix` | no pressure on 32 GB; on the Air fewer allocation stalls, about 10 % less work done by a program thrashing memory, see below |
| Flusher every 15 s (`dirty_writeback_centisecs=1500`) | `Modular/base/core.nix` | fewer disk wake-ups; safe because the caps bound the bursts |
| `tcp_mtu_probing=1` | `Modular/base/core.nix` | their cure for SSH hanging on bad links; costs nothing |
| `preempt=full` | `Modular/base/core.nix` | dev box: build unchanged, tail of wake-ups under load better. Air: no difference, see below |
| `systemd.tty.term.console=dumb` | `Modular/boot/plymouth.nix` | their fix for a black boot, about 1 in 10 on their machines. The Air and the VM test boot with it; three boots are no proof either way. Not the cause of the Air's hang, which stopped at another stage |
| `uwsm start -g -1` | `Modular/desktop/greeter.nix` | no gain measured: login to compositor 3.00 s before, 3.02 and 3.00 s after on the Air, under 0.16 s on the dev box. They claim about 3 s. Kept because it costs nothing and a slow disk, where the boot's queue lasts, may gain: not tested there |

### Power mode (dev box, on the charger, two rounds each, same results both times)

| Measure | balanced | performance |
|---|---|---|
| A small job right after 200 ms idle (the shape of everything a desktop does) | 31.8 ms | 13.7 ms |
| How late a 1 ms sleep wakes, median | 17.7 µs | 5.2 µs |
| One thread flat out | 3.20 s | 2.26 s |
| All 20 threads | 6.58 s | 4.84 s |
| A real release build of the dock | 120.9 s | 98.0 s |
| Package temperature at rest | 44 °C | 51 °C |
| Package temperature after the load | 49 °C | 73 °C |

The default is performance on the charger, balanced on the battery. What the owner picks
in Power mode is kept for that source. The cost is heat and possibly fan noise on the
charger: the owner has the pill.

**On the MacBook Air the mode changes nothing** (two rounds each, same results; a Haswell has
no hardware P-states for the daemon to tune):

| Measure | balanced | performance |
|---|---|---|
| A small job right after 200 ms idle | 36.0, 35.9 ms | 37.3, 33.3 ms |
| One thread flat out | 4.66, 4.66 s | 4.66, 4.67 s |
| All 4 threads | 8.15, 8.12 s | 8.09, 8.13 s |
| Hottest sensor after the load | 78, 76 °C | 80, 80 °C |

It keeps the same rule as every machine: a charger asks for performance. Nothing is gained
there and nothing was seen to break with its dead battery (PROCHOT released, 2.3 GHz).

### The hardware cursor (pointer moved 125 times a second on an empty workspace, three rounds each)

| | software (ours until now) | hardware |
|---|---|---|
| GPU render busy | 26, 24, 19 % | 1, 2, 0 % |
| GPU asleep (RC6) | 31, 27, 27 % | 94, 95, 96 % |
| Compositor, of one CPU | 7.0, 6.6, 6.5 % | 1.7, 2.2, 1.6 % |
| Panel refreshes a second (VRR on) | 165 | 130 |

The panel follows each move, so VRR does not make the pointer lag: 130 refreshes for 125
moves, against 48 at rest (DRM vblank timestamps, `vblank.py`). The display engine's own
state showed the cursor plane on, 256x256, at the exact pixel asked for. A screenshot
with the cursor still shows it. A fullscreen video or game no longer loses direct scanout
when the pointer moves.

On the MacBook Air (HD 5000, 1440x900 at 60 Hz, three rounds each) the cursor plane is in use too:

| | software | hardware |
|---|---|---|
| GPU asleep (RC6) | 68, 69, 68 % | 98, 98, 98 % |
| GPU render busy | 2, 2, 2 % | 1, 1, 1 % |
| Compositor, of one CPU | 7.6, 7.7, 8.0 % | 4.8, 4.9, 4.9 % |

### The dock at rest (60 s on an empty workspace)

| | before | after |
|---|---|---|
| Wake-ups a second, all threads | 100.7 | 12.6 |
| CPU | 0.60 % | 0.13 % |
| Loop turns a second | 40+ | 3.3 |

On the MacBook Air, 100 s starting about 2.5 min after boot, with no window open:

| | before | after |
|---|---|---|
| Wake-ups a second, all threads | 180.4 | 23.0 |
| CPU | 1.50 % | 0.09 % |
| Processes started | 13 | 0 |

Where they went, found with strace (`docs` in the launcher's `CLAUDE.md`, "THE DOCK AT REST"):

- 40/s were the loop's own lateness meter, a 25 ms timer. It is now a source that hears
  "the poll came back" and times each turn.
- About 45/s on average were `pw-dump`, writing a line at a time through a pipe. Its answer
  goes to a file in memory now.
- `settings.json` was read and parsed on the loop twice every 2 s. It is read when it changes.
- USB was found by reading sysfs every 3 s, twice. The kernel's uevent socket says it.
- Media asked the bus every second and Bluetooth every 3 s. Both listen for signals now,
  and see a change sooner. Tested on a private bus with fake services.
- The zone poll, two IPC round trips each 800 ms, slows to 4 s when nobody has touched
  anything for 3 s, and looks at once when a hand comes back.
- `adb devices` every minute per synced phone, plugged in or not: the bus is looked at first.

### Writes capped (8 GiB written on the NVMe while a small file is fsynced every 100 ms)

| | 10 % / 5 % of RAM | 256 / 64 MiB |
|---|---|---|
| Worst fsync during the write | 323, 433 ms | 201, 171, 165 ms |
| Median fsync during the write | 114, 275 ms | 161, 138, 145 ms |
| Worst page read during the write | 28, 119 ms | 22, 26, 27 ms |
| The writer's last fsync | 0.86, 0.74 s | 0.04, 0.08, 0.04 s |
| The writer's whole time | 4.45, 3.55 s | 3.82, 3.41, 3.52 s |

A slower disk should gain more (10 % of 16 GB on a 100 MB/s disk is 16 s of writes), but no
such machine was available to prove it. The unknown-RAM tier keeps its percentages, as that
tier's rule says. On the Air nothing moves: 200 MiB is what its 5 % already was.

### Reclaim early (the MacBook Air, 3.4 GB of its 3.8 GB written and touched at random for 35 s, six rounds each)

| | boost 15000, scale 10 (kernel defaults) | boost 0, scale 125 |
|---|---|---|
| Allocation stalls | 219, 99, 54, 115, 10, 124 | 0, 164, 8, 65, 25, 3 |
| Passes of work done | 18644, 24156, 18718, 22028, 20135, 18529 | 19847, 7233, 16648, 19968, 18390, 16358 |
| Worst small job beside it | 0.1 to 0.3 ms | 0.1 to 0.3 ms |

What Omarchy claims holds, stalls are about a sixth at the median, at a price: the program
thrashing memory did about 10 % less work, leaving out the one round at 7233. A small job
beside it never noticed either setting. Kept: a stall is what an owner feels, and this
test is far heavier than daily use. It is the first thing to take back if a small machine
feels slower under heavy memory use.

### Full preemption (8000 sleeps of 1 ms while all 20 CPUs are busy, half in the kernel)

| | lazy (default) | full |
|---|---|---|
| Median lateness | 3.3, 2.7, 3.6 µs | 3.2, 3.2, 2.3 µs |
| 99th percentile | 22, 351, 104 µs | 18, 18, 17 µs |
| Worst | 3.3, 3.2, 2.2 ms | 2.4, 0.9, 1.7 ms |
| Real build | 98.0 s | 98.5, 100.0 s |

On the MacBook Air the two cannot be told apart in eight rounds each: median 56 to 71 µs against
56 to 58 µs, worst 1.2 to 4.6 ms against 0.7 to 9.6 ms. Nothing there asks to take it back.

### Does anything keep drawing when nothing moves? (real panel refreshes, 7 s after settling)

| State | Refreshes a second | GPU |
|---|---|---|
| Empty desktop, box open, quick controls, Files | 48 (the panel's floor) | 0 % |
| Gear box open | 164 | 2–6 % |

The gear box redraws once a second with its readings, and `vfr_hold_ms` (the anti-flicker
patch, 2 s) then holds the panel at full speed by design. It lasts only while it is open and
the dock itself draws 1 frame a second, so it was left alone. The overview read 154 Hz and
17 % GPU, but my own terminal was animating on a workspace it shows, so that says nothing.

The whole machine at rest starts 3.9 processes a second (the kernel's counter), and the
sampler found the toolbox's keepalive behind what it could see: nothing of Golem's.

## Golem already had it

- oomd on memory pressure, 50 %, with the desktop's memory protected and tested with a
  runaway app on the Acer (`Modular/base/nix.nix`). Omarchy limits the killing to `app.slice`;
  ours avoids the desktop by preference. Same aim.
- BBR and fq. Wait-online off. A one-second boot menu. zswap off (kernel default here).
- Seam's Firefox prefs: VA-API, fractional scale, overscroll. Seam goes further, with a
  fallback when the hardware decoder fails.
- Bluetooth discovery stopping when its page closes (`gear_sync`, read and confirmed).
- No `lspci` at run time; the GPU meter never wakes the discrete card.
- Bar and panels built once and kept; previews off the loop; small icon tier, GL paths and
  Air boot work that go further than Omarchy on weak machines.

## Not taken, with the reason

| What | Why |
|---|---|
| Their kernel, 7.2 with 187 patches (BORE, ADIOS…) | 7.2 breaks nvidia-open, facetimehd and broadcom-sta here (10-27); no benchmark for it in their repos |
| Kyber on the NVMe | 8 GiB write test: read median 0.87 ms against 1.05, worst 21–25 ms against 22–27, fsync unchanged. No gain |
| Kyber on the Air's SATA SSD | 2 GiB write test, six rounds against mq-deadline, its default: read median 13.3 against 13.8 ms, worst reads 33–66 against 29–82 ms, fsync the same. No gain. BFQ was worse there (reads p95 91 against 22 ms) |
| Kyber on spinning disks | BFQ exists for exactly this; no disk here to compare |
| `swappiness=150` everywhere | Our RAM tiers are finer (180 on small machines, 10 on big ones) |
| `DefaultTimeoutStopSec=5s` | 14 days of the dev box's journal: no stop job ever hung |
| Mount rate limit (`SYSTEMD_DEFAULT_MOUNT_RATE_LIMIT_BURST`), eager binfmt | Mounts take 10–240 ms at boot here and there is no binfmt in use |
| Wi-Fi power save off everywhere | On iwlwifi: 3.0 ms average, 5.3 ms worst with the radio napping, against 1.4 and 3.7 ms awake. None of their 20–300 ms spikes. The lab machines already have it off |
| `MALLOC_ARENA_MAX=2`, `malloc_trim` (the idea of releasing memory after closing) | 175 against 176 MB; 6 MB of 177 |
| Rounding 0, no blur | The look is Max's decision |
| `usbcore.autosuspend=-1` | Costs battery; no problem seen |
| plocate on AC only | Golem has no locate |
| thermald on the dev box, intel-lpmd | Not tried. Golem's Intel laptops have thermald. lpmd saves battery, it does not add speed |

## Still to do

Both machines run this version and have rebooted into it: the dev box 15.4 s from power on
(16.9 s before), the Air 18.0 s (19.3 s before), neither with a failed unit.

- **A machine with a spinning disk** (the Acer): the dirty caps and `uwsm -g -1` are where it
  should gain, and neither was measured there. `ioprobe` and the login lines tell.
- **Heavy daily use on the Air**: see "Reclaim early".

## How to measure again

The tools are in the launcher's `tools/perf-guard/`:

- `rest-check.py`: the dock at rest against a budget.
- `churn-check.sh`: the dock busy against a budget (dev box: 4 stalls over 30 ms in 6 rounds, worst 39.6 ms).
- `burst.c`: a job after idling, wake-up lateness, one thread, all threads.
- `wakeload.c`: wake-up lateness with every CPU busy.
- `ioprobe.c <dir> <GiB>`: what a big write does to fsync and reads.
- `vblank.py <secs>`: how often the panel really refreshes (DRM timestamps).
- `cursor-test.py <secs>`: the pointer driven in a circle, and what the compositor spends.
