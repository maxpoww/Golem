# HP Pavilion dm4 — the module-database sweep (the failing dGPU)

HP Pavilion dm4 · i5 M 460 Arrandale (2c/4t) · switchable Intel iGPU +
**AMD Radeon HD 6370M dGPU (FAILING)** · BIOS · 3718 MB · 298 GB Toshiba
(**Linux — guarded**). Preinstall history + the #17c failing-dGPU story:
`~/Golem/docs/installing/preinstall/testing/hp.md`.

## 2026-09-18 — stage-0 metal, clean-image — INSTALLED, PASS (constitution rule 2 turn) — and #87 confirmed on Arrandale

**Status in one line:** `hp` on `/dev/sda3`, `is-system-running: running`,
**0 failed units**, rejoined `golem-lab` by itself, generation
byte-identical to the toplevel built here. Stage 0 is real on the
Arrandale / failing-dGPU machine.

Blessed by Max ("wipe it"). The guarded Toshiba turned out to hold only the
**unrecorded 2026-09-12 ghost Golem** (GPT bios-boot + swap + ext4 `golem`,
no user data) — read-only inspection shown to Max before the blessing; the
09-12 gap flag below is now moot (that install is gone).

### Method — clean image, stock engine (hp is above the #66 floor)
hp reports **3718 MB**, above the 3300 local-eval floor, so the shipping
medium's **stock** `golem-install` ran it with no live patch — meaning the
seed it dropped is the **frozen ISO source**, not the dev tree. The toplevel
was built on the dev box **from hp's own pulled seed** (nixpkgs `c5c4a43`,
no #92–#95 grub work), so this is a genuine clean-image round-I2 record,
like the acer's I2 turn — not a live-fix run.
- `--prepare-only --yes` (wiped `sda`: GPT bios-boot 1 MiB + swap 6 GiB
  `09dbede8…` + ext4 `golem` 287 G), `--lab-ssh` + `--lab-wifi HOLA` baked
  in. The engine dropped the four target files itself.
- **Chosen list = the sweep's prediction, exactly:** grub-bios ·
  intel-microcode · gpu/intel-legacy · **gpu2/failing** · zram-tier1 ·
  hibernation · disk/policy · power/laptop · power/thermald.
- **2.96 GiB / 1040 paths** built (clean seed) and delivered full-speed to
  `/mnt` over hp's **internal** wifi (1170 Mbit/s — not #67's dongle class;
  no throttle needed, zero drops), then `--skip-prepare --system` wrote
  GRUB to the Toshiba (`ata-TOSHIBA_MQ01ABF032…`, i386-pc). "No error."

### First-boot audit (tools/firstboot-audit.sh, over SSH)
| | |
|---|---|
| hostname / root | `hp` on `/dev/sda3` |
| generation | `3pvyglhpw94…-nixos-system-hp` — byte-identical to the built toplevel |
| health | `running`, **0 failed units** |
| boot time | 31.3 s (1.5 kernel + 8.5 initrd + 21.3 userspace) |
| tier1, exact | zram0 **5.4 G prio 100** + 6 G disk swap · swappiness 180 · cache-pressure 50 · dirty 5 · page-cluster 0 · max-jobs 1 |
| resume= | `by-uuid/09dbede8…` — wired · **#65** fbcon/splash = 0 |
| owner | `max` uid 1000, shell **zsh** |
| self-rebuild | `rebuild-golem` · seed · `modules.nix` all present |
| MINIMAL | hyprland / greetd / waybar / waverunner all **absent** |
| intel-legacy | `LIBVA_DRIVER_NAME="i965"` |
| **#87** | `thermald` **inactive** — the silent no-op **confirmed on Arrandale** (predicted from the comodore's Penryn); 0 failed units |
| **#64** | `golem-lab:wlp3s0:activated` — rejoined by itself (iwlwifi) |
| **#88** | `configurationRev = unknown` — the git-less seed, as expected |
| GRUB theme | **absent** — correct for the frozen image; #68/#89/#95 ride the recut |

### Self-rebuild (§5)
`rebuild-golem` (`#golem-minimal` from its own seed) evaluated, built, and
re-activated cleanly — "activated == latest", "activated == booted",
`running`, 0 failed. It fetched home-manager (hp has internet via HOLA) and
produced the **identical** frozen toplevel, so Nix kept it at generation 1
rather than cutting a duplicate — the honest distinction from the
acer/comodore, whose rebuilds carried a real delta. The rebuild pipeline
(evaluate → build → activate) is proven end to end; the eval completed
comfortably above the #66 floor.

### Verdict
**PASS — stage 0 is real on the hp.** Constitution rule 2 turn done: hp met
the same frozen image the acer/comodore did, chose exactly what CI
predicted, booted healthy, and rebuilds itself. It also confirmed #87 on a
second microarchitecture. **Roster now: only the macbook (the boss fight)
still owes its turn before this round can close.**

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
