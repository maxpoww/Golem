# Changes — the Installing ledger

The deferred queue for the next ISO, exactly as preinstall ran it
(archived original: `~/GolemOne/Install/Preinstall/testing/changes.md`).
**The number line is one line:** #1–#61 live in the preinstall archive
and DockMenu's FINDINGS.md; this file continues at **#62**. Round-scoped
surface items are `I<round>-<n>`.

## How to use this file

- While a round runs, a finding's raw experience goes in the machine's
  file; the CHANGE it implies lands here: what / why (which finding,
  which machine) / where (file:location) / size (small · medium ·
  needs-Max). Status rides the header tag.
- Nothing lands in an ISO mid-round. Round closes → work the queue top
  to bottom → `nix flake update` → rebuild → verify the built artifact
  → VM gate → reflash → move applied entries below with their round.
- Waverunner-side fixes ride the launcher → Golem lock → seed pipeline
  and are marked with their launcher rev.
- The live-fix refinement applies: a queued fix may be verified on a
  booted machine as a RAM overlay / seed update, marked
  **[verified live on <machine>]** — the frozen stick still never
  reburns mid-round.

## Queued for the next ISO

### 67. A multi-GB closure delivery over a USB WIFI DONGLE kills the machine — two machines, same night, same signature — [FOUND 2026-09-11 · lab-method finding, not a Golem bug]
**The dell and the comodore both died mid-`nix copy`**, minutes apart in
behaviour: transfer stalls → `error: write of N bytes: Broken pipe` →
the machine drops OFF the network entirely and does not return (needs a
physical power-cycle).
- **common factor:** both were receiving a ~3 GiB closure over a **USB
  wifi dongle** (dell: rtw88_8821au; comodore: rtl8187). The dell was
  also writing to a USB drive (double USB load); the comodore wrote to
  its internal SATA, so the dongle alone is sufficient to trigger it.
- **the control:** the ASUS took the same 2.93 GiB delivery over its
  **internal** ath9k card and finished clean. So: internal radio fine,
  USB dongle fatal.
- **measured pathology before the comodore's death:** ~25 KB/s
  sustained (188 MB in ~48 min of a 2.95 GiB closure — a ~30 h ETA),
  i.e. the link was already collapsing long before the drop; this is
  not merely "slow old hardware".
- **not a Golem bug** — it is the LAB's delivery method meeting weak
  USB stacks. But it shapes real work: the offline installer exists
  precisely so a machine never needs a 3 GiB network delivery, and
  these two machines are the argument for it.
- **workarounds, in order:** (a) internal NIC/ethernet where one
  exists; (b) **sneakernet** — write the closure to a USB drive from
  the dev box and import locally on the target (no network in the
  path); (c) batched, resumable delivery — one path at a time with
  retries, so drops cost seconds instead of the whole transfer (script
  written this session, unused so far:
  `scratchpad/overnight-copy.sh`).
- **where:** lab method (OPERATIONS-level), plus the offline-installer
  design rationale in implementation.md step 8e.
- **size:** no source change owed. Record + method change.

### 66. The #16 RAM floor refused a PREPARE that never evaluates — the guard fired on the wrong verb — [FIXED in source 2026-09-11 · live-fixed on the comodore]
**Found on the comodore's first real install (1931 MB):** `golem-install
--prepare-only` died at the preflight with *"this machine has 1931 MB —
installing Golem needs about 4 GB of RAM"*, before touching the disk.
- **why it was wrong:** #16's floor exists because a small machine
  cannot EVALUATE the target config locally without thrashing. But
  `--prepare-only` evaluates nothing — it partitions, mounts, seeds and
  drops the target files; the system is BUILT ELSEWHERE and delivered
  (`nix copy` — the closure-delivery seam used since the ASUS, and the
  shape a product stick will use). Same for a `--skip-prepare` resume:
  it activates a closure that already exists. So the check was gating
  the wrong verb — refusing an install that was never going to thrash
  the machine.
- **fix (applied):** the floor now distinguishes `eval_is_local`. A
  local-eval install still hard-FAILS below 3300 MB (unchanged, and a
  rehearsal still records the finding); a delivery-seam run
  (`--prepare-only` / `--skip-prepare`) records an honest **warn** —
  *"below the local-eval floor — fine here: this run does not evaluate
  (the system is built elsewhere and delivered)"* — and proceeds.
  Nothing is silently skipped; checks.txt still tells the truth.
- **why it matters beyond tonight:** this is exactly the distinction
  the OFFLINE INSTALLER needs — "can this machine eval?" vs "can it
  receive a prebuilt system?". Answering it here means the offline work
  inherits a preflight that already asks the right question.
- **where:** `Installer/preinstall/install.nix` (the ram check).
- **size:** done. Live-fixed on the comodore (patched golem-install
  nix-copied onto the running medium — the constitution's live-fix
  refinement, the frozen stick untouched); ships in the next cut.

### 65. Minimal boots to a BLANK console — fbcon=map:1 maps the tty to a framebuffer that doesn't exist — [FOUND + FIXED LIVE on the acer, first metal · 2026-09-10]
**The most important find of the first metal install, and the textbook
minimal-first catch.** The installed acer showed systemd-boot, then a
dead screen — no login ever drew. Max typed the login + `nmcli`
BLINDLY and it worked: the system was fully up and SSH-reachable the
whole time (running, 0 failed units) — only the display was dark.
- **root cause (read-only diagnosis):** `fbcon=map:1` in the kernel
  params (base/core.nix) maps the framebuffer console to fb**1**; the
  acer has only fb0 (`i915drmfb`), so getty@tty1 renders to nowhere.
  The param — plus `splash` — rode in VERBATIM from the fat config,
  where greetd→Hyprland takes the screen through KMS and a mapped-away
  fbcon is invisible-and-harmless. On minimal there is no compositor:
  **fbcon IS the display**, so the same param is invisible-and-FATAL.
- **fix (APPLIED to source + verified live):** drop `fbcon=map:1` and
  `splash` from `base/core.nix`; keep the log-quieting params (quiet,
  not blank). Built the fixed toplevel, updated the acer's seed,
  self-rebuilt `#golem-minimal` → gen 3, rebooted → **Max saw boot
  loader → quiet blank → `login:` → zsh on the acer's own screen.**
  Running kernel has no fbcon=map:1; vtconsole is `(M) frame buffer
  device` not the dummy. The desktop stage (I2) re-adds its own
  clean-boot handoff and should reconsider whether fbcon=map is the
  right mechanism on a single-framebuffer machine at all.
