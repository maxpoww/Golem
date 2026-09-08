# GolemModules — software bundles, as a spec

> Design doc for a new BUILD item on `apps.md`: **checking a box gives you
> the whole thing** — packages, system config and tweaks together, not just
> a package. Written 2026-09-08 at Max's direction ("modules — check a box,
> get the whole thing"), companion to `GolemInstall.md` (the hardware half
> of this exact idea, already shipped) and `apps.md` (the app set this
> extends). Everything cited to a file in this repo is checkable.
>
> Status: SPEC. Nothing below is built yet — this is the catalog/scope pass
> before any Nix or UI work starts.

## 1. The idea

A fresh Golem install should stay clean: nobody wants Steam, virt-manager
and DaVinci Resolve pre-seeded on a laptop that will only ever browse and
write documents. But the moment someone DOES want to game, or edit video,
or run VMs, they should get more than a package — they should get the
*correct machine* for that purpose: the packages, the system services, the
group memberships, the kernel bits, the tweaks a forum thread would
otherwise walk them through one Stack Overflow answer at a time.

Concretely, from a `Modules` surface in waverunner: pick a category
(Gaming, Virtualization, Video Editing, Office, Security, Image Editing,
Artificial Intelligence, Local AI, …), check the tools wanted inside it
(Steam, Proton, Lutris… / DaVinci Resolve, Kdenlive… / libvirtd, QEMU,
virt-manager…), hit Add. One rebuild later the machine has the software
AND is configured for it.

## 2. The one rule

**Options, never arbitrary Nix.** Exactly the discipline `GolemInstall.md`
§2 already proved for hardware ("facts, never text assembly") applied to
software: the UI never generates configuration and never installs anything
that wasn't already authored, reviewed and committed to this flake. The
only thing a user action ever does is flip a pre-declared boolean —
`golem.modules.<category>.<tool>.enable` — against a **closed set** of
options that exist in the evaluated config. This is the same trust
boundary `waverunner-apply.nix` already enforces for packages (§3), moved
up one level: instead of validating "is this a legal nixpkgs attr name,"
the apply step validates "is this a real, already-declared module option."
A category cannot contain a tool nobody has written config for yet —
scoping the catalog (§5) IS the engineering work, not a formality in front
of it.

Consequence that matters as much as it did for hardware: **one code path**.
A module's config is `mkIf`-gated and permanently imported, so it is
reviewed once, tested once (fake the flag the way `hosts/vm.nix` fakes
hardware facts), and correct for every machine that ever checks that box —
not reconstructed per install the way a forum answer is.

## 3. What already exists (credit where built — this grows it, not invents it)

| Piece | Where | State |
|---|---|---|
| The gated-module pattern itself: one family per file, permanently imported, internally `mkIf`-gated on a fact, every value `mkDefault` | `system/hardware/*.nix`, spec'd in `GolemInstall.md` §5 | built — this doc's `system/modules/*.nix` is the same pattern, gated on a user *choice* instead of a hardware *fact* |
| The declarative-install pipeline: user-writable selection file → `systemd.path` watch → root validates → regenerates a tracked Nix file → `nixos-rebuild switch` → snapshot last-good on success / restore on failure → status JSON back to the UI | `system/waverunner-apply.nix` | built — today it only ever emits a flat `home.packages` list; §6 generalizes it to flip option booleans instead |
| "Clean fresh install" is already policy, not aspiration: `golem.lean` strips the launcher-installed list and the non-essential CURATE set for the ISO; an installed machine starts from nothing and grows only through user action | `system/configuration.nix` (`golem.lean`) | built |
| The UI half already ships: waverunner's **Install section**, described in `apps.md` as `Software center — ✔ shipped`, drives `waverunner-apply.nix` today by writing `packages.list` | `apps.md` (BUILD table), `~/launcher` (out of scope for this repo — see §9) | built, single-tier |
| Rebuild-vs-reboot honesty: `rebuild-golem` already diagnoses "activated == latest" vs "REBOOT REQUIRED" by comparing `/run/current-system`, the system profile and `/run/booted-system` | `system/configuration.nix` (`rebuild-golem` script) | built — §7 reuses this signal for modules that need more than a rebuild |

## 4. The category catalog

Confirmed categories (named directly): **Gaming, Virtualization, Video
Editing, Office, Security, Image Editing, Artificial Intelligence, Local
AI.** Below is a first pass at what each contains and, honestly, what's
known vs. still needs research — the same "unknown means the safe default,
not a guess" ethos `GolemInstall.md` §7 applies to hardware applies here to
software: a tool this doc hasn't actually verified stays a **candidate**,
not a shipped checkbox, until someone builds and rebuilds with it on real
or VM hardware.

