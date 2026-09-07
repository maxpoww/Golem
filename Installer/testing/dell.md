# Dell

Dell Latitude E6420 · i5-2430M Sandy Bridge (2c/4t) · Intel HD 3000 (no
dGPU on this unit) · **boots BIOS/legacy** · **built-in keyboard dead**
(only Enter works — enough to pick Start; everything else driven over SSH).
As first seen: **1790 MB RAM, no internal disk** (USB stick + DVD-ROM
only). Reachable via the Realtek USB wifi dongle.

---

## Round 1 — 2026-09-06 — census PASS · install blocked (BIOS + no disk + RAM)

### Phase A: as-first-seen (1790 MB, no disk, BIOS)

- **ISO:** round-1 (`kizf3l8…`); cores fix confirmed (`cores = 2`).
- **Census — correct:** i5-2430M, cores=2/threads=4, **`intelLegacy =
  true` → `video decode = i965`** (2nd legacy machine on metal, correct —
  Sandy Bridge HD 3000, same reason as the MacBook). bluetooth true,
  laptop. **No `panelDpi`** in the facts — the probe found no readable eDP
  panel here, so no scale decision (correctly dropped, not printed empty).
- **Three install blockers, each a deliberate lab catch:**
  1. **BIOS/legacy boot** — the first non-UEFI machine. The install target
     is systemd-boot (UEFI-only). Confirmed directly: `/sys/firmware/efi`
     absent. The rehearsal's UEFI preflight check therefore **FAILS**
     ("this machine booted BIOS/legacy — the target's systemd-boot cannot
     boot here") — its first real catch on metal. → changes.md #8.
  2. **No internal disk** — only the USB medium (`sda`) and DVD (`sr0`).
     Nothing to install to; the only block device is the medium itself, so
     the target≠medium and disk-fit checks also fail. A real fail-early
     case.
  3. **1790 MB RAM** — the lab's lowest, below Golem's memory tuning floor
     (tiers start ~4 GB). The `nix eval` of the target thrashed so hard the
     machine swapped past 5 minutes and starved SSH — it could not
     complete. Reinforces the closure-delivery open question (PLAN.md): a
     sub-2 GB machine cannot self-build/eval an 18.8 GB closure; it needs a
     prebuilt closure, not a local build.
- **Keyboard:** built-in `AT Translated Set 2 keyboard` is dead (hardware
  fault) — a real "a stranger could not complete the keyboard step on this
  machine" data point, and a clean validation of the SSH-driven lab method
  (Enter alone reached Start; the dev box did the rest).
- **Phase A verdict:** census PASS; install correctly impossible here as-is,
  for three independent reasons the rehearsal's preflight is built to name.

### Phase B: RAM + disk added (Max, 2026-09-06) — pending

Max added ~2 GB RAM (→ **3799 MB**) and an internal disk — a 465.8 GB
Hitachi (`sdb`, holding xfs + ext4 "home" from a prior system; guarded
throughout). Could NOT switch to UEFI (dead keyboard can't reach the
firmware menu), so it stays **BIOS** — which gives us the clean result: the
UEFI-check catch WITH a completed eval and a real target.

**Full rehearsal, driven over SSH (dead keyboard, so 100% remote):**

- Six screens walked language(en) → tz(America/Denver, a US zone so the
  keyboard defaulted **English (US)** — no Spanish residue) → keyboard →
  disk(Hitachi `sdb`) → you → confirm. Hostname `dell` typed clean (ghost
  fix).
- **Reveal (fixed golem-setup, `nix copy` overlay):** GPU `Intel 2nd Gen
  Core (HD 3000) · i915`, Audio `Intel 6 Series/C200 HD Audio ·
  snd_hda_intel`, Bluetooth `DW375 Bluetooth Module · btusb`. No Wi-Fi row
  (its wifi is the *USB* Realtek dongle — not PCI — and no internal PCI
  wifi card present) and no touchpad (the E6420's didn't enumerate,
  consistent with its keyboard fault). **24 of 26 (92%)** drivers — honest
  count. Reveal fix verified on a THIRD machine.
- **Rehearsal outcome — the headline:** `status: findings: 1`, bar
  completed to **100% "Rehearsed"** (fix #4 handles the has-findings case),
  surface said "rehearsed — nothing was written, 1 finding". checks.txt:
  - **`FAIL firmware: this machine booted BIOS/legacy — the target's
    systemd-boot cannot boot here`** — the UEFI preflight's **first real
    catch on metal**, the entire reason that check exists.
  - `ok` target `sdb` ≠ medium `sda` · `ok` fit (470 GB root) · `ok` facts
    match boot audit · `ok` **eval instantiates in 171 s** → `nixos-system-dell`.
  - eval 171 s vs Acer 31 s / MacBook 58 s: Sandy Bridge + a 5400 rpm
    Hitachi is slow, but on 3.8 GB it COMPLETES — where 1.8 GB thrashed
    forever. So Golem's practical eval floor sits above 1.8 GB and at/below
    ~3.8 GB.
  - **`sdb` byte-identical before and after** (xfs + ext4 "home") — the
    prior system's data is safe.
- **Phase B verdict:** the rehearsal works end to end on the Dell, the
  reveal fix holds on a third machine, and the BIOS blocker is caught
  cleanly (→ changes.md #8, needs-Max). Census + rehearsal PASS; install
  correctly gated on the firmware decision.