- **where:** `system/Modular/base/core.nix` (done). Ships in the I2 cut.
- **size:** done. The self-rebuild that applied it also proved stage-0
  self-rebuild on metal.

### 64. A lab-installed minimal has no wifi — unreachable for the remote first-boot audit — [FIXED in source 2026-09-11 · --lab-wifi · ships in the I2 cut]
**APPLIED (2026-09-11):** `golem-install` gained `--lab-wifi SSID`,
mirroring `--lab-ssh`. It writes an OPEN NetworkManager profile
(`golem-lab`, autoconnect) into the installed `machine.nix`, so a lab
testbed auto-joins after reboot and is reachable over SSH with NO
keyboard — which is exactly what the dell (broken keyboard: only
e/g/i/Enter/Backspace) forces. Lab-only; a stranger's install gets none
of it (they pick their own wifi). Carries `autoconnect-retries = 0`
(infinite) so a slow driver/AP at boot can't exhaust NM's default 4 —
the cheap half of #63, ridden along here where it's free. `where`:
install.nix (arg + the machine.nix writer, beside the --lab-ssh block).
Original finding below.

The installed stage-0 acer booted healthy but off the network: the
`golem-lab` wifi profile lives on the INSTALLER medium (iso.nix), not
in the installed config, and minimal has no GUI to connect from. Had to
connect it at the keyboard (`nmcli device wifi connect HOLA`) to audit
over SSH. `--lab-ssh` already wires the lab KEY into machine.nix; the
lab needs the same for the lab WIFI so an installed lab machine is
reachable without a keyboard trip.
- **fix (queued):** a `--lab-wifi` that writes the golem-lab profile
  (open, or the baked PSK) into the installed `machine.nix`, gated the
  same way `--lab-ssh` is — lab-only, never on a shipped image
  (GolemSecurity phase 3). A real user connects to their own wifi; this
  is purely a lab-reachability affordance.
- **where:** `Installer/preinstall/install.nix` (arg + the machine.nix
  writer) — mirrors the `--lab-ssh` block.
- **size:** small. Ships in the I2 cut.

### 63. The lab medium sometimes doesn't join the network by itself — [DOWNGRADED to UNCONFIRMED 2026-09-11 · my detection was broken · re-verify before fixing]
**CORRECTION (2026-09-11, the thinkpad sweep):** the thinkpad joined
HOLA on its own, no bounce — and that exposed that my own reachability
checks were the unreliable part: `zsh -c 'echo >/dev/tcp/host/22'` FAILS
UNCONDITIONALLY (zsh has no /dev/tcp; it is a bash-only feature), so
every "not on the network" reading I reported from those sweeps was a
false negative. The "medium doesn't auto-join" narrative was built on a
mix of Max's REAL nmtui bounces (acer + comodore, round 5 — genuine)
and my broken checks reinforcing it. So the finding is NOT dismissed
(Max did have to bounce real machines) but its SCOPE and ROOT CAUSE are
unconfirmed: I never captured the NM "giving up" log I claimed. Method
fixed (ssh/ping/bash only, never zsh /dev/tcp). **Re-verify with a
working check WHICH machines actually fail to auto-join, and capture the
real NM journal, before applying the autoconnect-retries=0 fix below.**
The fix is still plausible and cheap, but it must be earned by evidence,
not by my tooling error.
- **real evidence:** Max DID have to nmtui-bounce the acer and the
  comodore (round 5) — his own hands, not my check. So SOME machines
  don't auto-join. The thinkpad (2026-09-11) did, cleanly. Inconsistent
  across machines — which is itself a clue.
