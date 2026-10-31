# What Golem took from Omarchy

Omarchy (github.com/omacom/omarchy, read at 717175d4a on 2026-10-30) is the closest
thing to Golem: an opinionated Hyprland system. Max asked what it does for speed on fast
and slow machines, and to apply everything that serves us.

"They do X" is not "X is faster". Omarchy publishes numbers for its shell, almost none
for its kernel or sysctl. So each item below was measured here before it was kept. Where
a machine could not be used, the entry says so.

Machines: the **dev box** (Lenovo Slim Pro 9, i9-13905H, 32 GB, NVMe, on the charger).
The **MacBook Air** (i5-4250U, HD 5000, 3.8 GB, SATA SSD, dead battery), measured the same
evening once it was back. The **ASUS X550LC** with a spinning disk, a night of its own the
evening after: see "The spinning disk", where a good part of this was measured again and
some of it taken back.

## Taken and applied

| What | Where | Result on the dev box |
|---|---|---|
| Power mode follows the charger, remembered per source | launcher `power_mode.rs` | see the table below: the largest gain of all |
| The cursor drawn by the display engine (Hyprland's default, which Omarchy keeps; ours was forced off with no reason recorded) | `system/home/hyprland.lua` | moving the pointer: GPU 24 → 1 %, see below |
| A dock at rest reacts to events, it does not poll | launcher (see below) | 100.7 → 12.6 wake-ups/s, 0.60 → 0.13 % of a CPU |
| Budget tests in counts, at rest and busy | launcher `tools/perf-guard/rest-check.py`, `churn-check.sh` | fail on a new timer, a poll or a stall |
| Writes capped in bytes, not percent | `Modular/memory/zram-tier{1,2,3}.nix` | worst stall halved, see below |
| No reclaim bursts from fragmentation (`watermark_boost_factor=0`; their `watermark_scale_factor=125` was taken back on the ASUS, see "The spinning disk") | `Modular/base/core.nix` | no pressure on 32 GB; on the ASUS no stalls and no cost |
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
beside it never noticed either setting. Kept at first; the ASUS then told the two settings
apart and scale 125 was taken back, see "The spinning disk".

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

## The spinning disk (ASUS X550LC, 2026-10-31)

i5-4200U, 7.4 GB, a TOSHIBA MQ01ACF032 hard disk, HD 4400 (GL only), 1366x768, on the charger with a
dead battery. A whole night on it: everything measured on the system as it was, updated to the
newest Golem, everything measured again. Times are seconds from the kernel's start; add 5.4 s for the
firmware and GRUB. Three clean boots each.

| | Old system (df2c916) | First update (103969b) | Now |
|---|---|---|---|
| Power on to `graphical.target` | 32.5 to 33.9 | 38.7 to 39.1 | 36.8 to 37.1 |
| Login opens | 28.1, 28.2 | 34.1 to 34.2 | 31.7 to 32.1 |
| The compositor's process | 40.0, 40.5 | 47.1 to 49.5 | 42.6 to 45.5 |
| The dock's process | 45.9, 47.4 | 54.6 to 56.9 | 49.8 to 52.6 |
| **The dock's first frame** | **61.5, 63.9** | **69.2 to 74.2** | **52.8 to 56.3** |
| The desktop's icons | 61.6, 63.9 | 69.4 to 74.8 | 54.3 to 57.5 |
| Memory used at rest after login | 960 MB | 1350 MB | 1130 MB |
| The dock at rest, wake-ups a second | 36.5 to 43.8 | 7.2 to 7.8 | 7.1 to 7.6 |
| The dock at rest, a CPU | 0.30 to 0.36 % | 0.09 to 0.16 % | 0.10 to 0.16 % |
| Processes the dock starts at rest | 4 to 10 | 0 | 0 |
| The compositor's late frames at rest | 19, worst 22 ms | 0 | 0 |
| …with every CPU busy | 27, worst 23 ms | 6, worst 23 ms | 0 |
| …opening and closing the shell's boxes | 43, worst 88 ms | 2, worst 812 ms | 3, worst 221 ms |
| The dock's worst stall in those boxes | not measured | 252 ms | 51 ms |
| Failed units | 1 boot in 6 (avahi) | 1 boot in 6 | 0 |

Apps, two cold starts each (the disk cache dropped), in seconds; warm starts did not move (foot 0.06, Files 0.06, Seam 1.4, Chrome 1.3):

| | Old system | Now | Now, during a 4 GiB write | Now, during the store's weekly check |
|---|---|---|---|---|
| foot | 4.09, 2.83 | 3.51, 3.20 | 8.63, 5.23 (was 6.57, 4.79) | 5.02, 3.78 (was 4.28, 3.20) |
| Files | 2.69, 0.80 | 2.44, 1.25 | 1.84, 4.45 (was 1.92, 3.56) | 6.31, 3.23 (was 1.05, 0.46) |
| Seam | 25.9, 17.6 | 29.0, 20.8 | 75.5, 60.7 (was 62.2, 57.4) | 30.7, 30.7 (was 28.9, 23.4) |
| Chrome | 26.1, 22.2 | 20.2, 18.0 | | |

NOT better, said plainly: `graphical.target` is still 3 to 4 s later than the old system's, spread over many services and no single one (the login with it); memory 170 MB more; Seam 3 s slower cold (a newer Seam reading 565 MB to its first window, no one thing: 8 s of it in its profile); Files during the store's weekly check 3 to 5 s slower with the caches cold, not looked into.

The first update made it WORSE. Reading why took the rest of the night, and the method is the lesson:
`/sys/fs/cgroup/**/io.stat` says who reads how much at boot, `strace -f -T -y` on the dock from
its first moment (a drop-in on its unit) says which files in which thread, and a spinning disk
turns every little file into seeks. What came out, largest first:

| What | Measured | Now |
|---|---|---|
| Mesa's shader cache, one file a shader, each in a folder of its own | the dock's 28 shaders: 10 to 15 s of its GPU opening at login, up to 1.5 s a file | `MESA_DISK_CACHE_DATABASE=1`, one part (`desktop/session.nix`): 0.3 to 2 s. The other single-file kind (`MESA_DISK_CACHE_SINGLE_FILE`) was as fast but has no size limit |
| cosmic-text opens every font flagged monospaced as a font system is made | 104 files (82 JetBrains), the first frame waited 5 s for them | The flag stays on the generic family and DejaVu Sans Mono only (launcher `font_index.rs`). The dock reads 113 MB at start, not 205 |
| The dock asked `powerprofilesctl`, a Python program, at each start (added the day before, for the power mode) | 1258 file opens, 5 s of disk while the GPU was opening | The bus (launcher `power_profiles.rs`) |
| sshguard's `journalctl -afb -n1 -t sshd` looks through the whole journal | 97 MB, 1400 reads, right at the login | 90 s after boot, on idle I/O (`base/security.nix`) |
| The bus reads three folders per package (`share/dbus-1/...`, forty packages) | 1329 reads for 8 MB, before `basic.target` | One folder of copies (`boot/flat-dbus.nix`), 492 reads for 4 MB |
| `avahi-daemon` killed by openresolv's SIGHUP before it has a handler, one boot in six | Failed for the rest of the boot, printers undiscovered, and a `switch` ending in exit 4 | Restarts; the stale PID file goes (`desktop/printing.nix`). Its first fix did not work: the `rm` needs the `+`, the unit's capabilities leave root unable to remove it. Only the kill test showed it |
| A test drop-in of 2026-10-16 (`zz-colours-test.conf`) pinned this machine's dock to a two-week-old build | Unseen by parity | Removed; parity reads the installed unit and lists undeclared drop-ins |
| `fwupd-refresh` every hour | Failed under disk load, and is a disk load | Daily |
| Vulkan asked first on a machine with no Vulkan GPU | 3.9 s at each start | Remembered per graphics stack and card (`gpu-gl-only`): straight to GL |

Measured and NOT changed, each its own small result:

- **Scheduler.** Small apps opened during a 4 GiB write (two cold launches each):

  | | foot | Files | Seam |
  |---|---|---|---|
  | BFQ, Golem's | 6.9, 5.3 | 5.3, 6.3 | 74.9, 65.4 |
  | mq-deadline | 41.8, 41.0 | 38.9, 36.2 | 60.8, 60.1 |
  | Kyber, Omarchy's | 46.1, 41.5 | 40.6, 41.1 | 61.6, 58.3 |

  BFQ stays: Omarchy's Kyber would make a small app seven times slower here. Seam gains a little without BFQ, because a
  big read is what BFQ holds back. BFQ also lets the store's weekly check run unnoticed: foot 4.3, 3.2 s under it, against 4.1, 2.8.
- **Writes capped in bytes** gain nothing on this disk and lose nothing (6.9, 5.3 against 8.3, 6.1 for foot, within noise). They stay for the NVMe.
- **`watermark_scale_factor=125` is TAKEN BACK.** A program using 90 % of memory, four rounds each, passes of its work:

  | | scale 10 | scale 125 |
  |---|---|---|
  | boost 15000 | 16390, 21671, 21707, 21584 (39 stalls in the first, then none) | 19161, 19981, 17237, 16360 |
  | boost 0 | 21674, 21222, 21637, 21198 (no stalls) | 19616, 20146, 20094, 16000 |

  Scale 125 keeps memory free by swapping for nothing (about 13 thousand pages out a round, almost none at scale 10 once started), about 10 % less work. Boost 0 alone is free. A small job beside it never noticed any of them.
- **Read-ahead.** The kernel gives a rotational disk 8 MB by itself now (twice its largest transfer). Cold starts of Seam and Chrome: 128 KB 31 to 38 and 34 to 39 s; 1 MB 23 to 27 and 23 to 28 s; 4 MB 21 to 24 and 19 to 33 s; 8 MB 21 to 29 and 18 to 20 s. foot and Files do not care. Left alone.
- **The journal's size.** With 16 MB of journal rather than 199 MB, flushing it at boot takes 1.9 s, not 5.9, and the login moves less than a second, because a device's udev rules hold `sysinit.target` as long. Keeping a month of logs is worth more.
- **The login waiting for the network** (`systemd-user-sessions` after `network.target`; `work/parity.md` kept this open for Max). Taken out: greetd starts 3.6 s sooner and the login still opens at 32 s, the first frame no sooner. Nothing to decide: left as it is.
- **The power mode and full preemption**: no difference on this machine, in either direction (a job after idling 29 ms, one thread 4.66 s, all 8.12 s; lazy and full cannot be told apart).
- `uwsm -g -1` and the dirty caps were the two things this machine was to prove. Neither did.

Where the rest goes now, as the next places to look: the initrd's 11 s (perl for users and `/etc`; userborn and an `/etc` overlay would cut it, not tried: it moves Wi-Fi keys and host keys on machines already installed); login to compositor 11 s (uwsm's Python, three starts; a compiled `aux exec` or its modules in one zip); compositor to dock 7 s (two `--version-json` runs and an `lspci` in Hyprland's own start, and Mesa with LLVM); on the dock 1.2 to 1.6 s each for creating the first surfaces, once its first frame is up.

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
| Kyber on spinning disks | Measured on the ASUS: a small app seven times slower during a big write than on BFQ, see "The spinning disk" |
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

The dev box and the MacBook Air rebooted into the first version of this: the dev box 15.4 s from power
on (16.9 s before), the Air 18.0 s (19.3 s before). Neither has rebooted into what the ASUS's night added.

- **Heavy daily use on the Air**: scale 125 is gone, stalls may be back; only there can it be felt.
- **The rest of a spinning disk's start**: the last paragraph of "The spinning disk".

## How to measure again

The tools are in the launcher's `tools/perf-guard/`:

- `rest-check.py`: the dock at rest against a budget.
- `churn-check.sh`: the dock busy against a budget (dev box: 4 stalls over 30 ms in 6 rounds, worst 39.6 ms).
- `burst.c`: a job after idling, wake-up lateness, one thread, all threads.
- `wakeload.c`: wake-up lateness with every CPU busy.
- `ioprobe.c <dir> <GiB>`: what a big write does to fsync and reads.
- `vblank.py <secs>`: how often the panel really refreshes (DRM timestamps).
- `cursor-test.py <secs>`: the pointer driven in a circle, and what the compositor spends.
- On a spinning disk: `cat /sys/fs/cgroup/**/io.stat` soon after a boot (who read how much, and in how many reads: the reads are what cost), then a drop-in on the suspect's unit, `ExecStart=strace -f --seccomp-bpf -tt -T -y -e trace=openat,read,pread64 -o <file> <its command>`, and a boot: each thread's opens and reads with what each took.
