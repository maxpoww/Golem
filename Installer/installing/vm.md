# VM — machine zero of the Installing era

Same rig as preinstall's machine zero (`~/Golem/Installer/preinstall/
run-vm.sh`; mechanics in the archived
`~/GolemOne/Install/Preinstall/testing/vm.md`, which also holds this
qcow2 family's prehistory — including the first BIOS install anywhere,
2026-09-10). 4 GB on purpose: the tight-RAM class.

**Role here:** gates every Installing ISO, and runs every FIRST before
metal — the stage-0 install (UEFI and BIOS), the self-rebuild proof,
every stage climb, every new module class. Record format matches the
machine files: one dated entry per session, Mode line
(gate | real-install | installed-boot | stage-climb), numbers, verdict.

## Prehistory carried forward

- Round-6 gate + the first BIOS install: archived vm.md (the GRUB
  by-id install, `is-system-running: running`, the seam's BIOS debut).
- Disposable disks in use: `golem-target-r6.qcow2` (UEFI, round-6
  gate), `golem-target-bios.qcow2` (the BIOS-install proof, hostname
  `vmbios`). New stages get fresh disks — a stage-0 proof starts from
  zero, a stage-climb proof continues an existing disk on purpose.

## Round I1 — stage 0, UEFI — 2026-09-10 — golem-minimal installed, booted, and SELF-REBUILT; caught + fixed #62

First modular install anywhere. **Mode: real-install + installed-boot +
stage-climb (self-rebuild).** Fresh `golem-minimal-uefi.qcow2`, round-6
stick, hostname `vmmin`.

- **The seam, minimal variant:** answers → `--prepare-only` → pull facts
  → **run the chooser** → build `golem-minimal` toplevel (**2.92 GiB**,
  vs the fat 18.9) → `nix copy` → `--skip-prepare --system` (systemd-boot
  written, header `hostname vmmin (from seed)`) → boot from disk.
- **Chooser output (vmmin):** systemd-boot · intel-microcode · virtio ·
  zram-tier1 · hibernation · disk-policy · qemu-guest — 7 leaves, each
  with its why in modules.nix.
- **First boot:** `is-system-running: running`, zero failed units, root
  /dev/vda3, sshd+NetworkManager active, max's shell = zsh (Golem's),
  **zram-tier1 exact** (zram 5.7G prio 100, swap 6G, swappiness 180,
  cache-pressure 50), resume wired, seed present. Correctly NO
  hyprland/waverunner — this is minimal.
- **#62 — the self-rebuild proof did its job:** the first attempt found
  the installed seed couldn't reproduce itself (no modules.nix dropped;
  golem-minimal never wired flakeDir/flakeAttr). Both fixed in source
  (changes.md #62); after the fix the machine **rebuilt itself
  `#golem-minimal` from its own seed → generation 2, still running.**
  Stage 0's defining requirement — climbs happen by rebuild — proven.
- **Owed on the round-I1 recut:** the engine's LIVE modules.nix drop
  (this stick predates the Modular work; the drop was verified by
  running its exact chooser line, and the seed was hand-synced for the
  rebuild proof — a harness artifact, not a Golem bug), and the
  **BIOS stage-0 install** (this entry is UEFI; BIOS boot-path is
  already proven for the fat target).
- **Verdict:** stage 0 is REAL on UEFI — choose → install → boot →
  self-rebuild, all green, 2.92 GiB. The modular composition reproduces
  the system it runs.

## Round I1 GATE — the recut ISO — 2026-09-10 — stage-0 minimal PASSED on BOTH firmwares, engine drops modules.nix by itself, self-rebuild clean

The round-I1 ISO (`jd9lgha3…-golem-installer.iso`, `result-roundI1`),
cut with the #62 engine fix aboard. `nix flake update` first (the rule);
verified in the built artifact: `golem-install` greps positive for
`Modular/choose.nix`, the embedded seed carries the full `system/Modular`
tree + the `golem-minimal` attr + waverunner `0696b72`.

**THE NEW CAPABILITY, proven live on both firmwares:** a real
`--prepare-only` **drops `hosts/target/modules.nix` into the seed by
itself** — no hand-sync this time (#62's live proof). The seed is
self-sufficient by construction.

- **UEFI (`golem-i1-uefi.qcow2`, vmi1u):** chooser dropped systemd-boot ·
  intel-microcode · virtio · zram-tier1 · hibernation · disk-policy ·
  qemu-guest. Installed 2.92 GiB, first boot `running` / 0 failed /
  root vda3 / zsh / swappiness 180 / sshd+NM active. **Self-rebuild
  `#golem-minimal` from the untouched seed → generation 2, running.**
- **BIOS (`golem-i1-bios.qcow2`, vmi1b):** chooser correctly swapped in
  **grub-bios** (not systemd-boot) — the leaf split works. SeaBIOS →
  GRUB (installed to the by-id alias) → Golem, first boot `running` /
  0 failed / root vda3 / zsh / swappiness 180. **Self-rebuild → gen 2,
  running.**
- **Verdict:** **round-I1 ISO GATE PASSED, both firmwares.** Stage-0
  modular install is real end to end — choose → drop modules.nix →
  install → boot → self-rebuild — with the seed carrying everything by
  construction. `jd9lgha3…` is the reflash candidate for the acer (the
  first blessed metal, stage 0).