- **original theory (UNCONFIRMED — the plausible fix to earn):**
  `iso.nix`'s `golem-lab` profile sets
  `autoconnect = true` but no `connection.autoconnect-retries`, so it
  takes NM's **default of 4**. When the wifi driver isn't up yet
  (ath10k/ath9k firmware load is seconds) OR the AP/DHCP is momentarily
  busy at boot, NM spends all 4 attempts before the device/router is
  ready and then STOPS trying until a manual `nmcli con up`. Same
  mechanism hit the comodore's WIRED sky2 (NM's default wired profile,
  same default-4 retries, waiting on DHCP) — which is why "slow wifi
  driver" alone never explained it.
- **fix (queued, needs-verify):** set infinite retries so NM keeps
  trying until it gets an address, for BOTH the baked wifi profile and
  the default wired profile:
  - `iso.nix` golem-lab profile: `connection.autoconnect-retries = 0;`
  - global default (covers auto wired): `networking.networkmanager`
    connection defaults — `settings.connection."autoconnect-retries" =
    0;` (NetworkManager.conf `[connection]`).
  - belt-and-suspenders candidate: a `NetworkManager-wait-online`-ordered
    oneshot that `nmcli con up golem-lab` if still down after boot —
    decide whether the retry fix alone suffices first (verify on the
    machine that a giving-up log actually appears).
- **verify:** confirm on the acer's journal that NM logged
  "autoconnect: giving up" (or retries exhausted) at boot BEFORE
  committing the fix as root cause; then prove a rebuilt medium joins
  unattended across a cold boot on the slowest wifi machine (acer/asus).
- **where:** `Installer/preinstall/iso.nix` (the golem-lab profile +
  networkmanager settings). Medium-only — the installed system uses the
  owner's own wifi, but the same retries=0 default is worth carrying
  into `base/network.nix` so a stranger's flaky-AP first boot doesn't
  strand them either (decide at fix time).
- **size:** small (the profile line); the wired/global half + the
  optional nudge need a decision. Ships in the round-I2 cut (no
  mid-round reburn — the acer installs on the current stick with the
  manual bounce).

### 62. The installed minimal seed can't reproduce itself — the engine never dropped modules.nix, and golem-minimal never wired its self-rebuild loop — [FOUND + FIXED in source, pre-ISO · VM stage-0 self-rebuild proof, 2026-09-10]
Caught by round I1's first VM stage-0 install (UEFI, golem-minimal),
exactly by the self-rebuild proof the constitution mandates. Two holes,
both breaking "a stage-0 machine can rebuild itself":
- **the engine dropped no `modules.nix`.** Phase 4 wrote golem-hardware
  / hardware-configuration / machine / postinstall-questions, but the
  chooser wasn't part of the engine — so the installed seed had no
  pointer list, and its `golem-minimal` self-rebuild would evaluate
  base-only (no chosen hardware leaves). **Fix:** `install.nix` phase 4
  now runs the chooser (`nix eval … Modular/choose.nix … .rendered`)
  and drops `hosts/target/modules.nix` into the seed, from the same
  facts it just wrote. A chooser THROW (an unmatchable machine) warns
  rather than blocks — the fat golem-target doesn't need it; a minimal
  install would then fail visibly at its own rebuild with the reason.
- **golem-minimal never set flakeDir/flakeAttr.** It doesn't import
  `hosts/target/default.nix` (which wires the FAT target), so flakeDir
  stayed null → `selfrebuild.nix` emitted no `rebuild-golem`, and the
  machine had no way to rebuild at all. **Fix:** new leaf
  `Modular/base/loop.nix` (flakeDir = /home/owner/Golem, flakeAttr =
  golem-minimal), in the base composition. The machine now reproduces
  the composition it actually runs; stage 1/2 are rebuilds of THIS attr
  with more leaves in modules.nix.
- **proven the same session (UEFI VM):** after both fixes, the installed
  minimal rebuilt itself `#golem-minimal` from its seed → generation 2,
  `is-system-running: running`. The engine's chooser line is verified
  to emit the 7-module list; its LIVE drop is owed on the round-I1 recut
  (this session's stick predates the Modular work, so its seed's
  flake.nix had no golem-minimal — a harness artifact, not a Golem bug).
- **where:** `Installer/preinstall/install.nix` (phase 4),
  `system/Modular/base/loop.nix`, `system/Modular/composition.nix`.
- **size:** done (pre-ISO source fix). Verify the engine's live drop +
  BIOS-minimal install on the round-I1 recut.

## Applied

*(moves here at round close, tagged with the round that shipped it)*
