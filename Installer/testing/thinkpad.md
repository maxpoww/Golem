# ThinkPad

Lenovo ThinkPad E15 Gen 2 (20T8005CUS) · **AMD Ryzen 7 4700U** (8c/8t —
no SMT on this part) · **Renoir Vega iGPU (single GPU)** · boots **UEFI** ·
238.5 GB NVMe (existing **Windows**: ESP 200M + MSR + NTFS 237.5G + WinRE;
guarded) · 7159 MB RAM · Realtek RTL8822CE wifi + RTL8111 ethernet ·
143-dpi panel. Joined the lab 2026-09-07 ("the first of the two new
beautys").

**Why it matters:** the lab's first AMD CPU (amd microcode path), first
amdgpu/Vega machine, first 8-core (the auto/0 build tier), first machine
with a panelDpi fact on metal, and the first UEFI rehearsal on NVMe
(p-suffixed partition names).

---

## Round 2 (first contact) — 2026-09-07 — census PASS · rehearsal PASS 0 findings · fastest metal eval ever

- **ISO:** round-2 (frozen stick; hostname fix + firmware fact confirmed).
  Driven 100% over SSH at 192.168.1.149 — joined the network on its own
  (RTL8822CE wifi · rtw88_8822ce, in-tree, no dongle needed).
- **Boot:** UEFI · sshd up ~1 min after power-on.
- **Census — correct on every AMD-first fact:** Ryzen 7 4700U,
  **cores=8/threads=8** (no SMT on this part — the sysfs topology got it
  right), ramMB 7159, `gpu = "amd"` (single GPU, Renoir Vega iGPU ·
  amdgpu bound on the medium), `cpuVendor = "amd"` (first — microcode
  path), `firmware = "uefi"`, **`panelDpi = 143`** (FIRST panel fact on
  lab metal → scale "none (normal density)", correct for 15.6" FHD),
  bluetooth, laptop. **thermald correctly OFF** (Intel-only daemon).
  Build tier first sighting: `parallel builds auto / cores per build 0`.
  `video decode: none` — the #11 reporting gap live on AMD (round-3 fix
  will say "vaapi, mesa radeonsi").
- **Surface (six screens, English/Denver):** ghost fix held
  (`› thinkpad`). Zram row reads **`50% of ram`** — the 8 GB tier's
  percentage (R3-2's "active" wording is round 3). Findings a stranger
  could trip on:
  1. **GPU row wraps the line even at 120 cols** — the full lspci Renoir
     string pushes `· amdgpu` onto the next line. Exactly what #17's
     `gpu_short` fixes in round 3 ("AMD/ATI Renoir …").
  2. **Audio row names the WRONG device:** "Renoir/Cezanne HDMI/DP Audio"
     — the HDMI audio function (04:00.1), not the speakers/mic device
     (Family 17h HD Audio, 04:00.6). AMD APUs expose two audio-class
     devices; hw_pci takes the first. → changes.md #21a.
  3. **Touchpad row names the TrackPoint** ("ETPS/2 Elantech TrackPoint")
     — a ThinkPad has both; hw_input takes the first /proc match. The
     actual touchpad row is missing. → changes.md #21b.
  4. **The boot stick is offered in the drive list** ("USB 2.0 FD") —
     #20's second on-metal instance; already fixed in the round-3 build.
  5. **22 of 36 (61%) drivers** — the lab's lowest, on its most modern
     machine: bridge-heavy AMD platform + the #10 bridge-counting bug
     (fixed round 3). Expect this number to jump on the round-3 stick —
     a before/after worth capturing.
  6. **(Max, physical screen)** Audio reads "AMD/ATI … · snd_hda_intel"
     — a perceived vendor mismatch, but CORRECT: HDA is the
     Intel-authored standard, its kernel module drives every vendor's
     controller and keeps the historic name. Noted on #21a. Touchpad's
     missing driver = R3-1, already in the round-3 build (though the
     row names the TrackPoint until #21b).
- **Rehearsal:** `status: ok`, **0 findings**, bar 100%. checks.txt all
  green: UEFI → systemd-boot to the ESP, target nvme0n1 ≠ medium sda,
  fit (234470 MiB root), facts match, **eval 22 s** →
  `nixos-system-thinkpad` — **fastest metal eval in the lab** (Acer 31 s,
  HP 43 s, MacBook 58 s, Dell 170 s; beats the VM-on-i9's 23 s).
  Transcript: ESP 512M ef00 + swap **9216M** (the swap rule at 7 GB) +
  root, `nvme0n1p1` p-suffix naming correct, ESP mounted at /mnt/boot.
  machine.nix: `thinkpad`, en_US, Denver, no grub line (systemd-boot).
- **Disk verified untouched:** all four Windows partitions identical
  UUIDs before/after (ESP `92D6-8297`, NTFS `0A52D6C6…`, WinRE
  `E020AFC7…`). The Windows install is safe.
- **Findings → changes.md:** #21 (new — reveal picks the wrong one of
  several same-class devices: audio + input); evidence notes on #17
  (name wrap at 120 cols), #20 (2nd instance), #11 (live on AMD).
- **Verdict:** PASS — the lab's first AMD machine sails through census
  and the UEFI/NVMe rehearsal with zero findings; every new-territory
  fact (SMT-less cores, amd vendor, panelDpi, thermald-off, 8-core
  tier) came out right on the frozen round-2 stick.

## Round 3 — 2026-09-07 — every fix this machine spawned, verified on it · 0 findings · eval record again

- **ISO:** round-3 `p5ylp6q6…`. Driven over SSH at 192.168.1.149.
- **Audit ok.** Census: `gpu = "amd"` via boot_vga (single-GPU APU — no
  gpu2, correct), panelDpi 143.
- **The before/afters, all landed:**
  - **#11:** `video decode: vaapi, mesa radeonsi` (round 2: "none").
  - **#21a:** Audio row names the SPEAKERS — `[AMD] Ryzen HD Audio
    Controller · snd_hda_intel` (round 2: "Renoir/Cezanne HDMI/DP").
  - **#21b + R3-1:** `Touchpad ETPS/2 Elantech Touchpad · psmouse`
    (round 2: the TrackPoint, driverless).
  - **#17 gpu_short + verdict:** `AMD/ATI Radeon Vega Series · amdgpu —
    tested, working · driving this screen` on ONE line (round 2: the
    full Renoir string wrapped 120 cols).
  - **#10:** 17 of 19 (89%) (round 2: 22/36, 61%).
  - **R3-2:** `Zram Active, zstd, priority 100` (round 2: "50% of ram").
- **Rehearsal:** `status: ok`, all checks green — UEFI→systemd-boot,
  target≠medium, fit, `ok ram: 7159 MB`, facts match (stable — no
  ASUS-style flap on a single-GPU machine), **eval 21 s → new lab
  record**. Windows partitions untouched (all four UUIDs identical).
- **Surface:** physical console reviewed by Max — visual OK, nothing
  to report.
- **ANSWERED (dedicated boot, same day) — Max: "the % of found drivers
  is poor, why?":** the 2 of 19 are (a) the AMD IOMMU function
  (00:00.2, class 0806 — never binds a driver on ANY OS; phantom
  denominator, → changes.md #25 excludes it like the bridges) and
  (b) the ACP audio co-processor (04:00.5) — `snd_rn_pci_acp3x` loads
  and DECLINES by design: this unit's mic is wired through the ALC257
  HDA codec, capture stream verified present. **The mic works; the
  machine is functionally 100%.** The count will read 17/18 (94%)
  after #25 — honest beats clever.
- **Verdict:** PASS, 0 findings — the machine that filed #11/#21a/#21b
  watched all three die on its own screen one round later.

## Round 4 (rehearsal check) — 2026-09-08 — the round-4 build verified on AMD metal · 0 findings

- **ISO:** round-4 (`yz5nqhsv…`); markers confirmed (wait_for_audit
  present, audit tty1-banner marker guard present). Audit ok.
- **The round-4 fixes, seen on this machine's own screen:**
  - **#21c AUDIO FIXED — the headline for this machine:** row now reads
    `AMD [AMD] Ryzen HD Audio Controller · snd_hda_intel` — the real
    speakers. Round 2/3 showed "Renoir/Cezanne HDMI/DP Audio" (the wrong
    HDMI function). The machine that filed #21a/#21c watched it land.
  - **R3-4:** `Scheduler  Bfq on hard disks, default on SSD/NVMe` (was
    "bfq on rotational disks" — vacuous on this NVMe box).
  - #21b touchpad still correct (`Elantech Touchpad · psmouse`, not the
    TrackPoint), lid value translated. No phantom gpu2, no count line.
  - R3-5 scale row correctly ABSENT (panelDpi 143 → normal density, not
    high-DPI; only the Lenovo's 239→1.60 surfaces one).
- **Rehearsal:** `status: ok`, all checks green, **eval 22 s** (matches
  its round-3 record pace), UEFI→systemd-boot. Windows on the NVMe
  untouched — all four partition UUIDs identical.
- **Verdict:** PASS — round-4 build confirmed on the AMD machine, its own
  audio finding fixed on its own screen. First of the round-4 rehearsal
  sweep (all PCs checked before the ASUS gets the first REAL install).
