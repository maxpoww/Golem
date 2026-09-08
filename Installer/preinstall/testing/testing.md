# Testing — the lab logbook

The synthesis file for the five-laptop install lab: after each round, the
*big picture* across all five machines is written here (see the method in
[constitution.md](constitution.md)). Between rounds this holds the last
round's summary.

## The directory

- **[constitution.md](constitution.md)** — the method: what a round is, the
  per-laptop test procedure, and the discipline that keeps five results
  comparable.
- **[changes.md](changes.md)** — the deferred queue of changes for the next
  ISO, applied only when the current one clears all five laptops.
- The per-machine records, one file each, the running log of every test on
  that specific laptop:
  [acer.md](acer.md) · [dell.md](dell.md) · [hp.md](hp.md) ·
  [macbook.md](macbook.md) · [comodore.md](comodore.md)

## Big picture

### Round 1 — all five tested (2026-09-06)

The round-1 ISO carried rehearsal mode, the sysfs cores fix, the hostname
ghost fix, and HOLA auto-join. Five machines, all driven over SSH (three
had dead or partial keyboards — the SSH-driven lab design paid off), each
disk verified byte-identical before/after. Nothing was written to any
disk, all round.

**The lab across five hardware generations:**

| Machine | CPU / GPU | RAM | Boot | Census | Rehearsal |
|---|---|---|---|---|---|
| Acer E5-573 | Broadwell / HD 5500 | 3.8 G | UEFI | ✅ (cores fix proven) | ✅ 5/5, disk safe |
| MacBook Air 6,2 | Haswell / HD 5000 | 3.9 G | UEFI | ✅ intelLegacy→i965 | ✅ 5/5, disk safe |
| Dell E6420 | Sandy Bridge / HD 3000 | 1.8→3.8 G | **BIOS** | ✅ | ✅ UEFI catch, disk safe |
| HP Pavilion dm4 | Arrandale / **AMD** Radeon | 3.7 G | **BIOS** | ✅ amd→modesetting | ✅ UEFI catch, disk safe |
| Comodore (GM45) | Penryn / **GMA 4500** | 1.9 G | **BIOS** | ⚠ GMA bug #12 | preflight only (2G) |

**What round 1 proved:**

- **Rehearsal mode works, on metal, safely.** Every machine ran the whole
  flow and every disk — including a MacBook's NixOS, a Dell's borrowed
  data disk, and the Comodore treasure — came through byte-identical. The
  core promise held five times.
- **The four surface fixes hold across disjoint hardware.** The hw_pci
  reveal parser, bluetooth detection, pci/usb closure deps, and the 100%
  bar were verified live on Broadwell, Haswell/Apple, Sandy Bridge,
  Arrandale+AMD, and GM45 — including the has-findings bar case.
- **The census is right almost everywhere**, and where it wasn't, the lab
  caught it: `intelLegacy→i965` proven correct on two legacy Intel parts,
  `gpu="amd"→modesetting` safe on the first AMD, cores/threads right
  including a no-SMT machine — but the GMA 4500 exposed a real
  misclassification (#12).
- **The preflight checks earn their place.** The UEFI check caught BIOS
  boot on all three BIOS machines — its whole reason to exist, proven on
  metal.

**What round 1 taught (the themes, → changes.md):**

1. **BIOS is the norm, not the exception** — 3 of 5 old laptops boot
   legacy. Golem needs a real position on BIOS boot, not just a refusal
   (#8, needs-Max).
2. **The minimal medium's missing firmware distorts two things** — the
   "N of M drivers" count reads pessimistically (the HP's demoralizing
   74%) and internal wifi is dark (the MacBook's Broadcom, forcing a USB
   dongle). Both are the same root cause; carrying all-hardware firmware
   on the medium would fix both (#10, needs-Max; #5).
3. **The census's GPU story has two reporting gaps** — a hybrid names the
   iGPU not the decided dGPU (#9), and AMD/nvidia show `video decode: none`
   though acceleration is on (#11).
4. **Two low-RAM machines (1.8–1.9 G) can't self-eval** the target — it
   thrashes. Reinforces the closure-delivery open question: sub-2 G
   machines need a prebuilt closure, not a local build.
5. **The GMA intelLegacy bug (#12)** — the device-id threshold breaks on
   pre-Ironlake parts.

**Also settled in-round** (proven, not real bugs): the "Spanish tty" was
`loadkeys` residue, not an ISO default; the "74% drivers" was the metric
measuring the medium.

**Round-2 gate:** work changes.md (the four verified surface fixes + the
small reporting fixes ship; the needs-Max items — BIOS boot, medium
firmware, Broadcom wifi — are Max's calls), cut the new ISO, reflash, then
open round 2. The wired install (the scoreboard's last box) waits until the
rehearsal rounds stop finding things — round 1 found plenty, so there will
be a round 2.
