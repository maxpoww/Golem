# Layout — where everything lives

> Max, 2026-11-19: *"cuando instalamos en una máquina hay archivos que van a
> Home y a diferentes lugares; los módulos no sé ni siquiera dónde van,
> deberían estar en /etc/nixos junto con configuration.nix. Todo el sistema
> debería vivir afuera de Home… si voy a la MacBook y quiero hacer un cambio
> manual voy a /etc/nixos, pero ahí no hay nada."*
>
> This is the design for where Golem's files live on an installed machine and
> in the repository, and the plan to get there. **Stage 1 is built** on branch
> `layout-1119` (it holds everything; Hyprland in modules and the app modules
> are also branches of their own, `hypr-modular-1119` and `app-modules-1119`,
> and can go to `main` before the rest); the stages after it are written here
> and wait for a go. No machine is installed this way yet. Supersedes the 2026-10-01
> proposal (`/etc/golem`) and GolemSecurity.md's "Phase 2 — root-owned seed":
> same idea, in the place NixOS already has for it.

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
   the admin's layer, which wins.
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
│   └── answers.list             what was answered to Golem's questions after the install
├── flake.nix                    the entry point: "this folder + the pinned Golem" (never needs editing)
├── flake.lock                   WHICH Golem this computer runs (the update moves it; going back restores it)
└── golem → /nix/store/…         GOLEM, exactly as the running system was built from it. Read-only.
    ├── system/                    the computer:  base, boot, cpu, gpu, disk, memory, power, quirks…
    ├── desktop/                   the desktop:   session, hyprland, audio, bluetooth, printing…
    ├── modules/                   the modules:   gaming.nix, media.nix, development.nix… (programs + the system they need)
    ├── home/                      the person's layer, one file a concern: hypr/ (Hyprland), terminal, editor, look, dock…
    └── docs/, updates/, seam/, installer/

/var/lib/golem/                  what the system keeps for itself (root-only)
├── secrets/                     the owner's password hash, the boot password — never in /etc/nixos
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
| `/etc/nixos/flake.lock` | root | the update (`golem-update`) | this is what it moves | the pin |
| `/etc/nixos/golem` | the store | the build | replaced whole | (it *is* the build's source) |
| `/var/lib/golem/secrets/*` | root, 0600 | the installer, `passwd` | never | a file path (`hashedPasswordFile`) |
| `~/.config/golem/settings.json` | the person | Controls | never | not by the build at all (applied live) |

### The one door

A person's click reaches the system in exactly one way: a root helper takes a
**request written as data** in the person's home (`~/.config/waverunner/packages.list`,
`~/.config/golem/modules.list`), validates every line against a closed set
(a name nixpkgs has; a module the catalog has), writes the accepted lines to
`/etc/nixos/machine/*.list`, and rebuilds. Those lists are read as text and
looked up (`system/machine/lists.nix`, `system/modules/lib.nix`); none is ever
imported as Nix. (Built: the build reads the lists this way, and a hostile
line is a warning — the check plants some. To do, stage 2: the helper that
writes them.)

So nothing a program running as the person can write is ever *code* for
root, and nothing root builds from is writable by the person. The seal, the
blessed copy, the root mirror, the pulls "as the owner" and the six November
fixes have nothing left to protect: with no checkout in a home they are
switched off, not ported.

### Why Golem is a link and not a checkout

`/etc/nixos/golem` points into the Nix store: the exact source of the running
system. It is not a git checkout you edit, for the reasons rule 2 exists:

- it **cannot drift** from what runs — what you read there is what was built;
- an update replaces it whole, with nothing to merge and nothing to set aside;
- going back a version brings back the Golem that version was built from.

To change something of Golem's on one machine you do what systemd and macOS
have you do — put your version in your layer:

```nix
# /etc/nixos/configuration.nix — an option of Golem's set differently
golem.desktop.effects = "light";
services.pipewire.extraConfig.pipewire."92-golem-low-latency" = lib.mkForce { };

# /etc/nixos/modules/gaming.nix — or a whole module of Golem's replaced by your copy
{ golemSource, ... }:
{
  disabledModules = [ "${golemSource}/system/modules/gaming.nix" ];
  # … the contents of /etc/nixos/golem/system/modules/gaming.nix, edited …
}
```

