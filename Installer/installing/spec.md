# Spec — modular Golem and the chooser

WHAT the Installing program builds and WHY it is shaped this way. The
HOW-in-order is [implementation.md](implementation.md); the parent
install spec remains `~/Golem/GolemInstall.md`; the app-bundle side is
`~/Golem/GolemModules.md`.

## The principle (Max, 2026-09-10)

> One module for systemd-boot, another for GRUB, one for nvidia,
> another for amd, another for intel, another for dual-GPU config,
> another for battery and energy, another for locale, one for zram,
> another for swap — and where today one file computes 3–4 zram
> configurations from RAM, we need ONE MODULE PER MODEL. Golem
> preinstall finds out the pc and POINTS (1, 2, 3…) to the module that
> has to be installed.

Formalized:

1. **A module is a leaf.** Concrete values only. No conditionals, no
   formulas, no reading of `golem.hardware`. Its header comment states
   its parameters and who should be pointed at it.
2. **The chooser is the only brain.** It reads the census facts and the
   user's answers, and emits pointers. Every rule that today lives as
   `mkIf`/arithmetic inside `~/Golem/system/*.nix` migrates INTO the
   chooser as an explicit facts→leaf mapping.
3. **The pointer list is the machine.** `hosts/target/modules.nix` is a
   plain imports list — the third dropped file becomes the machine's
   readable identity. The facts file stays as evidence; the module
   list is the decision record.

## The module tree (`~/Golem/system/modules/`)

Leaves grouped by concern; exactly one leaf per group is chosen unless
marked (∅ = choosing none is valid, + = additive, any number):

```
base/            — always chosen, stage 0
  network.nix        NetworkManager, the golem-lab profile's product twin
  ssh.nix            sshd key-only (lab key only when --lab-ssh asked)
  zsh.nix            Golem's zsh, exactly as the dev box has it
  users.nix          owner from answers, uid 1000, wheel
  console.nix        keymap/font from answers
  nix.nix            flakes, trusted settings, gc policy
  selfrebuild.nix    the seed contract + appliers + the seal (#56/#58/#61)
boot/
  systemd-boot.nix | grub-bios.nix
cpu/
  intel-microcode.nix | amd-microcode.nix
gpu/
  intel.nix | intel-legacy.nix | amd.nix | nvidia.nix | nouveau-floor.nix | virtio.nix
gpu2/  (∅)
  offload.nix | hold.nix | off.nix        (hold/off = the #33 pair)
memory/          — ONE LEAF PER TIER, values said out loud
  zram-tier1.nix     (<4 GB   — swappiness 180, cache-pressure 50, …)
  zram-tier2.nix     (4–8 GB  — …)
  zram-tier3.nix     (8–16 GB — swappiness 60, cache-pressure 10, …)
  zram-tier4.nix     (>16 GB  — …)
  (exact values lifted verbatim from today's memory.nix computation —
   the migration is relocation, not retuning; tier count = however
   many distinct shapes the current formula actually produces)
swap/
  hibernation.nix    resume wiring (partition sizing stays engine-side)
disk/
  hdd.nix | ssd.nix  (bfq-on-rotational vs default; trim policy)
power/  (+)
  laptop.nix | desktop.nix ; thermald.nix (∅) ; lid.nix
quirks/  (∅, +)
  broadcom-wl.nix, and siblings as machines demand them
locale/
  (data-driven from machine.nix — one mechanism module, answers carry
   the values; locales are answers, not hardware)
desktop/  (stage 1, + )
  hyprland.nix, waveview.nix, waverunner.nix, greeter.nix
programs/ (stage 2, +, owner-chosen)
  curate.nix, golem-modules bundles (GolemModules.md)
```

Growth rule inherited from the census: **add a leaf when a machine
demands it, against its fixture** — speculative leaves rot.

## The chooser

`golem-hw-choose` — grows out of the proven decide machinery (same
probes, same facts; the logic RELOCATES, it is not rewritten). Input:
`golem-hardware.nix` + the answers. Output:

```nix
# hosts/target/modules.nix — written by golem-hw-choose. The machine.
{ ... }: {
  imports = [
    ../../system/modules/boot/grub-bios.nix
    ../../system/modules/cpu/intel-microcode.nix
    ../../system/modules/gpu/intel-legacy.nix
    ../../system/modules/memory/zram-tier1.nix
    …
  ];
}
```

Contracts:

- **Total:** every group resolves to exactly one leaf (or a recorded ∅)
  — an unmatchable machine is a loud FAIL at choose time, never a
  silent default.
- **Explained:** each pointer carries a one-line WHY as a comment
  (`# ramMB=1931 → tier1`) — the reveal rule applied to the file.
- **Asserted:** the eval matrix pins every fixture machine to its
  exact expected list (acer, hp, dell, comodore, macbook, asus,
  thinkpad, lenovo, vm shapes). A chooser change that moves any
  machine's list is visible in review by design.
- **Revealed:** the confirm screen's decision rows read from the same
  choice the file records — one source, never two.

## The stage ladder

- **Stage 0 (minimal):** `base/*` + one leaf from boot/cpu/gpu/memory/
  swap/disk/power (+quirks as demanded). Definition of done: boots,
  SSH reachable, `nixos-rebuild` works from its own seed,
  `is-system-running` clean, zsh is Golem's, census facts re-derivable
  on the installed system.
- **Stage 1 (desktop):** + `desktop/*`, applied by rebuild. Done =
  waverunner desktop functional at that machine's GPU class, DockMenu
  harness green, a human hour survived.
  - **Hardware gate (2026-09-26):** the desktop is Hyprland, which needs
    **OpenGL ES 3.x**. That excludes pre-GLES3 GPUs — Intel gen ≤ 5/6 and
    dead dGPUs. Confirmed floor machines that STAY stage-0 (headless, never
    graduate to Hyprland): **comodore** (GMA 4500, gen 4, +1.9 GB RAM) and
    **HP Pavilion dm4** (Intel Ironlake, gen 5 — kernel: `Found ironlake`;
    its Radeon HD 6370M is dead, accel disabled). Desktop-capable: Intel
    gen 7+ (Haswell/Broadwell — macbook, acer, asus), modern AMD (thinkpad
    Renoir), nvidia (lenovo). A graphical session for the floor, if ever
    wanted, must be a lighter compositor (gles2 / framebuffer), not Hyprland.
- **Stage 2 (programs):** + owner-chosen `programs/*` through the dock
  and the Modules feature. Done = install/uninstall round-trips clean
  (the #37–#61 invariants hold on this machine).

## Migration policy

The fat, fact-keyed system stays as-is and keeps the ASUS alive — it is
the reference, not the enemy. Minimal is built as the new composition
beside it. Each stage-1/2 concern moves INTO a leaf as it is added to
the ladder; nothing flag-days. When the last concern migrates, the old
`mkIf` gating retires and `golem.lean` dies with it (finding #1 closes
structurally on that day).
