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
