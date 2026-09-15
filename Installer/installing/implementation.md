# Implementation plan — Installing, in build order

Each step is provable before the next starts; VM before metal, always.
Status marks: ☐ open · ◐ in progress · ✅ done (date).

## Round I1 — stage 0 exists

1. ☐ **`system/modules/base/`** — network, ssh, zsh, users, console,
   nix, selfrebuild. Lifted verbatim from the current system where the
   config already exists (zsh especially: Golem's identity, unchanged).
2. ☐ **Hardware leaves, first cut** — boot/ (systemd-boot, grub-bios),
   cpu/, gpu/ (intel, intel-legacy, virtio — only what round I1's
   machines need; nvidia/amd leaves land when their machines enter),
   memory/ (every tier the current formula actually produces, values
   copied verbatim and stated in each header), swap/, disk/, power/.
3. ☐ **The chooser** — `golem-hw-choose`, logic relocated from the
   decide machinery; writes `hosts/target/modules.nix` (total,
   explained, loud on unmatchable). Engine phase 4 drops it with the
   other target files; `hosts/target/default.nix` imports it when
   present.
4. ☐ **`golem-minimal` composition** — `nixosConfigurations` attr:
   base + chosen leaves, nothing else. Closure size measured and
   recorded (target: ≤3 GiB).
5. ✅ **Matrix: chosen-list AND effect assertions** (2026-09-10) —
   `checks.chooser-matrix` pins every fixture to its expected pointer
   list (nvidia machines to their refusal); `checks.minimal-matrix`
   (Max: build & test the hardware modules on source) composes each
   machine's chosen leaves via `mkMinimal` and asserts the evaluated
   config — the acer's 20 effects (iHD, systemd-boot, tier1 sysctls,
   thermald, laptop stack, flakeAttr=golem-minimal, no nvidia, no
   hyprland) + qemu-virtio's. The acer's composed toplevel is not just
   instantiated but BUILT on source (2.92 GiB, sysctls + LIBVA=iHD +
   rebuild-golem verified in the store path). `nix flake check` green.
6. ✅ **VM gate, both firmwares** (2026-09-10, vm.md) — UEFI (vmi1u) AND
   BIOS (vmi1b): choose → the engine DROPS modules.nix itself → deliver
   → install → first boot clean → **self-rebuild as golem-minimal → gen
   2** from the untouched seed. 2.92 GiB. The BIOS leaf split
   (grub-bios vs systemd-boot) verified.
7. ✅ **Recut the ISO** (`jd9lgha3…`, round-I1) — `nix flake update`
   done, built artifact verified (golem-install carries the chooser;
   seed carries Modular + golem-minimal + waverunner 0696b72). The
   engine's live modules.nix drop proven on both firmwares. ☐ Reflash
   the stick (Max) — this ISO installs minimal by default.
8. ✅ **First blessed metal machine, stage 0 — the acer** (2026-09-10,
   acer.md): installed, booted, self-rebuilt; caught #63/#64/#65 (the
   blank-console #65 fixed live). Round I1's implementation is proven;
   the round stays open for its findings' recut (I2).

## Round I2 — the module DATABASE, then stage 1 (Max, 2026-09-10)

> Max's sequencing: before an offline self-installer, the module
> library must be TOTAL — a chooser that refuses a stranger's nvidia
> box can't drive a hands-off install. So: complete the database, wire
> every condition, THEN the offline ISO. Then stage 1.

