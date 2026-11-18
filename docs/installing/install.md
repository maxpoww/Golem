# Installing Golem: how it works today

This is the one document about the Golem install. It was written on
2026-11-16 from the code on branch `next-1116` (commit `ccc38d3`). It covers
the installer medium, the install screens, what lands on the disk, the first
boot and the updates after it.

It replaces `GolemInstall.md`, `postinstall.md` and the maintainer set in
`preinstall/` (README, ARCHITECTURE, OPERATIONS, TESTING, DEBUGGING,
EXTENDING). Those files stay as short pointers; their old text is in git.
The lab story stays in [preinstall/HISTORY.md](preinstall/HISTORY.md) and the
six-round archive in [preinstall/testing/](preinstall/testing/). Updates have
their own document, [updates/README.md](../../updates/README.md).

When this document and the code disagree, the code wins. Fix this document.

## Contents

- [In one minute](#in-one-minute)
- [1. The two media](#1-the-two-media)
- [2. The install, screen by screen](#2-the-install-screen-by-screen)
- [3. What is written on the disk](#3-what-is-written-on-the-disk)
- [4. First boot](#4-first-boot)
- [5. Updates afterwards](#5-updates-afterwards)
- [6. The lab door](#6-the-lab-door)
- [7. How to test](#7-how-to-test)
- [8. Known limits](#8-known-limits)
- [9. Where the logs are](#9-where-the-logs-are)
- [10. Changing the installer](#10-changing-the-installer)
- [11. Decisions that still hold](#11-decisions-that-still-hold)
- [12. The old documents against the code](#12-the-old-documents-against-the-code)

## In one minute

1. Build the installer ISO in `Installer/preinstall`. A plain build is the
   public medium. A lab build adds the lab door.
2. Boot the stick and pick **Install**. The machine measures itself while
   you answer six screens.
3. Press ENTER on "Install Golem?". The installer erases the drive and copies
   a ready-made Golem system that matches the machine's hardware class.
   Nothing is compiled and no network is needed. It writes the machine's own
   files, checks the result and asks you to pull the USB.
4. First boot: the desktop opens at once. Behind it, Golem goes online,
   becomes a checkout of GitHub's `stable` branch and rebuilds itself for the
   measured hardware and your answers. That version starts at the next
   restart, and the account then takes the name you typed.
5. After that, once a day, the machine follows `stable` through the update
   lane.

## 1. The two media

The installer ISO is the flake in `Installer/preinstall`. It is a
console-only NixOS medium. One switch, the `GOLEM_LAB` environment variable,
makes it the public medium or the lab medium.

| | Public medium | Lab medium |
|---|---|---|
| Build (in `Installer/preinstall`) | `nix build .#iso` | `GOLEM_LAB=1 nix build --impure .#iso` |
| SSH server on the stick | off | on, keys only, for `root` and `nixos` |
| SSH keys on the stick | none | the dev box's `dev-lab` and `golem-vm-loop` |
| Lab Wi-Fi profile `golem-lab` on the stick | no | yes, joins by itself |
| Marker file | none | `/etc/golem/lab-medium` |
| Baked systems carry the lab door | no | yes (`/etc/golem/lab-door`) |
| An install from it | has no lab door | keeps the lab door (writes `hosts/target/lab.nix`) |
| May go behind the website's Download button | yes, after `golem-publish-iso` has looked inside | never: `golem-publish-iso` refuses it |

A pure build reads `GOLEM_LAB` as empty. So a plain `nix build .#iso` can
never make a lab medium by accident. The lab door is section 6.

### What both media carry

| Item | Where on the medium | Why |
|---|---|---|
| The Golem source | `/etc/golem/src` | the census evaluates it; the install copies it to the disk |
| Every pinned input (nixpkgs, home-manager, waverunner, waveview) | `/etc/golem/inputs` and the store | offline evaluation, each input passed with `--override-input` |
| The baked matrix: finished systems | the medium's Nix store | the install copies one; nothing is built |
| The manifest of the baked systems | `/etc/golem/baked-manifest.json` | maps a leaf list and a language to a system |
| All firmware (`hardware.enableAllFirmware`) | the medium's system | Wi-Fi and GPUs work on the stick as they will once installed |
| The tools | the PATH | `golem-setup`, `golem-setup-install`, `golem-install`, `golem-hw-detect`, `golem-hw-decide`, `golem-hw-evidence`, `golem-postinstall-questions` |

The image is `result/iso/golem-installer.iso`, volume label `GOLEM_INST`,
host name `golem-installer`. It boots quietly, with no kernel text, on BIOS
and on UEFI.

Not an installer: `nix build .#iso` at the repo root builds the old live
medium (`hosts/iso.nix`, the all-in-one profile). It installs nothing.

### The baked matrix

The install never builds Golem on the target machine. The medium carries
finished systems, made when the ISO is built (`bakedMatrix` and
`bakedManifest` in the root `flake.nix`).

| Dimension | Today |
|---|---|
| Hardware classes | the lab fixtures: acer, asus, comodore, hp, lenovo, macbook, thinkpad, qemu (`Installer/preinstall/fixtures/`) |
| Firmware | BIOS and UEFI, for every class |
| The floor | one per firmware, for a machine nothing was detected on with confidence: GPU `auto` (boots on any GPU) |
| Language | `en_US.UTF-8` only |
| Content | the full desktop: Hyprland, the dock and OPTIONS, Seam, the apps. It rebuilds itself as `golem-desktop`. |
| Account | the default owner in the code (`golem.owner`, today `max`) |

Each baked system finds its disks by label (`golem`, `ESP`, `swap`), has a
broad initrd that reaches a disk on any common controller, resumes from the
`swap` label, and opens a partition labelled `crypt` if there is one (the
password is asked on the boot bar).

### Building a medium

1. Make the installer's lock follow the tree. The `golem` input is the repo
   itself (`path:../../`), but its own inputs are pinned again in
   `Installer/preinstall/flake.lock`, and that lock does not follow the root
   lock by itself. After any change to the root `flake.lock`, and before
   every cut, run `nix flake update golem` in `Installer/preinstall` and
   commit that lock too. A medium built from a stale lock ships old pinned
   inputs (an old dock, for example). Check that
   `jq -r '.nodes.waverunner.locked.rev' flake.lock` gives the same commit in
   both locks.
2. Build the public or the lab medium (table above).
3. Check the built artifact, not the source:

   ```
   top=$(nix build '.#nixosConfigurations.golem-installer.config.system.build.toplevel' --no-link --print-out-paths)
   setup=$(nix-store -qR "$top" | grep -- -golem-setup$)
   grep -c '<a marker of this change>' "$setup/libexec/golem-setup-unwrapped"
   ```

4. Gate it in the VM before any flash (section 7).
5. Flash it. Confirm the stick every time with
   `lsblk -d -o NAME,SIZE,TRAN,MODEL`, then:

   ```
   sudo dd if=result/iso/golem-installer.iso of=/dev/sdX bs=4M oflag=direct conv=fsync status=progress
   ```

### Publishing

`golem-publish-iso <file.iso>` puts an ISO behind the Download button of the
website. It lives on the dev box, outside this repo. Before it uploads
anything, it reads the store image inside the ISO and refuses when it finds:

- an SSH key authorized for any user, on the medium or in a baked system;
- the lab Wi-Fi profile `golem-lab`;
- the marker `/etc/golem/lab-door` or `/etc/golem/lab-medium`.

It also refuses when it cannot look (it needs `7z`). With
`GOLEM_PUBLISH_CHECK_ONLY=1` it only looks and uploads nothing.

### Secure Boot

The medium and the installed system are not signed. Secure Boot must be off.
With it on, the firmware refuses the stick before the installer runs, so the
installer can neither notice nor explain it. On a Windows machine with
BitLocker, suspend BitLocker in Windows before changing firmware settings,
then resume it, or Windows asks for its recovery key.

## 2. The install, screen by screen

### The boot menu

Two entries, centred on black, no timeout.

| Entry | What it does |
|---|---|
| **Start** | A console. tty1 logs in as `nixos` by itself. The census runs and prints a short summary on tty1. The help line names the census file and `sudo golem-setup`, which **rehearses** the whole install and writes nothing. |
| **Install** | Adds `golem.install` to the kernel command line. tty1 opens the installer at once, as root, with no login and no banner (`golem-setup-install`). tty2 to tty6 keep a normal console login for debugging. |

### The census

`golem-audit.service` runs on both entries, right after boot. It never
touches a disk.

1. `golem-hw-evidence` dumps the raw hardware (lspci, lsusb, DMI, sysfs).
2. `golem-hw-detect` writes the facts (`golem-hardware.nix`).
3. `golem-hw-decide` evaluates Golem against those facts, offline, and
   writes what it decided (`summary.txt`, `decision.json`).

The results are in `/var/log/golem-audit/`. Its `status` file says `ok` or
which stage failed. The facts:

| Fact | What it says |
|---|---|
| `cpuModel`, `cores`, `threads`, `cpuVendor` | the processor; the vendor picks the microcode |
| `ramMB` | the memory; picks the zram tier and the swap size |
| `gpu`, `intelLegacy`, `nvidiaGen` | the main GPU, an Intel GPU older than Broadwell, the NVIDIA generation |
| `gpu2`, `gpu2BusAddr`, `gpu2Health` | a second GPU and the result of its sleep and wake test |
| `nvidiaBusId`, `intelBusId` | PCI slots, only on hybrid laptops |
| `firmware` | `bios` or `uefi`; picks the boot leaf and the disk layout |
| `chassis` | `laptop`, `desktop` or `unknown`; picks the power leaves |
| `vmGuest` | the hypervisor, if any |
| `hasBluetooth`, `fingerprint`, `broadcomWifi`, `hasFacetimeHD`, `lightSensor` | devices that need their own stack |
| `panelDpi` | the built-in screen's density; picks the desktop scale |

An unknown fact always means the safe default. NVIDIA's own driver is chosen
only for a known generation; anything else gets the open floor. A first boot
must never be a black screen.

### The six steps

ENTER takes the highlighted row. Typing filters the list. The arrow keys
move. ESC goes back one step. F1 or Ctrl+C leaves at once and cleanly; on the
Install entry the installer then starts over. Each answer stays on screen as
one line.

| # | Screen | What you do | What it sets |
|---|---|---|---|
| 1 | Language | A line rotates through several languages ("Press ENTER to select your language"). ENTER or any letter opens the list. | The system language (`golem.locale.defaultLocale`). The installer itself speaks English, Spanish, French, German, Italian and Portuguese; other languages see it in English. |
| 2 | Select your Timezone | Every zone on the medium. The zones where the chosen language is spoken come first. | `golem.locale.timeZone`. The answer line shows the local time, to check against a clock. |
| 3 | Select your Keyboard | A list, starting at the layout of the time zone's country, else the language's. | One name sets the console keymap, the XKB layout, variant, options and model, and a console font if needed. The keymap is loaded at once, so every password after this is typed with it. |
| 4 | Select your Drive | Disks by model and size, internal ones first. The title warns that everything on the drive will be erased. The last row is **Advanced**. | The target disk. Nothing is erased yet. |
| 5 | You | Four fields: **Name this Device** (an empty ENTER takes "Golem"), **User Name**, the password, the password again. | Host name, account name, password. The password is masked, and hashed (yescrypt) as soon as it is confirmed; the text never leaves that screen. |
| 6 | Install Golem? | Read the summary and press ENTER. ESC goes back. | Starts the install. |

What the "You" fields accept:

| Field | Accepted |
|---|---|
| Device name | letters, digits and dashes, no dash at either end |
| User name | a lowercase letter first, then lowercase letters, digits, `_` or `-`, 32 at most; never a name the system uses (root, nobody, greeter, the build and systemd accounts, any existing group) |
| Password | not empty, typed twice; a mismatch goes back to the first field |

The drive list never offers the stick it booted from, loop, zram or RAM
devices, CD drives, floppy drives, firmware flash chips or network block
devices. A machine with no usable disk stops at this step with "No drive
found to install on."

**Advanced**, the last row of the drive list:

| Row | Today |
|---|---|
| Dual-Boot | answers "not in this release yet" |
| Install on a partition | answers "not in this release yet" |
| Full-Drive encryption | works on UEFI machines (below) |
| Back | returns to the drive list |

Encryption is off by default. Turning it on asks for a drive password twice
(at least 8 characters, shown in the clear so a typo can be seen). A warning
screen follows: the password is asked at every start and there is no
recovery. ENTER accepts; ESC turns encryption off. The drive line then says
it will be erased and encrypted, and a red LOCKED row appears. The drive
password waits in a 0600 file in the medium's RAM and is shredded as soon as
the encrypted container exists.

The confirm screen shows three things:

- your answers;
- what Golem decided: zram, the swap for hibernation, thermald, the lid
  action, the disk scheduler, and the screen scale when it is not 1.0;
- what Golem found, read live from the machine: each GPU with its tested
  verdict, Wi-Fi, Ethernet, audio, Bluetooth, fingerprint reader, touchpad
  and touchscreen, each with the driver bound to it. A device that is not
  there gets no row.

Ctrl+D on the confirm screen opens a "Developer install" note. It only says
the mode is for experts. It changes nothing today.

### After ENTER: two bars

1. **The copy bar.** Formatting the drive, filesystems, copying Golem, the
   hardware profile, then package names fly by while the system is copied.
   At 100% it says "Installed".
2. **The verify bar.** Six checks on the new disk: the bootloader, the
   system profile, the kernel and initrd, a root line in fstab, the seed, a
   loginable account.

Then the verdict. "The installation is healthy" means all six checks passed.
"Installation finished" means one failed: read
`/var/log/golem-install/verify.txt` on tty2 before you restart (section 9).
Both end with "remove the USB and press ENTER". ENTER restarts at once and
silently, through a small helper already copied to RAM, so it is safe to pull
the stick first. An unattended install waits on this screen. It never loops
back into the installer.

If the install stops on the Install entry, the failure line shows only for a
moment: tty1's login service starts the installer again at the language
screen. The reason is in `/var/log/golem-install/` on the medium (read it on
tty2).

## 3. What is written on the disk

The engine is `golem-install` (`Installer/preinstall/install.nix`). The
screen runs it as
`golem-install --answers /tmp/golem-answers --disk <disk> --yes`.

### Checks before any write

| Check | Rule |
|---|---|
| Firmware | `/sys/firmware/efi` present means UEFI. GRUB on both. |
| Not the medium | the target is not the disk behind `/iso` |
| Fit | the root partition gets at least 20 GiB after the boot partition and the swap |
| RAM | under 3300 MB is only a warning on a medium with baked systems, because nothing is evaluated or built on the machine. It refuses only an install that would build locally. |
| Encryption on BIOS | refused ("encryption on a BIOS/legacy machine is not supported yet"); nothing is written |

Then the engine frees the disk (unmounts, closes LVM and LUKS, kills what
holds it, up to 4 tries) and wipes it.

### The partitions

GPT on every machine.

| Firmware | Encryption | Layout |
|---|---|---|
| UEFI | off (default) | 1: ESP, 512 MiB, FAT32, label `ESP`. 2: swap, label `swap`. 3: root, ext4, label `golem`, the rest of the disk. |
| UEFI | on | 1: ESP, 512 MiB. 2: one LUKS2 container (partition label `crypt`) holding the LVM group `golemvg` with the volume `swap` (label `swap`) and the volume `root` (ext4, label `golem`). |
| BIOS | off | 1: BIOS boot partition, 1 MiB, no filesystem (GRUB lives here). 2: swap. 3: root, ext4. No ESP: `/boot` is on the root. |
| BIOS | on | refused |

One container, not two: hibernation reads the swap from the initrd, so swap
and root open with one password, asked once.

The swap is sized for hibernation, which every install has
(`lib.golem.swapForHibernationMB`): the RAM plus the larger of a tenth of the
RAM and 2 GiB, rounded up to whole GiB.

| RAM | Swap | Smallest disk (512 MiB + swap + 20 GiB root) |
|---|---|---|
| 4 GB | 6 GiB | about 27 GiB |
| 8 GB | 10 GiB | about 31 GiB |
| 16 GB | 18 GiB | about 39 GiB |
| 32 GB | 36 GiB | about 57 GiB |

### The system: a copy, not a build

1. The chooser (`system/Modular/choose.nix`) turns the facts into a list of
   leaves: boot, microcode, GPU, second GPU, memory tier, swap, disk, power,
   virtualization, quirks.
2. The engine looks that list up in `/etc/golem/baked-manifest.json`, with
   the chosen language.
3. No match in that language: the same list in `en_US`.
4. No match at all: the floor for this firmware.
5. The last resort, which should never be reached: build `golem-minimal`
   from the copied source, offline.

Then `nixos-install --root /mnt --system <baked system> --no-root-password
--no-channel-copy` copies the store paths and installs the bootloader. The
root account gets no password; the owner uses `sudo` with their own.

| Bootloader | Detail |
|---|---|
| UEFI | GRUB-EFI at the removable fallback path (`EFI/BOOT/BOOTX64.EFI`). No firmware (NVRAM) entry is written. At most 3 entries, so the 512 MiB ESP never fills. |
| BIOS | GRUB in the BIOS boot partition, up to 15 entries |
| Both | a 1 s menu, then "Start Golem"; older systems under "Previous Versions". Editing an entry asks for a boot password (user `golem`), made on the machine and shown by `sudo golem-boot-password`. |

### The account

A baked system is one image for everybody. Its account has the name it was
built with, written in its `/etc/golem/owner` (today `max`). The engine reads
that file and gives the owner's things to that account:

- the copied source moves from `/home/<typed name>/Golem` to
  `/home/<baked account>/Golem`;
- the typed password is set on the baked account (`chpasswd -e` with the
  hash);
- `machine.nix` carries the typed name.

The account takes the typed name later, at the first restart after the
first-boot step (section 4).

### The machine's own files: `hosts/target/`

The copied source is the machine's own flake, `/home/<account>/Golem`
(`golem.flakeDir`). Its `hosts/target/` folder holds what makes this machine
itself. `.gitignore` lists the facts, hardware, machine, modules and questions
files, so the published repo never carries one machine's answers (`lab.nix`
and `apps.nix` are not listed). On the machine, `golem-seed-adopt`
stages every file in this folder with `git add -f` and never commits it,
because a git flake sees only tracked or staged files.

| File | Written by | Holds |
|---|---|---|
| `golem-hardware.nix` | `golem-hw-detect`, at install | the facts. They are compared with the boot census; a difference is a warning. |
| `modules.nix` | the chooser | the hardware leaves, each with its reason, and the groups left empty. If the chooser fails, the file is missing and the install warns. |
| `hardware-configuration.nix` | `nixos-generate-config --root /mnt` | the measured filesystems (by UUID), the swap, the initrd modules |
| `machine.nix` | `golem-install` | owner, host name, full name (the user name), language, time zone, keyboard; the LUKS container's UUID when encrypted; the GRUB disk by its stable `by-id` name on BIOS |
| `postinstall-questions.json` | `golem-postinstall-questions` | questions Golem chose not to decide. Today there is one (a second GPU that failed its wake test). Usually `[]`. |
| `lab.nix` | `golem-install`, only when the copied system has `/etc/golem/lab-door` | `{ golem.lab.door = true; }` |
| `apps.nix` | later, the dock's installs (`waverunner-apply`) | the owner's app list |
| `default.nix` | distro source, not written by the install | the import list of the old all-in-one target; installs do not use it |

Every rebuilt generation also keeps a copy of this folder at
`/etc/golem/machine`, so `golem-recover` can always rebuild what runs.

A shortened `machine.nix`, as the engine writes it (example values):

```nix
{ ... }:
{
  golem.owner = "ana";
  networking.hostName = "Golem";
  users.users.ana.description = "ana";
  golem.locale.defaultLocale = "es_ES.UTF-8";
  golem.locale.timeZone = "Europe/Madrid";
  golem.keyboard = {
    layout = "es"; variant = ""; options = ""; model = "pc105"; consoleKeyMap = "es";
  };
  # encrypted installs: boot.initrd.luks.devices.golem.device = "/dev/disk/by-uuid/...";
  # BIOS installs:      boot.loader.grub.device = "/dev/disk/by-id/...";
}
```

The password is never in `machine.nix`: everything in the flake is copied
into the world-readable Nix store.

### The other files

| Path on the new disk | What |
|---|---|
| `/var/lib/golem/secrets/owner-password-hash` | the password hash, root only, outside the flake and the store. The account reads it when it is created; after that an activation step keeps it equal to `/etc/shadow`. |
| `/etc/shadow` | the hash, set on the copied account, so the first login works without a rebuild |
| `/home/<account>/.config/golem/settings.json` | language, time zone and keyboard as live settings. The dock reads them when the first session starts, so the desktop already speaks the chosen language. |
| `/etc/vconsole.conf` | the console keymap and font |
| `/etc/nixos/configuration.nix` | deleted: Golem is a flake system, and a second configuration would only invite the wrong rebuild |

Last, the engine gives the whole home to the account, syncs, and unmounts the
disk cleanly, so the first boot does not have to recover the journal.

## 4. First boot

| When | What happens |
|---|---|
| Power on | GRUB for 1 s. An encrypted disk asks for its password on the boot bar and waits as long as needed. |
| Boot | The boot bar, then the desktop starts by itself as the baked account (greetd's first session of the boot needs no password). The password unlocks the lock screen and `sudo`. |
| First session | A generic system: host name `Golem`, system time zone UTC, the broad initrd, an English system locale. The desktop already uses the chosen language, time zone and keyboard (`settings.json`), and the home folders are named in that language. |
| 30 s after boot | The `golem-first-boot` timer starts the first-boot step, at the lowest priority. The desktop never waits for it. |

The first-boot step (`system/Modular/base/first-boot.nix`) runs once:

1. It waits until the desktop has run for a minute. On a weak machine (under
   6 GB of RAM, or a GPU on light effects) it waits 15 minutes and then a
   calm minute. With nobody logged in, it goes ahead 5 minutes after boot.
2. It waits for the internet (`cache.nixos.org`), up to 15 minutes. Offline,
   it gives up and runs again at the next boot.
3. `golem-seed-adopt` turns the copied source into a git checkout of
   `https://github.com/maxpoww/Golem`, branch `stable`. It stays at the
   revision the machine was installed from when GitHub has that commit;
   otherwise it takes the head of `stable`. It carries the machine's own files
   over, stages them, and hands the checkout to the owner. If GitHub cannot
   be reached, the source stays a plain copy and the nightly update tries
   again.
4. The seal. On first use it records what is there (trust on first use):
   `/var/lib/golem/seed.manifest` and a root-only copy,
   `/var/lib/golem/blessed`.
5. Root builds its own copy of the sealed files: `golem-rebuild boot` of
   `golem-desktop`. It downloads from `cache.nixos.org`, and from the
   version's Golem cache when the update lane published one.
6. On success it writes `/var/lib/golem/first-boot.done`. A failure leaves no
   stamp, so the step runs again at the next boot.

The new generation is not switched in live. It starts at the next restart and
brings:

| Change | From |
|---|---|
| An initrd trimmed to the real disk controller; the real filesystems by UUID | `hardware-configuration.nix` |
| The chosen hardware leaves: drivers, microcode, memory tier, laptop power, Bluetooth | `modules.nix` |
| Host name, time zone, keyboard, system language | `machine.nix` |
| The account takes the typed name | `machine.nix` and `system/Modular/base/users.nix` |
| The lab door, on lab installs | `lab.nix` |

The rename (`golemOwnerRename`) runs during activation at boot, before the
users step, and only when no process of the old account is running. It keeps
the uid and the password, moves `/home/<old>` to `/home/<new>`, fixes links
that pointed into the old home, and records the name in
`/var/lib/golem/owner`. Booting an older generation from the menu renames the
account back. The boot's journal shows it under `golem-owner`.

## 5. Updates afterwards

The full story is [updates/README.md](../../updates/README.md). In short:

| Piece | What it does |
|---|---|
| Branch | Installs follow `stable` (`golem.upstream.branch`). Only the update lane moves it, after every baked Golem system has built and the desktop has booted in a VM. |
| When | `golem-autoupdate`, once a day: at the machine's own moment between 00:00 and 06:00 (derived from its machine-id), or within 10 minutes of power-on when it was off at that moment. |
| Wave | A new version waits the machine's wave: 0 to 6 days from its machine-id (the lab: 0), counted from when the machine first saw it was behind, or from the version's publication if that is earlier. |
| How | Wait for the internet; pull `stable`, fast-forward only; check that every changed file is upstream's own code (`golem-seal-heal`); build root's copy with `golem-rebuild boot`. |
| Live | At the next restart. Never a live switch, never a forced reboot. |
| Failure | A version that does not build: the source goes back to what built the running system (`golem-recover`). A version that crash-loops the desktop: the machine rolls back and holds that revision. |
| The owner is told | "Golem has an update ready" after 2 days waiting for a restart; "Golem could not update" after 7 days without a run that worked. Nothing leaves the machine. |
| Update now | The Controls button starts `golem-update-now`: one run that skips the wave. |
| The owner's own edits | Edits to Golem's files outside `hosts/target/` are copied to `~/Golem-local-edits/<time>/` and put back before a pull. To build their own change the owner runs `rebuild-golem` (asks for the password, builds a copy and seals that same copy) or approves it with `sudo golem-bless`. Root never builds a change nobody approved. |

## 6. The lab door

The lab door is `system/Modular/lab/lab-door.nix`, option
`golem.lab.door`. It makes a machine a lab testbed that the dev box can reach.

| Part | Detail |
|---|---|
| SSH keys | the dev box's keys (`dev-lab`, `golem-vm-loop`) for root and for the owner |
| Lab Wi-Fi | profile `golem-lab`: the open lab network named in the file, joins by itself, retries forever, Wi-Fi power saving off |
| Wi-Fi address | the card's real address (other installs use a stable private one) |
| Wave | 0: the lab meets every new version first |
| Heartbeat | a ping to the gateway every 20 s, so the access point keeps the machine known |
| Marker | `/etc/golem/lab-door`, which the installer and the publish check look for |

sshd runs on every install, keys only, no passwords (`base/ssh.nix`). Without
the lab door no key is authorized, so nobody can log in over SSH.

How a machine gets the door, and keeps it:

| Case | What happens |
|---|---|
| Installed from the public medium | no door |
| Installed from a lab medium | The baked systems were evaluated with `GOLEM_LAB=1`, so the first system already has the door. The engine sees `/etc/golem/lab-door` in the copied system and writes `hosts/target/lab.nix`, so the door survives every rebuild. |
| An existing lab machine | the lab deploy puts `hosts/target/lab.nix` in its machine layer, then `golem-bless` seals it |
| Any machine without `lab.nix` | loses the door at its next rebuild: a pure evaluation reads `GOLEM_LAB` as empty |

The lab medium also has its own sshd with the two keys for `root` and
`nixos`, and the lab Wi-Fi. `GOLEM_LAB_WIFI_SSID` and `GOLEM_LAB_WIFI_PSK`
(with `--impure`) change only the medium's Wi-Fi profile; the installed door
always uses the network named in `lab-door.nix`.

`golem-install --lab-ssh KEY` and `--lab-wifi SSID` still exist: they write
SSH and Wi-Fi lines into `machine.nix`. The install screen never passes them.
The lab door replaced them.

**Decision (Max, 2026-11-16):** the lab door and the lab Wi-Fi stay on the
lab notebooks, also in the next ISO. The public medium never carries them.

The effect matrix checks both sides. A machine without `lab.nix` has no key,
no lab Wi-Fi, no fixed wave and no marker. A machine with it has all four.

## 7. How to test

The ladder, cheapest first:

| Rung | What | Catches |
|---|---|---|
| 1. Flake checks | `facts-matrix`, `chooser-matrix`, `minimal-matrix`, `desktop-matrix`, `keyboard-table`, `timezone-defaults`, `boot-test`; the package `update-gate` builds every baked system | logic, each lab machine's leaf list, the composed configuration, a version that does not boot |
| 2. The screen script | `Installer/preinstall/mockup/install-cli` runs in any terminal: `--fake-disks` plays the whole flow with nothing real, `--dump <screen>` prints one screen, `--check` checks that every string the code asks for exists and that every language has a real keyboard row. The build runs `bash -n` on it. | screen and key bugs |
| 3. The VM | `Installer/preinstall/run-vm.sh` | the whole install on a disposable disk, BIOS and UEFI |
| 4. Metal | the lab machines (`preinstall/testing/`, `Installer/installing/`) | real GPUs, real Wi-Fi, real timing |

Flake checks are built from the repo root. Address the flake as `git+file:`,
never `path:` (see the root README):

```
G="git+file://$(git rev-parse --show-toplevel)"
nix build --no-link "$G#checks.x86_64-linux.chooser-matrix"
```

A census or decision bug can be replayed without the machine:
`golem-hw-decide --facts <fixture>` (and `golem-postinstall-questions
--facts <fixture>`) evaluate a committed fixture from
`Installer/preinstall/fixtures/`. Both tools are packages of the installer
flake (`.#hw-decide`, `.#hw-postinstall-questions`).

Record every pass, a clean one too, in the machine's file (the format is in
`preinstall/testing/CLAUDE.md`). The change a finding implies goes to the
ledger, `Installer/installing/changes.md`.

### VM recipes (`run-vm.sh`)

The script runs from `Installer/preinstall` and boots
`result/iso/golem-installer.iso`, or the file given with `--iso PATH`. The VM
gets 4096 MB of RAM on purpose: the weak class. The target disk is virtio
with a serial number, so it has a `/dev/disk/by-id` name like a real disk.

```
cd Installer/preinstall

./run-vm.sh                                       # look at the medium, in a window
./run-vm.sh --uefi --disk ~/VMs/golem/t1.qcow2:40G   # install on UEFI (disk made if absent)
./run-vm.sh --uefi --no-cd --disk ~/VMs/golem/t1.qcow2  # boot the installed disk
./run-vm.sh --disk ~/VMs/golem/b1.qcow2:40G          # BIOS (see the BIOS limit, section 8)
./run-vm.sh --headless --uefi --disk ...             # no window; a virtio GPU so the census still sees one

# The monitor socket drives the VM without a window:
echo sendkey ret | socat - unix:/tmp/golem-vm-hmp         # ENTER (the menu's first row is Start)
echo sendkey down | socat - unix:/tmp/golem-vm-hmp        # then ENTER again, for Install
echo 'eject -f ide1-cd0' | socat - unix:/tmp/golem-vm-hmp # pull the USB, then ENTER on the verdict
echo system_wakeup | socat - unix:/tmp/golem-vm-hmp       # wake a desktop that suspended

ssh -p 2222 root@127.0.0.1                        # the medium over SSH: lab medium only, key only
```

- Rehearse: pick Start, then `sudo golem-setup`. The full flow runs and
  nothing is written. Read `/var/log/golem-rehearsal/checks.txt` first.
- `--uefi` keeps the VM's EFI variables in `ovmf-vars.fd` in
  `Installer/preinstall`. Delete it for fresh firmware settings.
- An installed system of the qemu class runs the qemu guest agent on
  `/tmp/golem-vm-qga`, a way in without SSH.
- First boot needs the internet; the VM's user networking gives it. In the
  4 GB VM the first-boot step waits 15 minutes after the desktop is up (weak
  class), then builds. Expect the new generation about 20 minutes after boot.
- The desktop suspends after 15 minutes idle. Wake it from the monitor.
- First boot clones `stable` from GitHub. To test a branch that is not on
  `stable`, serve it in the guest and point git at it with an
  `url.<mirror>.insteadOf` rule in `/etc/gitconfig`. Activation rewrites that
  file at every boot, so set it after the boot and before the first-boot step
  starts.

### What every pass proves again

- A rehearsal writes nothing: the UUIDs, the partition table and the first
  MiB are unchanged, the disk's writes-completed counter does not move, and
  the transcript has only `would` lines.
- The install-time probe agrees with the boot census, fact for fact.
- The boot medium is never offered, whatever the device order.
- F1 and Ctrl+C leave from any state, once, and the temporary files are gone.
- The reveal says only true things: verdicts measured on this boot, absences
  that are real.

The disk-untouched proof, before and after:

```
lsblk -o NAME,UUID /dev/sdX ; sfdisk -d /dev/sdX | head -3
awk '{print $5}' /sys/block/sdX/stat      # writes completed: must not move
```

### After an install

| Check | How |
|---|---|
| Census against the probe | `checks.txt` warns when they differ |
| System health | `systemctl is-system-running`, `systemctl --failed` |
| Memory | zram and swap match the RAM tier; `resume=` is on `/proc/cmdline` |
| First boot | `journalctl -u golem-first-boot`; `/var/lib/golem/first-boot.done` exists |
| The checkout | `~/Golem` is a git checkout following `origin/stable`; the machine's files are staged |
| The rename | after the restart: `/var/lib/golem/owner`, `ls /home`, the boot's journal lines from `golem-owner` |
| Parity | `tools/parity/golem-parity <user>@<ip>` and `golem-deep`; findings go to `work/parity.md` |
| The dock's first state | `docs/shell/dockmenu/harness/aging-check.sh` and `state-census.sh`: a first boot is free data |

## 8. Known limits

| Limit | Detail |
|---|---|
| Whole disk only | Dual-Boot and Install on a partition answer "not in this release yet". |
| Encryption is UEFI only | On a BIOS machine the screen's encryption row says it needs a UEFI machine and cannot be chosen (18-Nov). The engine refuses it too, before writing anything. |
| A failed install | The screen shows the engine's reason (its `golem-install: …` line, in English) and where the whole log is, and waits for ENTER before starting over at the language screen (18-Nov; it used to restart after a moment, the reason only on tty2). |
| Secure Boot must be off | the medium and the system are not signed |
| English is the only baked language | Another language installs the English system. The desktop speaks the chosen language from the first session; the system language arrives with the first-boot rebuild, after a restart. |
| Unknown hardware gets the floor | A machine whose leaf list matches no baked class installs the floor: GPU `auto`, no microcode, the lowest zram tier, no laptop power leaves, Bluetooth off. Its own leaves arrive with the first-boot rebuild. |
| First boot needs the internet | Offline, the machine stays on the generic system and tries again at every boot. |
| The account name | Until the first restart after the first-boot step, the account is the baked one (`max`): its home is `/home/max` and that name shows in paths. |
| First boot moves to GitHub | The first-boot step stays at the installed revision only when GitHub has that commit. Otherwise it builds the head of `stable`, which can differ from what was installed (an old `stable` can bring back what the medium removed). Build media only from a pushed commit, best one already on `stable`. |
| Updates only fast-forward | A machine follows `stable` only while its checkout is part of `stable`'s history. A machine installed from a commit that never becomes part of `stable` stops updating, and says so after 7 days. |
| Post-install questions are never asked | The engine writes `postinstall-questions.json`, but the services that ask and apply (`system/postinstall.nix`) are only in the old all-in-one profile, not in the modular system installs run. A second GPU that failed its wake test stays on the safe default, `hold`: available, never autosuspended. |
| The confirm screen's decisions come from the old profile | `golem-hw-decide` evaluates `lib.golem.mkTarget`, the all-in-one composition, not the modular system that is copied. Its rows can drift from what is installed. |
| A light sensor (suspected, not yet seen) | `golem-hw-detect` writes `lightSensor = true` when it finds an ambient light sensor. The old profile (`system/hardware.nix`) does not declare that fact, and both `golem-hw-decide` and `golem-postinstall-questions` evaluate the old profile. On such a machine the census should report `FAILED at: golem-hw-decide`, and the install should stop at the hardware profile phase, after the disk was wiped. No fixture carries the fact, so the flake checks never met it. |
| The logs of a FAILED install die with the medium | A finished install copies `/var/log/golem-install/` into the new system (18-Nov, below). A failed one keeps them only in the medium's RAM: read them on tty2 before pressing ENTER. |
| The BIOS GRUB disk | The baked BIOS systems install GRUB to `/dev/sda`, the default in `system/Modular/boot/grub-bios.nix`; the chosen disk's `by-id` name in `machine.nix` takes effect only with the first-boot rebuild. So since 18-Nov a BIOS install that COPIES a baked system onto any other disk is REFUSED before anything is written (a system built on the machine, with no manifest on the medium, reads `machine.nix` and is not refused) (it would have put GRUB into the first disk's boot code, or failed after the wipe where there is no `/dev/sda`); the screen shows the reason. A BIOS test in `run-vm.sh` needs an IDE disk (`/dev/sda`), not the default virtio one. The real fix is a baked BIOS system that installs GRUB where it is told (`nodev` plus the engine's own `grub-install` on the chosen disk), tested on a BIOS VM install. |
| The lab Wi-Fi name | The installed door always joins the open network named in `lab-door.nix`. A lab medium built for another network does not change that. |
| The public Start console | Fixed 18-Nov: the `ssh nixos@<address>` line shows only on a medium that runs SSH (a lab medium); the public one no longer offers it. |

## 9. Where the logs are

On the medium. They live in RAM and are gone at the restart.

| Path | What |
|---|---|
| `/var/log/golem-audit/status` | `ok`, or `FAILED at: <stage>`. Read it first. |
| `/var/log/golem-audit/golem-hardware.nix` | the facts |
| `/var/log/golem-audit/summary.txt`, `decision.json` | what the facts decided |
| `/var/log/golem-audit/detect.log`, `decide.log`, `evidence.log` | the tools' errors |
| `/var/log/golem-audit/evidence/`, `evidence.tar.gz` | the raw dump, ready for `fixtures/<machine>/` |
| `/var/log/golem-install/` | a real install: `plan.txt`, `checks.txt`, `transcript.txt` (every command, as `run`), `nixos-install.log`, `verify.txt`, `choose.err`, `personalize.err`, `output.txt` (everything the engine printed, kept by the screen), and `status` (only when it failed) |
| `/var/log/golem-rehearsal/` | a rehearsal: `status` (`ok` or `findings: N`), `checks.txt` (read it first), `transcript.txt` (`would` lines), `plan.txt`, `target/` (the machine's files), `answers`, `rehearsal.tar.gz` |
| `/tmp/golem-answers`, `/tmp/golem-machine.nix` | the screen's answers (the password's hash, never the password) |
| `/tmp/golem-drv.*`, `/tmp/golem-kb-orig.*`, `/run/golem-setup.owns-console` | temporary files; gone on any exit |

On an installed machine:

| Where | What |
|---|---|
| `/var/log/golem-install/` | the install's own logs, copied from the medium at its end (root only; `output.txt` up to the verify) |
| `journalctl -u golem-first-boot` | the first-boot step |
| `journalctl -u golem-autoupdate` | the nightly update |
| `journalctl -u waverunner-apply` | the dock's installs |
| `/var/lib/golem/` (root only) | the seal manifest, the blessed copy, the first-boot stamp, the owner record, the secrets, held revisions, the wave's clock |
| `/var/lib/golem-notices/update-ok`, `update-failed` | when an update last worked, and last failed |

Failure classes the lab already paid for. Check these before a new theory:

| Class | Lesson |
|---|---|
| The artifact does not carry the fix | Locks, copies and sticks do not refresh themselves. Check the built store path and the embedded lock. |
| A git flake sees only tracked or staged files | A new file is invisible until `git add`. A generated module changes nothing until something imports it. |
| Success without the effect | An exit code can say ok while nothing changed. Check the observable result. |
| The clean PATH of a service | A tool missing from `runtimeInputs` works by hand and fails under systemd. |
| The rig lies | Suspect the test harness first: root SSH sessions, a store glob that picks the wrong binary, `sudo -n` returning nothing, a flaky router. |
| Slow hardware races | What takes no time on the dev box takes minutes on a 5400 rpm disk. If it fails only on the slow machine, it is a race, and the slow machine is right. |
| Terminal input | F1 arrives as `\eOP`, `\e[[A` or `\e[11~`. Reproduce key bugs with exact bytes (`tmux send-keys -H`). |
| GPU generations | Device-id rules break on old parts. New GPU logic gets a fixture and both directions of the health question. |

## 10. Changing the installer

| To add | Do this |
|---|---|
| A census fact | Measure it in `system/hardware-detect.nix`: measured, never guessed, cross-checked when one source can lie (like `hasBluetooth`: sysfs, rfkill or a USB class). Declare it in `system/Modular/base/options.nix`, and also in `system/hardware.nix` as long as the census and the question tool evaluate the old profile (see the light sensor limit). Save the machine that needs it in `Installer/preinstall/fixtures/<machine>/`. Add a fact only when a machine needs it. |
| A hardware decision | A leaf in `system/Modular/<group>/`, pointed at by a rule in `choose.nix`. `chooser-matrix` pins each lab machine's list; `minimal-matrix` or `desktop-matrix` asserts the leaf's effect. |
| A baked class | Add the fixture to `bakedFixtures` in the root `flake.nix`. The medium grows, and the update gate builds it too. |
| A confirm-screen decision row | The row in `system/hardware/decide.nix`, with a `key` and `args` so the screen can translate it; the screen needs the words in six languages. |
| A hardware row | `hardware_reveal` in `mockup/install-cli`: "name · driver". A missing device gets no row; an uncertain tail is dim (`hw_row`). |
| A screen string | Every string goes through the `S[lang:key]` table and `t`, in all six languages (en, es, fr, de, it, pt). |
| A screen or a key | Each screen says what ENTER, ESC and F1 do. New key names go into `read_key` and never become filter text. Blocks keep a fixed height. Ctrl+C means what F1 means. |
| A disk command in the engine | Through `run()`, so a rehearsal records it instead of running it. A phase marker carries a key (`##golem N/100 <key>`), never display text. |
| A language for the screens | A full `S[xx:*]` block, a line in the invitation, and a check that the console font draws it. |
| A dock fix (waverunner) | Commit and push in the launcher repo, bump the root lock, then `nix flake update golem` in `Installer/preinstall`. |

Two rules hold for every change:

- Add a gate only where always-on has a real cost (a GPU driver, microcode,
  the laptop power stack). A stack that is harmless when idle stays on
  everywhere; the disk policy decides per device at runtime. Every new gate
  is one more combination to test.
- One frozen ISO per round: fixes land in the source and ship in the next
  cut, after the VM gate. Findings go to `Installer/installing/changes.md`
  (it continues the archive's numbering).

## 11. Decisions that still hold

| Date | Decision |
|---|---|
| 2026-09-03 | The installer is Golem's own, not calamares. The disk scope is the whole disk, with an encryption switch. The boot menu is Start and Install, with no timeout. |
| 2026-09-05 | The screens are a console conversation, one question at a time, not a painted TUI. The default install: no encryption, ext4, swap sized for hibernation, the whole disk erased. Encryption, one partition and dual boot sit behind Advanced. |
| 2026-09-05 | The keyboard comes before the disk, so a drive password is never typed with the wrong keymap. |
| 2026-09-08 | What the installer cannot judge honestly (a second GPU that fails its wake test) is held in a safe state and left to the owner (#33). |
| 2026-09-15 | Secure Boot is out of scope: Golem requires it off. Microsoft's signing review is out of reach, and an owner-enrolled key means firmware visits and a signed kernel on every rebuild, forever. `boot/systemd-boot.nix` stays retired but kept, and lanzaboote stays the way back in if this is ever reopened. |
| 2026-09-18 | Install by copying baked systems; never build on the target. |
| 2026-10-01 | The desktop is baked: the first boot is the real desktop. |
| 2026-11-12 | The lab door only on lab machines (`hosts/target/lab.nix`). |
| 2026-11-14 | The stick's SSH, keys and lab Wi-Fi only on a lab medium; `golem-publish-iso` refuses a lab medium. |
| 2026-11-15 | The typed user name becomes the account, renamed at the restart after the first-boot step. |
| 2026-11-16 | The lab door and the lab Wi-Fi stay on the lab notebooks, also in the next ISO. |

Always:

- The iron law: an uncertain fact lands on the safe stack, and NVIDIA's
  driver is chosen only for a known generation. A first boot is never a black
  screen.
- No telemetry: the census reads only the local machine and nothing leaves
  it. New hardware classes come from the lab and public data, never from
  users' machines.
- Hibernation is locked: every install has swap sized for it.
- No per-machine copies of module code: a machine is its facts, its leaf
  list and its answers, the files in `hosts/target/`.

## 12. The old documents against the code

What the replaced documents said, and what the code does today. The code
wins.

| Old document said | The code does |
|---|---|
| GolemInstall.md: the installer's hardware output is two files; everything else is one library on every machine, switched on by facts | It writes up to six files (`golem-hardware.nix`, `hardware-configuration.nix`, `machine.nix`, `modules.nix`, `postinstall-questions.json`, and `lab.nix` from a lab medium). Installs import only the leaves the chooser picked. |
| GolemInstall.md: `nixos-install --flake <checkout>#golem-target`; the first boot is already correct | `nixos-install --system <baked system>`, a copy. The first boot converges online and is live at the next restart. Installs rebuild themselves as `golem-desktop`. |
| GolemInstall.md: baking the common hardware combinations onto the medium is an open plan | Built: every lab class in both firmwares, plus the floor, English only, with the desktop. |
| postinstall.md: built; the owner is asked at the first graphical login | Not on installs: the ask and apply services are only in the old all-in-one profile. |
| preinstall/README.md: the spec is `~/Golem/GolemInstall.md` | It was `docs/installing/GolemInstall.md`; now this file. |
| ARCHITECTURE.md: the lab SSH keys and the lab Wi-Fi are on the medium | Only on the lab medium (`GOLEM_LAB=1`, `--impure`). The public medium has no sshd. |
| ARCHITECTURE.md: tty1 logs in as `nixos`; the stick's installer only rehearses, and a real install runs the engine by hand | The Start entry does that. The Install entry runs `golem-setup-install` as root: a real install. |
| ARCHITECTURE.md: phases `##golem 1/6` to `6/6`; 6/6 restarts the machine | `##golem N/100 <key>`, then `##verify N/100` and a verdict; the restart waits for ENTER. |
| ARCHITECTURE.md: the system is evaluated on the machine when RAM allows; systemd-boot on UEFI | A baked system is copied and nothing is evaluated. GRUB on both firmwares. |
| ARCHITECTURE.md and TESTING.md: the RAM floor refuses under about 3.3 GB | Only a warning with baked systems; a 2 GB machine installs. |
| ARCHITECTURE.md: the checkout goes to `/home/<owner>/Golem` | It goes to the baked account's home until the rename. |
| ARCHITECTURE.md and OPERATIONS.md: `--lab-ssh` gives a lab machine its key | The screen never passes it; the door comes from a lab medium and `lab.nix`. |
| OPERATIONS.md: the VM gate and lab machines are driven over SSH; the stick joins the lab Wi-Fi | Only with a lab medium. |
| OPERATIONS.md: a real install is prepare-only, a `golem-target` build on the dev box, `nix copy`, then finish | The Install entry copies a baked system. The `--prepare-only` and `--skip-prepare` seams remain, but that recipe builds `golem-target`, which installs no longer run. |
| OPERATIONS.md: the first-boot checklist expects `golem-postinstall-apply.path` | There is no such unit on an install. |
| OPERATIONS.md and EXTENDING.md: installed machines get fixes through their copy on the deploy loop | Through the update lane and `stable`. |
| DEBUGGING.md: a rehearsal's `target/` holds four files; `journalctl -u golem-postinstall-apply` | It also holds `modules.nix`. No such unit on installs. |
| EXTENDING.md: answers reach the system through `system/postinstall.nix` | That module is not part of an install. |
