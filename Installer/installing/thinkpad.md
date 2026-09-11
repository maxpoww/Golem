# ThinkPad — the module-database sweep (AMD)

Lenovo ThinkPad E15 Gen 2 · AMD Ryzen 7 4700U (8c/8t) · Renoir Vega
iGPU (single GPU) · UEFI · 238.5 GB NVMe (**Windows — guarded**) ·
7159 MB · RTL8822CE wifi. Preinstall history:
`~/GolemOne/Install/Preinstall/testing/thinkpad.md`.

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
