# MacBook — the module-database sweep (the boss fight)

MacBook Air 2013 · i5-4250U Haswell · HD 5000 · **Broadcom BCM4360**
wifi + BCM2046 BT · **BCM 720p FaceTime HD camera (14e4:1570)** · Apple EFI ·
~3858 MB · Apple SSD (held **macOS/APFS** until 2026-09-18 — the old
"NixOS — guarded" note was wrong; installed Golem, PASS). The lab's boss fight
(Broadcom + Apple EFI + the FaceTime HD webcam). Preinstall history:
`~/Golem/docs/installing/preinstall/testing/macbook.md`.

## 2026-09-18 — THE BOSS FIGHT, WON — stage-0 metal, INSTALLED, PASS, with the webcam working

**Status in one line:** `macbook` on `/dev/sda3`, `is-system-running: running`,
**0 failed units**, GRUB-EFI booted the Apple firmware, the internal BCM4360
came up on `wl` and rejoined `golem-lab` by itself, and **the FaceTime HD
webcam captures 1280x720 frames on the installed system.** Every driver Max
named — webcam, wifi, BT, audio — accounted for.

Blessed by Max ("wipe it", informed it was **macOS/APFS**, not the "NixOS"
this file's old header claimed — corrected below). The 234 G Apple SSD held
a real macOS install (APFS "Mac"); erased whole.

### The webcam — made functional the Golem way (Max: "IMPORTANT!! …webcam")
The 2013 Air's camera is the Broadcom 720p **FaceTime HD (PCI 14e4:1570)**,
which needs the out-of-tree `facetimehd` (bcwc_pcie) module + an ISP firmware
blob nixpkgs extracts from a 2 MB byte-range of Apple's OSXUpd10.11.5.dmg.
- **Proven LIVE on the medium BEFORE any wipe:** module loads on 6.18.48,
  ISP firmware loads ("Loaded firmware, size: 1392kb"), `/dev/video0` appears,
  captured a 1,843,200-byte (1280x720 YUYV) frame. The only gap live was the
  per-sensor `1871_01XX.dat` calibration — harmless (capture worked without it).
- **Made modular** (spec growth rule + rule 4): new census fact
  `hasFacetimeHD` (probe detects 14e4:1570), new leaf `quirks/facetimehd.nix`
  (`hardware.facetimehd.enable` + `allowUnfreePredicate` scoped to the blob),
  chooser rule, matrix assertion + fixture updated. The option had to be
  declared in **both** option sets — Modular `base/options.nix` AND the fat
  `system/hardware.nix` (the postinstall-questions eval routes through the fat
  `lib.golem`). See changes.md #96.
- **On the installed system:** `hardware.facetimehd.enable` also pulls
  `facetimehd-calibration` → the `1871` error is GONE, full factory
  calibration. `/dev/video0` auto-appears at boot and **captured a frame on
  the installed macbook (1,843,200 bytes).**

### Method — live-fix run (patched engine, dev-tree seed)
facetimehd is a dev-tree source addition, so this is a live-fix run (not
clean-image like hp/acer). The patched engine (golem-install + hw-detect +
postinstall-questions, built `--override-input golem path:<clean-tree>`, then
`nix copy`'d to the medium) drops the dev-tree seed with the facetimehd +
grub-efi leaves the frozen ISO lacks. `--prepare-only` (wiped `sda`: ESP 512M
+ swap 6G `d7e03536` + ext4 golem) → build golem-minimal from the seed
(3.00 GiB, 1040 paths) → deliver to `/mnt` → `--skip-prepare` wrote GRUB-EFI
(x86_64-efi). **The facetimehd work must ride the recut (8e) to reach the image.**

### First-boot audit (tools/firstboot-audit.sh)
| | |
|---|---|
| hostname / root | `macbook` on `/dev/sda3` |
| generation | `d04fg…-nixos-system-macbook` — byte-identical to the built toplevel |
| health | `running`, **0 failed units**, boot **24.1 s** (fastest in the lab) |
| tier1 exact | zram0 5.7 G prio 100 · swappiness 180 · cache-pressure 50 · dirty 5 · pc 0 · max-jobs 1 |
| resume / #65 | by-uuid `d7e03536` wired · fbcon/splash = 0 |
| **wifi (#5 live proof)** | **`golem-lab:wlp3s0:activated`, wlp3s0 = `wl`** — the internal BCM4360 up on the unfree driver, rejoined by itself |
| **webcam** | `facetimehd` loaded (fw + calibration), `/dev/video0`, **frame captured 1,843,200 B** |
| BT | `hci0` up, unblocked (bluez daemon dormant — correct on headless minimal) |
| audio | HDA-Intel PCH + HDMI cards present |
| intel-legacy | `LIBVA_DRIVER_NAME="i965"` (Haswell HD 5000) |
| thermald | **active** (Haswell is post-RAPL — genuinely runs, unlike #87's pre-RAPL boxes) |
| GRUB | **theme present** — the #92/#95 Golem menu, on grub-efi, on Apple EFI |
| self-rebuild (§5) | `rebuild-golem` → evaluate/build/activate clean from the seed (facetimehd + wl predicates resolve), `activated == latest`, /dev/video0 still live |
| minimal / owner | no desktop; `max` uid 1000 zsh |

### Verdict
**PASS — the boss fight is won.** Apple EFI booted GRUB-EFI (#94 removable
fallback), the Broadcom wifi live proof (#5) is finally banked, and the
FaceTime HD webcam is functional on installed metal. **This was the last
roster machine — the round can now close → implementation step 8e (the
offline self-installer) is released.**

## Round I2 sweep — 2026-09-11 — fixtured; the BROADCOM wl leaf BUILT on source · NO install (census only)

- **Reachable at 192.168.1.109 via the Realtek USB dongle** (the
  internal BCM4360 is dark on the medium — no wl — so the dongle is the
  only path; Max reconnected it). Apple EFI booted the round-I1 stick.
- **Census (fixtured → `fixtures/macbook-air-2013/`):** i5-4250U 2c/4t,
  3858 MB, gpu=intel, **intelLegacy=true** (Haswell HD 5000 → i965),
  firmware=uefi (Apple EFI), **broadcomWifi=true**, panelDpi=126,
  hasBluetooth=true, cpuVendor=intel, laptop. Internal SSD (ESP + ext4
  "root" + swap) untouched, 0 writes.
- **Chosen leaves — the FIRST broadcom machine, unlocks the boss-fight
  leaf:** systemd-boot · intel-microcode · gpu/intel-legacy ·
  zram-tier1 · hibernation · disk/policy · power/laptop · power/thermald
  · **quirks/broadcom-wl**.
- **BUILT on source (2.94 GiB):** the composed toplevel compiles WITH
  the unfree module — **broadcom-sta 6.30.223.271 (`wl`) is in the
  built closure**, `wl` in boot.kernelModules, LIBVA=i965 for the
  Haswell iGPU. The allowInsecurePredicate scoping (broadcom-sta is
  flagged insecure) evaluates cleanly. chooser-matrix + minimal-matrix
  lock the list and the effects (wl module requested, broadcom_sta in
  extraModulePackages, i965, systemd-boot, thermald, tier1).
- **Verdict:** the boss fight's LEAF is proven to compile on source —
  the BCM4360 driver a MacBook needs is chosen from the census fact and
  builds. What's NOT yet proven (needs a real install, a future
  blessing): wl actually bringing the internal card UP on the installed
  MacBook — the #5 "live proof" still owed, now one blessing away.
