# Acer — the first blessed metal install of the modular era

## 2026-09-15 — #92's first metal: systemd-boot → GRUB-EFI, and the firmware fought back (#94)

**Status in one line:** the acer boots **GRUB-EFI** wearing the same Golem
menu as the comodore — `booted == current == jr3f86mg…` (a generation
only GRUB knows), `running`, 0 failed units.

- **Method — local rebuild, not delivery.** 3833 MB is above the #16/#66
  eval floor and this machine had self-rebuilt twice already, so: rsync
  the updated source into its seed (`system/` + flake, `installed ==
  seed` preserved), re-point `hosts/target/modules.nix` at
  `boot/grub-efi.nix` (an owner edit, marked `#92`, with a
  `.pre-92` backup beside it), pre-deliver the patched grub over the
  INTERNAL ath10k (#67's sanctioned path — 100 MiB, plain `nix copy`),
  then `nixos-rebuild boot`. ~15 minutes end to end.
- **First attempt LOOKED perfect and silently failed.** GRUB installed,
  a named `Golem-boot` NVRAM entry appeared, BootOrder put it first —
  and the next boot came up on **generation 2**. The firmware had purged
  entry 0002 and booted its own `HDD:` entry → the removable fallback →
  **systemd-boot**, which knows nothing past gen 2. Caught only because
  the wire check compares `booted` against `current`; the machine was
  healthy and would have passed any casual look. **→ #94.**
- **The fix that stuck:** own `\EFI\BOOT\BOOTX64.EFI`
  (`efiInstallAsRemovable`), now the default for every UEFI machine.
  Needed `nixos-rebuild boot --install-bootloader` — a plain rebuild
  regenerates grub.cfg but skips `grub-install`.
- **Escape hatch left in place:** sd-boot's binary still at
  `/boot/EFI/systemd/`, plus `BOOTX64.EFI.sdboot-backup`; F12 →
  "Linux Boot Manager" returns to the old loader.
- **Owed:** Max's eyes on the menu — whether it reads as the SAME menu
  as the comodore's on a different panel (1366×768 vs 1024×768; the
  theme is percentage-based, so it should).

## Round I2 — reinstalled from the SHIPPING ISO — 2026-09-11 — PASS; #65 and #64 arrive from the image, not from a patch

