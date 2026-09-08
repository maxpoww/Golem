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

## Round 4 test — procedure for the Fedora driver (2026-09-08) — DONE, see the round-4 record at the bottom

Same handoff as round 3 above (Fedora drives, dev-box down, git is the
channel — `git pull` first). What's DIFFERENT / what to verify:

- **The stick is the FROZEN round-4 build `yz5nqhsv…`** (identify by:
  `golem-setup` unwrapped contains `wait_for_audit`; census has the R3-5
  scale row wiring). Do NOT expect F1-cancel, dimmed GPU-2 verdict, or
  the #26 reveal-half — those are round-5 source, deliberately NOT on
  this stick. If you see the old "ESC back" on the language page and an
  undimmed "apps can use it on demand", that is EXPECTED, not a finding.
- **This machine is the ONLY metal proof of two round-4 things:**
  1. **R3-5 panel scale row.** The Lenovo's 239-dpi panel → scale 1.60
     is the only non-1.0 scale in the lab, so it is the only machine
     where the confirm screen should show a `Scale 1.60` row. Every
     other machine correctly shows none. Confirm it appears.
  2. **Healthy-nvidia force-cold verdict.** Expect `gpu = intel`
     (boot_vga), `gpu2 = nvidia`, `nvidiaGen = turing+`,
     `gpu2Health = "working"` — and NO facts-match flap (round 3's
     boot-audit false-negative must not recur now force-cold waits for
     a real suspend before poking). Reveal: `GPU 2 … tested, working ·
     apps can use it on demand`.
- **#28 note:** on this fast machine the audit finishes quickly, but if
  you start golem-setup mid-audit, wait_for_audit should hold the reveal
  cleanly (no "audit incomplete", no tty1 dump).
- **THE ONE RULE still absolute:** rehearsal only, nvme0n1 byte-untouched
  before AND after (this NVMe is the lab). Never run the engine without
  `--rehearse`.

---

## Round 5 test — procedure for the Fedora driver (2026-09-08)

Same handoff as rounds 3–4 above (Fedora drives, dev-box down, `git pull`
first — this round's ISO was cut and flashed straight from the dev-box
session, so the very latest commit is the one to pull). What's DIFFERENT /
what to verify:

