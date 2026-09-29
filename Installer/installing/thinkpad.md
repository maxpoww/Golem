# ThinkPad — the module-database sweep (AMD)

Lenovo ThinkPad E15 Gen 2 · AMD Ryzen 7 4700U (8c/8t) · Renoir Vega
iGPU (single GPU) · UEFI · 238.5 GB NVMe (**Windows — guarded**) ·
7159 MB · RTL8822CE wifi. Preinstall history:
`~/Golem/docs/installing/preinstall/testing/thinkpad.md`.

## 2026-09-18 — THE AMD PATH ON REAL METAL — installed to an EXTERNAL 2 TB HDD, Windows untouched, PASS

**Status in one line:** `thinkpad` on `/dev/sda3` (an external 2 TB USB HDD),
`is-system-running: running`, **0 failed units**, GRUB-EFI booted off the
external drive via F12, the AMD split is live, and **the internal Windows
NVMe was never touched.** This banks the one hardware class we'd only ever
proven on source — AMD — and the first **tier2** on metal.

Max: *"lets install on the external drive on the thinkpad (not touch
windows)"* → *"swipe the 2tb. nothing important on that one."* The asus
playbook (external-drive install), so the dual-boot testbed (Windows) is
preserved for later.

### Safety — the target picked by identity, Windows excluded
Three disks present: **`/dev/sda`** = the 2 TB Seagate BUP (USB, target,
by-id `usb-Seagate_BUP_Slim_BL_NA9BKT0Z-0:0`); `/dev/nvme0n1` = the internal
Windows (ESP+MSR+NTFS+WinRE — untouchable); `/dev/sdb` = the Golem boot stick
(=/iso, #20-excluded). Hard guards before the wipe: target must resolve from
the Seagate by-id, be USB, be ~2 TB, and not be the NVMe. **Post-install
confirmed the NVMe still carries all four Windows partitions.**

### Method — grub-efi, no NVRAM (Windows boot untouched)
For an external drive booted via F12, `boot/grub-efi.nix`'s #94 defaults are
ideal: `efiInstallAsRemovable=true` + `canTouchEfiVariables=false` → GRUB
goes ONLY to the external ESP (`\EFI\BOOT\BOOTX64.EFI`), zero NVRAM writes,
so the thinkpad still defaults to Windows and Golem boots only when F12
selects the external drive. That needs the dev-tree engine (grub-efi is a
#92 leaf the frozen ISO lacks), so this is a live-fix run: patched
golem-install (`--override-input golem path:<clean git tree>`) nix-copy'd to
the medium → `--prepare-only` (ESP 512M + swap 9G `42b6db13` + ext4 golem on
the 2 TB) → build golem-minimal from the seed (2.97 GiB) → deliver to /mnt →
`--skip-prepare` wrote GRUB-EFI (x86_64-efi).

### First-boot audit
| | |
|---|---|
| hostname / root | `thinkpad` on `/dev/sda3` (external 2 TB) |
| generation | `f05f3dp…-nixos-system-thinkpad` — byte-identical to the built toplevel |
| health | `running`, **0 failed units** (boot 80 s — slow off a USB HDD, expected) |
| **AMD split, live** | **amd microcode** `0x08600106`; **no LIBVA pin** (radeonsi/mesa default, as predicted); **thermald not running** (correctly gated off AMD); gpu/amd |
| **tier2 (first on metal)** | zram0 3.5 G prio 100 · swap 9 G · swappiness **60** · cache-pressure **10** · dirty **10** · page-cluster 0 · max-jobs auto |
| resume / #65 | by-uuid `42b6db13` wired · fbcon/splash = 0 |
| wifi (#64) | `golem-lab:wlp3s0:activated` (rtw88_8822ce, in-tree) — rejoined itself |
| boot | GRUB-EFI off the external ESP, theme present (#92/#95 look) |
| **Windows** | `nvme0n1` ESP+MSR+NTFS+WinRE **all intact — untouched** |
| self-rebuild (§5) | `rebuild-golem` → evaluate/build/activate clean, `activated == latest`, running/0-failed |
| minimal / owner | no desktop; `max` uid 1000 zsh |

### Verdict
**PASS — the AMD path is real on metal**, and tier2 with it, without
destroying Windows or the dual-boot testbed. Every GPU class the lab holds is
now proven on installed hardware (intel-legacy, Broadwell, broadcom/Apple,
AMD). Live-fix run (dev-tree, grub-efi) — rides the recut. The internal-disk
dual-boot install stays a future test (implementation.md), for which this
box's Windows is deliberately preserved.

## Round I2 sweep — 2026-09-11 — fixtured; the AMD path proven on source · NO install (census only)

Booted the round-I1 stick for its facts — the module DATABASE sweep, not
an install (Windows stays guarded; NVMe writes-completed = 0).

- **Joined the network ON ITS OWN** — no bounce. This is the datapoint
  that corrected a harness error (see below): my earlier
  `zsh -c 'echo >/dev/tcp/…'` reachability checks failed unconditionally
  (**zsh has no /dev/tcp** — a bash-only feature), so every "not on the
  network" reading I reported was a false negative. Method fixed to
  ssh/ping/bash. Reachable at 192.168.1.149; Max's own `ssh max@.149`
  from a tty is what exposed my broken check.
- **Census (fixtured → `fixtures/thinkpad-e15-gen2/`):** Ryzen 7 4700U
  8c/8t, 7159 MB, `gpu=amd` (Renoir Vega, single), `cpuVendor=amd`,
  intelLegacy=false, firmware=uefi, panelDpi=143, hasBluetooth=true,
  laptop. Windows disk (ESP + MSR + NTFS + WinRE) untouched.
- **Chosen leaves — the FIRST AMD machine, and it splits correctly:**
  systemd-boot · **cpu/amd-microcode** (not intel) · **gpu/amd** ·
  zram-tier2 (7159 MB) · hibernation · disk/policy · power/laptop —
  and **NO power/thermald** (the chooser gates thermald on
  intel-laptop only; thermald is Intel's daemon). gpu2/virt/quirks all
  skipped with reasons.
- **Proven on source (Max's rule):** chooser-matrix pins the list;
  minimal-matrix asserts the effects — amd microcode on, intel
  microcode off, no LIBVA pin (mesa radeonsi rides the default stack),
  power-profiles-daemon on, **thermald OFF**, tier2 swappiness 60,
  systemd-boot. The AMD-primary + amd-microcode + no-thermald paths are
  now locked against this fixture.
- **Verdict:** fixtured and source-proven. The thinkpad's contribution
  to the database — the clean AMD split — is banked without touching its
  disk. (A real AMD install would come later if Max blesses it; the
  sweep only needed its facts.)
