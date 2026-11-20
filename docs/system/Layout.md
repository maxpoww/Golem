# Layout — where everything lives

> Max, 2026-11-19: *"cuando instalamos en una máquina hay archivos que van a
> Home y a diferentes lugares; los módulos no sé ni siquiera dónde van,
> deberían estar en /etc/nixos junto con configuration.nix. Todo el sistema
> debería vivir afuera de Home… si voy a la MacBook y quiero hacer un cambio
> manual voy a /etc/nixos, pero ahí no hay nada."*
>
> This is the design for where Golem's files live on an installed machine and
> in the repository, and the plan to get there. Max decided its open points
> the same day (the last section). Stage 1 is on `main` since 2026-11-19;
> stages 2 and 3 (the services and the installer on the new layout) are
> being built on branch `stage2-1119`. Supersedes the 2026-10-01 proposal
> (`/etc/golem`) and GolemSecurity.md's "Phase 2 — root-owned seed": same
> idea, in the place NixOS already has for it.

## 1. What is wrong today

An installed Golem keeps **the whole system in its owner's home**:

| What | Where it is today | Whose it should be |
|---|---|---|
| Golem itself (every module, the installer, the docs) | `~/Golem`, a git checkout owned by the owner | the system's |
| This computer (name, owner, language, disk, hardware facts, chosen hardware modules) | `~/Golem/hosts/target/{machine,golem-hardware,modules,hardware-configuration}.nix`, untracked files inside that checkout | the machine's |
| The apps installed from the dock | `~/Golem/hosts/target/apps.nix`, written as the owner | the machine's |
| The owner's settings | `~/.config/golem/settings.json`, `~/.config/waverunner/…` | the owner's (right) |
| Secrets (password hash, boot password) | `/var/lib/golem/secrets/` (right, since 2026-10) | root's |
| `/etc/nixos` | one leftover file nothing reads; no `flake.nix`, no `nixos-config` | — |

What follows from it:

- **A manual change has no place.** `sudo nixos-rebuild switch` answers
  "nixos-config not found". The real way (edit `~/Golem/hosts/target/machine.nix`,
  run `rebuild-golem`, approve the seal) is known to nobody who learned NixOS
  anywhere else.
- **Root builds what any program can write.** Everything in `~/Golem` is
  writable by every program the owner runs, and root builds the system from
  it. The seal (`golem-seal`, hashes of every file, a blessed root copy, a
  root mirror of upstream, git never run as root inside the owner's
  repository) exists only to make that safe, and in November it took six
  fixes ("roads to root") to close what it missed.
- **The machine is tangled into the distro.** The machine's files sit inside
  Golem's tree, so `git reset --hard` loses them, an update has to set the
  owner's edits aside, and the machine carries a rendered list of paths into
  Golem's tree (`modules.nix`) — the reason `system/Modular` can never be
  renamed.
- **A home is the wrong container.** It can be encrypted, on another disk,
  restored from a backup, deleted with its user. The system should survive
  all four.

## 2. How other systems do it

