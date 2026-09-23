# VM — machine zero of the Installing era

Same rig as preinstall's machine zero (`~/Golem/Installer/preinstall/
run-vm.sh`; mechanics in the archived
`~/GolemOne/Install/Preinstall/testing/vm.md`, which also holds this
qcow2 family's prehistory — including the first BIOS install anywhere,
2026-09-10). 4 GB on purpose: the tight-RAM class.

**Role here:** gates every Installing ISO, and runs every FIRST before
metal — the stage-0 install (UEFI and BIOS), the self-rebuild proof,
every stage climb, every new module class. Record format matches the
machine files: one dated entry per session, Mode line
(gate | real-install | installed-boot | stage-climb), numbers, verdict.

## Prehistory carried forward

- Round-6 gate + the first BIOS install: archived vm.md (the GRUB
  by-id install, `is-system-running: running`, the seam's BIOS debut).
- Disposable disks in use: `golem-target-r6.qcow2` (UEFI, round-6
  gate), `golem-target-bios.qcow2` (the BIOS-install proof, hostname
  `vmbios`). New stages get fresh disks — a stage-0 proof starts from
  zero, a stage-climb proof continues an existing disk on purpose.

## 2026-09-23 — RECUT I2 CLOSE — fresh lock + #102–#116 folded — GATE: menu + autostart + install-to-disk + installed-boot ALL PASS; boot-bar-on-installs bug CAUGHT

**Mode:** gate + real-install + installed-boot (headless, `-vga std`, screendumped,
40 GB virtio target). ISO `98g35kfamj9khcvjcbiahwbd74m4llkm` (HEAD after
`nix flake update` — waverunner/waveview→Sep-16, home-manager→Sep-13, nixpkgs
unchanged). Markers verified on the recut's own `golem-setup`: #111 w=42 bar,
#115 in-place paint (no flicker), #113 white flying names, #110 centering
reverted (0 `compute_layout`); + #114 skip-login launcher, #97 pciutils, and the
baked (installed) side carries `plymouth-start` + `golem-plymouth-theme`.
- **PASS — menu:** Start/Install renders centred on black.
- **PASS — autostart:** Install boot lands straight on "Pulsa ENTER…", NO agetty
  banner (the #114 skip-login launcher).
- **PASS — install-to-disk:** drove language→…→confirm; ENTER ran `golem-install`
  to **100%** — the 42-cell orange bar (steady, no flicker) with white filenames
  flying ("Copying etc-systemd-coredump-con" at 94%), then `systemctl reboot`.
- **PASS — installed boot:** rebooted from vda → GRUB-EFI → **`<<< Welcome to
  Golem 26.05… >>>` / `Golem login:`**. The full loop works on the official recut.
- **BUG CAUGHT — the boot bar does NOT render on the installed system.** Black
  until login; mid-screen empty for the whole 5–24 s boot window. Root cause
  confirmed: the minimal installed **initrd has no GPU/DRM module** (ahci,
  ata_piix, hid_*… but no `bochs`/`i915`/`virtio_gpu`), so Plymouth has no display
  in the initrd and never paints — the DRM only loads in the main system, after
  getty. This is exactly Max's earlier "no bar on installed Golem, blank until
  login": the baked-plymouth fix (#116) was necessary but not sufficient. The
  installer MEDIUM showed the bar only because installation-cd ships a broad
  initrd module set. **Fix owed:** put the GPU DRM in the installed initrd →
  finding #117.

## 2026-09-22 — RECUT I2 — the #62–#101 queue frozen into a fresh ISO — GATE: menu + boot + census PASS; install-to-disk owed on metal

**Mode:** gate (ISO build + markers + UEFI boot + census). Install-to-disk NOT
run here — the dev sandbox's SSH key is not the golem-vm-loop key, so
`golem-install` could not be driven; the install FLOW is unchanged from the 8e
gate below, which proved it end to end.

The round-I2 close, first half: work the queue, build a fresh ISO carrying every
source fix earned since the last cut, and prove the ONE piece of new work the
recut itself owed — the medium's OWN grub (#89/#95/#92, "the ISO side owed at
the recut").

**Built:** `golem-installer.iso`, 3.0 GiB (fits an 8 GB stick), from a CLEAN
tree — `git write-tree` of the staged index -> `git archive` -> `nix build
.#iso --override-input golem path:<clean>` (the #96 rule: never
`path:$HOME/Golem`, which bakes the 70 GB working tree).

