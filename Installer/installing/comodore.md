# Comodore — the module-database sweep (BIOS + legacy Intel)

Max's treasure. Intel GM45 whitebox · Pentium T4200 (2c/2t) · GMA 4500
(Gen4) · BIOS/legacy · 1931 MB · no BT · wired-only (Marvell sky2) ·
931 GB HGST (**Linux — guarded**). Preinstall history:
`~/GolemOne/Install/Preinstall/testing/comodore.md`.

## Round I2 coda — 2026-09-15 — the lid that lies (#90), the boot that wasn't (#91), and the quiet boot (#89) — gens 3→5 in one morning

**Status in one line:** gen 5 booted and verified (`c7lx0rd7…`, `running`,
0 failed units, 0 suspends), the lid quirk live, the boot fully silent
from Golem's first MBR instruction to the themed menu — the one
remaining cursor blink is the BIOS's own, before our code exists.

### The lid that lies (#90) — Max: "it goes sleep after like 30s ish, and that is Golem"
It was. Caught in one of the 30 s wake windows and pinned awake by
masking every sleep target; the evidence in one pull:
`/proc/acpi/button/lid/LID/state` = **closed** with the lid open and Max
at the screen; battery innocent (BAT0 100 %, on AC); `PM: suspend entry`
every ~31–35 s — logind's post-resume holdoff cadence, `HandleLidSwitch=
suspend-then-hibernate` (power/laptop) believing a stuck 2008 reed
switch. The medium never showed it (installer profiles ignore the lid);
the 09-14 audit never showed it (the switch read open then — it sticks
INTERMITTENTLY: after the gen-3 reboot it read **open** again). Fix:
`quirks/lid-switch-broken.nix` (`HandleLidSwitch=ignore`), an OWNER EDIT
in `hosts/target/modules.nix` — the first quirk to arrive by hand rather
than by the chooser. Gens 3–5 have slept **zero** times.

### The boot that wasn't (#91)
The morning power-on that "rebooted" the machine had not: `/run/booted-system`
still said gen 1 (`yi4krfsi…`) while the profile said gen 2 — the bag
timer had hibernated it overnight and the power button RESUMED the image
instead of booting. On a machine with suspend-then-hibernate + wired
`resume=`, "power-cycled" and "rebooted" are different claims; only the
audit's `booted:` line tells the truth. Gen 3's clean `systemctl reboot`
discharged the long-owed real reboot.

### The quiet boot (#89) — three generations, each moved the line
Max's eyes at the screen were the instrument for all three:
| gen | change | Max saw |
|---|---|---|
| 3 | banner strings emptied (boot.S "GRUB ", diskboot "loading…", main.c Welcome) + lid quirk | "looks good" — banner gone; a `_` blinks twice before the menu |
| 4 | cursor hidden at `grub_console_init` (BIOS int 10h, 0x2000) | still blinking — the window is EARLIER than core |
| 5 | cursor-hide as boot.S's opening move, replacing the old "GRUB " print (%dx already stacked; `.org` layout makes overflow a build error) | **one blink** — pre-MBR, the BIOS's own |
Byte-verified before and after landing: `strings` on boot.img/diskboot
show only error strings; `b4 01 b9 00 20 cd 10` present in the built
boot.img AND read back from `/dev/sda` sector 0 after gen 5's
grub-install. `grub_console_cls` and the menu path were audited for
re-enables: the only `setcursor(1)` sites are the command-line reader
and editor — off the menu path, so the emergency CLI keeps its cursor.
What remains is firmware territory: the BIOS's cursor during POST/USB
enumeration. Levers if Max wants it: BIOS Quiet/Fast boot, or unplug
the spare dongle (`wlp0s29f7u2` sits disconnected but is enumerated at
POST). Owed at the next recut: the ISO's UEFI GRUB gets the same patch.

### The deliveries — #67's answer, re-proven three times in one morning
Three live deliveries over the rtl8187 (the dongle class that killed
two machines), all via the new `tools/deliver-live.sh` (the throttle
pointed at a running system, DB-checked per #85): gen 3 16 paths (one
drop, auto-backoff 400→200 KB/s, resumed, complete), gen 4 14 paths
(clean, 2 m 25 s), gen 5 14 paths (clean, 2 m 20 s). The seed synced
each time — `installed == seed` held through all three generations.

## Round I2 — the real install — 2026-09-13/14 — **PASS** (stage 0 on the lab's oldest machine), and it caught #87

**Status in one line:** installed, booted, audited — `comodore` on
`/dev/sda3`, `is-system-running: running`, **0 failed units**, rejoined the
lab by itself over a USB dongle, tier-1 exact. It also caught a leaf that
was doing nothing while every layer of verification said it worked (#87).

**The overnight dark period was branch 1, confirmed by Max at the screen:**
BIOS boot order took the USB stick again, and the MEDIUM gave up on wifi
after NM's default 4 retries. The retry-asymmetry inference recorded below
was right, and **#63's prediction held** — see changes.md #63, now upgraded.
Stick pulled → the installed Golem booted → `.129`, the same address the
I2 sweep used.

### First boot — the rule-6 audit (`tools/firstboot-audit.sh`)
| | |
|---|---|
| hostname / root | `comodore` on `/dev/sda3` |
| generation | `yi4krfsi…-nixos-system-comodore` — **byte-identical to the toplevel built here**, so what CI built is what booted |
| health | `running`, **0 failed units** |
| boot time | 40.9 s (1.1 kernel + 10.4 initrd + 29.5 userspace) — the slowest in the lab, as expected of a 2008 Pentium |
| **tier1, exact** | zram0 **2.8 G prio 100** + 4 G disk swap · swappiness **180** · cache-pressure **50** · dirty **5** · page-cluster **0** · max-jobs **1** |
| resume= | `by-uuid/e6ac076f…` — wired |
| **#65** | **0** fbcon/splash occurrences on the booted cmdline |
| owner | `max` uid 1000, shell **zsh** |
| self-rebuild | `rebuild-golem` present · seed present · `modules.nix` in the seed |
| MINIMAL | hyprland / greetd / waybar / waverunner all **absent** — correct |
| intel-legacy | `LIBVA_DRIVER_NAME="i965"` |
| **#68** | theme present at `/boot/theme/` · `set theme=` in grub.cfg · **bootctl noise = 0** (the BIOS fix works) |
| **#64** | **`golem-lab:wlp0s26f7u3:activated`** — rejoined by itself, over a USB dongle, no keyboard |

**#64 is the quiet win here:** the machine came back on the network
unattended over a **USB wifi dongle** — the hardware class #67 convicted.
`--lab-wifi` + `rtw8821a`/rtl8187 firmware in the closure did their job.

### What the audit CAUGHT — #87, and it is the reason rule 6 exists
`thermald` reads **inactive**. The chooser picked `power/thermald.nix` on
purpose; the effect matrix asserts `services.thermald.enable == true`; the
source build confirmed `thermald.service` in the closure. On metal it
starts, prints *"NO RAPL sysfs present … Unsupported cpu model or
platform"*, and **exits 0** — a clean success. systemd therefore reports
`enabled`, `inactive (dead)`, and **`failed units` stays 0**.

Family 6 **model 23** (Penryn, 2008) predates RAPL/powercap, which arrive
with Sandy Bridge; `/sys/class/powercap/` does not exist here. The machine
is **not unprotected** — `acpitz` at 40.8 °C, two `Processor` cooling
devices, `coretemp`, `acpi_cpufreq`/`schedutil` — but thermald's adaptive
layer is absent while our records claimed it was present. Full entry and
the proposed fix: **changes.md #87**. The hp (Arrandale) is predicted to
be identical; it was powered off, so that is unconfirmed.

### SELF-REBUILD — generation 2, and it demolishes an assumption
`rebuild-golem` (`nixos-rebuild switch --flake /home/max/Golem#golem-minimal`)
on the **1931 MB** machine:

