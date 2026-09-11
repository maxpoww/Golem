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

| # | Machine | Blessed? | Stage 0 installed · first boot OK | Stage 1 desktop | Stage 2 programs | Dogfood |
|---|---------|----------|-----------------------------------|-----------------|------------------|---------|
| 0 | VM (UEFI + BIOS, disposable qcow2) | always | ☐ | ☐ | ☐ | — |
| 1 | acer (UEFI, HD 5500) | ☐ | ☐ | ☐ | ☐ | ☐ |
| 2 | hp (BIOS, failing radeon — the real #33 answer) | ☐ | ☐ | ☐ | ☐ | ☐ |
| 3 | dell (BIOS, USB wifi, dead keyboard) | ☐ | ☐ | ☐ | ☐ | ☐ |
| 4 | comodore (BIOS, 1.9 GB — always the seam, GMA 4500) | ☐ | ☐ | ☐ | ☐ | ☐ |
| 5 | macbook (Apple EFI, Broadcom wl — the boss fight) | ☐ | ☐ | ☐ | ☐ | ☐ |
| — | asus | installed 2026-09-09 | **✅ (fat, pre-modular)** — the reference machine | ✅ | ✅ | ongoing |
| — | lenovo / thinkpad | guarded | never — rehearsal metal only | — | — | — |

A "Blessed?" box ticks only on Max's explicit per-machine wipe call —
the constitution's first rule.

## Where the pieces live

- The engine and medium: `../preinstall/` (implementation, unchanged
  home). The module tree: `../../system/modules/` (built by this
  program). The chooser: grows out of the census/decide machinery, its
  output is `hosts/target/modules.nix`.
- Prehistory of this directory: [FirstInstall.md](FirstInstall.md) (the
  ASUS dogfood — the war that taught us the desktop is where bugs
  live), [DockMenu.md](DockMenu.md), [issues.md](issues.md).

## Working agreements

Unchanged: Max is the idea guy — scope, blessings, graduations, the
round-close call. The technician builds what's agreed, records numbers,
and never lets a pass go unrecorded.