### 4.1 Gaming
**Shared plumbing (category-level, on if any tool below is checked):**
`hardware.graphics.enable32Bit` (Proton needs the 32-bit stack),
`programs.gamemode.enable`, `programs.gamescope.enable`.
**Tools:** Steam (`programs.steam.enable` — this is itself already a NixOS
module that wires firewall ports and the FHS wrapper correctly, so the
"tool" here mostly *is* the option), Proton/Proton-GE (rides Steam; may
just be a Steam sub-toggle rather than its own checkbox), Lutris, Heroic
(Epic/GOG), MangoHud (perf overlay), a controller-config note (`hardware.
uinput.enable` already on for golem-connectd — confirm no conflict).
**Hardware gate:** old-hardware honesty — a machine `golem.hardware.gpu`
reports as pre-Turing nouveau-floor or ancient Intel should see this
category with a visible caveat, not a silent invitation to install Steam
onto a GPU that will chug (same posture as the [[golem-show-linux-trauma-hardware-working]] rule: reveal it, don't hide it, don't oversell it).

### 4.2 Virtualization
**Shared plumbing:** `virtualisation.libvirtd.enable`,
`users.users.${owner}.extraGroups = [ "libvirtd" ]` (needs re-login, not
just rebuild — flag for §7), `virtualisation.spiceUSBRedirection.enable`.
**Tools:** virt-manager (GUI), QEMU/KVM (rides libvirtd), `virtualisation.
docker.enable` or podman as a separate "Containers" toggle (own group,
own re-login caveat), `virtualisation.waydroid.enable` (Android app
compat — genuinely useful on a distro courting Android-adjacent users per
the phone-as-lab-driver work) as a candidate.
**Hardware gate:** KVM needs `vmx`/`svm` in `/proc/cpuinfo` — worth a real
check (`golem.hardware.cpuVendor` already exists; a `virtEnabled` fact is
a cheap addition) so the box is honestly greyed out on hardware without
hardware virtualization rather than installing a stack that can't run.