- **The stick is the round-5 build, ISO `4qyiiazybywxnpzskyf4d2pmsihkqfvj…`**,
  built from `f92d6f7` (the preinstall/installing split — no functional
  change) on top of `7659227` (#33, the postinstall ASK framework).
  Identify it by: `golem-setup` unwrapped hashes `kmvcmr1r…` (round 4 was
  `dgavg21k…`); **`golem-postinstall-questions` exists on the medium at
  all** — round 4 had no such binary, so its mere presence is the cleanest
  single tell. `golem-hw-detect` is unchanged from round 4
  (`3fniyyq2…`) — the probe itself did not move this round, only the
  surface and the postinstall wiring did.
- **What's new since round 4, all applied to source per changes.md:**
  - **#33 — the postinstall ASK subsystem exists for the first time.**
    `golem-install` now calls `golem-postinstall-questions` right after
    the probe and drops a FOURTH file into the rehearsal bundle's
    `target/`: `postinstall-questions.json`. On THIS machine, expect it
    to be an **empty array** — the question only fires for a *failing*
    second GPU, and the Lenovo's RTX 4050 is the lab's one healthy dGPU
    (`gpu2Health = "working"`). A non-empty array here would be a
    regression worth flagging loudly.
  - **#34 — Ctrl-C now exits, once, cleanly.** `cleanup` runs on EXIT
    only; `cancel_install` (the F1 path) owns INT/TERM. Worth a deliberate
    Ctrl-C on the confirm screen: expect the prompt back, no leftover
    `golem-setup` process, the `#28` console marker and keymap backup both
    gone (not leaked, per round 4's finding on this exact machine).
  - **R4-1 — the audio row should now name the class, not a hex id.**
    THIS machine is the one that filed it: round 4 showed `Intel
    Corporation Device 51cf · sof-audio-pci-intel-tgl`; expect `Intel
    Corporation Multimedia audio controller · sof-audio-pci-intel-tgl`
    this round. The direct verification, on the hardware that found the
    bug.
  - **#31/#32/#26-reveal** (round-4-sweep findings, round-5 source): F1 on
    the language page should now actually cancel (dead "ESC back" is
    gone); a failing-GPU verdict tail (not applicable here — healthy chip)
    should render dimmed if it ever shows; no same-chip-sibling
    double-counted as a second GPU.
- **Everything round 4 already proved on this machine should still hold,
  unchanged — this round is a regression check for it, not a re-discovery:**
  `Scale 1.60` row present, `gpu2Health = "working"` from the boot audit
  itself with no facts-match flap, #28's wait_for_audit still holding the
  reveal cleanly.
- **THE ONE RULE still absolute:** rehearsal only, nvme0n1 byte-untouched
  before AND after. Never run the engine without `--rehearse`.

### Handoff back

After the rehearsal (and the deliberate Ctrl-C check), commit this file on
the Fedora session and push. Max reboots the dev box to normal; the
dev-box Claude pulls the record over SSH/git and continues from there.

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

---

## Round 3, follow-up session — 2026-09-08 — 23b fixed and validated on the metal that found it

Max: *"make the live test on the dev box to see if its fixable."* Done,
while the box was still on the medium. **Yes — fixed, applied to source,
and proven on the machine that exposed it.** Disk re-verified
byte-untouched after everything below.

**First, a correction to the record above.** The initial 23b write-up
blamed the unscoped counter. The live test says that is wrong on its own:
the BDF lines this boot break down as **32 err · 29 info · 15 warn**, and
the 32 nouveau GSP `ctrl cmd … failed` lines are **error-level AND carry
the BDF** — so scoping alone would still have counted all 32 and still
returned the false negative. **Force-cold is the load-bearing fix;**
scoping fixes a different, latent bug. Both shipped.

**The fix** (`system/hardware-detect.nix`): force cold before every poke
(`control=auto` → bounded wait for a real `suspended` → wake), bound
widened **10 s → 15 s**, and count only error-level records that name the
device, as a before/after delta.

**Why 15 s, measured not guessed:** this chip goes cold in a rock-steady
**7 s** (three samples, zero spread). Seven seconds after this boot's init
ends is ~t=27.4 s; a 10 s bound opened when the audit starts (t=17.06 s)
expires at t=27.0 s — **0.4 s too early, on the fastest machine in the
lab.**

**What was verified live, in order:**

| test | result |
|---|---|
| 3 × force-cold cycles, healthy RTX 4050 | `working`, `working`, `working` — each a real cold resume (7 s to suspend, 13–15 s cold, **0 errors**, no new kernel lines) |
| still convicts (HP `No VRAM object` + ASUS `PRIVRING` FAULT, injected at KERN_ERR) | delta **2** — conviction intact |
| cross-attribution (`i915 … *ERROR* Port E/TC#2` during an NVIDIA probe) | old counter **1**, new counter **0** |
| safety: bound starved to 2 s (chip needs 7) | `poke1 → -1` → **`unknown`** — never a default pass |
| `dmesg --level` inside the tool's own closure (`env -i`) | resolves to util-linux 2.42.2 — no new dependency |
| patched detector end to end, `env -i`, nothing ambient | `gpu2Health = "working"`, 12 s, **zero stderr** |
| shellcheck 0.11.0 (the `writeShellApplication` build gate) + `bash -n` | clean |

**One documented miss, accepted:** `[drm:evergreen_resume] *ERROR*
evergreen startup failed on resume` carries no BDF and is skipped. Its
companion line names the device and convicts, so the HP is still caught —
but a chip whose only fault line is a bare `[drm:…] *ERROR*` would
escape. Noted in changes.md rather than papered over.

### The visual, finally — the row #17c promised, on real metal

With the patched facts installed and `golem-setup` re-driven through all
six screens:

```
·  GPU    Intel Iris Xe Graphics · i915 — tested, working · driving this screen
·  GPU 2  NVIDIA GeForce RTX 4050 Max-Q · nouveau — tested, working · apps can use it on demand
```

That is the exact wording the first-contact procedure predicted, rendered
on physical metal for the first time in the lab's history. The facts were
then restored to the as-booted census so this file's round record above
still describes what the machine actually did on its own.

### BONUS FINDING (#30) — the awk bug, one field over, found by the same test

Running the detector under **only its own declared store paths** turned up
`sed: command not found` → `cpuModel = "unknown"`. **`pkgs.gnused` was
never in `runtimeInputs`.** `writeShellApplication` appends `:$PATH`, so
the undeclared `sed` resolved from the ambient environment and worked
purely because the `golem-audit` unit's PATH happens to carry gnused. The
`|| true` and the `[ -n … ] || cpu_model="unknown"` guard meant it would
have degraded **silently** — the cores=4 shape exactly. The file's own
header warns "a tool must not reach outside its own closure for something
this basic"; a second instance was sitting four lines below the warning.
Fixed (one line), and round 4 should run the same `env -i` closure test
over `golem-hw-evidence` and `golem-hw-decide`.

- **Verdict:** 23b closed — force-cold + scoped counter, applied to
  source, validated six ways on the metal that found it, with the
  promised reveal row seen on screen. #30 found and fixed as a
  side-effect. Neither ships until the round-4 build; the round-3 stick
  is untouched and still frozen.

---

## Round 4 (rehearsal check) — 2026-09-08 — R3-5 scale row + healthy-nvidia force-cold verdict BOTH PROVEN on metal · #28 exercised live · eval 7 s · one new finding (#34)

Driven from the **Fedora ThinkPad** (192.168.1.167) over SSH, per the
round-4 procedure above. The dev box sat on the medium the whole slot.

- **ISO:** round-4 stick (`GOLEM_INST`, 14.4 GB, `/dev/sda`). The ISO's
  own `yz5nqhsv…` hash is not visible from the booted system
  (`/iso/version.txt` is empty), so identified by the markers the
  procedure names: `golem-setup` `dgavg21k…` unwrapped contains
  `wait_for_audit` (2 hits), the R3-5 `dl_scale` label + jq `scale`
  select, the R3-4 `dv_bfq` wording; `golem-hw-detect` `3fniyyq2…`
  carries the 15 s force-cold bound and the `dmesg --level` scoped
  counter (#23/#23b/#30). Still "ESC back" on the language page and an
  undimmed GPU-2 verdict — **expected**, round-5 source. `GOLEM_REHEARSE='1'`
  + `GOLEM_LAB='1'` baked into the wrapper. Kernel 6.18.48.
- **Boot:** UEFI · joined HOLA on its own (`iwlwifi`) · found at
  192.168.1.152 by sweep · DMI `LENOVO` / `83C0` · `findmnt /iso` →
  `/dev/sda`. `golem-audit.service` **16.96 s → 41.11 s** (24.1 s; round
  3: 17.06 → 46.06). Three deliberate re-runs later took 17.7–18.0 s each.

### ⚠️ The one rule: HELD (three snapshots, zero writes)

`nvme0n1` snapshotted before the run, after the rehearsal, and again at
the very end of the session (after three audit re-runs and a second
rehearsal): GPT label-id + all three UUIDs/PARTUUIDs, `sfdisk -d`, first
4 MiB SHA256 (`4a61ff63…`), last 4 MiB SHA256 (`194fb860…`) — `diff`
**zero lines** all three times. Stronger than round 3's check:
`/sys/block/nvme0n1/stat` **writes-completed = 0 for the entire boot**,
and the disk was never mounted. Engine never ran without `--rehearse`;
both transcripts all `would`.

(The first-4-MiB hash differs from round 3's `a5082774…`. Expected, not
a finding: the EFI partition starts at 2 MiB and the dev box booted its
own system between the rounds — systemd-boot writes its random seed /
entry state there. Last-4-MiB hash is identical to round 3. The rule is
before-vs-after *within* a run, and that held.)

### THE TWO THINGS ONLY THIS MACHINE CAN PROVE — both delivered

1. **R3-5 panel scale row — SEEN.** `panelDpi = 239` → `scale 1.60` in
   the census, and the confirm screen now shows **`Scale  1.60`** between
   Lid and GPU. The only non-1.0 scale in the lab, rendered on the only
   machine that has one; every other round-4 record correctly shows the
   row absent.
2. **Healthy-nvidia force-cold verdict from the BOOT audit — `working`,
   no flap.** `golem-hardware.nix` written by the boot audit itself (not
   a re-probe) carries `gpu2Health = "working"`; round 3's boot audit had
   no key at all (`unknown`). `checks.txt`: **`ok facts: the probe now
   matches the boot audit fact for fact`** — the #23 instrument that
   warned in both directions on round 3 is silent. Everything that
   convicted the chip in round 3 was present again this boot: nouveau's
   GSP init 18.77 → 19.97 s *inside* the audit window, its 32 err-level
   `ctrl cmd … failed` lines, and `i915 0000:00:02.0: [drm] *ERROR* Port
   E/TC#2` at 14.2 s — the force-cold wait + scoped delta counter read
   through all of it. Evidence the suspend was real: `power/runtime_
   suspended_time` = 862 ms right after boot (0 would mean no suspend
   ever happened), 4133 ms after the three re-runs — **`working` ×4**,
   every audit this session.
   Reveal: `GPU 2  NVIDIA GeForce RTX 4050 Max-Q · nouveau — tested,
   working · apps can use it on demand` — from a real boot-audit verdict
   this time, not the round-3 patched-facts demo. Target closure:
   `nvidia-open-595.71.05-6.18.48`, `nvidia-offload`,
   `nvidia-x11-595.71.05`, `nvidia-vaapi-driver-0.0.17`, and **no**
   `golem-dgpu-off` — the healthy branch, evaluated from facts the boot
   audit measured on metal.

- **Census:** `status: ok`, every fact identical to round 3's (i9-13905H,
  14c/20t, 31816 MB, uefi, laptop, BT, `gpu = intel` by boot_vga, `gpu2 =
  nvidia` @ `0000:01:00.0`, `turing+`, both PRIME bus ids) plus the
  `gpu2Health` key above. Nothing wrong, nothing uncertain.
- **Surface (six screens):** English → Europe/Madrid → keyboard
  **Español** (tz→country default, as round 3) → drive → `lenovo` (ghost
  replaced cleanly) → `max` + password ×2 → confirm. Round-4 fixes on
  this machine's own screen:
  - **#20b FIXED here:** the drive list offers **only** the Samsung
    (`SAMSUNG MZVL21T0HCLR-00BL2  953.9G` + Advanced). Round 3 showed
    `USB 2.0 FD  14.4G` — the boot stick — under it. 2nd machine to
    confirm the fix on metal.
  - **R3-4:** `Scheduler  Bfq on hard disks, default on SSD/NVMe` (was
    the vacuous "on rotational disks" this machine filed).
  - **#27:** no driver-count line. GPU row `Intel Iris Xe Graphics · i915
    — tested, working · driving this screen`, Wi-Fi `iwlwifi`, Bluetooth
    `btusb`, Touchpad `ELAN0001:00 04F3:3292 Touchpad · hid-multitouch`.
  - **Minor, new (R4-1):** Audio reads `Intel Corporation Device 51cf ·
    sof-audio-pci-intel-tgl`. Upstream data, not a Golem bug: the stick's
    pciutils 3.15.0 `pci.ids` (2026.04.01) has no `8086:51cf` entry, so
    lspci itself says "Device 51cf" and the reveal passes it through. A
    stranger sees a hex id where every other row has a name. Queued.
- **Rehearsal:** `status: ok`, **no findings**, all six checks `ok`
  (UEFI → systemd-boot, target ≠ medium `/dev/sda`, fit 940410 MiB root
  for ~19 GiB, RAM, facts match, eval). **eval 7 s** →
  `nixos-system-lenovo` — new lab record (round 3 here: 13 s). Transcript
  addresses `/dev/nvme0n1` + `nvme0n1p1..p3` throughout (p-suffix right).
  A second rehearsal later in the session (see #34): `ok`, eval 7 s again.
- **#28 exercised LIVE, deliberately:** this box's audit is too fast to
  race by accident (Dell caught the race by luck), so I restarted
  `golem-audit.service` and burst all six screens' keys in 10 s. The
  reveal **held on "Reading this device" for ~7 s** while the audit was
  `activating`, then drew the full census intact (Scale row, GPU 2
  verdict, all rows) the moment `status` turned `ok`. No "audit
  incomplete", no tty1 dump. The other half checked directly: audit
  restarted **with the owns-console marker present → no banner on tty1**
  (banner count 1 → 1). Both halves of #28 work as built.
- **Console quiet (#17a):** `loglevel=3`, printk `3 4 1 7`; **0 lines at
  emerg/alert/crit**, 45 at err (the same 32 GSP + i915 set); not one new
  kernel line after the boot audit for the rest of the session.

### NEW FINDING — #34: Ctrl-C runs golem-setup's cleanup but does NOT exit

Found by the harness (my own Ctrl-C to a tmux'd instance), then
reproduced under control. `golem-setup` installs one handler for
`EXIT INT TERM` (unwrapped line 3853; round-5 source
`mockup/install-cli:3902` identical): show cursor, `kb_restore`, delete
the keymap backup and the drv temp file, remove
`/run/golem-setup.owns-console`. On INT bash runs the handler and
**continues** — nothing in it exits. Measured on the confirm screen:
before Ctrl-C → marker present, `/tmp/golem-drv.*` + `/tmp/golem-kb-orig.*`
present, pid 5419; after Ctrl-C → **all three gone, pid 5419 still
running, confirm screen still drawn and responsive.** ENTER then ran a
full rehearsal successfully (`ok`, eval 7 s) — the install path survives.
What does not survive:

1. **The #28 marker is gone while the UI still owns the screen.** Seen
   live this session before I understood it: Ctrl-C at 19:44:49, audit
   restarted 19:44:51 (unrelated to the Ctrl-C), audit finished 19:45:08
   → **its census banner landed on tty1** — the exact dump #28 exists to
   stop. The guard itself is fine (proven above); the marker had been
   deleted from under it.
2. **The keymap backup is deleted**, so the real exit later has nothing
   to restore — a stranger who taps Ctrl-C and then quits leaves the
   console on the chosen keymap (#7's failure mode, via a side door).
3. Cursor shown over a raw-mode UI (cosmetic).

Fix is small: the INT/TERM handlers must exit after cleanup (or route to
`cancel_install`, which round 5 already adds for F1 — Ctrl-C should mean
the same thing). Queued as #34.

- **Parallel keyboard session, noted for the record:** the journal shows
  `nixos` on tty1 ran `sudo golem-setup` at 19:35:57 (the physical
  keyboard — Max), typing until ~19:39; tty1 ended on a "rehearsed —
  nothing was written, no findings" screen. The surviving bundle in
  `/var/log/golem-rehearsal/` is the SSH-driven one (its `answers`,
  including the randomly-salted password hash, is byte-identical to my
  instance's `/tmp/golem-answers`). Both runs were rehearsals; the disk
  saw zero writes. Harness note only: two instances share one rehearsal
  directory, so the later writer wins — drive from one seat.
- **Findings → changes.md:** **#34** (INT/TERM trap cleans up without
  exiting — reopens the #28 tty1 race and #7's keymap leak; small),
  **R4-1** (unresolved `Device 51cf` on the audio row — fall back to the
  class name when pci.ids has no entry; small). #20b confirmed fixed on
  a 2nd machine.
- **Verdict:** **PASS.** Both round-4 items only this machine can prove
  are proven on metal — the `Scale 1.60` row is on the screen, and the
  boot audit itself now calls the RTX 4050 `working` with no flap, from
  under the noisiest driver init in the lab. #28 held the reveal when
  made to race, #20b/R3-4/#27 landed on this box's own screen, eval set a
  new record at 7 s, and the NVMe that is the lab took zero writes. One
  new small finding (#34), found the way round 3's were: by the rig
  doing something a stranger would.

---

## Round 4, live-fix phase — 2026-09-08 — #34 and R4-1 fixed in source and verified on the metal that found them

Max: *"fix all in source and record the results."* Both round-4 findings
from this box are applied to `mockup/install-cli` and verified on the
Lenovo while it was still on the medium — the constitution's live-fix
phase. The round-4 stick is untouched; nothing rebuilt; the fixes ship in
the round-5 build with #31/#32.

**How it was verified live (no nix on the Fedora driver):** the patched
script was copied to `/root/install-cli-patched` on the booted medium
(SHA256 `a279a391…` identical to the source), and the stick's own
`golem-setup` wrapper was copied with its `exec` path pointed at it — so
the test ran under the frozen build's exact env (`GOLEM_REHEARSE='1'`,
`GOLEM_LAB='1'`, its closure PATH, its bash). `bash -n` clean under the
stick's bash 5.3p9. RAM overlay only; gone on reboot.

**#34 — Ctrl-C now exits, once, cleanly.** The single `EXIT INT TERM`
handler became a `cleanup` function on EXIT only, plus
`trap cancel_install INT TERM` — Ctrl-C takes #31's F1 path (`exit 0`),
which fires EXIT exactly once. Measured on the box:

| test | before (frozen stick) | after (patched) |
|---|---|---|
| Ctrl-C on the confirm screen | handler ran, **process kept running**, marker + `golem-drv.*` + `golem-kb-orig.*` deleted under the live UI | **prompt back**, no instance left (`ps`), marker gone, temp files gone |
| Ctrl-C on the language page | (same) | prompt back, marker gone, exited |
| full rehearsal after the change | — | `status: ok`, no findings, all checks ok, **eval 7 s**, marker cleared on exit |
| tty1 banner count across the phase | 1 | still 1 — no new dump |

**R4-1 — the audio row names the class when pci.ids has no name.** Both
lspci parsers (`hw_pci`, `hw_pci_all`) now replace a name ending in a bare
`Device xxxx` with the PCI class from the same header line (minus
" compatible"). On the confirm screen, patched build, live:

```
·  Audio        Intel Corporation Multimedia audio controller · sof-audio-pci-intel-tgl
```

(was `Intel Corporation Device 51cf · …`). Unit-tested against a
synthetic `lspci -k` dump too: `Device 51cf` (audio) and `Device 7af0`
(Wi-Fi) fall back to their class names; every real name (Iris Xe, AD107M,
RTL8111) passes through unchanged, `(rev xx)` still stripped, bus ids
still lead in `hw_pci_all`. The rest of the reveal was identical to the
frozen build's (Scale 1.60, both GPU verdicts, Wi-Fi, Touchpad).

### ⚠️ The one rule: HELD through the live-fix phase too

`nvme0n1` re-snapshotted after everything above (a fourth snapshot):
`diff` against the pre-run snapshot **zero lines**, hashes `4a61ff63…` /
`194fb860…` unchanged, `/sys/block/nvme0n1/stat` **writes-completed
still 0** for the whole boot. Two rehearsals with the patched build, both
`--rehearse`, both all `would`.

- **Findings → changes.md:** #34 and R4-1 moved to **APPLIED to source ·
  verified live on Lenovo · round-5 build**.
- **Verdict:** both closed on the machine that filed them. Round-5 source
  now carries #31, #32, #26-reveal, #34, R4-1; the round-4 stick stays
  frozen.
