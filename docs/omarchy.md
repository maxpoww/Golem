# What Golem took from Omarchy

Omarchy (github.com/omacom/omarchy, read at 717175d4a on 2026-10-30) is the closest
thing to Golem: an opinionated Hyprland system. Max asked what it does for speed on fast
and slow machines, and to apply everything that serves us.

"They do X" is not "X is faster". Omarchy publishes numbers for its shell, almost none
for its kernel or sysctl. So each item below was measured here before it was kept. Where
a machine could not be used, the entry says so.

Machines: the **dev box** (Lenovo Slim Pro 9, i9-13905H, 32 GB, NVMe, on the charger).
The **MacBook Air** (i5-4250U, 4 GB) was off the network all day and measured nothing.
No machine with a spinning disk was available.

## Taken and applied

| What | Where | Result on the dev box |
|---|---|---|
| Power mode follows the charger, remembered per source | launcher `power_mode.rs` | see the table below: the largest gain of all |
| A dock at rest reacts to events, it does not poll | launcher (see below) | 100.7 → 14.7 wake-ups/s, 0.60 → 0.14 % of a CPU |
| A budget test for rest, in counts | launcher `tools/perf-guard/rest-check.py` | fails on a new timer or poll |
| Writes capped in bytes, not percent | `Modular/memory/zram-tier{1,2,3}.nix` | worst stall halved, see below |
| Reclaim early, in the background (`watermark_boost_factor=0`, `watermark_scale_factor=125`) | `Modular/base/core.nix` | no memory pressure on 32 GB: nothing to see; for small machines, not measured |
| Flusher every 15 s (`dirty_writeback_centisecs=1500`) | `Modular/base/core.nix` | fewer disk wake-ups; safe because the caps bound the bursts |
| `tcp_mtu_probing=1` | `Modular/base/core.nix` | their cure for SSH hanging on bad links; costs nothing |
| `preempt=full` | `Modular/base/core.nix` | build unchanged, tail of wake-ups under load better, see below |
| `systemd.tty.term.console=dumb` | `Modular/boot/plymouth.nix` | their fix for a black boot, about 1 in 10 on their machines; boots in the VM test. Not the cause of the Air's hang, which stopped at another stage |
| `uwsm start -g -1` | `Modular/desktop/greeter.nix` | gain under 0.16 s on the dev box; they claim about 3 s; to be measured on the Air |

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

### The dock at rest (60 s on an empty workspace)

| | before | after |
|---|---|---|
| Wake-ups a second, all threads | 100.7 | 14.7 |
| CPU | 0.60 % | 0.14 % |
| Loop turns a second | 40+ | 3.3 |

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
tier's rule says.

### Full preemption (8000 sleeps of 1 ms while all 20 CPUs are busy, half in the kernel)

| | lazy (default) | full |
|---|---|---|
| Median lateness | 3.3, 2.7, 3.6 µs | 3.2, 3.2, 2.3 µs |
| 99th percentile | 22, 351, 104 µs | 18, 18, 17 µs |
| Worst | 3.3, 3.2, 2.2 ms | 2.4, 0.9, 1.7 ms |
| Real build | 98.0 s | 98.5, 100.0 s |

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
| Kyber on the NVMe | 8 GiB write test: read median 0.87 ms against 1.05, worst 21–25 ms against 22–27, fsync unchanged. No gain. Not tried on SATA |
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

The MacBook was unreachable all day. When it is back, in this order:

1. `GOLEM_LAB_BRANCH=main tools/deploy/lab-pull.sh` to bring it to this version.
2. `journalctl -t uwsm` and Hyprland's log: did `-g -1` bring the 3.4 s from login to the
   compositor down?
3. Power mode on it, balanced against performance (its dead battery and PROCHOT release are
   why this one must be looked at), with the benchmark below.
4. Kyber against its current scheduler, with `ioprobe`.
5. `rest-check.py` on it, to see the budget on a weak machine.

## How to measure again

The tools are in the launcher's `tools/perf-guard/`:

- `rest-check.py`: the dock at rest against a budget.
- `burst.c`: a job after idling, wake-up lateness, one thread, all threads.
- `wakeload.c`: wake-up lateness with every CPU busy.
- `ioprobe.c <dir> <GiB>`: what a big write does to fsync and reads.
