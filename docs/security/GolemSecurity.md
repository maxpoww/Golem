# GolemSecurity — the security model and roadmap

> Max, 2026-09-09: "we need Standard to be secure as fuck. super secure in
> general for all users." This file is the model, the phases, and the
> standing rules. Component-level detail for the dock lives in
> `~/Golem/docs/shell/dockmenu/SECURITY.md`; findings carry changes.md numbers.

## The threat model, in one paragraph

Standard is a single-owner desktop. The assets are the owner's data and the
machine's integrity; the attackers are (a) malicious code that got to run
AS the owner (a bad script, a compromised app), (b) other local accounts,
(c) the network. The line we hold: **user-level compromise must never
become silent root**, secrets must never persist where code-as-user
routinely reads, and nothing we ship may widen the Linux baseline.

## Phase 1 — the seed blessing gate (#56) · LANDED 2026-09-09

The one real escalation we shipped with: the seed flake is owner-owned in
`$HOME`, and root helpers rebuild the system from it unattended — so
user-level malware could edit the config and root the machine with no
password ever shown. Closed by `system/golem-seal.nix`:

- Root keeps a sha256 manifest of the seed in `/var/lib/golem` (0700).
- `waverunner-apply` and `golem-postinstall-apply` refuse an unattended
  rebuild when the seed differs from the manifest — except the two
  sanctioned DATA channels (`waverunner-packages.nix`,
  `postinstall-generated.nix`), which the helpers themselves generate
  from charset/schema-validated user input.
- `sudo golem-bless` shows the changed paths and re-seals: one password,
  only when the system config itself was edited. App installs and
  postinstall answers never prompt.
