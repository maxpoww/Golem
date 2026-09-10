# GolemSecurity — the security model and roadmap

> Max, 2026-09-09: "we need Golem to be secure as fuck. super secure in
> general for all users." This file is the model, the phases, and the
> standing rules. Component-level detail for the dock lives in
> `~/GolemOne/DockMenu/SECURITY.md`; findings carry changes.md numbers.

## The threat model, in one paragraph

Golem is a single-owner desktop. The assets are the owner's data and the
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
  authorized keys and `PermitRootLogin no`.
- sudo requires a password (no NOPASSWD anywhere in shipped config).
- Firewall on by default; no listening services beyond what a feature
  explicitly declares.
- Disk encryption offered by the installer (owner's choice, default on
  for laptops).
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
   (`~/GolemOne/DockMenu/harness/` today; grow per component).
