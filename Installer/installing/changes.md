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
