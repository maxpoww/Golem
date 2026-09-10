# Testing — what "proven" means for the preinstaller

The lab's rules are `testing/constitution.md`; the drive mechanics are
`testing/CLAUDE.md`. This page is the method in brief, for whoever
tests the next change.

## The ladder (cheapest first)

1. **The eval matrix / fixtures** — every decision asserted against
   `fixtures/<machine>/` census shapes at build time. Catches logic
   regressions with zero hardware; caught #22's crash shape from a
   file. New GPU/decision logic starts here.
2. **`bash -n` + the built script** — `mockup/install-cli` is bash; the
   built `golem-setup-unwrapped` is what actually runs. Verify markers
   in the STORE PATH, not the source file.
3. **The VM (machine zero, `run-vm.sh`)** — gates every ISO before any
   flash. 4 GB on purpose (the tight-RAM class), UEFI and BIOS, qemu
   guest facts are real census facts (`vmGuest`). The one place a full
   install onto a disposable qcow2 is always allowed. Limits it cannot
   see: real GPUs (#22 was invisible to virtio — GPU paths need a
   fixture eval or metal), real wifi, real timing.
4. **Metal** — the machine files in `testing/` are the roster, each
   with its unique proof (the acer = RAM boundary; comodore = BIOS +
   #16 refusal + Gen4 GPU; hp = failing AMD dGPU; dell = flipped
   device order + USB wifi; thinkpad = AMD CPU; macbook = Apple
   EFI/Broadcom; lenovo = modern hybrid + the dev box; asus = nvidia
   hybrid, now the installed dogfood machine).

## The invariants every pass re-proves

- **Rehearsal writes nothing:** UUIDs + partition table + first-MiB
  hash identical before/after, `/sys/block/sdX/stat` writes-completed
  unchanged, transcript all `would` / zero `run`.
- **Facts match:** the install-time probe agrees with the boot audit
  fact for fact (the #23 flap detector).
- **The boot medium is never offered** as a target — in both device
  orders (stick as sdb AND as sda).
- **Cancellable everywhere, residue-free:** F1/Ctrl-C from any state →
  prompt back, one exit, run-scoped temps gone, outputs kept.
- **The reveal is honest:** verdicts measured this boot, absences
  real, uncertainty dim.

## The record

Passes are findings too. One block per run, appended to the machine's
file (format in `testing/CLAUDE.md`): ISO markers confirmed, census
cross-check, surface walk, rehearsal checks + eval time, disk proof,
findings queued, one-line verdict. The finding itself goes to the
machine file; the CHANGE it implies goes to `changes.md`. Fixture-worthy
raw data → `fixtures/<machine>/`.

## Regression baselines worth knowing

Eval times per machine are stable identity: lenovo ~8 s, VM ~18 s,
thinkpad ~22 s, acer/asus ~30 s, hp ~44 s, dell ~171–174 s. A big move
without a hardware story is a finding. RAM floor: 3833 MB passes,
1931 MB refuses — the boundary machines are the acer and the comodore.