- First boot is trust-on-first-use (the installer's tree seals itself).
- Residual (accepted): an attacker who already HAS root can re-seal —
  the gate guards escalation, not a lost root. DNS-level nix input
  trust rides the flake.lock, which is INSIDE the seal.

## Phase 1b — the owner's password hash never enters the store · LANDED 2026-10-01

The installer wrote `users.users.<owner>.hashedPassword` into the seed's
`machine.nix`. Everything in the flake is copied into the world-readable Nix
store, so the hash sat in every generation's `users-groups.json` and every
source copy (12 on the ThinkPad): any process could read it and guess the
password offline — exactly what `/etc/shadow`'s permissions exist to prevent.

- Accounts are mutable (NixOS's default): the declared hash only seeds the
  account's CREATION; `/etc/shadow` is the truth afterwards. So the hash now
  lives in `/var/lib/golem/secrets/owner-password-hash` (root, 0600), read
  through `hashedPasswordFile`; the installer writes it there and still
  applies it to the new system's shadow (step 5b).
- An activation step mirrors the account's current shadow hash into that
  file, so existing machines migrate themselves and a later `passwd` is
  followed.
- A machine file that still declares the hash keeps working with a build
  warning; `golem-autoupdate` removes the line.
- Old generations still contain the hash until they are deleted and
  collected: on a migrated machine, delete the old system generations.
- RULE: no secret is ever written into the flake or anything it imports.

## Phase 1c — the three roads to root, closed · 2026-11-12

The security study (2026-11-12) found that the line in the first paragraph
no longer held: three root services trusted the owner's tree, so code
running as the owner reached root with no password.

1. **The app list.** `desktop/app-setup.nix` put the owner in `docker` when
   Docker was installed and in `libvirtd` for virt-manager — both root. The
   list is written without a password, so `echo docker >> packages.list`
   was root. Now: Docker runs rootless (the owner's own daemon,
   DOCKER_HOST), machines run in the owner's libvirt session (virt-manager
   connects to `qemu:///session`), and desktop-matrix asserts that no
   installed app adds a root-equivalent group.
2. **The nightly update.** `golem-autoupdate` ran `golem-bless || true`
   before every build, so a local commit plus `golem-update-now` (polkit,
   no password) was built as root. Now it builds only a tree that passes
   `golem-seal-check`, or that `golem-seal-heal` proves is the blessed tree
   moved by upstream's own code (each file against root's own fetch, never
   the owner's `.git`). Its git calls run as the owner.
3. **Seam's lane.** `seam-update` rebuilt the checkout even when it was not
   sealed. Now it refuses the same way, and after a release it seals only
   its own pin (`golem-seal-adopt`, from root's copy) instead of blessing
   the whole tree. Its backup pin no longer sits in the checkout.

The same rule now covers the two other places that blessed whatever they
found: `golem-recover` (run by `golem-rollback`, which needs no password —
rewritten git objects, then a reset, were sealed) and `golem-seed-adopt`
(deleting `~/Golem/.git` made the next update re-adopt and seal an edited
`machine.nix`). Both seal only through check or heal; recover vouches for
the machine layer by the system's own store copy
(`GOLEM_SEAL_TRUSTED_MACHINE`).

A change nobody approved now waits: the update fails (the 7-day notice
says so) until `rebuild-golem` builds it with the owner's password.

Still open after 1c: the race below (closed in 1d), `golem-rollback` and
`golem-clean-system` can be started without a password (a downgrade or a
wipe of rollback points, not root), and the owner was in the `input` group
(closed in 1d; `uinput` stays: it can write input, not read it).

## Phase 1d — no friction, one level deeper · 2026-11-12

Max approved five items from the next round, the ones nobody sees.

1. **Root builds its own copy.** Every root build checked `~/Golem` and then
   built `~/Golem`; in between, a program running as the owner could swap a
   file in (the harness showed the built `golem-autoupdate` reading the swapped
   `flake.nix`). Now `golem-seal-copy` gives every unattended root build (the
   nightly update, Seam's lane, the dock's installs, first boot) a root-only
   copy of exactly the sealed files, checked against the manifest file by
   file, plus the generated data channels (plain files only) and `.golem-rev`,
   which the flake reads for `system.configurationRevision` when it is built
   from a plain directory. `golem-seal-heal` and `golem-bless` hash root's copy
   and keep that same copy as the snapshot, so the seal and what root builds
   are the same bytes. `rebuild-golem` runs `golem-seal-approve`: build a copy,
   then seal that copy, so a file changed during the build is never approved
   unbuilt. The install helper and Seam's lane no longer write through names a
   link could be planted at (`apps.nix.new`, the pin's restore).
2. **Private windows out of the clipboard's pictures** (launcher, branch
   `private-clip`): a private Seam window is never photographed for a copied
   link's picture. It goes live with a dock restart.
3. **No `input` group.** It let every program read every keyboard and mouse
   directly. Hyprland opens devices through logind, controllers come by
   uaccess, the phone's gamepad writes through `uinput`.
4. **The lab door only on lab machines.** `standard.lab.door`, set by the
   machine's own `hosts/target/lab.nix`. A lab medium is built with
   `GOLEM_LAB=1 nix build --impure .#iso`; its baked systems carry the door
   from the first boot and `golem-install` writes `lab.nix` when the system it
   copies has `/etc/golem/lab-door`. Every other install loses the door at its
   next update. The lab laptops get `lab.nix` from the deploy, before this
   version is published.
5. **The boot menu asks a password only to be changed.** `e` and GRUB's command
   line ask for the user `golem` and the machine's boot password: random, made
   at the first bootloader install, root-only in `/var/lib/golem/secrets`
   (`sudo golem-boot-password` shows it). Every entry and the Previous Versions
   submenu boot without it. Put into `grub.cfg` after the generator (like the
   menu's words), because NixOS's `boot.loader.grub.users` dies on a missing
   file before anything of ours runs, which would have failed every machine's
   first nightly update.
6. **A desktop that comes back after a crash comes back locked** (Max: "fix
   it"). The session keeper, or Hyprland's own watchdog, used to start a
   crashed desktop again open: a crash caused at the lock screen handed over
   the desktop. Now the second start of the desktop in a boot runs the lock
   screen first thing, as the compositor's child (`golem-lock-screen --login`,
   a marker in the runtime dir), whatever the login setting says. The first
   start of a boot shows the lock screen as the login (branch login-live),
   unless `standard.home.loginLock.enable` is off (disk encryption stays an
   installer option, off by default, Max 2026-11-12). Tested on the ASUS: a SIGSEGV to Hyprland and a stopped
   session both came back on the lock screen.

Found on the ASUS while testing 1: the seal walked regular files only, so the
777 symbolic links (the icon themes) were neither sealed nor in root's copy,
and a build from the copy lost those icons. Links are now sealed by where
they point (never followed), staged and copied as links, and heal checks them
against upstream; an install sealed before re-heals once. After the fix a
build from root's copy and one from `~/Golem` give the same system, byte for
byte.

## Phase 2 — root-owned seed as the INSTALLER DEFAULT (queued, design set)

For users, the strongest model costs nothing: they never edit config
files. New installs should place the seed root-owned (e.g. `/etc/golem`),
with:
- every UI system-toggle flowing through a narrow validated data channel
  (the packages.list pattern — this is now a RULE for every future
  system-touching feature);
- `golem edit` for tinkerers: stage in `$HOME`, apply+bless with one sudo;
- lab/dev machines (Max's) may keep the owner-owned seed + gate.
Implementation lands with the installer round that first ships to
someone who isn't Max.

## Phase 3 — the distro hardening baseline (queued → release-checklist)

- **Lab artifacts must never ship**: the lab root-SSH key (used by the
  deploy loop; it exists on the ASUS today and root-SSH is how #44
  happened) is a LAB device convenience — release images carry no
  authorized keys and `PermitRootLogin no`. (Status 2026-11-12, Phase 1d:
  the lab door is on lab machines only, `hosts/target/lab.nix`; the installer
  ISO medium itself still carries the lab keys and Wi-Fi until the first
  finished ISO.)
- sudo requires a password (no NOPASSWD anywhere in shipped config).
- Firewall on by default; no listening services beyond what a feature
  explicitly declares.
- Disk encryption offered by the installer (owner's choice, default on
  for laptops). (Status 2026-11-12: offered behind "Advanced", default
  off — Max, 2026-09-05; the security study proposes default on.)
- The quiet hardening (2026-11-12, `base/security.nix`, `base/network.nix`):
  kexec off, BPF JIT hardened, no TTY line-discipline autoload, protected
  FIFOs and files in sticky folders, no unprivileged userfaultfd, no ICMP
  redirects sent, `slab_nomerge` and a shuffled page allocator, a
  blacklist of network protocols and filesystems no desktop uses (DCCP,
  SCTP, RDS, TIPC, the ham-radio stack, cramfs, jffs2…), and a private
  Wi-Fi address per network (the lab door keeps the real one), sudo
  runnable only by the admin group, and /tmp emptied at every boot.
  Nothing an owner sees; the boot test and the matrices pass with it.
- Seam's lane trusts Mozilla's SHA256SUMS only when Mozilla's release key
  signed it (fingerprint `14F2 6682 D091 6CDD 81E3 7B6D 61B7 B526 D98F
  0353` pinned in `seam/update.sh`; the current subkey comes from the
  release folder). Until 2026-11-12 TLS alone vouched for the archive.
- The dock's posture (already landed/staged): secrets never recorded
  (#53), network fetches hardened (#54), state dirs 0700 (#55), root
  channels data-validated (audited), corrupt state preserved not lost
  (#49).
- Updates: an update story that keeps nixpkgs security patches flowing
  is itself a security feature — the S7 upgrade design item inherits a
  security requirement.

## Standing rules (apply to every new feature)

1. Anything that lets the UI change the SYSTEM goes through a root
   helper that reads user input as validated DATA and generates the
   code itself. Never eval user-writable files.
2. Anything that records user content (clipboard, notifications,
   history) must: honor sensitivity hints, live in 0700 dirs, be
   bounded, and be sweepable.
3. Anything that touches the network treats every target as hostile:
   protocol pinning, size caps, private-range refusal, timeouts —
   and defaults to OFF when it's a convenience.
4. Every security property gets a drill or an assertion in a harness
   (`~/Golem/docs/shell/dockmenu/harness/` today; grow per component).