To change Golem *for everyone* you work in the repository (the dev box keeps
its `~/Golem` checkout; its `/etc/nixos/flake.nix` names it as the `golem`
input instead of GitHub's `stable`).

## 4. Everyday

| You want to… | You do |
|---|---|
| change something by hand | `sudo nano /etc/nixos/configuration.nix`, then `sudo nixos-rebuild switch` (or `rebuild-golem`: the same, behind Golem's rebuild lock) |
| add something of your own that deserves a file | drop `/etc/nixos/modules/printer.nix`, rebuild |
| switch a whole module on by hand | `golem.modules.gaming.enable = true;` in `configuration.nix`, or the line `gaming` in `machine/modules.list` (what the dock's Modules page will write) |
| take one program of a module, or refuse one | `golem.modules.gaming.lutris.enable = true;` · `golem.modules.gaming.steam.enable = false;` |
| add a key or a window rule of your own to Hyprland | `~/.config/hypr/user.lua` (yours, loaded after Golem's; saving it reloads) — or `golem.home.hyprlandExtra` in `configuration.nix` for the whole machine |
| see what Golem does for this hardware, and why | `cat /etc/golem/layout.json`; the modules themselves are in `/etc/nixos/golem/system/` |
| read or copy one of Golem's modules | `/etc/nixos/golem/…` |
| update now | `sudo golem-update` (the nightly update does it for you) |
| go back a version | Controls → Updates → Go back (the pin goes back with the system: `golem-recover`) |
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
person's `~/.config/hypr/user.lua`, then the live settings last.

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
| **1** | The layout itself: `lib.golem.machine` composes a machine from its folder; the `/etc/nixos` template and `golem-machine-scaffold` (a new machine's folder from the installer's answers); `golem-relocate` (an old install's folder); facts and lists as data; the chooser at evaluation; `rebuild-golem`, `golem-update`, `golem-recover` for the layout; the check `machine-layout` (two fixture machines, 23 assertions). Hyprland in Lua modules with one generated facts file; the 25 app modules, switched on from `machine/modules.list`; the home layer one file a concern. | **built** — branch `layout-1119` (and `hypr-modular-1119`, `app-modules-1119`). Proven: every check of the repository; the real `nixos-rebuild`, with no arguments, on a scaffolded `/etc/nixos`, before and after a change made by hand; a fixture machine built whole and its files read. Nothing installs this way yet |
| **2** | The services on the new layout, each a port of a root helper that today writes into the checkout: the nightly update (today's `autoupdate.nix` — waves, notices, held versions — with "pull the checkout, heal the seal" replaced by `golem-update`); the dock's app installs and the Modules page (`waverunner-apply` writing `machine/apps.list` and `machine/modules.list` instead of `hosts/target/apps.nix`); the post-install questions (`machine/answers.list` is already read); Seam's update lane (`seam/sources.json` is part of Golem's source: on this layout a Seam update is a Golem update, or moves to a list of its own); the session's re-seed of the dock's list (`desktop/home-boot.nix` reads `/etc/golem/machine/apps.nix`); the version's binary cache for a hand-run `nixos-rebuild` (`golem-cache-args` reads the checkout's `.git`; here the pin is `flake.lock`). | to do — VM-tested one by one |
| **3** | The installer writes this layout: `/etc/nixos` from the template, `facts.json` from the census, the pin from the medium; first boot builds from it. `golem-desktop` and `hosts/target` retire. | to do |
| **4** | Machines installed before it move by themselves: `golem-relocate` (run by the update) makes `/etc/nixos` from `~/Golem/hosts/target`, builds, switches, and leaves `~/Golem` for the owner to delete. Lab laptops first. | to do |
| **5** | The repository's rename (§6) and the older profile's retirement. | to do |

### Checked against the latest (2026-11-19)

"Check them against the latest documentation of NixOS and Hyprland": both
documentations are generated from source, so the source was read, by a
program that stays in the repository (`tools/latest/check.sh`, to run before
either pin moves):

- **NixOS** — the 55 NixOS options that the app modules, the loopback camera
  and this layout define are all in nixos-unstable (26.11pre), visible and of
  the same type; with all 25 modules and every program on, the pinned 26.05
  evaluates with no failed assertion and no deprecation warning.
- **Hyprland** — the 63 options the configuration sets and every `hl.*`
  function, rule key, bind option, event and animation it names are in 0.57.0
  (main of that day) as in the 0.55.4 Golem runs. One option changes type
  there (`decoration:shadow:color`, a colour → a gradient) and still takes
  Golem's value.

### Decisions for Max

1. **Golem as a read-only link** (`/etc/nixos/golem` → the store), changed
   from your own layer — as built — or a root-owned git checkout you can edit
   in place? The link is what §2's rule 2 says and what makes updates and
   going back trivial; the checkout is more "hackable" on one machine and
   brings back merges and drift.
2. **Stage 4 for the lab laptops**: move them with `golem-relocate`, or
   reinstall them from the first ISO that writes the new layout?
3. **The rename** (§6): after stage 3, in one commit — every open branch of
   every session has to be rebased across it.