The acer's round-I2 turn (the round runs the whole roster — constitution
rule 2). Its round-I1 install carried the #65 console fix as a LIVE
patch; this one takes it from the shipping image, on the machine that
found the bug. Blessed by Max ("do it") — the I1 install on `sda` (the
dell's old 465.8 G drive) was wiped.

- **ISO:** round-I2 (`m8vkd2jg…`), booted from the stick; DHCP handed
  the medium `.99`.
- **Chosen leaves — identical to round I1** (the chooser is
  deterministic for identical facts): systemd-boot · intel-microcode ·
  gpu/intel · zram-tier1 · hibernation · disk/policy · power/laptop ·
  thermald.
- **Delivered over the acer's INTERNAL ath10k** — the path that works
  (#67: the USB-dongle deliveries are what killed the dell/comodore).
- **First boot, generation 1:** `acer` on `/dev/sda3`,
  `is-system-running: running`, **zero failed units**.
  - **#64 from the image:** `--lab-wifi` baked the profile in and the
    machine **rejoined HOLA by itself** (`golem-lab:wlp3s0:activated`)
    — its I1 install predated the flag.
  - **#65 from the image:** no `fbcon=map:1` on the booted cmdline.
    Last round this fix had to be nix-copied on after the fact; now it
    ships. Console confirmed visible at the machine.
  - `LIBVA_DRIVER_NAME=iHD` (Broadwell), zsh, swappiness 180 (tier1),
    seed + modules.nix, rebuild-golem, no desktop (minimal ✓).
- **Self-rebuild:** `#golem-minimal` from its own seed → **generation
  2**, still running.
- **Verdict:** **PASS.** The acer now runs a stage-0 Golem built
  entirely from the shipping round-I2 image, with no live patches in
  it. Round-I2 turn: done.


Acer Aspire E5-573 · i5-5200U Broadwell (2c/4t) · Intel HD 5500 ·
QCA9377 wifi+BT · **boots UEFI** · 3833 MB RAM. Its census identity
throughout the preinstall rounds
(`~/GolemOne/Install/Preinstall/testing/acer.md`); Installing starts
here.

## The setup — a drive swap (Max, 2026-09-10)

Max put **the dell's old Hitachi HTS545050A7E380 (465.8 G) into the
acer** to save the acer's factory-Windows drive: the wipe target is the
dell's disposable Linux disk (xfs + a 441 G ext4 "home"), the acer's
own Windows disk is out of the machine and safe. So this record's
hardware is the acer's (CPU/RAM/GPU census confirms: 3833 MB, Broadwell,
HD 5500) but its disk is the dell's — a distinction the harness-first
check caught before any write (see below).

## Round I1 — stage 0, minimal — 2026-09-10 — INSTALLED, and caught 4 findings the VM couldn't

First real modular install. golem-minimal, blessed by Max ("acer").

### The install
- **ISO:** round-I1 stick (`jd9lgha3…`), UEFI. Census `ok`.
- **Harness-first catch (constitution rule 7):** the census read acer
  hardware (3833 MB, intelLegacy=false) while the disk read the DELL's
  exact UUIDs (xfs `492cfb55…` + ext4 "home" `bd0c3e05…`, 465.8 G) —
  a 441 G home of real data. STOPPED before any write, surfaced the
  contradiction; Max confirmed the drive swap. Writes-completed was 0
  at the halt. This is why we snapshot the disk and suspect the rig.
- **The seam, on metal:** answers (English/Denver/us, host `acer`,
  user `max`) → real `--prepare-only` (wiped the Hitachi: GPT + ESP
  512M + swap 6G + ext4 "golem" 459 G) → **the engine dropped
  `modules.nix` itself** (#62's fix, first time on metal).
- **The chosen list = the source prediction, exactly:** boot/
  systemd-boot · cpu/intel-microcode · gpu/intel · memory/zram-tier1 ·
  swap/hibernation · disk/policy · power/laptop · power/thermald —
  byte-identical to the `minimal-matrix` acer row built & asserted on
  source. The modular promise held: what CI proved is what the metal
  chose.
- **2.92 GiB closure** delivered over lab wifi, `--skip-prepare` wrote
  systemd-boot (header `hostname acer (from seed)`), gen 1.
- **First-boot audit (over SSH):** hostname acer, root /dev/sda3,
  `is-system-running` **running**, 0 failed units, sshd+NM active, zsh
  shell, uid 1000. **tier1 exact** (zram 5.6G prio 100, swap 6G,
  swappiness 180, cache-pressure 50, dirty 5, max-jobs 1). **LIBVA=iHD**
  (Broadwell, correct). resume wired, thermald active, upower/ppd
  enabled-but-dormant (dbus-activated; nothing queries them on a
  headless minimal — correct, not a fault). Seed present, rebuild-golem
  present, modules.nix in the seed. No hyprland/waverunner (minimal).

### The findings this install caught (the VM never could)
- **#63 — the medium doesn't auto-join** (NM gives up after 4 retries):
  the acer needed the manual nmtui bounce to reach the network, on a
  new day — promoted from a round-5 watch item to a real finding.
- **Boot-hang incident (watch item):** on the ISO's FIRST metal boot,
  a stuck blinking cursor / blank screen; a power-cycle (same Start
  entry) booted clean. One-off, unreproduced — recorded to watch for
  recurrence on this Broadwell box (may share a root with #65's KMS/
  console timing).
- **#64 — an installed minimal has no lab wifi**, so it can't rejoin
  the lab for the remote first-boot audit; had to be connected at the
  keyboard. Lab installs need `--lab-wifi` (or `--lab-ssh`'s pathway
  extended) → changes.md.
- **#65 — THE BIG ONE: minimal booted to a DEAD SCREEN.** systemd-boot
  drew, then blank — no login ever appeared; Max typed the login and
  `nmcli` BLIND and it worked, proving the system was fully up and
  SSH-reachable the whole time. Root cause (read-only diagnosis):
  `fbcon=map:1` in the kernel params maps the console to framebuffer
  1, but the acer has only fb0 → the tty renders to nowhere. It rode
  into `base/core.nix` verbatim from the fat config, where greetd→
  Hyprland takes the screen via KMS and a mapped-away fbcon never
  mattered. On minimal, fbcon IS the display. **Exactly the class of
  bug minimal-first exists to surface.**
  - **Fixed live:** dropped `fbcon=map:1` + `splash` from
    `base/core.nix` (kept the log-quieting — quiet, not blank), built
    the fixed toplevel, updated the acer's seed, **self-rebuilt
    `#golem-minimal` → gen 3**, rebooted. **Verified on the acer's own
    screen (Max): boot loader → quiet blank → `login:` → zsh.** The
    running kernel has no `fbcon=map:1`; the vtconsole is now `(M)
    frame buffer device`, not the dummy. The desktop stage will own its
    own clean-boot handoff.
  - This also **proved the self-rebuild on metal** (gen 1 install →
    gen 3 by rebuild from the seed), stage 0's defining requirement.

### Verdict
**PASS — stage 0 is real on metal.** The acer installed, booted healthy,
chose exactly what CI predicted, and now shows a usable login. Four
findings the harness/VM could never see (#63 network, the boot-hang
watch item, #64 lab-wifi, #65 the blank console) — the human-at-the-
keyboard catching what SSH cannot, precisely the first-install lesson.
Live-fixed #65 on the frozen stick (seed update, marked); #63/#64/#65
source fixes ship in the round-I2 cut. **Stage 1 (the desktop) is next,
as a rebuild on top of this working stage 0.**
