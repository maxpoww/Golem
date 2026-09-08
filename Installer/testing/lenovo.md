# Lenovo

Lenovo Slim Pro 9 16IRP8 (83C0) · i9-13905H Raptor Lake (14c/20t) ·
**hybrid: Intel Iris Xe iGPU + NVIDIA RTX 4050 Max-Q dGPU** · boots
**UEFI** · 953.9 GB Samsung PM9A1 **NVMe** · 32 GB RAM · Intel CNVi wifi ·
high-DPI 16" panel. **This is the dev box** — the machine that drives the
lab and holds the records.

## Why it's in the lab (joined for round 3)

The only machine that exercises what the five old laptops can't:
- **NVMe target** — every other machine is SATA; the disk step, by-id
  naming, and scheduler decision (bfq is rotational-only) meet NVMe here
  first.
- **The healthy-dGPU path (#17c) on lab metal** — the gpu-health-probe
  prototype already proved HEALTHY here (nvidia wake from suspended, 0
  errors); round 3+ tests the real census/reveal path: primary by
  `boot_vga` (Iris Xe), dGPU second row, `tested, working · apps can use
  it on demand`.
- **panelDpi / scale decision** — no old laptop has a high-DPI panel; the
  census fact and the scale decision have never been seen on metal.
- **Modern baseline** — 13th-gen, fast eval: the "Golem also works on new
  metal" proof, and a lower bound for eval-time comparisons.

## Lab mechanics for THIS machine (different from the others)

- Testing it means **booting the dev box from the stick** — the dev
  session, the records, and the SSH driver's seat are down for the slot.
  Driven at the physical keyboard (it works, unlike the Dell's); findings
  photographed/noted, written up after reboot back into the dev system.
- **Rehearsal only, indefinitely.** The NVMe holds the lab, the source,
  and the records. The disk-untouched check (lsblk UUIDs before/after) is
  MANDATORY here every single run, no exceptions, and a real install on
  this box is out of scope until Golem is well past round 4.
- "Suspect the harness first" gets a twist: here the rig IS the subject.
  Anything odd → re-check from the reboot-restored dev system before
  believing it.

---

## Status: ~~DEFERRED~~ → FIRST CONTACT DONE (2026-09-08, Fedora driver)

**Superseded — see the round-3 record at the bottom of this file.** The
portable driver closed the gap the same day: the Fedora ThinkPad drove
the rehearsal over SSH while this box sat on the medium, so the dev box
never had to drive its own test. The healthy turing+ path below is now
proven on metal, not by fixture. The deferral reasoning is kept as
written for the record:

> First contact deferred indefinitely. Testing this box means booting the
> dev box itself from the stick — which takes down the session that drives
> the whole lab — so it is the one participant that can only be tested from
> ANOTHER machine, "someday, not today" (Max). Round 3 is considered closed
> without it.

> **What it would have added, and why deferral is low-cost:** its unique
> contribution was the HEALTHY modern-nvidia path on real metal (Iris Xe +
> RTX 4050 → turing+ → open module + working PRIME offload). The ASUS
> (round 3) already covers the intel+nvidia hybrid TOPOLOGY and the risky
> questions — boot_vga primary pick, the dGPU health verdict, the iron-law
> floor — but with a FAILING old Fermi, not a healthy RTX. So the healthy
> turing+ offload path stays proven by FIXTURE EVAL only (done during the
> #22 fix: turing+ facts → open module + PRIME offload activate), not on
> physical metal. That is the happy path and the least likely to surprise;
> the first healthy-nvidia machine to appear gets the live proof.

## Round 3 first-contact — procedure for the Fedora driver (2026-09-08)

The portable driver now exists: **Fedora on the ThinkPad**
(192.168.1.167), running Claude Code with the golem-vm-loop key and a
clone of this repo. That session — NOT the dev-box session — runs the
Lenovo's test, because the Lenovo is down (booted on the medium) during
it. Steps for the Fedora-Claude:

1. `cd ~/Golem && git pull` first (always).
2. The Lenovo boots the **Golem round-3 stick** (14.4 GB, `p5ylp6q6…`).
   Sweep 192.168.1.0/24 for it; identify by DMI
   (`product_name` = Slim Pro 9 16IRP8) and confirm it's on the MEDIUM
   (`findmnt /iso` resolves) before trusting anything.
3. Follow [CLAUDE.md](CLAUDE.md) exactly: read census
   (`/var/log/golem-audit/summary.txt` + golem-hardware.nix), then drive
   `golem-setup` in a tmux (apt/dnf a tmux if none — it's not a frozen
   artifact) through the six screens, poll the rehearsal status, pull the
   bundle, checks.txt first.
4. **What this machine uniquely proves:** the HEALTHY modern-nvidia path
   on metal — expect `gpu = intel` (boot_vga), `gpu2 = nvidia`,
   `nvidiaGen = turing+`, `gpu2Health = working` → reveal "GPU 2 … tested,
   working · apps can use it on demand" and the target evaluating PRIME
   offload. Watch for a facts-match flap (#23) and confirm the console is
   quiet. Record it all in this file, per the round record format.

### ⚠️ THE ONE RULE THAT CANNOT BE BROKEN

This machine's NVMe (`nvme0n1`) **IS the lab** — it holds this repo, the
Golem source, every record, and the dev-box Claude's whole world. A real
`golem-install` here erases all of it. The stick bakes
`GOLEM_REHEARSE=1`, so golem-setup only rehearses (writes nothing) — but:
**never** run the engine without `--rehearse`; **verify `nvme0n1` is
byte-untouched before and after** (constitution rule, mandatory every
run); treat that disk as radioactive. When in doubt, stop.

### Handoff back

After the rehearsal, commit this file on the Fedora
(`git commit`; push if `gh auth` is set, otherwise leave it committed
locally). Max reboots the dev box to normal; the dev-box Claude pulls the
record straight off the Fedora over SSH. Done.

---

## Round 3 (machine 7 of the round — the dev box, last in) — 2026-09-08 — the healthy modern-nvidia path PROVEN ON METAL · NVMe first contact · a THIRD manifestation of #23

- **ISO:** round-3 stick (14.4 GB, `GOLEM_INST`), `golem-setup`
  `acpa26g0k9py…`. Identity checks all pass: `valid_host Golem` = 1
  (hostname fix), `cores = 14` (sysfs fix, correct for the i9-13905H),
  `firmware = "uefi"` fact present, `GOLEM_REHEARSE='1'` + `GOLEM_LAB='1'`
  baked into the wrapper. Same frozen round-3 Golem the other six met.
- **Driven from the Fedora ThinkPad** (192.168.1.167) over SSH, per the
  first-contact procedure above — NOT at the physical keyboard. The
  portable driver worked exactly as designed: the dev box was down on the
  medium the whole slot and the driver session never needed it.
- **Boot:** UEFI · joined HOLA on its own (Intel CNVi, `iwlwifi`) ·
  found at 192.168.1.152 by sweep · DMI `LENOVO` / `83C0` ·
  `findmnt /iso` → `/dev/sda`, on the medium. `golem-audit.service`
  finished clean (17.06 s → 46.06 s).

### ⚠️ The one rule: HELD

`nvme0n1` verified **byte-untouched**, before and after, four ways:
GPT label-id + all three partition UUIDs/PARTUUIDs identical, `sfdisk -d`
dump identical, first 4 MiB SHA256 identical
(`a5082774eade…`), last 4 MiB SHA256 identical (`194fb860f3a8…`).
`diff` of the before/after snapshots: **zero lines**. The lab, the source
and the records are intact. Engine never ran without `--rehearse`;
transcript is all `would`.

- **Census:** `status: ok`. Every fact cross-checks against known
  hardware: i9-13905H, **cores 14 / threads 20** (correct — 6P+8E), RAM
  31816 MB, `firmware = uefi`, `chassis = laptop`, `hasBluetooth = true`,
  `cpuVendor = intel`. **#17b live and correct on a modern hybrid:**
  `gpu = "intel"` by `boot_vga` (`0000:00:02.0` = 1, `0000:01:00.0` = 0),
  `gpu2 = "nvidia"` + `gpu2BusAddr = "0000:01:00.0"`,
  `nvidiaGen = "turing+"` (AD107 `10de:28e1`, well above the 0x1e00
  Turing floor), both bus IDs emitted for PRIME.
  **First high-DPI panel in the lab: `panelDpi = 239` → `scale 1.60`** —
  the census fact and the scale decision, never before seen on metal,
  both land correctly.
  **First NVMe in the lab:** target named `SAMSUNG MZVL21T0HCLR-00BL2
  953.9G` in the drive list, engine addressed `/dev/nvme0n1` and
  `nvme0n1p1..p3` throughout — the `p`-suffix partition naming is right
  everywhere in the transcript.

### THE HEADLINE: the healthy modern-nvidia path, proven on metal — but NOT by the boot audit

The boot audit reported **`gpu 2 health: unknown`** (no `gpu2Health` key
at all in `golem-hardware.nix`), where the whole point of this machine
was to prove `working`. Suspected the harness first, and the harness was
the problem. **The chip is healthy — proven three independent ways:**

1. **The install-time re-probe** (rehearsal, minutes later, quiet log):
   `gpu2Health = "working"`.
2. **The evaluated target took the right branch** — the built toplevel's
   closure contains `nvidia-open-595.71.05-6.18.48` (the open GSP
   module), `nvidia-offload` (the PRIME offload wrapper),
   `nvidia-x11-595.71.05` (current branch, NOT the 580 legacy) and
   `nvidia-vaapi-driver`. **This is the first time the turing+ → open
   module + PRIME offload path has been evaluated from facts measured on
   physical metal** rather than from a fixture. #17c's happy path is now
   real.
3. **A hand-run of #23's DECIDED round-4 probe** (below): a genuine cold
   resume from a 12.6 s suspend → **0 errors, zero new dmesg lines.**

### NEW FINDING — #23's third manifestation, and a NEW direction: a FALSE NEGATIVE

The ASUS gave a flap (`working` → `failing`), the HP a false positive
(`working` on a chip that fails every resume). The Lenovo gives the
mirror image: **`unknown` on a demonstrably healthy chip.** Root cause,
established on the box:

- `golem-audit.service` starts at **t = 17.06 s**. nouveau's own GSP
  init runs **t = 14.6 s → 20.4 s**. The probe's 3-second dmesg window
  therefore sat on top of the driver's *own boot chatter*.
- The counter matches **any line containing the dGPU's BDF** — not just
  errors. So `nouveau 0000:01:00.0: NVIDIA AD107`, `gsp: RM version:
  570.144`, `drm: VRAM: 6141 MiB` and ~40 benign GSP `ctrl cmd` lines all
  counted as convictions. **A healthy chip convicted itself with its own
  successful initialisation.**
- The retry could not rescue it: `power/control` was already `on`
  (`runtime_enabled: forbidden`), so the bounded wait for
  `runtime_status = suspended` could never succeed; the second poke was
  vacuous, returned 0, and the verdict fell through to *unspoken* →
  `unknown`.
- **Replayed the identical probe logic by hand on a quiet log: `e1 = 0`
  → `working`.** Same machine, same boot, same code — only the log
  window differed.

**Does the decided #23 fix (force-cold before every poke) rescue this
machine? TESTED HERE: YES — but only just.** Set `power/control = auto`
and the chip went `active → suspending` at t+7 s, `suspended` at t+8 s of
the 10 s bound. Then the cold-resume poke: **0 errors**, `suspended
(12634 ms) → active`, not one new kernel line. So force-cold produces the
correct `working` here — with **2 seconds of margin on a 10-second
bound**, on the fastest machine in the lab.

**What #23's fix still does NOT cover** (queued as 23b):
  a. the error counter is **unscoped** — it matches the bare BDF, so
     ordinary init lines convict, and it matches `\*ERROR\*` from *any*
     device, so an iGPU fault is charged to the dGPU. This very boot
     carries `i915 0000:00:02.0: [drm] *ERROR* Port E/TC#2: timeout
     waiting for PHY ready` at t = 15.2 s — it missed the audit window by
     1.9 s. On a slightly slower boot the Intel iGPU's error would have
     condemned the NVIDIA chip.
  b. nothing makes the probe **wait for the driver to finish
     initialising** before counting.

- **Reveal / target skew, this boot — the REVERSE of the ASUS's, and the
  safe direction:** the confirm screen showed
  `GPU 2  NVIDIA GeForce RTX 4050 Max-Q · nouveau` — **bare, with no
  verdict clause at all**, where a `working` verdict would have added
  "tested, working · apps can use it on demand". So an `unknown` health
  degrades *gracefully*: the reveal makes no promise it cannot keep. The
  evaluated target meanwhile used the re-probed `working` facts and built
  the offload stack. The user is under-promised and over-delivered —
  where the ASUS was over-promised. **`checks.txt` caught it:**
  `warn facts: the probe now DIFFERS from the boot audit … > gpu2Health =
  "working"`. The #23 instrument has now caught the flap in both
  directions.

- **Surface (six screens):** language(English) → timezone(Europe/Madrid)
  → keyboard(**Español**, defaulted from the tz→country map, same correct
  behaviour as the Acer) → drive(Samsung NVMe) → device(`lenovo`, ghost
  placeholder replaced cleanly — the hostname fix holds) → user(`max`) +
  password + confirm. `GPU  Intel Iris Xe Graphics · i915 — tested,
  working · driving this screen`, Wi-Fi `iwlwifi`, Audio
  `sof-audio-pci-intel-tgl`, Bluetooth `btusb`, Touchpad
  `ELAN0001:00 04F3:3292 Touchpad · hid-multitouch` (R3-1 holds),
  decision values rendered (`Suspend, then hibernate`), honest count
  **28 of 30 (93%)** (#10). Nothing a stranger would trip on.
- **#20b reproduced, 2nd on-metal instance:** the drive list still offers
  the boot stick — `USB 2.0 FD  14.4G` sitting under the Samsung. The
  engine's backstop worked exactly as designed on an NVMe target:
  `ok target: /dev/nvme0n1 is not the boot medium (/dev/sda)`.
- **Two minor surface notes (new, small):**
  - The disk row reads `Scheduler  Bfq on rotational disks` on a machine
    with **no rotational disk at all**. True but vacuous — it tells an
    NVMe owner nothing about their own disk. Queued as R3-4.
  - `panelDpi 239 / scale 1.60` is decided and shown in the census, but
    **no panel or scale row appears on the confirm screen**. On the first
    high-DPI machine, the one decision most visible to the user after
    first boot is the one the reveal never mentions. Queued as R3-5.
- **Console quiet (#17a) — held on the noisiest machine in the lab:**
  `loglevel=3`, `printk` = `3 4 1 7`. This boot logged **45 lines at
  KERN_ERR**, 32 of them nouveau GSP — and **zero at emerg/alert/crit**,
  the only levels a console_loglevel of 3 prints. Nothing reached the
  screen. The strongest confirmation of #17a yet: the machine with the
  chattiest driver in the lab stays silent.
- **Rehearsal:** `status: ok`, **no findings** (the facts warn is a
  warning, not a finding). checks.txt all `ok` but the one warn: UEFI →
  systemd-boot, target≠medium, fit (940410 MiB root for a ~19 GiB
  closure), RAM ok. **eval 13 s** → `nixos-system-lenovo` — the fastest
  eval ever recorded in the lab (previous best: ThinkPad, 22 s). Modern
  metal proof delivered. Disk verified untouched, before and after.
- **Findings → changes.md:** #23 third manifestation + new **23b**
  (unscoped counter, no init-settle wait); **R3-4** (vacuous scheduler
  row on non-rotational targets); **R3-5** (panel/scale decided but never
  revealed). #20b confirmed on a second machine.
- **Verdict:** **PASS.** Every unique contribution this machine was
  brought in for was delivered — NVMe target, boot_vga primary on a
  modern hybrid, high-DPI panelDpi/scale, the fastest eval in the lab,
  and above all the **healthy turing+ → open module + PRIME offload path
  proven from facts measured on real metal**. It also did what it was
  best placed to do: broke the health probe a third way, in the one
  direction the ASUS and HP could not show, and proved that the fix
  already decided for round 4 works here — with two seconds to spare.