- **07:02:28 → 07:05:25 — under 3 minutes. EXIT=0. → generation 2.**
- **Peak memory ~1165 MB. Peak swap: 1 MB.** It did not thrash. It barely
  touched swap.
- `activated == latest`; health after: `running`, **0 failed units**.

**This contradicts the #16/#66 premise for the minimal path.** That floor
says a sub-3300 MB machine "cannot EVALUATE the target config locally
without thrashing" — and it is right, but it was measured against the
**FAT `golem-target`**. `golem-minimal` evaluates on the lab's oldest and
smallest machine in three minutes using 60% of its RAM. So **rule 5's
ladder holds even here**: stage 1 can arrive on the comodore by rebuild,
not reinstall. The floor's message and scope should say *which* config it
is talking about — worth a look when #66 is next touched.

**One real difference, chased to the bottom (→ changes.md #88):** gen 2's
toplevel is not the installed one. `diff-closures` is **empty**; same
kernel, same params, same binaries; the two `system-path` buildEnvs differ
by exactly one input — `nixos-version` — because
`configurationRevision` went from the dev box's `d0347f9d…-dirty` to
**`unknown`**, the seed being a plain copy with no `.git`. Functionally
identical, but the machine can no longer say what it runs. That **answers
the #35b carried decision** with a consequence instead of a preference.

### Verdict
**PASS.** Stage 0 installs, boots, audits clean, reaches the lab
unattended over a USB dongle, and **rebuilds itself** on the oldest,
smallest, slowest machine in the lab — a 2008 Penryn with 1931 MB. The
i965-legacy + grub-bios path is no longer just "built on source"; it runs.

Findings this machine produced that no other could: **#67 answered**
(throttle, not sneakernet), **#66 proven on metal**, **#63's prediction
confirmed**, **#85** (present-but-unregistered store paths), **#87**
(thermald is a silent no-op pre-RAPL), **#88** (self-rebuild erases the
revision).