8a. ✅ **Port the portable fat modules to leaves** (2026-09-10) — from
   the fixtures we already have: gpu-nvidia → gpu/nvidia-{turing,
   preturing,nouveau-floor} + gpu2/nvidia-offload-{turing,preturing};
   gpu-second → gpu2/failing (the #33 hold/off); broadcom-wifi →
   quirks/broadcom-wl; fingerprint → quirks/fingerprint; gpu2/amd-offload.
   **The chooser is now TOTAL for every fixtured machine** (acer, qemu,
   lenovo, asus — no refusals). Each source-tested: chooser-matrix pins
   the lists, minimal-matrix builds the lenovo's full nvidia-offload
   config + the asus iron-law config on source.
8b. ✅ **The census/fixture SWEEP** (2026-09-11) — thinkpad (amd),
   comodore (intel-legacy/BIOS), macbook (broadcom-wl/Apple EFI), hp
   (failing amd gpu2) all fixtured, chosen, and BUILT on source; dell
   confirmed redundant with comodore (identical leaf list — no new leaf,
   not swept). Pure census, every guarded disk 0 writes. Each build
   proved its class in the closure: lenovo's nvidia driver, asus's
   iron-law absence, macbook's broadcom-sta wl, hp's golem-dgpu-hold.
8c. ◐ **Remaining leaves** — non-qemu virt guests (vmware/vbox/hyperv,
   still refused — land when a machine needs them; no lab machine does).
   No new fact surfaced in the sweep.
8d. ✅ **Database-complete gate PASSED** (2026-09-11) — 8 fixtures
   (acer, qemu, lenovo, asus, thinkpad, comodore, macbook, hp) pinned in
   chooser-matrix + minimal-matrix; every one BUILDS on source; the
   chooser refuses NOTHING a real lab machine presents. Green light for
   the offline installer.
8e. ☐ **The offline self-installer** (Max's end goal) — bake the minimal
   closure into the ISO + wire ENTER-runs-it-locally, so a stranger
   flashes, answers, presses play, and it installs — no dev box.
   Round I1's #63/#64/#65 fixes ride this recut.
   - **Inherit #85's lesson:** when it decides "what still needs
     installing?", ask the store DATABASE (`path-info --all`), never
     `[ -e ]` on the path. A resumed install can meet a half-written path
     from a previous death, and a filesystem test calls that present.
   - **#67's rationale is now weaker, and that is good news:** the
     comodore proved a throttled per-path delivery moves 2.96 GiB over a
     USB dongle with zero drops. The offline installer is still the right
     end state (no delivery at all), but it is no longer the only way to
     reach these machines — so it does not have to be rushed to unblock
     the small-RAM boxes.

## Round I3 — stage 1 climbs (desktop)

9. ☐ desktop/ leaves (hyprland, waveview, waverunner, greeter) —
   config lifted from the current system, added to the VM's stage-0 by
   REBUILD; then the blessed machines, one at a time.
10. ☐ The GPU-class dogfood ladder: HD 5500 → Arrandale → HD 3000 →
    GMA 4500 as machines enter — each desktop hour recorded, DockMenu
    harness at every first boot.
11. ☐ The #33/#35c live proof on the hp (the real failing-dGPU answer
    through verify_effect).

## Round I3+ — stage 2 and the long tail

12. ☐ programs/ leaves + GolemModules bundles through the dock.
13. ☐ The MacBook (boss fight): broadcom-wl.nix quirk leaf, Apple EFI.
14. ☐ Retirement of the fat path: last concern migrated, `golem.lean`
    deleted, finding #1 closed structurally. The ASUS re-installed
    minimal+stages as the final parity proof.

## DUAL BOOT — the installer learns to share a disk (Max, 2026-09-15)

Scope set by Max: **make dual-boot work from the installer.** Secure
Boot is explicitly NOT part of it (decision record in GolemInstall.md).
The surface was already decided 2026-09-05 — dual boot is an **Advanced
row at the foot of the disk list**, so the ordinary path stays one
keypress and nobody meets a question they cannot answer.

GRUB was already the right loader for this: `grub-bios.nix`'s header
picked it partly because it chainloads other OSes, and the engine
already lays GPT + a BIOS-boot partition on both firmware paths.

**v1 policy — DETECT, NEVER RESIZE.** Golem installs into existing
**free space** and refuses to shrink anyone else's filesystem. Shrinking
NTFS is where installers earn their reputation for eating data; Windows'
own Disk Management does it safely, so the instruction is "make room
there first, then come back". Resize is a v2 question, if ever.

- ☐ **a. Layout: kernels must not live on a Windows ESP.** Measured on
  the acer 2026-09-15: one kernel+initrd is **54 MiB**, and 8
  generations occupy **122 MiB**. A Windows ESP is typically **100 MiB**
  — it cannot hold even one generation. So on a shared disk: reuse the
  EXISTING ESP, mount it at `/boot/efi` for the EFI binaries only, and
  keep kernels in `/boot` on Golem's own filesystem. Worth taking as the
  layout EVERYWHERE rather than a dual-boot special case — BIOS already
  works that way (the comodore's `/boot` is on root), so one shape for
  both firmwares, fewer branches. Note the LUKS interaction: with
  encryption on, `/boot` must be its own unencrypted partition (or GRUB
  cryptodisk, which is slower and fiddlier).
- ☐ **b. Never create a second ESP.** Detect the existing one and adopt
  it; two ESPs on one disk is a mess firmware resolves unpredictably.
- ☐ **c. The destructive-verb guard grows a partition dimension.** #20
  proved disk identity before a destructive verb; the same rigour now
  applies one level down — the engine must know which partitions are
  NOT ours and refuse to touch them, by identity, before anything runs.
- ☐ **d. Find the neighbour: `boot.loader.grub.useOSProber = true`**
  (confirmed present in our nixpkgs). Adds the Windows entry by
  chainloading its bootmgfw.efi.
- ☐ **e. #95's menu rule gains a case.** os-prober titles read
  `Windows Boot Manager (on /dev/sda1)` (~380px) and would blow past
  the 226px box — rewrite to **`Windows`**, then re-measure. The menu
  becomes `Start Golem` / `Windows` / `Previous Versions`.
- ☐ **f. #94's default flips here.** Owning `\EFI\BOOT\BOOTX64.EFI`
  saved the acer from firmware that deletes NVRAM entries, but on a
  shared disk it is a liability — Windows Update rewrites that path.
  A named NVRAM entry is the dual-boot answer; `efiInstallAsRemovable`
  is already `mkDefault`, so the leaf just overrides it.
- ☐ **g. The paper cuts, in a `quirks/dual-boot.nix` leaf** pointed at
  by a new census fact (another OS present on the target disk):
  `time.hardwareClockInLocalTime = true` (Windows keeps local time),
  do NOT auto-mount the Windows partition (Fast Startup leaves NTFS
  dirty — read-only if at all), and the BitLocker warning belongs in
  the installer's own words before the disk step, not in a wiki.
- ☐ **h. Prove it in the VM first** — a second OS installed in a qemu
  disk, then Golem alongside it, both firmwares. Nothing is at risk and
  the VM already gates every ISO. Metal after that, on a machine Max
  blesses; the thinkpad is the only lab box with real Windows.

## Carried decisions (Max's, non-blocking until their step)

- **#35b** — seed git policy (plain-path vs git; kill the dead
  `git add`s either way). Interacts with selfrebuild.nix (step 1).
- **R5-4 target half** — USB wifi dongles stay reveal-only (current
  recommendation) or gain a quirk leaf.
- **Naming of tier leaves** — numbered (`zram-tier1`) per Max's
  pointer model, parameters in the header. Rename cosmetics welcome
  any time; the chooser is the only consumer.

## Standing verifications every step inherits

`nix flake update` before every cut · verify the BUILT artifact ·
VM before metal · chosen-list assertions green · first-boot audit +
DockMenu harness · the record or it didn't happen.
