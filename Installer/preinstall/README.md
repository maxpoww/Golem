# preinstall — the Standard installer (MiniGolem)

This directory is the **implementation**: the flake the installer ISO is
built from. How the install works today, from this code, is
`../../docs/installing/install.md`.

**GRADUATED 2026-09-10.** The preinstall lab program — six rounds,
eight machines, ~70 findings — proved the census, the surface, the ask
framework and the install seam on real metal, and closed. What moved,
and where:

- **Lab records + the graduation:** `~/Golem/docs/installing/preinstall/testing/`
  (PLAN.md with the scoreboard, changes.md the finding ledger, the
  per-machine files, the constitution and the lab playbook).
- **Maintainer documentation** (architecture, operations, debugging,
  extending, testing): `~/Golem/docs/installing/install.md`.
- **The live program continues** in `../installing/` — the installing
  rounds, on the first-install dogfood's foundation.

What stays here, because the build consumes it: `flake.nix` + the
`.nix` modules, `mockup/install-cli` (the surface's source of truth),
`run-vm.sh` (machine zero), and `fixtures/` (the eval matrix reads it —
do not move it).

One operational rule worth repeating at the door (the round-6 lesson):
**`nix flake update standard` here whenever a pin moves in Standard's
`flake.lock`** — this flake's lock holds a copy of those pins and nothing
refreshes it by itself. It is enforced now: with pins that are not Standard's
this flake does not evaluate (`flake.nix`, pinsAreStandards), and Standard's own
`checks.installer-lock` fails on a commit that moves one without the
other.