**Still owed:** Max's eyes on the GRUB menu — #68's theme is verified on
disk and in `grub.cfg`, but a boot menu is only true on the screen. And a
reboot, since the rebuild reports `REBOOT REQUIRED` (gen 2 is activated
but gen 1 is still the booted kernel).

*(The pre-boot record below is kept as written — it is how the night
actually ran, including the inference that turned out correct.)*

The comodore's round-I2 turn, resumed after #67 killed the first attempt
mid-`nix copy` on 09-11 (disk left prepared, ~188 MB of 2.95 GiB landed,
no bootloader, machine off the network until power-cycled).

### The state found at 23:35
- Powered back on by Max, booted the round-I2 stick, reachable at
  **192.168.1.109** over `golem-lab` — but on a **different dongle** than
  the one that killed it: `wlp0s29f7u1` = **rtw88_8821au** (the DELL's
  dongle from #67). The original `wlp0s26f7u3` = rtl8187 is present and
  DOWN. Both are #67's convicted hardware.
- **`enp4s0` (sky2) is present with carrier 0** — the internal ethernet
  the I2 sweep used at .129 is there, but no cable reaches the machine
  tonight. That is why the dongle path was taken at all (Max's call).
- The first attempt's work had survived intact: GPT `sda1` bios-boot /
  `sda2` swap / `sda3` ext4 `golem`, a complete seed, and target files
  whose census matched the fixture fact for fact.
- **The db-vs-filesystem hazard, found here:** `/mnt/nix/store` held 78
  path directories but the database had registered only **76** — a
  truncated `nix-manual-2.34.8` (+ its `.lock`) left mid-write by #67's
  death. An `[ -e ]` presence test — which the first overnight script
  used — calls that path present, and the install would then activate
  against a path Nix does not know. The delivery now asks
  `path-info --all`, i.e. the DATABASE, so a half-written path is
  correctly re-sent.

### Why it was re-prepared rather than resumed
The surviving `machine.nix` had **no `--lab-wifi` block** — the 09-11
prepare predated the flag reaching this machine. On a box whose only link
is a USB dongle, that means an installed system with no known network:
#64 all over again, and unreachable for the first-boot audit with no
keyboard help. The patched engine's delta measured **1.92 MiB** on the
wire, so a clean re-prepare cost ~10 min of re-sent closure and bought an
engine-written `machine.nix` instead of a hand-edited one.

### The prepare (23:48) — and #66 proven on metal, in its own record
The shipping I2 stick predates #66, so its engine still `check_fail`s
both `--prepare-only` and `--skip-prepare` at 1931 MB. The patched
`golem-install` was nix-copied onto the running medium (the constitution's
live-fix refinement — **the stick stays frozen**). checks.txt:

```
ok     firmware: booted BIOS/legacy — GRUB to /dev/sda (BIOS-boot partition)
ok     target: /dev/sda is not the boot medium (/dev/sdb)
ok     fit: root gets 949772 MiB after boot+swap (the closure needs ~19 GiB)
warn   ram: 1931 MB is below the local-eval floor — fine here: this run
       does not evaluate (the system is built elsewhere and delivered)
ok     facts: the probe now matches the boot audit fact for fact
```

That `warn` is #66's whole point, on the machine that found it: the run
that would have been refused completed. `choose.err` empty. Disk identity
confirmed against `ata-HGST_HTS541010A9E680_JB10001320T92B` before the
first destructive verb; the stick (`sdb`) was correctly excluded (#20).

### A scope fact worth stating plainly
`golem-install` bakes its seed source at BUILD time (`src="${golemSrc}"`).
Because the patched engine was built from today's tree, the seed it
dropped is **today's source, not the frozen I2 cut** — same nixpkgs rev
(`c5c4a43b`, verified identical on both sides), differing only by the
in-flight **#68** boot work. So this install carries the Golem GRUB theme
and the bootctl-noise fix, `installed == seed` still holds (byte-identical
`system/Modular` and `flake.nix`), and the ISO itself is untouched. Marked
as a live-fix run, not a clean-image run — the acer's I2 entry is the
clean-image record, this one is not.

### The artifact, verified before a byte moved
`yi4krfsi…-nixos-system-comodore` — **2.96 GiB / 1037 paths**.

| check | result |
|---|---|
| hostname | `comodore` |
| chosen leaves | the 8 the sweep predicted, unchanged |
| #65 console | no `fbcon=map:1`, no `splash` — quiet only |
| #68 GRUB theme | `golem-grub-theme` wired into the grub config |
| #68 BIOS noise | `bootctl` occurrences in `activate` = **0** |
| GRUB device | `ata-HGST_HTS541010A9E680_JB10001320T92B` (by-id) |
| intel-legacy | `LIBVA_DRIVER_NAME="i965"` |
| tier1 | swappiness 180 · cache-pressure 50 · dirty 5 · page-cluster 0 · max-jobs 1 |
| power | thermald + upower + power-profiles-daemon |
| self-rebuild | `rebuild-golem` present |
| dongle firmware | `rtw8821a_fw.bin.zst` present — first boot will have a radio |
| resume= | wired to the new swap UUID `e6ac076f…` |

### The delivery (23:52 →) — #67's shape, answered
Plain `nix copy` is what died twice, and #67's own measurement said why:
**~25 KB/s sustained before the drop**, i.e. the link was collapsing
UNDER LOAD, not merely slow. So the delivery rate-limits (`pv -L`) to stay
under saturation, sends **one store path at a time**, and recomputes the
missing set from the target database every round — a drop costs one path,
never the transfer.

- Mechanism smoke-tested first: 465 KiB exported, throttled, imported and
  **registered in the target db** in 2.8 s.
- Opening run: 400 KB/s start, **zero drops**, auto-eased 400 → 500 →
  625 KB/s on consecutive clean streaks. ~295 KB/s effective including
  per-path ssh handshakes and the 2 s breathing pause.
### The delivery RESULT (23:52 → 01:44) — #67 answered, and this is the headline
**2.96 GiB / 1037 paths delivered in 1 h 52 m over a USB wifi dongle, with
ZERO drops, ZERO backoffs and ZERO waits.** One uninterrupted pass; the
second "round" is only the verification sweep finding nothing missing.
The rate auto-climbed the whole way — 400 → 500 → 625 → 781 → 900 KB/s
(cap) — and held. ~460 KB/s average end to end.

This is the control #67 never had. Same machine, same class of hardware
that killed it (tonight's dongle is the rtw88_8821au — the one the DELL
died on), same ~3 GiB payload. The only variables changed were **rate
limiting** and **per-path granularity**. #67's own measurement said the
link was collapsing UNDER LOAD (~25 KB/s sustained before the drop), and
that is exactly what a cap prevents. **The lab does not need sneakernet
for these machines; it needs a throttle.** See changes.md #67.

The one slow stretch — 01:17→01:34, 17 min for 25 paths — is the big
firmware/kernel paths (linux-firmware et al), not a stall: it never
dropped, it just had more bytes to move.

### The install (05:45 medium clock / 01:45 lab clock)
`--skip-prepare --system yi4krfsi…`, patched engine. Clean:
```
resuming: /mnt mounted, seed present — install step only
hostname    comodore  (from seed)      ← the engine reading back its own drop
installing the boot loader...
installing the GRUB 2 boot loader on /dev/disk/by-id/ata-HGST_HTS541010A9E680_JB10001320T92B...
Installing for i386-pc platform.
Installation finished. No error reported.
```
Target state at install time: 1037/1037 paths **registered in the target
database** (not merely present on the filesystem), 3527 MiB, toplevel
valid on the target store.

**#68's theme verified ON DISK** at `/mnt/boot/theme/` — `theme.txt`
carrying the exact `grub-bios.nix` geometry (360×120 at `50%-180`/`50%-60`,
item height 24, `#cccccc` on black, `select_*.png` bar), plus
`background.png`, `select_c.png`, `dejavu.pf2`. The font name written into
theme.txt is **`DejaVu Sans Regular 20`** — read out of the .pf2 at build
time, which is the exact trap grub-theme.nix's header warns about. grub.cfg
loads it: `set theme=($drive1)/boot/theme/theme.txt` + `terminal_output
gfxterm` + `loadfont …/dejavu.pf2`.

### The reboot — where it stood that night *(RESOLVED next morning: branch 1 — it was the ISO)*
> Kept in its original present tense as the honest record of what was and
> was not known at 02:00. Max confirmed at the screen that BIOS boot order
> took the stick; the retry-asymmetry inference below was correct. The
> outcome is the PASS at the top of this file.

Unmounted cleanly (`/mnt` clean, swap off), `systemctl reboot`, machine
down in ~4 s. **It has not returned to the network since.** ~15 minutes of
polling `.109` plus three full sweeps of `192.168.1.2–254`: only the dev
box (.152) and one unrelated host (.190). No ARP entry for it at all.

**What is NOT known:** whether the installed Golem boots. The install
completing says nothing about that, and I will not record a pass I did not
see. Both branches are live:
- **it booted the medium again** (BIOS boot order still prefers the USB
  stick) and the medium simply did not auto-join — this machine is one of
  **#63's two REAL data points**, the round-5 nmtui bounce Max did with
  his own hands; or
- **it booted the installed system** and the rtw88 dongle did not come up
  — NM profile and `rtw8821a_fw.bin.zst` are both verified present in the
  closure, so this would be a new finding, not a known one; or
- it did not boot at all.

I cannot separate these over SSH, and nothing about the disk is at risk in
any of them.

**NARROWED after a 5 h 45 m watch (02:06 → 07:31, machine never appeared).**
The two configurations retry differently, and that asymmetry is
diagnostic:

| | `autoconnect-retries` | behaviour after failing to join |
|---|---|---|
| **installed system** (`machine.nix`, via `--lab-wifi`) | **0 = infinite** | keeps trying forever |
| **the medium** (`iso.nix` `golem-lab`) | **absent → NM default 4** | gives up after 4 and stays silent |

A healthy installed Golem with a working dongle would therefore have
retried all night and turned up. It did not. A booted MEDIUM, by contrast,
would go silent permanently after four attempts — **which is exactly the
observed behaviour**.

So the leading hypothesis is **branch 1: BIOS boot order took the USB
stick again, and the medium gave up on wifi after 4 retries.** This is
inference from the retry asymmetry, **not an observation** — "booted Golem
with a dead dongle" and "did not boot" are not excluded, and only the
screen settles it. But it is the branch that predicts a 5 h 45 m silence
without any new failure.

It also means this machine is, again, evidence for **#63** — the finding
downgraded to UNCONFIRMED. The medium's missing `autoconnect-retries` is
still queued and unapplied; the comodore is one of the two machines whose
hand-bounce was real evidence; and tonight the predicted behaviour
happened. Still not the captured NM journal #63 asks for — but the theory
now has a successful prediction behind it rather than only a story.

**For the morning, at the machine:**
1. Look at the screen before touching anything — that is the only place
   #68's GRUB menu is true, and it also says instantly which of the three
   branches happened (Golem GRUB menu / ISO boot menu / nothing).
2. If it is on the ISO menu → BIOS boot order took the stick. Pull the
   stick and reboot; that is the real first boot.
3. If it is at a `login:` → it booted Golem and only the radio is missing.
   Log in, `nmcli device wifi connect HOLA`, and the audit can run from
   here. That branch is a finding worth its number.
4. A cable into `enp4s0` makes any of this moot for reachability.

Once it answers on the network, the whole rule-6 audit is one command:
```
Installer/installing/tools/firstboot-audit.sh <ip> root
```
It prints identity, health + failed-unit count, the tier-1 sysctls against
actual RAM, `resume=`, the #65 fbcon count, owner/shell, seed +
`rebuild-golem`, the minimal-means-minimal absences, LIBVA/thermald, the
#68 theme + bootctl-noise counts, and which device NM came up on (#64).
Read-only. (Written and run-tested this session — running it caught two of
its own formatting bugs, which is the only reason it is trustworthy.)

**Still owed:** the first-boot audit (rule 6), the self-rebuild to gen 2,
and Max's eyes on the GRUB menu. The #68 theme on a second BIOS machine
and the rtw88 rejoin remain the two things only this machine proves.

## Round I2 sweep — 2026-09-11 — fixtured; the i965-legacy + grub-bios path built on source · NO install (census only)

- **Reachable at 192.168.1.129, no bounce needed** (working ssh/ping
  check — the corrected method; another auto-join datapoint against the
  downgraded #63).
- **Census (fixtured → `fixtures/comodore-gm45/`):** T4200 2c/2t, 1931
  MB, gpu=intel, **intelLegacy=true** (GMA 4500 Gen4 — the #12 fix
  holds), firmware=bios, hasBluetooth=false, cpuVendor=intel, laptop.
  Linux disk (ext4 + swap) untouched, 0 writes.
- **Chosen leaves — the FIRST intel-legacy AND second BIOS in the
  database:** **boot/grub-bios** · cpu/intel-microcode ·
  **gpu/intel-legacy** · zram-tier1 · hibernation · disk/policy ·
  power/laptop · power/thermald.
- **BUILT on source (2.95 GiB):** the composed toplevel compiles, and
  the built system carries the right things — `LIBVA_DRIVER_NAME=i965`
  (not iHD — the Gen4 GMA has no iHD decode), the enhanced-h264ify
  Chrome policy, GRUB enabled + systemd-boot disabled + device
  /dev/sda. chooser-matrix + minimal-matrix pin the list and the
  effects (i965, grub-not-systemd-boot, tier1 swappiness 180 / one
  build job, thermald on).
- **Verdict:** fixtured and source-built. The i965-legacy + grub-bios
  combination — the oldest-hardware path in the lab — is proven to
  compile without touching the treasure's disk.