**Markers verified on the artifact:**
- `nixosConfigurations.golem-installer.pkgs.grub2_efi.patches` carries
  `grub-quiet.patch` + `grub-item-align.patch` ONCE each. The first build
  FAILED — "Reversed (or previously applied) patch detected!". The overlay had
  patched BOTH `grub2` and `grub2_efi`, but `grub2_efi = grub2.override
  { efiSupport = true; }` already inherits the fixpoint's patched `grub2`, so
  patching it again double-applied. Fix: the shared overlay patches ONLY
  `grub2`; `grub2_efi` inherits (which is why the installed EFI machines always
  built fine). Recorded so the next person does not re-earn it.
- The seed on the medium (`/etc/golem/src -> hosts/target/`) holds ONLY
  `default.nix` — no comodore drops (the #102 leak, git-rm'd + gitignored).

**UEFI GATE PASS (`-vga std`, headless, screendumped):**
- **The menu reads like Golem** — `Start` / `Install` centred (item_align now
  honoured by the patched medium grub), the selection bar hugging `Start`, a
  clean black background. Before this recut the medium's UEFI grub was stock
  NixOS (left-aligned, blue bar). #89/#95/#92's ISO side is now a fact on the
  medium, not just in source.
- **Start boots clean** — no kernel spam (quiet), `<<< Golem installer —
  minimal cut >>>`, autologin `nixos`, the census ran (tier1 for the 4 GB VM:
  zram zstd/prio-100, swappiness 180; virtio gpu, modesetting/fbdev; 6 GiB
  hibernation swap, resume by-label), SSH advertised key-only.

**Source proven before the cut:** matrices GREEN — facts-matrix 21 permutations
(incl the new `fixture-lenovo-slim-pro-9-16irp8` row, #98), chooser-matrix,
minimal-matrix 8 composed (built the grub overlay + pciutils, #97, into the
toplevels).

**OWED — the round does not close until:** install-to-disk on THIS ISO is gated
(partition -> offline copy -> the installed disk boots its own now-patched grub
menu -> login), then the stick is reflashed + metal-verified. What this recut
changes vs 8e is what it INSTALLS (patched grub on the installed system too,
pciutils in the closure) and the seed's cleanliness — not the install flow.

**INSTALL-TO-DISK, then driven anyway (2026-09-22, same session, `-vga std`):**
drove the full guided TUI (English) to "Install Golem?" — it STOPPED before
partitioning. Root cause found: the product autostart runs golem-install as the
unprivileged `nixos` user, so it dies before its logdir (**#103**). Re-ran the
same answers file with **`sudo`** → the install completed: format → fs → seed →
probe → **BAKED toplevel direct-copy, offline** (`…-nixos-system-Golem-26.05.
20260829.c5c4a43`) → bootloader → "installation finished!" → 6/6. Booted the
installed disk (removable EFI, #94) → clean quiet boot to `Golem login:` →
**login as `max` works**. So the recut installs correctly end-to-end when
golem-install has root; #103 is the only defect and needs its fix + a re-cut.

**#103 FIXED + RE-GATED (same session):** `iso.nix` loginShellInit now runs
`sudo golem-setup-install` (Max's call). Rebuilt the ISO, booted "Install" →
the autostart TUI came up as root, drove it (English) → ENTER on "Install
Golem?" → the install ran to completion and **rebooted at 6/6 with NO manual
sudo** (reboot is the done trigger; a failure shows "stopped" + a shell). Fresh
target disk grew to 5 GB. The TUI-driven full product install now works.

**Verdict:** the recut carries the round's markers, boots + presents correctly,
and installs to disk end-to-end via the PRODUCT AUTOSTART to a loginable system
(#101/#103). OPEN: reflash + metal.

## 2026-09-18 — 8e USABLE INSTALL — gen-1 loginable (password + SSH key) on the opt-A generic system — GATE PASS

**Mode:** real-install + installed-boot + login (Max: "take on the usable-install
piece next").

The opt-A generic baked system had no owner creds (boots, but nobody can log in).
Fix in `install.nix` (step 5b): after `nixos-install`, apply the answers
IMPERATIVELY into /mnt — `chpasswd -e` (via `nixos-enter`) for the owner's hashed
password + write the SSH key to `~owner/.ssh/authorized_keys`. Sticks because
`users.mutableUsers` is unset → NixOS default true → activation won't reassert
shadow/keys. The seed's machine.nix keeps the DECLARATIVE answers for the first
rebuild.

**PASS on the FLOOR (unbaked VBox+unknown-GPU, `-vga std`):** installed with
`--password-hash <sha512> --lab-ssh <key> --hostname golembox`, **synced +
unmounted before power-off (HOLE-E lesson)**, booted the disk alone →
- **SSH key login as `max@Golem`** (shell zsh) ✓
- **console password works**: `echo golemtest123 | sudo -S whoami` → `root`;
  wrong password rejected ✓
- machine.nix on the installed system carries `hostName="golembox"` +
  hashedPassword + owner/root keys → the first `rebuild-golem` makes them
  declarative + applies the measured hardware config + real hostname.

**Verdict: USABLE-INSTALL GATE PASS.** A never-fail floor install is now a
loginable machine on first boot, offline, no rebuild.

**CONVERGENCE TO IDEAL — ONLINE, PROVEN (offline is a non-goal):** on the
exact-match install, `nixos-rebuild switch --flake …#golem-minimal` (online)
built `nixos-system-golembox` → **gen-2** with the measured hardware-config
(fstab by-uuid, ESP fsck + swap units) + real hostname + declarative creds. The
flake eval works offline (inputs cached; version matches the bake), but the
rebuild must BUILD thin glue (trimmed initrd, os-release, toplevel) and a gen-1
disk has no toolchain → offline build dies. `includeBuildDependencies` (the only
built-in fix) is the sledgehammer — timed out realizing, blows the 8 GB stick —
tried + REVERTED. Decision: gen-1 usable offline, converge ONLINE (L2 rung). See
changes.md #101.

## 2026-09-18 — 8e DEEP DOUBLE-CHECK — 3 never-fail holes fixed + never-fail PROVEN end-to-end to multi-user; the 4th (grub-rescue) was a harness artifact

**Mode:** deep debug / double-check of the whole 8e install path (Max: "run deep
debug test, double check … then we move on").

**Fixed + verified:**
- **HOLE A (install.nix):** the floor fallback was gated behind a successful
  chooser (`-n "$leaves_json"`), so a chooser throw / bad facts → floor skipped
  → doomed offline source build. Split so the floor runs on ANY no-match/failure.
  Proven: VirtualBox facts → chooser throws → floor selected offline.
- **HOLE B (choose.nix):** the `virt` group threw on vmware/virtualbox/hyperv
  (the census emits these). Floored to `[ ]` with a skip note (like `gpu2`); GPU
  tripwire kept. Zero regression — manifest hash identical, all 8 fixtures still
  exact-match.
- **HOLE C (flake.nix):** the baked initrd carried only `ahci nvme sd_mod xhci`,
  **no virtio_blk** → a virtio-blk machine hung on `/dev/disk/by-label/golem` →
  systemd-initrd EMERGENCY (caught by actually watching the boot; the earlier
  opt-A gate only checked "GRUB starts"). Added a broad
  `boot.initrd.availableKernelModules` (virtio family + common controllers) to
  `bakedFakeDisk`. Verified: the rebuilt floor initrd now carries
  `virtio_blk/pci/scsi/mmio`.

**Live floor install PROVEN (fixed ISO, `-vga std`→gpu=auto, rigged
VirtualBox+unknown-GPU facts):** `golem-install` → "no exact baked match — using
the generic FLOOR (firmware=uefi, boots on anything)" → direct-copy → "Installation
finished. No error reported." (exit 0), fully offline. The installed profile IS
the floor-uefi toplevel; grub.cfg → floor kernel; kernel+initrd on ESP; parts
labeled ESP/swap/golem.

**Integrity all-green:** firmware override flips only the boot leaf per class; all
18 baked toplevels (both floors) in the matrix closure; autostart confined to the
Install boot; install evals the SAME choose.nix the manifest baked from; all 8
fixtures exact-match their class.

**HOLE E — RESOLVED, was a HARNESS ARTIFACT (not a Golem bug):** the first boot
of the direct-copied disk hit `grub rescue> normal.mod not found`. Chased it into
the rescue prompt — `root`/`prefix` were CORRECT, but GRUB could only read a
PARTIAL x86_64-efi dir (~15 of 250 modules); `fsck.fat -v` showed **corrupted LFN
entries** (fragments "outside a LFN sequence", boot-sector≠backup). Cause: the
harness `quit`s QEMU right after the install with no guest sync, dropping
unflushed FAT writes — the product flow REBOOTS after 6/6 (a clean sync). PROVEN
by re-installing then `sync; umount -R /mnt` before power-off: `fsck.fat` clean
(344 files, no errors) and the disk **booted to `Golem login:` on tty1 with sshd
answering (`Permission denied (publickey)`) = FULL MULTI-USER.**

**⇒ NEVER-FAIL PROVEN END-TO-END:** an UNBAKED machine (VirtualBox + unknown GPU)
→ chooser floors, no throw (HOLE B) → installer picks the floor (HOLE A) →
offline direct-copy of the floor toplevel → clean sync → GRUB boots →
HOLE-C-fixed initrd finds root via virtio_blk → **multi-user login + sshd.** The
8e install is never-fail to a booted system. (Login itself needs the per-machine
owner/password — the separate "usable install" follow-on; the generic floor has
user `max` but no password/key by design at gen-1.)

**HARNESS LESSON:** after a real install driven over SSH (not via the surface,
which reboots itself), always `sync; umount -R /mnt` before `quit` — a hard qemu
quit corrupts the freshly-written FAT ESP and fakes a grub-rescue.

## 2026-09-18 — 8e COBERTURA + AUTOARRANQUE — GATE PASS (Max: "Cobertura/autoarranque first")

**Mode:** gate (coverage manifest + autostart-on-Install) + never-fail SELECTION.

The two halves Max asked for next, both proven.

**COBERTURA (coverage) — the never-fail manifest.** `flake.nix` now bakes and
manifests **18** entries: each of the 8 hardware classes (acer, asus, comodore,
hp, lenovo, macbook, thinkpad, qemu) in BOTH firmwares (bios+uefi) = 16, plus a
generic **floor** in both firmwares (`floor-bios`, `floor-uefi`, `isFloor:true`).
`install.nix` picks the toplevel by: (1) exact leaf-list match → the ideal baked
class; (2) no match → the floor for this firmware; both **direct copies**, never
a source build. Verified against the built manifest: 18 entries, floor-uefi
leaves = `boot/grub-efi gpu/auto memory/zram-tier0 swap/hibernation disk/policy`,
floor-bios swaps grub-bios.

**NEVER-FAIL SELECTION — proven on a genuinely unbaked machine.** Fed the
chooser real weird facts (gpu=`auto` unknown GPU, but intel µcode + laptop +
fingerprint + tier2 — a 9-leaf combo no fixture and not the floor has). Ran the
EXACT jq logic install.nix uses: exact match = **empty** (correctly unbaked) →
floor-uefi selected → toplevel **exists offline**. The floor toplevel is a
complete bootable object: **1017-path closure, 0 missing**, kernel+init present.
So an unclassified machine installs on the generic floor by direct copy — it
never fails to install. (Live floor install→boot is the one gold-standard proof
still owed; selection + offline-closure completeness are proven.)

**AUTOARRANQUE (autostart) — the Install boot drops straight into the product
surface.** New `golem-setup-install` wrapper in `setup.nix` = the surface with
NEITHER `GOLEM_REHEARSE` nor `GOLEM_LAB` set (per the mode ladder: neither =
the full real install). The `install` specialisation in `iso.nix` autostarts it
on tty1 via `environment.loginShellInit`, guarded `[ "$(tty)" = /dev/tty1 ]`.
- **Caught a real bug in the VM gate:** the first cut used
  `environment.etc."profile.d/…"` — but **NixOS `/etc/profile` does NOT source
  `/etc/profile.d/*.sh`** (only `/etc/bashrc` sources the one bash-completion
  file), so the autostart silently no-op'd (tty1 sat at `-bash`). Fixed to
  `environment.loginShellInit` (appended straight into `/etc/profile`).
- **PASS (rebuilt 3.0 GiB ISO, headless UEFI, selected "Install"):** SSH in →
  `/proc/cmdline` carries `golem.install`; `/etc/profile` carries the guard;
  tty1 process tree = `login -f` → `-bash` → **`golem-setup-unwrapped --out
  /tmp/golem-answers --write /tmp/golem-machine.nix`** (live, foreground). Its
  `/proc/<pid>/environ` has `GOLEM_SURFACE_STARTED=1` + `GOLEM_KEYBOARDS` and
  **no REHEARSE / no LAB → product mode confirmed** — armed to run a real
  install on confirm. SSH logins land on a pty, so the `tty` guard keeps the
  dev box's automation in a plain shell (verified: `ssh … command` never trips
  it). Clean powerdown.

**Verdict: COBERTURA + AUTOARRANQUE GATE PASS.** The 18-entry coverage installs
every class+firmware by direct copy and falls to a complete offline floor for
anything unbaked; the Install boot autostarts the product surface with zero
typing. Owed: a live floor install→boot, and a TUI-driven full product install
(autostart → 6 answers → confirm → installed system boots).

## 2026-09-18 — 8e ALL-IN BAKED ISO — BOOT-GATE PASS (the real install-gate still owed)

**Mode:** gate (boot + bake-presence + census; NOT yet a real-install gate).

The first 8e cut — the ALL-IN baked ISO (`golem-installer.iso`, **2.91 GiB**):
every hardware class's minimal closure + btop baked in via `flake.nix`
`bakedMatrix` → `iso.nix` `system.extraDependencies`, so install is a LOCAL
COPY (Omarchy model, Max 2026-09-18 — no online, no 50 G ISO). Built
`nix build .#iso --override-input golem path:<clean git tree>`; the preinstall
flake was made self-contained first (`../../system/...` → `"${golem}/..."`, else
it breaks when built from a copy).

- **Booted** (UEFI/OVMF via run-vm.sh): GRUB → Enter → `golem-installer`,
  SSH-reachable on :2222.
- **Bake present:** 8 class systems (`nixos-system-Golem-<hash>`) in the medium
  store, complete offline closures (0 paths missing).
- **Census runs:** golem-hw-detect read the VM → `gpu=virtio cpuVendor=intel
  firmware=bios ramMB=3917`.
- **Floor (never-fail):** chooser on nothing-detected facts → grub-efi +
  `gpu/auto` + tier0 + swap + disk, no throw (proven on the dev box; a CI row).
- btop / golem-setup / golem-install all present. Clean powerdown.

**Verdict: BOOT-GATE PASS.** The 2.91 GiB all-in ISO builds, fits an 8 GB stick
(~4.5 GiB spare), boots, and carries every class offline.

**INSTALL-GATE ATTEMPTED 2026-09-18 — FAILED, and CAUGHT A REAL GAP (the gate
working):** with golem-install changed to build golem-minimal offline from the
seed (`golem-target`→`golem-minimal`), a VM install to a blank 40 G disk
**died** — it fell into building `cmake`/`glib`/`elfutils`/`bash`/initrd FROM
SOURCE, which `--offline` can't do. **Root cause:** the toplevel it built was
`nixos-system-vmtest-26.05.19700101.dirty` but the baked matrix is
`…20260829.c5c4a43` — DIFFERENT evaluations → different store paths → `--offline`
can't reuse a single baked path. **The "rebuild golem-minimal from the seed at
install" design CANNOT reuse the bake** (a dirty path: seed never matches the
flake-built bake). Fix is an architecture call (changes.md #99): **(A) install
the BAKED toplevel directly** (`nixos-install --system <baked class>`, pure
local copy, no rebuild — can't mismatch; per-machine bits via first-boot
rebuild) — recommended; or (B) make the seed-rebuild byte-reproduce the bake
(fragile). **Awaiting Max's A/B call.** The definitive gate (offline install →
boot the result; + a weird-facts floor boot) is still owed pending the fix.

**OPT A PROVEN (2026-09-18, Max chose A):** golem-install now matches the
machine's chosen leaf-list to a baked toplevel (`/etc/golem/baked-manifest.json`)
and `nixos-install --system <baked>` — DIRECT COPY, no rebuild. In the UEFI VM:
live leaves == the baked `qemu` entry → **"copying path … to local" →
"installing the GRUB 2 boot loader (x86_64-efi)" → "Installation finished. No
error reported." (exit 0)** — fully OFFLINE, no build, so the eval-mismatch
cannot recur. Booting the target disk alone (UEFI, no ISO): OVMF **found +
started the removable grub-efi** (`BdsDxe: starting … Pci(0x4,0x0)`) — bootable.
(One-word unblock: the leaves eval needed `--impure`.) **Still owed:** OS
reaching multi-user isn't serial-captured (baked-generic has no console/sshd); a
USABLE install needs the per-machine machine.nix (owner/hostname/sshd), i.e. the
FIRST-BOOT rebuild must reuse the baked deps (the deeper reproducibility the
direct copy sidestepped for gen-1); plus coverage (firmware×class + a floor
entry) and the `golem.install` autostart. See changes.md #99.

## Round I2 GATE — 2026-09-11 — the dell-shaped ISO: BIOS + --lab-wifi + the #65 fix, all live on a fresh install

The round-I2 ISO (`m8vkd2jg…-golem-installer.iso`, `result-roundI2`) —
cut for the DELL, whose keyboard is broken (only e/g/i/Enter/Backspace),
so the installed machine must come up reachable with NO keyboard.
`nix flake update` first (the rule); built artifact verified:
`--lab-wifi` in golem-install (3 hits), the seed's base/core.nix carries
NO fbcon/splash kernelParam (#65), the full 17-leaf database aboard.

- **Mode:** real-install + installed-boot, BIOS (matching the dell),
  fresh `golem-i2-bios.qcow2`, hostname `vmi2b`.
- **`--lab-wifi HOLA` (#64's fix) works end to end:** the prepare baked
  the profile into machine.nix
  (`golem-lab`, autoconnect, `autoconnect-retries = 0`), golem-minimal
  evaluated with it (`ssid: HOLA`), and the INSTALLED system carries it
  — `nmcli con show` lists **golem-lab**. That is the property the dell
  needs: after reboot it joins on its own and I reach it over SSH.
- **#65 fixed at the ISO level, not just live-patched:** the installed
  GRUB entry has no `fbcon=map:1`/`splash`, and the booted kernel's
  cmdline is clean. A fresh install from this stick shows a real login.
- **First boot:** `running`, zero failed units, zsh, tier1 swappiness
  180, rebuild-golem present, GRUB/BIOS.
- **Verdict:** **GATE PASSED — `m8vkd2jg…` is the dell's stick.**
  Everything the keyboard-less install needs is proven in the rig: BIOS
  path, baked lab wifi, visible console, healthy first boot.

## Round I1 — stage 0, UEFI — 2026-09-10 — golem-minimal installed, booted, and SELF-REBUILT; caught + fixed #62

First modular install anywhere. **Mode: real-install + installed-boot +
stage-climb (self-rebuild).** Fresh `golem-minimal-uefi.qcow2`, round-6
stick, hostname `vmmin`.

- **The seam, minimal variant:** answers → `--prepare-only` → pull facts
  → **run the chooser** → build `golem-minimal` toplevel (**2.92 GiB**,
  vs the fat 18.9) → `nix copy` → `--skip-prepare --system` (systemd-boot
  written, header `hostname vmmin (from seed)`) → boot from disk.
- **Chooser output (vmmin):** systemd-boot · intel-microcode · virtio ·
  zram-tier1 · hibernation · disk-policy · qemu-guest — 7 leaves, each
  with its why in modules.nix.
- **First boot:** `is-system-running: running`, zero failed units, root
  /dev/vda3, sshd+NetworkManager active, max's shell = zsh (Golem's),
  **zram-tier1 exact** (zram 5.7G prio 100, swap 6G, swappiness 180,
  cache-pressure 50), resume wired, seed present. Correctly NO
  hyprland/waverunner — this is minimal.
- **#62 — the self-rebuild proof did its job:** the first attempt found
  the installed seed couldn't reproduce itself (no modules.nix dropped;
  golem-minimal never wired flakeDir/flakeAttr). Both fixed in source
  (changes.md #62); after the fix the machine **rebuilt itself
  `#golem-minimal` from its own seed → generation 2, still running.**
  Stage 0's defining requirement — climbs happen by rebuild — proven.
- **Owed on the round-I1 recut:** the engine's LIVE modules.nix drop
  (this stick predates the Modular work; the drop was verified by
  running its exact chooser line, and the seed was hand-synced for the
  rebuild proof — a harness artifact, not a Golem bug), and the
  **BIOS stage-0 install** (this entry is UEFI; BIOS boot-path is
  already proven for the fat target).
- **Verdict:** stage 0 is REAL on UEFI — choose → install → boot →
  self-rebuild, all green, 2.92 GiB. The modular composition reproduces
  the system it runs.

## Round I1 GATE — the recut ISO — 2026-09-10 — stage-0 minimal PASSED on BOTH firmwares, engine drops modules.nix by itself, self-rebuild clean

The round-I1 ISO (`jd9lgha3…-golem-installer.iso`, `result-roundI1`),
cut with the #62 engine fix aboard. `nix flake update` first (the rule);
verified in the built artifact: `golem-install` greps positive for
`Modular/choose.nix`, the embedded seed carries the full `system/Modular`
tree + the `golem-minimal` attr + waverunner `0696b72`.

**THE NEW CAPABILITY, proven live on both firmwares:** a real
`--prepare-only` **drops `hosts/target/modules.nix` into the seed by
itself** — no hand-sync this time (#62's live proof). The seed is
self-sufficient by construction.

- **UEFI (`golem-i1-uefi.qcow2`, vmi1u):** chooser dropped systemd-boot ·
  intel-microcode · virtio · zram-tier1 · hibernation · disk-policy ·
  qemu-guest. Installed 2.92 GiB, first boot `running` / 0 failed /
  root vda3 / zsh / swappiness 180 / sshd+NM active. **Self-rebuild
  `#golem-minimal` from the untouched seed → generation 2, running.**
- **BIOS (`golem-i1-bios.qcow2`, vmi1b):** chooser correctly swapped in
  **grub-bios** (not systemd-boot) — the leaf split works. SeaBIOS →
  GRUB (installed to the by-id alias) → Golem, first boot `running` /
  0 failed / root vda3 / zsh / swappiness 180. **Self-rebuild → gen 2,
  running.**
- **Verdict:** **round-I1 ISO GATE PASSED, both firmwares.** Stage-0
  modular install is real end to end — choose → drop modules.nix →
  install → boot → self-rebuild — with the seed carrying everything by
  construction. `jd9lgha3…` is the reflash candidate for the acer (the
  first blessed metal, stage 0).
