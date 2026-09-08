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

## Status: DEFERRED (Max, 2026-09-08)

First contact deferred indefinitely. Testing this box means booting the
dev box itself from the stick — which takes down the session that drives
the whole lab — so it is the one participant that can only be tested from
ANOTHER machine, "someday, not today" (Max). Round 3 is considered closed
without it.

**What it would have added, and why deferral is low-cost:** its unique
contribution was the HEALTHY modern-nvidia path on real metal (Iris Xe +
RTX 4050 → turing+ → open module + working PRIME offload). The ASUS
(round 3) already covers the intel+nvidia hybrid TOPOLOGY and the risky
questions — boot_vga primary pick, the dGPU health verdict, the iron-law
floor — but with a FAILING old Fermi, not a healthy RTX. So the healthy
turing+ offload path stays proven by FIXTURE EVAL only (done during the
#22 fix: turing+ facts → open module + PRIME offload activate), not on
physical metal. That is the happy path and the least likely to surprise;
the first healthy-nvidia machine to appear gets the live proof.

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
