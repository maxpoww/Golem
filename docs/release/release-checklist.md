# Alpha gate — Golem 26 "Uprise"

> What has to be true before a download link exists, and what a first tester
> will hit: **versioning · known issues · feedback channel · the gate**.
> It is not the release, and it puts nothing on the site (a separate repo).
>
> Written 2026-09-01. **Re-cut 2026-11-16** against the code of that day:
> the September list of blockers (no ISO, no installer, no host for a
> stranger's machine, no Wi-Fi page) is all built, and is gone from §2.
> Every claim cites a file in this repo; `launcher:` is the shell's repo.

---

## 1. Versioning

### 1.1 What the name means

**Golem 26 "Uprise"** (`docs/vision/Golem.md`).

- **26** — the train: the flake pins nixpkgs `26.05`. Golem 27 is the one
  built on 27.05.
- **Uprise** — the codename of this train, chosen once.

`system.stateVersion` is **not** a Golem version and is never bumped to
express one: it is a nixpkgs compatibility pin.

### 1.2 What the machine says today

| Surface | Today | From |
|---|---|---|
| `/etc/os-release` `NAME` | Golem | `system/Modular/base/core.nix:11` |
| `/etc/os-release` `ID`, version, codename | nixos, the nixpkgs ones | nothing overrides them |
| Boot menu | "Start Golem", then "Previous Versions" → "Gen N - date" | `system/Modular/boot/grub-patched.nix:58-63` |
| Which build a machine runs | its source revision (`nixos-version --configuration-revision`) | `system.configurationRevision` in `flake.nix` |
| ISO file / volume | `golem` / `GOLEM_ISO`; the installer `golem-installer` / `GOLEM_INST` | `hosts/iso.nix:105-106`, `Installer/preinstall/iso.nix:166-167` |

The boot loader is GRUB on every installed machine, BIOS or UEFI
(`system/Modular/choose.nix:46-48`); systemd-boot is retired.

- [x] The machine calls itself Golem (os-release, boot menu).
- [x] Any booted Golem can name the revision it was built from.
- [ ] **One version string**, the same in os-release, the boot menu, the ISO
      name and the download link. There is none: no version attribute
      anywhere in the flake (plan F14.1).
- [ ] **Decide: does `ID=` become `golem`?** Third-party scripts read it to
      detect NixOS. Recommended for the alpha: leave `nixos`.
- [ ] **Tag the revision each published ISO is built from** (plan F14.2).
      The only tag in the repo is `pre-loop-20260901-1114`.

### 1.3 Alpha marker

- [ ] **Decide: "Golem 26 Uprise" or "Golem 26 Uprise alpha"?** Recommended:
      the word alpha inside the version string, so it survives being shared.

---

## 2. Known issues

What a first tester needs to be told, grouped by what it costs them.

### 2.1 To say on the download page

- **The name typed in the installer is not the account's name** on `main`:
  the installer asks and records it (`Installer/preinstall/install.nix`,
  `golem.owner`), but the first system is the baked one, whose owner is
  `max` (`system/Modular/base/options.nix:25-27`). Fixed on the branch
  `release-candidate` (`d09f20c`, the account is renamed at the first
  restart), not merged.
- **The installer has no Wi-Fi step.** The install itself needs no network
  (the first system is copied from the medium). Wi-Fi is joined afterwards
  from the gear in the top bar (`launcher:crates/daemon/src/net.rs`).
- **The first start is in English**; the chosen language arrives with the
  first update, which needs a network (`flake.nix`, the baked gen-1).
- **The timezone is the one picked in the installer**; it is not found
  automatically. It can be changed in Controls.
- **An nvidia card of an unknown generation gets the open nouveau driver.**
  Turing and newer get nvidia's open module, older ones the legacy driver
  (`system/Modular/choose.nix:74-79`).
- **On a UEFI machine three versions are kept in the boot menu**
  (`system/Modular/boot/grub-efi.nix:53`: fifteen filled the 512 MiB boot
  partition in a month); on BIOS, fifteen. The store keeps fifteen, or three
  when the disk is short (`system/Modular/base/store-gc.nix:17-34`).
- **In the live session, dragging an app into Install does nothing**
  (`hosts/iso.nix:72-77`). It works on an installed machine.
- **No on-screen keyboard.** The screen reader (Orca) is a switch in
  Controls → Accessibility, not on by default. Text size, pointer size,
  magnifier and less motion are there
  (`launcher:crates/daemon/src/access_page.rs`).
- **Seven languages** besides English in the shell and the system's own
  messages: es, es_ES, pt, pt_PT, fr, de, it. The installer offers more
  languages than the desktop is translated into.

### 2.2 Fixed in code, never verified by eye

Still open in `work/todo/todoSH.md` (lines 69, 122, 333, 340, all `[?]`):

- overview motion leaking to the workspace underneath;
- the overview opening with no pointer (intermittent: it closes on a week
  without it, not on one look);
- the float leak ("no more leaks for now").

All three are answered by the same week of daily use, not by separate work.

### 2.3 Open design calls

- **The UI font** is still DejaVu Sans, a deliberate stand-in
  (`system/Modular/desktop/fonts.nix:17`).

### 2.4 The compositor

Golem carries its own Hyprland patches: 21 in
`system/Modular/desktop/hyprland-patches/`, applied by
`hyprland-overlay.nix`. Three of them close crashes (a gesture null
dereference, an orphan subsurface, screenshare exit). The two September
crashes (`dragEnd` with no target, `resizeTarget` on a window with no
space) are guarded in the waveview plugin and have no patch here; whether
upstream fixed them was not re-checked.

### 2.5 Closed since September

No ISO, no installer, no host for a stranger's machine, nvidia always on
nouveau, no Wi-Fi page, Max's locale for everyone, no translations, the
silent `replaceStrings` miss, rollback depth by age, `nix flake check` never
run: all built or fixed. The installer is a text one that starts by itself
from the "Install" entry of the medium (language, timezone, keyboard, disk,
encryption, you: `Installer/preinstall/mockup/install-cli`); the installed
machine is `golem-desktop`, built on the hardware measured at install
(`flake.nix`).

---

## 3. The feature to lead with: going back

- **Real:** every update is a whole new version, the earlier ones stay, and
  the boot menu starts any of them ("Previous Versions").
- **Real:** if the desktop crashes twice in a row right after starting, the
  machine goes back to the earlier version by itself, does not take the bad
  update again, and says so
  (`system/Modular/desktop/crash-recovery.nix`).
- **On a branch, not merged:** the button. Controls → Updates → "Go back to
  it" (`launcher` branch `tarde-1116`, `dd7c820f`), which starts the same
  service.
- **Not built:** a page listing every version (plan F10.1), and any backup
  (F10.4–F10.6).

- [ ] **Decide the alpha claim.** With the button merged, "one click and you
      are back on yesterday's system" is true. Without it, headline the boot
      menu.

---

## 4. Feedback channel — **open, Max's call**

| | Barrier to the tester | Trail | Cost to Max |
|---|---|---|---|
| GitHub Issues on `maxpoww/Golem` | needs an account | public, searchable | triage only |
| Email | none | none: every report is private and answered again | inbox |
| Matrix / Discord | account + app | chat: reports scroll away | constant |

Two constraints:

1. **One front door.** Bugs come from three repos (Golem, the shell, the
   overview plugin); a tester cannot be asked which one broke.
2. **Reachable from another machine.** The first report may be "it cannot
   get online", so the channel is printed on the download page, not only
   inside the system. Golem itself sends nothing (no telemetry).

- [ ] **Pick it.** Recommended: GitHub Issues as the one door, plus an email
      address on the download page.
- [ ] A report template that asks for the version string of §1.2.

---

## 5. The gate

- [ ] The week of daily use closes, with the three of §2.2 seen
      (`work/todo/todoSH.md:333,340`).
- [x] The ISO builds and boots on real machines (cut record below; three
      fresh installs on 2026-10-03, `work/parity.md`).
- [x] The install needs no network.
- [ ] An installer a stranger gets through with no terminal: it exists and
      starts by itself; no stranger has been watched using it.
- [ ] The lab door is out of the public image and the owner's name is the
      one typed (branch `release-candidate`, not merged).
- [ ] §1: one version string, the revision tagged.
- [ ] §4: the channel picked and printed on the download page.
- [ ] §2.1 published **with** the download, not after it.
- [ ] Install on a machine that is not Max's, watched, in silence
      (`docs/vision/roadmap.md`).

---

## Cut record — 2026-10-07 (main `e6965d1`)

Built from the clean checkout at `e6965d1` with `nix build …#iso` (the union closure of every
lab hardware class; everything but the image steps was already in the dev box's store, 6 min):

- `golem.iso`, 3.0 GB, ISO 9660 'GOLEM_ISO', bootable (BIOS + EFI);
  sha256 `aa4c1b203f43771b558c8a62c193f9d2f8b583f0636e637d6b5ae767aa3123de`;
  rooted on the dev box at `~/golem-iso/result` (store `fvhi15rqym2km1rs8hxlyh6h5437w44w-golem.iso`).
- Live system toplevel `j82d9ykbvrjsb60f7xp8npymwm7q4m21` (2364 store paths): the Seam of this
  cut (`g0gpnz6a…-seam-157.0.1`: uBlock refresh policy, the six YouTube hooks excepted, learned
  60 fps cap, YouTube's service worker out), waverunner/waveview, no Chrome; the source on the
  medium at `/etc/golem/src` is this revision.
- Write it: `cp golem.iso /dev/sdX && sync` (or `dd bs=4M status=progress conv=fsync`) onto a
  stick of 4 GB or more; the laptops in the lab are the test fleet (Acer E5-573, MacBook Air
  6,2, ASUS, ThinkPad E15, Comodore GM45, HP dm4, Lenovo Slim Pro 9 — the classes in the union).
- Seam in this cut: see `seam/README.md` "Seam at the 2026-10 cut" (Firefox 157.0.1 pinned; uBlock 1.75.0 and ATBC 4.3.0 pinned and installed from the package, offline first start).
- Boot test in QEMU/KVM (4 GB, virtio-vga-gl): the ISO boots to greetd → uwsm → Hyprland start within 30 s; the graphical session itself was not confirmed in QEMU (virtio-gpu without 3D from the toolbox) — confirm on a laptop.
