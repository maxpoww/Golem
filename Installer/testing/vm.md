# VM — machine zero

Not a laptop: qemu/KVM on the dev box, via `Installer/run-vm.sh`. Boots
every new ISO **first**, before any laptop time is spent on it. 4096 MB on
purpose (the lab's tight-RAM class — testing at 8 GB would hide the memory
pressure the low tier exists for), 4 vcpus, virtio disk/net/gpu.

## What the VM is for (and not)

- **The round's gate:** a fresh ISO that can't clear the VM doesn't touch
  a laptop. Flow regressions (six screens, rehearsal engine, checks.txt,
  bundle) are caught here for free.
- **The only place a FULL install is cheap:** the rehearsal discipline
  exists to protect real disks; a qcow2 is disposable. So the VM may run
  the real `golem-install` — partitioning, nixos-install, the 6/6 reboot,
  first boot of the installed target — every round, long before round 4
  touches metal. Both firmware branches: `--uefi` (systemd-boot) and
  default SeaBIOS (the GRUB/BIOS path).
- **What it can NOT test:** hardware truth. The census sees virtio
  (gpu=virtio/auto, no wifi, no bluetooth, no battery, no panel, no real
  firmware quirks) — every hardware finding still needs the laptops. The
  VM proves the flow; metal proves the facts.

## Mechanics

```
cd ~/Golem/Installer
./run-vm.sh --headless                          # lab-loop mode, SSH-driven
./run-vm.sh --headless --uefi \
            --disk golem-target.qcow2:40G       # UEFI + a target disk
ssh -p 2222 <lab ssh opts> nixos@127.0.0.1      # key-only, golem-vm-loop key
echo sendkey ret | socat - unix:/tmp/golem-vm-hmp   # press Enter at the boot menu
```

- `--uefi` is REQUIRED to test an installed target's boot (qemu defaults
  to SeaBIOS; systemd-boot has nothing to boot from without OVMF).
- After a real install: `--no-cd --uefi --disk golem-target.qcow2` boots
  the installed system.
- Headless + BIOS: the boot menu is invisible (no display for SeaBIOS to
  draw on) — the sendkey line stands in for the keypress.
- Same record block format as the laptop files, plus one extra line:
  **Mode:** rehearse | real-install | installed-boot.

---

## Round 2 (late entry) — 2026-09-07 — FIRST CATCH: silent engine death on the BIOS branch

- **ISO:** round-2 (`result/`, same frozen image as the laptops).
- **Mode:** rehearse (Max driving the visual in the VM window; reproduced
  twice over SSH).
- **The catch:** Max's run stopped at "la instalación se detuvo — el
  registro está arriba" — and the log above had NOTHING. Traced: the BIOS
  branch resolves the target disk to /dev/disk/by-id, the virtio disk had
  no by-id alias (no serial= in the rig), and the resolving loop's failed
  `[[ ]]` guard under `set -o errexit` killed the engine at the
  assignment — one line before its own no-match fallback. No check_fail,
  no eval.err, no status, machine.nix truncated. Minimal repro proven in
  the guest. → **changes.md #19** (errexit-safe loop + an ERR trap so no
  future death is ever silent again).
- **Why five laptops missed it:** SATA disks always have ata-… by-id
  entries; UEFI machines skip the branch. Only a bare virtio disk walks
  it with an empty by-id — machine zero earned its name on day one.
- **Rig fix (harness, not ISO):** run-vm.sh target disk now carries
  `serial=golemtarget` via `-device virtio-blk-pci` (modern qemu removed
  `-drive serial=`), so the VM disk has a by-id alias like real hardware.
- **Verified on the frozen ISO after the rig fix:** full rehearsal exit 0,
  `status: ok`, all checks green — BIOS→GRUB line, target≠medium (sr0!),
  fit (55295 MiB root on the 60G qcow2), facts, **eval 25 s** (i9 host;
  lab metal: HP/Dell 43/170 s). machine.nix:
  `boot.loader.grub.device = "/dev/disk/by-id/virtio-golemtarget"`.
