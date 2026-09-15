# HP Pavilion dm4 — the module-database sweep (the failing dGPU)

HP Pavilion dm4 · i5 M 460 Arrandale (2c/4t) · switchable Intel iGPU +
**AMD Radeon HD 6370M dGPU (FAILING)** · BIOS · 3718 MB · 298 GB Toshiba
(**Linux — guarded**). Preinstall history + the #17c failing-dGPU story:
`~/GolemOne/Install/Preinstall/testing/hp.md`.

## ⚠ Round I2 — an UNRECORDED session, 2026-09-12 — reconstructed from artifacts only

**This is not a record, it is a gap flagged.** Noticed 2026-09-14 while
working the comodore: the repo carries artifacts from an hp session that
no file describes. Constitution rule 8 says a pass is recorded with its
numbers; there are no numbers here because I was not there. Written down
only so the evidence is not lost — **Max should replace this with the
real account.**

What the artifacts prove, and nothing more:
- `hosts/target/golem-hardware.nix` was regenerated **2026-09-12T01:28:40Z**
  with the hp's facts (i5 M 460, 3718 MB, gpu2=amd/failing @ 0000:01:00.0)
  and `machine.nix` carried `networking.hostName = "hp"` plus a
  `boot.loader.grub.device` of `ata-TOSHIBA_MQ01ABF032_83DAS9EVS` — i.e.
  a **real `--prepare-only` ran against the hp's own Toshiba disk**, the
  one this file calls "Linux — guarded". Whether that disk was blessed is
  not recorded anywhere.
- The chosen list dropped that night included **`gpu2/failing`** — the
  first time the #33 leaf was pointed at on metal rather than in a fixture.
- Source comments written the same night (`system/Modular/boot/grub-bios.nix`,
  `grub-theme.nix`, `systemd-boot.nix`, `base/core.nix`) record two
  observations made **at the hp's screen**: GRUB's stock menu looked wrong
  ("all golem should look the same"), and a BIOS machine printed
  *"Not booted with UEFI."* onto every activation because `bootctl` lived
  in `base/core.nix`. Both were fixed in source; both are still
  uncommitted.
- Those `hosts/target/*` files were **overwritten on 2026-09-14** by the
  comodore's install. They remain recoverable from the git index
  (`git show :hosts/target/machine.nix`).

**Owed:** the actual hp experience — was it blessed, did it install, did it
boot, what did the screen show. And the GRUB work's number is contested
(see changes.md #86).

## Round I2 sweep — 2026-09-11 — fixtured; the #33 gpu2/failing leaf BUILT on source against REAL failing-dGPU facts · NO install (census only)

The machine that closes the database — the only lab hardware with a
genuinely failing second GPU, so the only one that exercises
`gpu2/failing` on real facts (asus's GF117M also fails but the fixture
we hold is its old crash-shape without gpu2Health).

- **Reachable at 192.168.1.150** (working ping/ssh; sshd came up a beat
  after ping — the slow Arrandale + the forced-cold dGPU health probe
  make its boot audit the longest in the lab, ~30 s after login).
- **Census (fixtured → `fixtures/hp-pavilion-dm4/`):** i5 M 460 2c/4t,
  3718 MB, gpu=intel, **intelLegacy=true** (Arrandale → i965),
  firmware=bios, **gpu2=amd, gpu2Health=failing, gpu2BusAddr
  0000:01:00.0** (the #23 force-cold verdict holding — the dead radeon
  convicts itself), hasBluetooth=true, laptop. Linux disk untouched, 0
  writes.
- **Chosen leaves — unlocks gpu2/failing:** boot/grub-bios ·
  intel-microcode · gpu/intel-legacy · **gpu2/failing** · zram-tier1 ·
  hibernation · disk/policy · power/laptop · power/thermald.
- **BUILT on source (2.95 GiB):** the composed toplevel compiles and
  carries **golem-dgpu-hold.service** — the SAFE default (no post-install
  answer yet, so hold, never the destructive off). minimal-matrix
  asserts it: hold enabled, golem-dgpu-off ABSENT (mkIf'd out until an
  explicit answer), grub-not-systemd-boot, i965, thermald, tier1. The
  off branch is the verbatim port of gpu-second.nix, already proven live
  end-to-end on the ASUS (#33/#35, generations 2/3/4).
- **Verdict:** the #33 hold/off leaf is proven on source against real
  failing-dGPU facts. **This closes the module database** — every lab
  hardware class now resolves and builds; the chooser refuses nothing
  the lab can present.
