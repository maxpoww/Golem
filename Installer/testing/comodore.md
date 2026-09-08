# Comodore

Max's treasure. Intel Cantiga/ICH9M (GM45) whitebox · **Pentium Dual-Core
T4200** (Penryn, 2c/**2t — no SMT**) · **GMA 4500 (Gen4)** graphics ·
**boots BIOS/legacy** · no Bluetooth · 1931 MB RAM · 931 GB HGST with an
existing Linux install (ext4 `fc240c7b…` + swap `59331be7…`). Handled with
extra care: rehearsal-only, eval stopped early to spare it, disk verified
byte-identical.

---

## Round 1 — 2026-09-06 — census PASS w/ 1 real bug · preflight caught BIOS · treasure safe

- **ISO:** round-1. Driven over SSH via the USB wifi dongle.
- **Census — mostly right, and one genuine bug:**
  - T4200, **cores=2/threads=2** — first no-SMT machine; the sysfs cores
    fix gives 2/2 correctly (nproc would also say 2 here, but the fix is
    right regardless).
  - ram 1931, swap **4 GiB** — verified correct: `swapForHibernationMB(1931)
    = 4096` (the rule scales generously for hibernation on tiny RAM). Not a
    bug.
  - `hasBluetooth = false` — first machine with no BT; correctly detected
    (no BT row in the reveal).
  - **BUG — `intelLegacy = false → iHD` on a GMA 4500.** The GPU is
    `8086:2a42` (GM45 GMA 4500, Gen4 — 2008). iHD (intel-media-driver)
    supports Broadwell+ only; a Gen4 GMA needs the legacy i965 path (or no
    HW decode). The probe's test is `device-id < 0x1600 → legacy`, but
    0x2a42 (=10818) > 0x1600 (=5632), so it reads as MODERN. The heuristic
    assumes device IDs grow with generation — true across
    Ironlake→Skylake, FALSE for the ancient GMA parts whose IDs are
    numerically high (0x2xxx) despite being the oldest. So this machine
    would install iHD and get NO working hardware video decode. Display is
    fine (kernel `i915` drives GMA 4500), so the iron law holds — it is a
    degraded-decode bug, not a black screen. → changes.md #12.
- **Firmware: BIOS/legacy** — the THIRD BIOS machine (Dell + HP +
  Comodore). BIOS is the MAJORITY of the lab's old laptops, not an edge
  case. Strengthens #8.
- **Reveal (fixed golem-setup):** GPU `Intel Mobile 4 Series · i915`, Audio
  `Intel 82801I (ICH9) HD Audio · snd_hda_intel`; no Bluetooth row
  (correct), no Wi-Fi row (its wifi is the USB dongle, not PCI). **28 of 31
  (90%)** drivers.
- **Rehearsal preflight (run directly, eval stopped early to spare the old
  machine):** checks.txt —
  - **`FAIL firmware: booted BIOS/legacy — systemd-boot cannot boot here`**
    — third BIOS catch. → #8.
  - `ok` target `sda`≠medium `sdb` · `ok` fit (949 GB) · `ok` facts match.
  - eval NOT run to completion — at 1931 MB it thrashes like the Dell's
    Phase A; the preflight (the rehearsal-specific value here) was captured
    and the eval killed so the treasure did not grind. (Eval-on-2GB is
    already a known finding from the Dell.)
- **Treasure safety:** `/dev/sda` UUIDs byte-identical before and after
  (sda1 ext4 `fc240c7b…`, sda2 swap `59331be7…`), partition table intact,
  no swap activated, machine returned to idle, RAM freed. Nothing touched.
- **Verdict:** census PASS with a real GMA-misclassification bug (#12), the
  reveal fix holds on a 5th machine, third BIOS catch, disk safe. The
  install is gated on the firmware decision (#8) and the decode bug is a
  quality fix, not a blocker.

### Reveal completeness fixes, verified here (2026-09-06)

Max: "no hardware on the description, not even the touchpad." Traced to two
reveal detection gaps, both fixed and re-verified live on the Comodore
(driven to the reveal, ESC before the eval — treasure disk untouched):
- **Touchpad** was an `AlpsPS/2 ALPS GlidePoint`; the old `ouchpad|rackpad`
  pattern missed it. Broadened (#14) → reveal now shows
  `Touchpad AlpsPS/2 ALPS GlidePoint`.
- **Networking** was blank: the Comodore has no Wi-Fi, only a Marvell
  Ethernet NIC, and the reveal only queried the Wi-Fi PCI class. Added an
  Ethernet row (#15) → reveal now shows `Ethernet Marvell … 88E8055 · sky2`.
The reveal went from 2 rows (GPU, Audio) to 4 (GPU, Ethernet, Audio,
Touchpad). Also applied this pass: invitation option A + rotation 5s→4s
(#13).

## Round 2 — 2026-09-07 — census wins CONFIRMED · install unrunnable (RAM floor)

Reached only in the brief window right after a reboot (Max rebooted; no
spare RAM for this one). It thrashes into unresponsiveness under any real
load on **1931 MB**.

- **GMA fix (#12) PROVEN on metal:** census now reads **`intelLegacy =
  true`** for the GMA 4500 (0x2a42) — round 1 read `false` (the bug → a
  broken iHD); round 2 → the legacy i965 path. Fixed on the exact machine
  that exposed it. (i965 follows from intelLegacy=true in decide.nix,
  verified.)
- **`firmware = "bios"` CONFIRMED:** the new census firmware fact correctly
  detects BIOS boot.
- **gpu intel, T4200, ram 1931** — as round 1.
- **Disk safe:** `/dev/sda` before-snapshot = ext4 "root" (`fc240c7b…`) +
  swap; rehearsal writes nothing by design and barely started, so untouched.

- **FINDING — the install cannot RUN on 1.9 GB, only the census can.**
  `golem-install --rehearse` made the machine unresponsive the instant it
  started — before the target eval even, at the early `nix eval` (swap
  rule) + seed copy. sshd stopped answering (TCP open, handshake times
  out). So on this box the boot census works (barely), but the installer's
  own nix evaluation does not. This is the low-RAM floor made concrete:
  ~2 GB is below what a LOCAL eval/build install needs. Reinforces the
  closure-delivery open question — a sub-2 GB machine must receive a
  PREBUILT closure and skip local evaluation, or the installer should
  detect very-low-RAM and refuse/redirect rather than thrash. → changes.md.
- **BIOS install-path rehearsal:** could not be captured here (RAM). Will
  be proven on the Dell (now 3.8 GB) or HP — both BIOS, neither starved.
- **Verdict:** the two Comodore round-2 census fixes are confirmed on
  metal; the machine itself is below the install's RAM floor — a finding,
  not a Golem bug.

## Round 3 — 2026-09-07 — the RAM refusal works: findings: 1 in ~50 s on the box round 2 left comatose · 1 new census finding (#26)

- **ISO:** round-3 `p5ylp6q6…`, SSH at 192.168.1.129.
- **THE #16 PROOF — this machine's whole reason to run round 3:** all
  six screens walked normally, ENTER, and ~50 s later:
  `FAIL ram: this machine has 1931 MB — installing Golem needs about
  4 GB of RAM` + `note eval SKIPPED: … cannot evaluate the target
  without thrashing`. Bar to 100% "Rehearsed", "1 finding(s)", every
  other check green (BIOS→GRUB, target≠medium, fit, facts match), the
  machine RESPONSIVE throughout (1.4 GB available after). Round 2: the
  same ENTER produced an unresponsive swap spiral. Also: the engine's
  early swap-rule eval passed quickly at 1931 MB — the round-2 thrash
  was the target eval's doing; no check reorder needed.
- **Census:** ramMB 1931, gpu=intel, intelLegacy=true (the #12 GMA
  range holding), BIOS — and **NEW FINDING #26:** `gpu2 = "intel"` at
  `00:02.1` — the GMA chipset's SECOND FUNCTION of the same chip,
  enumerated as a second GPU. The reveal then fibs: "GPU 2 Intel
  Mobile 4 Series Chipset Graphics — tested, working · apps can use it
  on demand" — a driverless dead sibling function of the ONLY GPU,
  wearing the offload promise. Config impact zero (intel+working
  activates nothing); surface honesty impact real. Fix: exclude
  same-slot functions from gpu2 (the HDMI-audio sibling rule, applied
  to display class). Health probe on the sibling read "working" both
  boots — stable, at least.
- **Reveal otherwise:** GlidePoint `· psmouse` (#14 + R3-1), the
  Ethernet-only row (#15), audio CORRECT here (ICH9 at 00:1b.0 — GMA
  silicon has no HDMI-audio sibling, so first-match is right), zram
  Active, 4 GiB swap tier, **25 of 26 (96%)**.
- **Disk untouched** (prior Linux ext4 + swap intact).
- **Verdict:** PASS with the round's most satisfying delta — the
  machine that couldn't survive its own rehearsal now finishes it in
  under a minute with an honest refusal. #26 queued.

## Round 4 (rehearsal check) — 2026-09-08 — RAM refusal works · #26 census fixed · #26 reveal-half gap found & fixed

- **ISO:** round-4 (`yz5nqhsv…`, pre-F1). BIOS, 1931 MB. Audit ok.
- **#16 RAM refusal — clean, again:** all six screens walked, then
  `FAIL ram: this machine has 1931 MB — installing Golem needs about
  4 GB of RAM` + `note eval SKIPPED`, `findings: 1`, machine responsive
  throughout (1384 MB free). The round's low-RAM guard holds.
- **#26 census fixed:** `golem-hardware.nix` has NO gpu2 line — the GMA's
  00:02.1 sibling of 00:02.0 is correctly excluded (round 3 had
  `gpu2 = "intel"` + a phantom "working" verdict).
- **#26 reveal-half GAP FOUND & FIXED:** the confirm screen STILL showed
  `GPU 2 Intel Mobile 4 Series Chipset Graphics` — because reveal_gpus
  enumerates display controllers live from lspci, independently of the
  census fact, so the census fix didn't reach it. Added the same
  same-slot exclusion to reveal_gpus (skip a non-primary display
  controller sharing the primary's PCI slot). Source-only; ships in the
  reburn. THIS run (old stick) still shows the phantom.
- **Round-4 surface:** Scheduler `Bfq on hard disks, default on SSD/NVMe`,
  audio correct (ICH9 at 00:1b.0), GlidePoint · psmouse, Ethernet row.
- **Disk untouched:** ext4 "root" + swap (prior Linux) intact.
- **Verdict:** PASS on substance (RAM refusal + census #26); the reveal
  phantom-GPU2 was a real miss in the round-4 build, now fixed for the
  reburn — the Comodore earns its keep every round.
