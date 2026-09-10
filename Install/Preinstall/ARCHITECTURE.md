# Architecture — how the preinstaller is put together

Everything lives in `~/Golem/Installer/preinstall/` unless noted. The
one-page census reference (every fact and every decision) is
`testing/list.md`.

## The flake (`flake.nix`)

The ISO is `nix build .#iso` from this directory. Inputs:

- `golem = path:../../` — **the parent repo is the single pin.** Every
  other input `follows` golem's own lock (`nixpkgs`, `home-manager`,
  `waverunner`, `waveview-src`, + waverunner's sub-inputs). One pin,
  upstairs; the medium can never drift from what it installs.
- The inputs are declared here (not just reached through golem) because
  the medium needs their **store paths**: the offline eval on the stick
  pins each one with `--override-input` instead of fetching github.
  `offlineSeed` (a linkFarm) drags them all into the image's store and
  doubles as a browsable `/etc/golem/inputs`.
- `overrideArgs` — the pin table as CLI args, shared by decide and
  install so "what the audit evaluated" and "what the engine builds"
  cannot be two different systems.

**THE TRAP:** a locked `path:` input is never re-read by `nix build`.
`nix flake update` before every cut, always (OPERATIONS.md).

## The image (`iso.nix`, `iso-image-golem.nix`, `grub-theme.nix`)

Minimal console medium ("MiniGolem"): stock installation-cd-minimal
behavior (autologin `nixos` on tty1), two-entry no-timeout boot menu
(vendored in `iso-image-golem.nix`), lab SSH keys baked for `root` and
`nixos`, the lab wifi profile (`golem-lab`, open HOLA by default;
`GOLEM_LAB_WIFI_SSID/PSK` env at build for others), hostname
`golem-installer`, volume id `GOLEM_INST`. The getty helpLine prints
the machine's IPv4 (`\4`) — the console tells you where to SSH.

Deliberately separate from the full live ISO (`~/Golem#iso`); they
merge later by decision, not drift (see the PLAN.md separation rule).

## Boot: census → decision (audit.nix → decide.nix, evidence.nix)

- `golem-audit.service` runs at boot: `golem-hw-detect` (from
  `~/Golem/system/hardware-detect.nix` — the same probe the installed
  system uses) writes **facts** to
  `/var/log/golem-audit/golem-hardware.nix`; `golem-hw-decide`
  evaluates the real target config against those facts and writes
  `decision.json`/`summary.txt`; status lands in
  `/var/log/golem-audit/status` (`ok` | `FAILED at: …`).
- Facts are things like: cpu/cores/threads/ramMB, gpu + gpu2 +
  gpu2Health (the force-cold suspend/resume probe), intelLegacy,
  firmware (bios/uefi), panelDpi, hasBluetooth (sysfs ∨ rfkill ∨ USB
  class e0 — triangulated), cpuVendor, chassis, vmGuest.
- `golem-hw-evidence` (evidence.nix) is the raw dump (lspci -vv, lsusb,
  dmidecode, input devices) for fixtures — run as root.

## The surface (`mockup/install-cli` → `setup.nix` → `golem-setup`)

One bash script is the source of truth; `setup.nix` wraps it as
`golem-setup` (the wrapper carries env; the real script is
`libexec/golem-setup-unwrapped` — grep THAT for markers). Six screens:
language (rotating invitation, type-to-filter), timezone (clock as
evidence), keyboard, drive (never the boot medium, never tiny devices'
— see R6 note in vm.md — title says exactly what will be erased),
device name (ghost default), user+password (hashed at the screen;
nothing downstream ever sees text). Then the confirm: answers + the
decision rows + the hardware reveal (name · driver — measured verdicts,
dimmed tails, honest absences), and `ENTER` hands everything to the
engine.

Key internals: `read_key` (all three F1 encodings; ESC=back everywhere;
Ctrl-C = leave once cleanly, #34), `pick()` (the fixed-height filter
list), the reveal builders (`hw_pci`, `reveal_gpus`, `hw_bt`, `hw_wifi`
— PCI first, USB fallback, `hw_input` two-tier touchpad), i18n via the
`S[lang:key]` table + `t` (all six languages, #18 — never hardcode a
string). Answers accumulate in `/tmp/golem-answers` (a sourceable
GOLEM_* file) + `/tmp/golem-machine.nix`.

`GOLEM_REHEARSE=1` is baked into the stick's wrapper: ENTER on the
confirm REHEARSES (writes nothing, bundles
`/var/log/golem-rehearsal/`). A real install runs the engine directly
with a clean env.

## The engine (`install.nix` → `golem-install`)

Phases `##golem 1/6..6/6`: format (wipefs+GPT: ESP 512M on UEFI /
bios-boot 1M on BIOS; swap sized for hibernation; root; optional LUKS2
single-container+LVM — refused on BIOS), fs, seed (copies the golem
checkout to `/mnt/home/<owner>/Golem`), probe (drops
`hosts/target/{golem-hardware,hardware-configuration,machine}.nix` +
`postinstall-questions.json` into the seed), eval/install (local when
RAM allows; bootloader per firmware: systemd-boot / GRUB via by-id with
/dev fallback, #19), done.

**The seams** (flags, not forks): `--rehearse` (shadow tree, the six
preflight checks, the eval — writes nothing), `--prepare-only` (stop
after phase 4 — the closure gets DELIVERED next: `nix copy` from a dev
box in the lab, a carried closure on a product stick), `--skip-prepare
--system PATH` (resume: bootloader + finish; header reads the hostname
from the seed, R5-2). `--answers FILE` joins the surface to the engine;
`--lab-ssh KEY` wires a driving key into machine.nix.

Preflight checks (rehearsal AND real): firmware/bootloader match,
target ≠ boot medium, fit, RAM floor (#16 — refuses to eval on <~3.3
GB), facts match the boot audit, eval instantiates. `checks.txt` is
always read first.

## The target (`~/Golem/hosts/target/`)

`nixosConfigurations.golem-target` exists only when
`hardware-configuration.nix` is present (a published repo must `flake
check` green). The machine surface is exactly the dropped files: facts
in, evaluation out, no assembled configuration prose. **A git flake
sees only tracked files** — on a dev box the dropped files must be
`git add`ed (staged, never committed) or the attr does not exist.

## Postinstall (the ask framework, `postinstall-questions.nix` + `~/Golem/system/postinstall.nix`)

Questions the installer could not answer for the user ride as DATA
(`postinstall-questions.json`, generated from facts — e.g.
`gpu2-failing-action` when a dGPU fails its wake test; default `hold`).
On the installed system: a user service asks at first graphical login;
answers land in `postinstall-answers.json`; a root path unit fires the
apply → validates answers against the shipped question set → generates
`postinstall-generated.nix` (imported path-conditionally, #35) →
`nixos-rebuild switch` → **`verify_effect`** confirms the switched
system actually contains what each answer implies before `ok:true`
(#35c). The seal gate (#56) guards every unattended rebuild.
