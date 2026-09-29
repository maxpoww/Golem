# Lenovo (the dev box) — nvidia stage-0 to an EXTERNAL drive, from the live dev box

Lenovo Slim Pro 9 16IRP8 · i9-13905H Raptor Lake · **hybrid Intel Iris Xe +
NVIDIA RTX 4050 Max-Q** · UEFI · 953.9 GB Samsung NVMe (internal, the dev box)
· 32 GB RAM · Intel CNVi wifi. **This is the dev box** — it drives the lab and
holds the records; its internal disk is never an install target. Preinstall
history: `~/Golem/docs/installing/preinstall/testing/lenovo.md`.

## 2026-09-18 — INSTALLED to an external 2 TB, from the running dev box — verified static; boot-audit OWED

**What / why (Max):** *"install on the external 2tb here too… not touch
windows."* The lenovo is the only lab machine that exercises **nvidia primary
offload** (RTX 4050) and **tier3** (32 GB) — both proven only on source. So we
banked them on metal without disturbing the dev box: Golem installed to the
external 2 TB, the internal Samsung NVMe (dev-box OS) never touched.

### Method — a controlled MANUAL install FROM the live dev box (a first)
`golem-install` is unsafe to run on the live dev box: it does `swapoff -a`
(kills the dev box's swap) and mounts/swaps by the label `swap` — which BOTH
the dev box's internal swap and the new external swap would carry, so it'd
grab the wrong device or die. So a hand-written, guarded script
(`scratchpad/install-lenovo-external.sh`) reused golem-install's *logic*
(chooser, grub-efi leaf, machine.nix shape) while being dev-box-safe:
- **Hard guards** — wipes only `/dev/sda` iff it resolves from the Seagate
  by-id, is USB, ~2 TB, and the running root is `nvme0n1`. Never `swapoff -a`.
- **by-uuid swap** in hardware-configuration.nix (dodges the label collision);
  root/ESP by-label (`golem`/`ESP` are unique).
- Partition (ESP 512M + swap 35 G + ext4 root) → seed the dev tree → drop
  `hosts/target` (golem-hw-detect reads THIS box → RTX 4050; chooser →
  modules.nix) → build `golem-minimal` locally (nvidia closure already warm) →
  `nixos-install --root /mnt/gx` → **grub-efi to the external ESP with
  `efiInstallAsRemovable` + `canTouchEfiVariables=false` (#94)** — writes ONLY
  `\EFI\BOOT\BOOTX64.EFI` on the external, **zero NVRAM writes**, so the dev
  box still boots normally and Golem boots via **F12**.
- Ran as root via `sudo` (Max ran it; sudo needs a password here). The dev
  box lacked `sgdisk` etc. in root's PATH + sudo resets PATH → the script
  pins the installer tools from the pinned nixpkgs (c5c4a43).

### Verified statically (post-install, read-only)
- external: `sda1` ESP (vfat) + `sda2` swap 35 G + `sda3` ext4 `golem`
- **`/mnt/gx/boot/EFI/BOOT/BOOTX64.EFI` present**, `EFI/` holds only `BOOT`
  (removable, no NVRAM) ✓
- system profile `system-1-link` (generation 1) installed ✓
- **chosen leaves = the nvidia+tier3 split:** grub-efi · intel-microcode ·
  **gpu/intel** (Iris Xe primary, iHD) · **gpu2/nvidia-offload-turing**
  (RTX 4050) · **zram-tier3** (32 GB) · hibernation · disk/policy · laptop ·
  thermald — the FIRST nvidia-primary-offload + tier3 chosen on metal
- internal Samsung NVMe + dev-box swap: untouched

### BOOT-CHAIN PROVEN on the thinkpad (2026-09-18) — Max's cross-boot test
Booting the external on the dev box would reboot it and end the session, so
Max F12-booted the external **on the thinkpad** (AMD) instead — a hardware
mismatch on purpose, to test the boot chain (which is hardware-agnostic)
without killing the session. It **booted** (slow — USB HDD) and audited over
SSH at `.149`:
- **grub-efi booted off USB (F12); the initrd mounted the USB root** —
  `usb_storage` + `uas` loaded, root `/dev/sda3` (my dev-box-generated-config
  fear that the initrd would lack USB modules was WRONG; golem's base carries
  them).
- **`running`, 0 failed units** — even cross-hardware. The nvidia driver
  found no GPU ("NVRM: No NVIDIA GPU found"), unregistered gracefully, **no
  failed unit** — it does not block boot.
- **tier3 sysctls applied** (swappiness 10 / cache-pressure 10 / dirty 10);
  rejoined `golem-lab` on the thinkpad's radio (#64 works cross-hardware).
- **Conclusion:** the boot chain + config + system health are proven; since
  those are hardware-agnostic, **the lenovo will boot it too.**

### RTX 4050 PROVEN on metal (2026-09-18) — via the Fedora agent — **PASS**
The external was F12-booted on the actual lenovo; a Claude agent on the
Fedora ThinkPad (handed a `CLAUDE.md`) audited it over SSH at `.152` and
recorded the result (synced here from the dev box afterward). **The one open
item — the RTX 4050 binding — is closed:**
- **driver = `nvidia`** (not nouveau, not unbound): `0000:01:00.0 [10DE:28E1]`
  → `/sys/bus/pci/drivers/nvidia`, uevent `DRIVER=nvidia`. (`lspci` is NOT in
  the minimal image — sysfs was the canonical read; see changes.md #97.)
- **`nvidia-smi`:** GeForce RTX 4050 Laptop GPU, driver **595.71.05**, CUDA
  13.2, 6141 MiB.
- **dmesg found+initialized it:** `NVRM: loading NVIDIA UNIX Open Kernel
  Module … 595.71.05`, `nvidia-modeset` loaded, `[drm] Initialized nvidia-drm
  … for 0000:01:00.0`. Nodes `/dev/nvidia{0,ctl,-modeset,-uvm,-uvm-tools}`.
- **offload topology correct:** Intel `0000:00:02.0` → `i915` drives the
  primary display; nvidia drives no CRTC ("Cannot find any crtc") — **bound
  but idle**, exactly right for PRIME offload on a headless minimal.
  `nvidia-offload nvidia-smi` dispatches to the dGPU.
- **rule-6:** `lenovo` on `/dev/sda3` (external), **`running`, 0 failed**;
  **tier3** (swappiness/cache-pressure/dirty 10 · zram 25 % = 7.8 G prio 100
  + 35 G disk swap); resume `by-uuid/7b1cb727…` (→ /dev/sda2), no
  fbcon/splash; `rebuild-golem` + seed `modules.nix` present; rejoined
  `golem-lab` (wlp0s20f3) on its own.
- **source leg (from the seeded checkout):** `chooser-matrix` /
  `minimal-matrix` / `keyboard-table` / `timezone-defaults` all PASS; the
  chooser's lenovo leaf list is byte-identical to the installed
  `modules.nix`, and all ten `minimal-matrix` effects (open module,
  `nvidiaPackages.stable`, the suspend fix via `PreserveVideoMemoryAllocations`,
  offload bus ids, LIBVA=iHD on the intel primary, tier3 zram 25 %) were
  observed on metal. The 2026-09-08 ISO fixture recorded the SAME
  `[10de:28e1]`/`[17aa:3fa0]` as `nouveau`; Golem binds it as `nvidia` — the
  leaf's job, one before/after pair.

**Verdict: PASS.** The `gpu2/nvidia-offload-turing` leaf is proven on real
RTX 4050 metal — the lenovo was the last open hardware class. Live-fix run
(dev-tree, grub-efi) — rides the recut. Findings the audit surfaced:
changes.md **#97** (lspci absent from minimal), **#98** (facts-matrix needs a
pristine tree + no lenovo facts-matrix row). Non-nvidia note: two i915 Type-C
DP-PHY boot WARNINGs (no failed unit) — logged against the Iris Xe path.