### 4.3 Video Editing
**Tools:** Kdenlive (native nixpkgs package, straightforward), Shotcut
(same), DaVinci Resolve (candidate, **research flag**: historically
unfree/FHS-wrapper-only in nixpkgs and GPU-driver-picky — needs a real
build-and-run pass before it's a checkbox, not a promise), OBS Studio
(recording/streaming — arguably belongs here AND in a future
"Streaming/Content" category; parking it here for now).
**Hardware gate:** VA-API/NVENC hardware encode matters a lot on old CPUs
— worth surfacing which encode path a machine actually has, mirroring the
`gpu-nvidia.nix`/`gpu-intel.nix` VA-API wiring that already exists.

### 4.4 Office
**Tools:** LibreOffice (currently `apps.md`'s explicit "NOT shipped by
default, one drag away in Install section" — this category is arguably
where that promise should actually live), OnlyOffice as an alternate pick
(better MS-format fidelity — pick one, per `apps.md`'s "pick one after
trying" convention used for the media apps).
**Note:** this is the lightest category — mostly a packages-only module,
little config beyond MIME/default-app wiring (`apps.md` item 3, already
planned).

### 4.5 Security
**Tools:** KeePassXC (password manager), a VPN client (WireGuard is
already close to zero-config via `networking.wireguard`; the checkbox is
really "make it easy," not "make it possible"), Wireshark (needs the
`wireshark` group + capability setup, not just the package — a real config
tool, good proof case for "module ≠ package"), a firewall-rules-visibility
tool. **Research flag:** this category most needs a scope conversation
with Max — "security" spans password hygiene, network privacy and
pentesting-adjacent tools, which are different audiences.

### 4.6 Image Editing
**Tools:** GIMP, Krita, Inkscape (vector), darktable or RawTherapee (RAW
photo) — all straightforward nixpkgs packages, config is mostly
plugin/color-profile defaults. Lowest-risk category to build first: no
group memberships, no kernel bits, no reboot story — pure proof of the
mechanism before tackling the categories with real system config.

### 4.7 Artificial Intelligence
Reads as **cloud/API-backed AI tools** distinct from 4.8: chat clients,
API-key-holding assistants, agent CLIs. Config here is mostly desktop
integration (webapp entries — `apps.md`'s WEBAPP catalog already covers
Claude/ChatGPT/Gemini as webapps) plus maybe CLI tooling
(`claude-code`-style installs). **Open question (§8):** does this
category overlap the WEBAPP catalog enough that it's not really a
"module" at all — worth resolving before authoring it.

### 4.8 Local AI
On-device inference: Ollama (`services.ollama.enable` already exists
upstream in nixpkgs with a `hardware`/`acceleration` option worth reusing
rather than re-inventing), llama.cpp, a local web UI (Open WebUI or
similar). **Hardware gate is the whole story here:** Golem's stated
priority is broad old-hardware support ([[golem-north-star-and-rounds]]) —
most of the lab fleet cannot run useful local models. This category must
be the most honest about it: CPU-only inference offered without
inflated promises, GPU acceleration only where `golem.hardware.gpu`
actually supports it (nvidia CUDA / ROCm), and a plain "this will be slow
on this machine" note rather than silence, matching the reveal-and-affirm
posture already set for hardware.

### 4.9 Proposed additions (not yet confirmed — flagging, not deciding)
Development toolchains (language runtimes + editors, likely overlaps
existing dev habits from the ACTIONS research), Audio Production (Ardour,
Reaper-via-wine candidates), 3D/CAD (Blender, FreeCAD). Left out of the
confirmed list until Max says which of these earn a slot.

## 5. Naming & file layout

```
system/modules/
  gaming.nix
  virtualization.nix
  video-editing.nix
  office.nix
  security.nix
  image-editing.nix
  ai.nix
  local-ai.nix
```

Each declares, per tool: `options.golem.modules.<category>.<tool>.enable =
lib.mkEnableOption "<human label — this doubles as UI catalog text, see
§8>";` and `config = lib.mkIf cfg.enable { … };`. Category-level shared
plumbing (§4.1/4.2's "shared" blocks) is `mkIf (lib.any (t: t.enable)
(builtins.attrValues cfg.tools))` — on if anything in the category is, off
otherwise. All permanently imported into `system/configuration.nix`
alongside the existing `./hardware/*.nix` imports — same list, same
pattern, new subdirectory.

## 6. The apply pipeline — generalizing `waverunner-apply.nix`

A new `system/golem-modules-apply.nix`, sibling to (not a rewrite of)
`waverunner-apply.nix` — packages and modules are different enough
surfaces (arbitrary attr names vs. a closed option set) that keeping them
separate services is simpler than merging:

- **Selection file:** `~/.config/golem/modules.list`, user-writable, one
  `golem.modules.<category>.<tool>` token per line (mirrors the
  attr-per-line shape of `packages.list`).
- **Validation:** for each line, confirm it names a real, currently
  evaluated `.enable` option (a closed set baked into the generated file
  at build time, or checked via a small `nix eval --json` of
  `options.golem.modules` — needs picking one; either keeps the "never
  interpret user text as code" rule `waverunner-apply.nix` already
  states). Anything else is dropped and logged, exactly like an invalid
  package name is today.
- **Generate → git add → `nixos-rebuild switch` → snapshot/restore
  last-good → status JSON** — identical shape to §3's existing pipeline,
  same atomicity guarantee (a failed switch never leaves the tree
  unbuildable).
- **One rebuild per Add, not per checkbox** — the UI stages checks locally
  and writes the whole desired state on one user action, the same way
  today's Install section presumably batches (worth confirming against
  the real waverunner code, out of reach from this repo — §9).

## 7. What a rebuild alone doesn't finish

Some modules need more than `nixos-rebuild switch` to be actually usable,
and the status the UI shows must say so rather than declare victory early:

- **Group membership** (`libvirtd`, `docker`, `wireshark`) only takes
  effect on the next login — the existing `rebuild-golem` script's
  activated-vs-booted check (§3) covers *kernel/reboot* drift; a parallel
  *groups-changed-since-last-login* check is new work, not a reuse.
- **Reboot required** (kernel modules, bootloader-relevant changes) —
  `rebuild-golem` already detects and prints this; the module UI needs to
  surface it as a real status, not swallow it into a generic "done."
- **Hardware that can't back the choice** (§4.1/4.2/4.8's gates) — belongs
  as a visible, honest caveat on the checkbox itself, before the user ever
  clicks Add, not a failure after the rebuild runs.

## 8. UI surface (spec only — not built from this repo, see §9)

What the Modules screen needs, so the catalog above is usable data and not
just prose:
- Per category: label, one-line description, icon.
- Per tool: label (`mkEnableOption`'s string is a real candidate — single
  source of truth instead of a hand-maintained duplicate), one-line
  description, a size/weight hint, a reboot-required flag, a
  hardware-gate warning string when relevant (§4's gates).
- Stage-then-Add interaction (§6), and a status readout reusing
  `apply-status.json`'s shape (phase/ok/error) the same way the Install
  section presumably already renders it.

Whether AI (4.7) is really a "module" at all versus already covered by the
WEBAPP catalog (§4.7's open question) is a UI-side judgment call as much
as a Nix one — worth settling before that category gets authored.

## 9. Out of reach from here

This repo cannot touch `~/launcher` (waverunner's UI code — a standing
sandbox limit, see [[golem-agent-sandbox-limits]]). Everything in §5–§8 is
buildable and testable from `~/Golem` alone (fake the option the way
`hosts/vm.nix` fakes hardware facts, verify with `nixos-rebuild
build-vm`); the actual Modules screen is a separate session against the
launcher checkout, consuming whatever catalog format §8 settles on.

## Non-goals / open calls

- No category ships until its tools are real, tested config — a name in
  §4 is a candidate, not a promise (mirrors `GolemInstall.md` §7's "the
  line gets drawn after the numbers are measured").
- No arbitrary user-authored modules — every checkbox is code Max (or
  Claude, reviewed) wrote and committed, per §2. This is deliberately not
  as open-ended as a package manager; it's a curated set, same spirit as
  `apps.md`'s CURATE column.
- **Open, Max's call:** build order (§4.6 Image Editing is the lowest-risk
  first real category — no groups, no reboot, no hardware gate — good
  proof-of-mechanism before Gaming/Virtualization's harder cases); the
  §4.7 vs WEBAPP overlap question; whether §4.9's proposed categories ship
  at all.
