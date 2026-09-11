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
