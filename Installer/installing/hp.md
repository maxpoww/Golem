# HP Pavilion dm4 — the module-database sweep (the failing dGPU)

HP Pavilion dm4 · i5 M 460 Arrandale (2c/4t) · switchable Intel iGPU +
**AMD Radeon HD 6370M dGPU (FAILING)** · BIOS · 3718 MB · 298 GB Toshiba
(**Linux — guarded**). Preinstall history + the #17c failing-dGPU story:
`~/GolemOne/Install/Preinstall/testing/hp.md`.

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
