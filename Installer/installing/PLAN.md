# Installing — the wired-install phase

> The successor program to preinstall (GRADUATED 2026-09-10 — records
> and maintainer docs at `~/GolemOne/Install/Preinstall/`, the
> implementation still at `../preinstall/`). Preinstall proved Golem can
> read a machine, ask the right questions, and assemble a system.
> Installing proves the system it assembles — MODULAR, minimal-first,
> installed for real on every lab machine, one round at a time.
>
> The spec (WHAT/WHY) is [spec.md](spec.md). The rules are
> [constitution.md](constitution.md). The build order is
> [implementation.md](implementation.md). The finding ledger is
> [changes.md](changes.md). One file per machine, plus vm.md.

## The mission (Max, 2026-09-10)

Golem is **completely modular**. One module per concrete configuration
— one for systemd-boot, one for GRUB, one for nvidia, one for amd, one
for intel, one for each dual-GPU arrangement, one for battery/energy,
one PER ZRAM TIER, per swap shape, per locale mechanism. Modules carry
no logic; **the preinstaller measures the machine and POINTS** — the
installed system is an explicit list of chosen leaves
(`hosts/target/modules.nix`), readable as what the machine is.

## The ladder

- **Stage 0 — minimal:** boots, is reachable, can rebuild itself, and
  feels like Golem at the tty. Bootloader + kernel/firmware + chosen
  hardware leaves + memory tier + NetworkManager + SSH + the seed &
  self-rebuild machinery + Golem's zsh + user/locale from the answers.
  Nothing else. (~2–3 GiB closure; minutes per install.)
- **Stage 1 — desktop:** hyprland + waveview + waverunner leaves,
  added to a WORKING stage-0 machine by rebuild, never by reinstall.
- **Stage 2 — programs:** the CURATE set and the GolemModules bundles,
  same mechanism, chosen by the owner not the installer.

A machine climbs one rung per entry; a failure bisects itself because
every rung lands on a proven previous rung.

## The method (same lab, disks now real)

Rounds, exactly like preinstall: **one frozen ISO per round**, the VM
gates every ISO first, machines meet the same image, every experience
recorded in the machine's file, every implied change queued in
[changes.md](changes.md), and when the round closes the queue is worked
and the ISO is "changed" — recut, re-gated, reflashed. Findings
continue the global number line (#62 onward); round-scoped items are
`I<round>-<n>`.

## The scoreboard

*(state as of 2026-09-18, roster complete + the AMD path banked on metal — every GPU class now proven on installed hardware)*

| # | Machine | In the module DB | Stage 0 on metal | Stage 1 | Notes |
|---|---------|------------------|------------------|---------|-------|
| 0 | VM (UEFI + BIOS) | ✅ qemu-virtio | ✅ **both firmwares**, self-rebuild proven | ☐ | gates every ISO |
| 1 | **acer** (UEFI, HD 5500) | ✅ | ✅ **PASS 09-10 (I1) + 09-11 (I2, from the shipping ISO)**; **09-15: GRUB-EFI (#92) live**, caught #94 | ☐ | runs on the dell's old drive |
| 2 | **asus** (UEFI, Haswell + failing GF117M) | ✅ | ✅ **PASS 09-11** — on an external USB drive; `gpu2/failing` live. **09-15: #92 swap DEFERRED** — the external drive no longer enumerates (no block dev, no USB bus entry, no errors) | ☐ | internal disk still holds the fat dogfood Golem — **it answers as `asus` too; check modules.nix + Hyprland before ANY write** |
| 3 | comodore (BIOS, 1.9 GB, GMA 4500) | ✅ | ✅ **PASS 09-14** — audited clean, rejoined over a USB dongle, **self-rebuilt → gen 2 in <3 min on 1931 MB**; **09-15: gen 6**, quiet boot (#89) + lid quirk (#90) + graphics handoff (#93) all live-verified — "the message is gone, clean boot" | ☐ | **#67 answered here** (throttle); caught #85/#87/#88, then #89/#90/#91/#93 |
| 4 | dell (BIOS, USB wifi, **no keyboard**) | ✅ (redundant with comodore) | ✗ blocked — USB-enumeration boot quirk; firmware mode unknown (F2/F12 unreachable). **#67 no longer blocks it** — retry under the throttle | ☐ | needs a USB keyboard, or stays parked |
| 5 | **hp** (BIOS, Arrandale, failing radeon) | ✅ | ✅ **PASS 09-18** — clean-image stage-0 from the frozen ISO seed (stock engine, above the #66 floor); `running`, 0 failed, rejoined golem-lab by itself (#64); self-rebuild proven; **#87 confirmed on Arrandale** | ☐ | blessed + wiped 09-18 (disk held only the unrecorded 09-12 ghost Golem, no user data) |
| 6 | **macbook** (Apple EFI, Broadcom wl, **FaceTime HD cam**) | ✅ | ✅ **PASS 09-18 — BOSS FIGHT WON**: GRUB-EFI booted Apple EFI (#94); internal BCM4360 up on `wl`, rejoined by itself (#5 live proof); **webcam captures 720p on installed metal** (facetimehd fw+calibration); running, 0 failed | ☐ | blessed + wiped (macOS erased); live-fix run (facetimehd = #96, rides the recut) |
| — | **thinkpad** (UEFI, **AMD** Ryzen/Renoir, Windows) | ✅ | ✅ **PASS 09-18 — AMD path on metal**: installed to an **external 2 TB HDD** (Windows NVMe untouched); amd-ucode + radeonsi (no LIBVA) + no-thermald + **tier2**; grub-efi off the external ESP (no NVRAM); running, 0 failed | ☐ | Windows preserved for the dual-boot test; live-fix run (grub-efi) rides the recut |
| — | **lenovo** (dev box, **nvidia** RTX 4050) | ✅ | ✅ **PASS 09-18: nvidia + tier3 on metal** — nvidia stage-0 on an external 2 TB (internal NVMe/Windows untouched); **RTX 4050 bound to the `nvidia` driver** (595.71.05, nvidia-smi + /dev/nvidia*, offload topology correct), running/0-failed, tier3, self-rebuild. Audited by the Fedora agent; source leg (chooser/minimal/kbd/tz matrices) also green | ☐ | internal never wiped (dev machine); [lenovo.md](lenovo.md); findings #97/#98 |

**Module database: COMPLETE** — 8 fixtures, every hardware class the lab
holds, each one chosen correctly AND built on source (intel/iHD,
intel-legacy/i965, amd, virtio, nvidia turing primary + offload, the iron
law, failing gpu2, broadcom-wl, both bootloaders, 4 memory tiers).

A "Blessed?" box ticks only on Max's explicit per-machine wipe call —
the constitution's first rule.

## Where the pieces live

- The engine and medium: `../preinstall/` (implementation, unchanged
  home). The module tree: `../../system/modules/` (built by this
  program). The chooser: grows out of the census/decide machinery, its
  output is `hosts/target/modules.nix`.
- Prehistory of this directory: [FirstInstall.md](FirstInstall.md) (the
  ASUS dogfood — the war that taught us the desktop is where bugs
  live), [DockMenu.md](DockMenu.md), [issues.md](../../work/todo/issues.md).

## Working agreements

Unchanged: Max is the idea guy — scope, blessings, graduations, the
round-close call. The technician builds what's agreed, records numbers,
and never lets a pass go unrecorded.
