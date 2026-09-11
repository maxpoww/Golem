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

*(entries begin with round I1, step 6 of implementation.md)*