- **Verdict:** the VM caught in its first hour a bug all five laptops
  structurally could not see, and the silent-death UX finding (#19b) on
  top. Machine zero justified.

## Round 3 GATE — 2026-09-07 — the round-3 ISO cleared machine zero

- **ISO:** `fm6x2fi7…` (third build of the close: build 1 shipped a
  config importing the untracked gpu-second.nix — flakes only see
  git-tracked files, the audit FAILED at golem-hw-decide on the guest;
  build 2 exposed the census_reveal @tsv bug below; build 3 is the gate).
- **Mode:** rehearse ×3 (no-by-id engine run, full engine run, full
  Spanish TUI run). Disk verified untouched after all three.
- **#19a PROVEN DEAD:** removed `/dev/disk/by-id/virtio-golemtarget*` on
  the guest and ran the engine — the exact conditions that silently
  killed round 2 now finish: exit 0, `status: ok`, all checks green,
  `grub.device = "/dev/vda"` (the fallback finally reachable).
- **#16 visible:** new `ok ram: 3917 MB is enough…` check line.
- **Full Spanish TUI run — the #18 family end to end:** every decision
  row translated (`Zram Activo…`, `Swap 6 GiB, para hibernar`,
  `Planificador Bfq…`, `Tapa Systemd default`), driver count `5 de 5
  (100%) controladores se instalarán.` rendered at display time, GPU
  verdict row `… — probada, funciona · muestra esta pantalla`, bar
  phases `Evaluando el sistema`, 100% label `Ensayado`, outcome
  `ensayado — no se escribió nada, sin hallazgos`. status ok, eval 23 s,
  machine.nix carries es_ES + GRUB by-id.
- **New catch during the gate (fixed in build 3):** census_reveal read
  the decision rows via jq `@tsv` — but TAB is IFS *whitespace* in bash,
  so the lid row's EMPTY key field collapsed under `read` and shifted
  every later field left: "Tapa" rendered valueless. Fields now travel
  on `` (args on ``), which read does not collapse. Also
  caught: the 100% bar label was a hardcoded English "rehearsed" —
  now `t reh_bar`, translated in all 6.
- **Verdict:** GATE PASSED — the round-3 ISO is clear to reflash onto
  the stick. Two of the gate's three builds existed because the gate
  caught something; machine zero keeps paying for itself.

**Gate addendum (same day):** the ASUS X550LC's first contact caught a
crash the VM structurally can't see (#22 — decide.nix reading
hardware.nvidia.* on the iron-law floor; virtio has no nvidia). Fixed in
source, proven by direct `lib.golem.decide` evals against three fact
shapes (the exact crash facts, the ASUS's round-3 shape, a healthy
Turing hybrid — which also proved gpu-nvidia.nix's gpu2-keyed
activation), ISO rebuilt (**`0cn2c7lq…` is the reflash candidate**),
re-gated: audit ok, engine rehearsal ok. Lesson for the gate's limits:
GPU-dependent eval paths need a metal machine or a fixture eval — now
part of the close checklist via the decide evals.

**Gate addendum 2 — the "all in" build (Max, 2026-09-07):** the two new
machines' remaining findings folded in pre-reflash: #21a (audio row
prefers non-HDMI — unit-tested on the ThinkPad's device list), #21b
(touchpad two-tier, pad beats TrackPoint), #22's visible
"audit incomplete" line (6 languages), and the #17c bounded
re-suspend wait so a probe retry is a real cold resume (if-guarded —
the `[[ ]] && break` form would have been #19a's errexit footgun
again). Rebuilt and re-gated: audit ok, engine ok, disk untouched.
**Reflash candidate: `p5ylp6q6…`** (supersedes `0cn2c7lq…`).

(next for the VM: the closure-delivery dance for a FULL real install —
prepare-only + `nix copy` from the dev box — so the GRUB/BIOS boot of an
installed target gets proven here before round 4 touches metal)