| | The system itself | This computer (admin) | State the system keeps | A person's settings | A person's files |
|---|---|---|---|---|---|
| **macOS** | `/System`, `/usr`, `/bin` on the **sealed, read-only system volume** (signed; an update swaps the whole snapshot) | `/Library` (Preferences, LaunchDaemons, Application Support), `/etc` | `/private/var`, `/Library/…` | `~/Library` (Preferences, Application Support, Caches) | `~/Documents`, `~/Desktop`… |
| **Windows** | `C:\Windows` (protected: only the servicing stack writes it), `C:\Program Files` | registry `HKLM`, Group Policy, `C:\ProgramData` | `C:\ProgramData`, `C:\Windows\System32\config` | `%APPDATA%` (roams), `%LOCALAPPDATA%`, registry `HKCU` | `%USERPROFILE%\Documents`… |
| **Linux (FHS + systemd)** | `/usr` (the vendor's; `/usr/lib/*` holds every default) | `/etc` (overrides the defaults; `*.d/` drop-in folders) | `/var/lib`, `/var/log`, `/var/cache` | `~/.config`, `~/.local/share`, `~/.local/state`, `~/.cache` | `~/Documents`… |
| **Image-based Linux** (Fedora Silverblue, SteamOS, ChromeOS, Android) | a **read-only, verified image** (`/usr`, `/system`); updates replace it whole and keep the last one to go back to | `/etc` (Silverblue merges it across updates) | `/var`, `/data` | as Linux | as Linux |
| **NixOS** | `/nix/store` (immutable; generations to go back to) | **`/etc/nixos`**: `configuration.nix`, `hardware-configuration.nix`, and `flake.nix` — which `nixos-rebuild` uses by itself when it is there | `/var/lib` | `~/.config`… (home-manager can generate them) | `~/…` |
| **Omarchy** | `~/.local/share/omarchy` (a git checkout in the home, updated by `git pull`) | — | — | `~/.config/*` files that *source* Omarchy's defaults and then override them | `~/…` |

The rules every mature system follows (Omarchy is the one that does not, and
is where today's Golem got its shape):

1. **Split by owner, not by topic.** Three owners — the vendor, the machine's
   admin, the person — and three places. An update replaces the vendor's part
   and touches nothing else.
2. **The vendor's part is read-only and verified.** Nobody edits `/System`,
   `C:\Windows` or `/usr` in place. You change the system's behaviour from
   the admin's layer, which wins. (Golem keeps the two things this rule
   buys — an update that cannot be blocked by a local change, and a way
   back — and lets root edit its copy all the same: §3.)
3. **One well-known place to change the machine.** `/etc`, `/Library`,
   `gpedit`. On NixOS that place is `/etc/nixos`: every manual, forum answer
   and habit says "edit `/etc/nixos/configuration.nix`, run `nixos-rebuild
   switch`".
4. **Override by layering.** Vendor default → machine → person, each in its
   own file (systemd's `/usr/lib` → `/etc` → `~/.config`; macOS's System →
   Local → User domains). To change a vendor file you put *your copy* in your
   layer; you do not edit theirs.
5. **A home holds a person, never the system.** Settings and files. The
   system builds and boots without reading it.

## 3. Golem's layout

Three owners, three places, and one door between the person and the system.

```
/etc/nixos/                      THE MACHINE — root's. What you edit. Never rewritten by an update.
├── configuration.nix            yours: this computer's name, owner, language… and every manual change
├── hardware-configuration.nix   this hardware's disks and kernel modules (nixos-generate-config)
├── modules/                     yours: every .nix file here is part of the system (a drop-in folder)
├── machine/                     what Golem's TOOLS recorded — data, never code
│   ├── facts.json               the hardware census (processor, graphics, memory, firmware, panel)
│   ├── install.json             the shape chosen at install ({"profile": "desktop"})
│   ├── apps.list                the programs installed from the dock
│   ├── modules.list             the app modules switched on in the dock
│   ├── answers.list             what was answered to Golem's questions after the install
│   └── questions.json           what Golem deliberately left for the owner to decide
├── flake.nix                    the entry point: "this folder, and Golem in golem/" (never needs editing)
└── golem/                       GOLEM — root's own copy, a git checkout. You may edit it.
    ├── system/                    the computer:  base, boot, cpu, gpu, disk, memory, power, quirks…
    ├── desktop/                   the desktop:   session, hyprland, audio, bluetooth, printing…
    ├── modules/                   the modules:   gaming.nix, media.nix, development.nix… (programs + the system they need)
    ├── home/                      the person's layer, one file a concern: hypr/ (Hyprland), terminal, editor, look, dock…
    ├── flake.lock                 the versions of everything Golem is built with (NixOS, the dock…)
    └── docs/, updates/, seam/, installer/

/var/lib/golem/                  what the system keeps for itself (root-only)
├── secrets/                     the owner's password hash, the boot password — never in /etc/nixos
├── golem.git/                   git's own data for /etc/nixos/golem (out of the folder a rebuild copies)
├── local-edits/                 files you had changed in golem/ that an update had to set aside
└── update state                 what is held back, tries of a new version

~/.config/golem/                 THE PERSON — settings chosen in Controls (live, no rebuild)
~/.config/hypr/user.lua          the person's own Hyprland additions
~/.local/share, ~/.local/state   their data and state
~/Documents, ~/Pictures…         their files
```

(The names under `golem/` are the repository's final ones; §6 maps today's
onto them.)

### Who owns what

| Path | Owner | Written by | An update | Read by the build as |
|---|---|---|---|---|
| `/etc/nixos/configuration.nix`, `modules/*.nix` | root (the admin) | you; the installer once | never touches it | Nix modules (it is the admin's code) |
| `/etc/nixos/hardware-configuration.nix` | root | `nixos-generate-config` | never | Nix module |
| `/etc/nixos/machine/*.json`, `*.list` | root | Golem's tools, through the one door | never | **data**: parsed, validated, looked up |
| `/etc/nixos/golem/**` | root | the update; you, when you want to change Golem here | merges the new version into it, your edits kept | Golem itself (Nix, and everything it ships) |
| `/var/lib/golem/secrets/*` | root, 0600 | the installer, `passwd` | never | a file path (`hashedPasswordFile`) |
| `~/.config/golem/settings.json` | the person | Controls | never | not by the build at all (applied live) |

### The one door

A person's click reaches the system in exactly one way: a root helper takes a
**request written as data** in the person's home (`~/.config/waverunner/packages.list`),
validates every line against a closed set (a name nixpkgs has; a module the
catalog has), writes the accepted lines to `/etc/nixos/machine/*.list`, and
rebuilds. Those lists are read as text and looked up (`system/machine/lists.nix`,
`system/modules/lib.nix`); none is ever imported as Nix. The new list is
built first in a root-only copy of the folder: the one in `/etc/nixos`
changes only when that system built (`system/machine/apps.nix`).

So nothing a program running as the person can write is ever *code* for
root, and nothing root builds from is writable by the person. The seal, the
blessed copy, the root mirror, the pulls "as the owner" and the six November
fixes have nothing left to protect: with no checkout in a home they are
switched off, not ported.

### Golem is root's copy, and it stays editable

Max, 2026-11-19: *"copia editable por root."* `/etc/nixos/golem` is a git
checkout that belongs to root. You may change any file of Golem's there and
rebuild; `sudo nixos-rebuild switch` builds what the folder holds at that
moment, an edit in `golem/` as much as one in `configuration.nix`.

What makes that safe to live with:

- **One set of pins.** The machine's `flake.nix` has no inputs: it calls
  `golem/machine.nix`, which evaluates Golem with the versions named in
  Golem's OWN `flake.lock` (`system/machine/from-lock.nix`). As a flake
  *input*, Golem would have been locked twice — Nix copies an input's pins
  into the outer lock once and never looks again — and after a pull the
  machine would have built the new Golem with the old NixOS (measured).
- **An update keeps your edits.** `golem-update` is a three-way merge of the
  files as they are with the new version, against the version they started
  from. Where you and the new version changed the same lines, Golem's wins
  and your file is set aside in `/var/lib/golem/local-edits/<when>/` — never
  lost, and never a reason to stop updating (an edited checkout that could
  no longer fast-forward once froze a lab machine for a month).
- **The folder moves only when the new system builds.** The merged files are
  built from a root-only copy first. A version that does not build, or a
  network that fails, leaves `/etc/nixos` exactly as it was.
- **Never backwards.** If the branch a machine follows is behind what the
  machine has, nothing is taken from it.
- **Going back.** Every generation keeps the folder it was built from, Golem
  with your edits included; `golem-recover` puts those files back when the
  machine goes back a version.
- **What you changed is one command away:** `sudo golem-status`, or plain
  `git status` / `git diff` in the folder.

The other way to change one of Golem's modules still works and touches
nothing of Golem's: carry your version in your own layer.

```nix
# /etc/nixos/configuration.nix — an option of Golem's set differently
golem.desktop.effects = "light";

# /etc/nixos/modules/gaming.nix — or a whole module of Golem's replaced by your copy
{ golemSource, ... }:
{
  disabledModules = [ "${golemSource}/system/modules/gaming.nix" ];
  # … the contents of /etc/nixos/golem/system/modules/gaming.nix, edited …
}
```

To change Golem *for everyone* you work in the repository (the dev box keeps
its `~/Golem` checkout).

## 4. Everyday

| You want to… | You do |
|---|---|
| change something by hand | `sudo nano /etc/nixos/configuration.nix`, then `sudo nixos-rebuild switch` (or `rebuild-golem`: the same, behind Golem's rebuild lock) |
| add something of your own that deserves a file | drop `/etc/nixos/modules/printer.nix`, rebuild |
| switch a whole module on by hand | `golem.modules.gaming.enable = true;` in `configuration.nix`, or the line `gaming` in `machine/modules.list` (what the dock's Modules page will write) |
| take one program of a module, or refuse one | `golem.modules.gaming.lutris.enable = true;` · `golem.modules.gaming.steam.enable = false;` |
| add a key or a window rule of your own to Hyprland | `~/.config/hypr/user.lua` (yours, loaded after Golem's; `hyprctl reload` the first time, from then on saving it reloads) — or `golem.home.hyprlandExtra` in `configuration.nix` for the whole machine |
| see what Golem does for this hardware, and why | `cat /etc/golem/layout.json`; the modules themselves are in `/etc/nixos/golem/system/` |
| read or change one of Golem's own files | `/etc/nixos/golem/…` (root's copy: edit, rebuild; `sudo golem-status` says what this computer changed) |
| update now | `sudo golem-update` (the nightly update does it for you; `--now` switches at once) |
| go back a version | Controls → Updates → Go back (Golem's files go back with the system: `golem-recover`) |
| reinstall and keep the machine as it was | keep `/etc/nixos` (it is small, and holds no secret) |

## 5. The layers, from the bottom

Every setting has one of three sources, and the later one wins:

1. **Golem's default** — a module in `golem/`.
2. **The machine** — `/etc/nixos/configuration.nix` and `modules/` (a NixOS
   definition beats a default; `lib.mkForce` beats a definition Golem insists on).
3. **The person, live** — what is chosen in Controls (`~/.config/golem/settings.json`),
   applied at once without a rebuild and again at every start.

Hyprland follows the same three (system/home/hypr/README.md): Golem's Lua
modules (one file a concern, the same text on every machine, with ONE
generated file of this machine's facts), then the Lua of the app modules that
are on, then the machine's own (`golem.home.hyprlandExtra`), then the
person's `~/.config/hypr/user.lua`, then the live settings last. All of
Golem's part is one folder in the store, and the home holds ONE link to it
(`~/.config/hypr/hyprland.lua`): a rebuild swaps the whole configuration in
one step, and the running session reloads into it by itself.

## 6. The repository

Golem's tree stays what it is — one leaf per concern — and gets the names a
person browsing `/etc/nixos/golem` would look for. New things are already
where they will stay; the old profile's files move when it retires.

| Final | Today | What |
|---|---|---|
| `system/<family>/` | `system/Modular/{base,boot,cpu,gpu,gpu2,disk,memory,power,quirks,swap,virt,lab}/` | the computer: one leaf per concern, hardware leaves picked by the chooser from the facts |
| `desktop/` | `system/Modular/desktop/` | the desktop: session, Hyprland (package and patches), audio, printing… |
| `modules/` | `system/modules/` | the app modules: one file per kind of work (§7) |
| `home/` | `system/home/` | the person's layer (home-manager), one file a concern: `hypr/` (Hyprland's Lua modules), `hyprland.nix`, `dock.nix`, `look.nix`, `terminal.nix`, `editor.nix`, `files.nix`, `default-apps.nix`, `idle.nix`, `fits.nix`… |
| `machine/` | `system/machine/` | this layout: `mkMachine`, the `/etc/nixos` template, the lists' readers |
| `installer/`, `updates/`, `seam/`, `docs/`, `tools/`, `work/` | as today | |
| — (gone) | `system/*.nix`, `hosts/target/`, `hosts/golem/` | the older all-in-one profile and the per-machine files inside the tree |

The rename is one mechanical commit, possible once machines stop carrying a
rendered `modules.nix` (stage 3: the chooser runs at evaluation, from
`machine/facts.json`) and the older profile is retired.

## 7. The modules

Three kinds, one rule each for when they are on:

| Kind | Where | On when | Decided by |
|---|---|---|---|
| **Hardware leaves** | `system/…/gpu/amd.nix`, `power/laptop.nix`… | the facts say so | the chooser (`choose.nix`), from `machine/facts.json`, at every build |
| **Desktop leaves** | `desktop/…` | the machine runs the desktop | `machine/install.json`'s profile |
| **App modules** | `modules/gaming.nix`, `media.nix`… | the owner chose them | `machine/modules.list` (the dock) or `golem.modules.*` (by hand) |

An app module is **the programs and the system they need**: its packages,
and the services, device rules, ports and kernel modules without which they
do not work (system/modules/README.md) — and, where it has any, its own
Hyprland rules (`system/home/hypr/golem/modules/<module>.lua`, loaded only
while the module is on). Options, never arbitrary Nix: a click only ever
flips `golem.modules.<module>.<program>.enable`, one of a closed set that the
catalog defines. Two rules hold for all 25: what is set up is what a program
needs to WORK, never a preference; and no selection gives the owner a group
that is root (Docker is rootless, virtual machines run in the owner's own
session).

## 8. Stages

| | What | State |
|---|---|---|
| **1** | The layout itself: `lib.golem.machine` composes a machine from its folder; the `/etc/nixos` template and `golem-machine-scaffold`; `golem-relocate`; facts and lists as data; the chooser at evaluation; the check `machine-layout`. Hyprland in Lua modules behind one link; the 25 app modules, switched on from `machine/modules.list`; the home layer one file a concern. | **on `main`** since 2026-11-19 (b83f8fd) |
| **2** | Golem as root's editable copy (`machine.nix`, `from-lock.nix`, `golem-machine-checkout`); the update that keeps the edits (`golem-update`, `golem-recover`, `golem-status`) and its nightly service, waves and held versions; the dock's installs into `machine/apps.list`; the first-boot build. | **built and run on a machine** (`stage2-1119`): the checks `machine-layout` and `machine-update` (the update driven on a made-up upstream, 101 assertions) and a VM installed from the medium — see below |
| **3** | The installer writes this layout: the medium's baked systems are systems of the layout; `golem-install` gathers the machine's files in a root-only stage, makes `/etc/nixos` from them and Golem beside it, and asks for the first-boot build. `golem-desktop` and `hosts/target` stay only for machines installed before. | **built and run in a VM** (`stage2-1119`): install, first boot, first restart, see below; the lab's MacBook next |
| **4** | Machines installed before are REINSTALLED from the first medium that writes the layout (Max, 2026-11-19), the lab's first. `golem-relocate` stays as a tool, not as a migration. | waits for stage 3 |
| **5** | The repository's rename (§6) and the older profile's retirement. | after stage 3 (Max: yes) |

### Tried on a machine (2026-11-20)

A VM (4 cores, 4 GB, UEFI) installed four times from lab media cut from the
branch, its upstream a local mirror standing in for GitHub. The last pass
was left alone from the installer's last line to the first restart, but for
one thing a person does: installing an app from the dock a minute into the
first session.

- **The install** (5 min, nothing built on the target) leaves `/etc/nixos`
  as §3 draws it, Golem's files beside it at the medium's commit, git's data
  in `/var/lib/golem/golem.git`, and nothing of the system in a home.
- **The first boot** builds this machine's own system from that folder (its
  owner, name, language, measured hardware). The machine computes exactly
  the system another computer computes from a copy of the folder: what is
  built does not depend on where it is evaluated, so the published cache
  serves every machine.
- **In that first session**, before any restart: the app asked for from the
  dock and Seam's own update (160.0 → 160.0.1, its timer) are both built
  and staged for the next start — neither switches the installer's system
  out from under the session (see below) — and the first-boot build takes a
  newer Golem that the branch had by then.
- **The first restart** starts it: the owner's account under the owner's
  name with the same uid and the first session's home, the language, the
  time zone, the keyboard, the desktop, the app, the newer browser; no
  failed unit.
- **By hand**: `nixos-rebuild` with no arguments, as root, in `/etc/nixos`.
- **An update** across 12 commits with two of Golem's files edited by root
  and a module of the owner's in `modules/`: 2.5 min, switched under the
  running session (same compositor, no configuration error), the edits
  still there and built in, nothing set aside.
- **The browser's own update** (Seam 160.0 → 160.0.1) wrote its pin into
  root's copy and rebuilt from the folder; `golem-status` shows it for what
  it is.
- **An install from the dock** (the owner's list, with two hostile lines in
  it): the two names written to `machine/apps.list`, the programs in the
  owner's profile, the hostile lines refused.
- **A post-install answer**: the one valid answer in `machine/answers.list`.
- **Going back** to the files that built an earlier generation, and forward
  again (`golem-recover`).

What that install taught, and is now enforced:

- **No system of another owner's name starts under the old account's
  session.** The installer copies a system built for everybody (its account
  has the medium's name); the owner's own name arrives with the first system
  built from `/etc/nixos`, and the account is renamed at the restart that
  starts it. A live `switch` in that first session did not wait: NixOS made
  the new name a second, empty account and dropped the first, and the
  restart found nothing to rename — the first session's files left in
  `/home/<the medium's name>`, owned by nobody. Seam updating itself did
  exactly that eleven minutes into the test install; an app from the dock or
  an answer to a post-install question would have. (This is in the
  checkout-in-a-home layout too, since the rename exists: 2026-11-15.) Now
  such a switch is refused before it begins, whoever asks
  (`system.preSwitchChecks`, `base/users.nix`), and `golem-rebuild` stages
  the system for the next start instead and says so; the dock's helper
  tells the owner their apps arrive at the restart.

- The installer keeps a COPY of Golem's pins in a lock of its own. Two days
  stale, it baked the old dock, and the new machine compiled the new one,
  the overview and the compositor's headers on its first start. The
  installer no longer evaluates with pins that are not Golem's, and
  `checks.installer-lock` fails a commit that moves one without the other.
- A medium cut from a commit the branch does not know builds its first
  system from the files as they are (it no longer guesses that the branch
  is newer). For its nightly updates to work, the commit has to be
  reachable upstream — any branch will do: a machine ahead of `stable`
  waits for it.

- **The idle suspend waits for a running install or update.** It was meant
  to and never had: the units are one-shots, "activating" while they run,
  and `systemctl is-active` says no to that. On a machine of the weak tier
  the first-boot build opens at the same 15th minute the idle suspend
  fires: the test VM went to sleep as its build began (and went on when
  woken). Now the suspend waits for the job, two hours at most, and happens
  when it ends, unless the owner came back meanwhile (`home/idle.nix`,
  `checks.idle-suspend`).

A test machine's own trap, for whoever repeats this: QEMU's virtio-gpu does
not survive a suspend (after the idle suspend, at 15 minutes, the next
shutdown waits for ever on the display). Golem's caffeine switch, in the
VM's session, keeps the test honest.

Known and not done: a baked system does not say which commit it was built
from (`nixos-version --configuration-revision` is "unknown" until the first
boot's build); the first evaluation on a new machine downloads nixpkgs'
source (the medium has it, the installed disk does not).

### Checked against the latest (2026-11-19)

"Check them against the latest documentation of NixOS and Hyprland": both
documentations are generated from source, so the source was read, by a
program that stays in the repository (`tools/latest/check.sh`, to run before
either pin moves):

- **NixOS** — the 54 NixOS options that the app modules, the loopback camera
  and this layout define are all in nixos-unstable (26.11pre), visible and of
  the same type; with all 25 modules and every program on, the pinned 26.05
  evaluates with no failed assertion and no deprecation warning.
- **Hyprland** — the 63 options the configuration sets and every `hl.*`
  function, rule key, bind option, event and animation it names are in 0.57.0
  (main of that day) as in the 0.55.4 Golem runs. One option changes type
  there (`decoration:shadow:color`, a colour → a gradient) and still takes
  Golem's value.

### Decided (Max, 2026-11-19)

1. **Golem on a machine is an editable copy that belongs to root**
   (`/etc/nixos/golem`), not a read-only link into the store. §3 says what
   keeps updates and going back working with it.
2. **Machines installed before are reinstalled**, the lab's MacBook first;
   they are not moved in place.
3. **The rename** of the repository's folders (§6): yes, in one commit after
   stage 3.
4. **Stage 1 went to `main` at once**; stages 2 and 3 follow.

What that order asks for: a medium that writes this layout takes its first
update from the branch installs follow (`stable`), so the layout has to be
ON that branch before such a medium is given to anyone — as with every
medium before it.
