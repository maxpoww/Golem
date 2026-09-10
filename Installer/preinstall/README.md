# preinstall — the Golem installer (MiniGolem)

This directory is the **implementation**: the flake the installer ISO is
built from. The spec (WHAT and WHY) is `../../GolemInstall.md`.

**GRADUATED 2026-09-10.** The preinstall lab program — six rounds,
eight machines, ~70 findings — proved the census, the surface, the ask
framework and the install seam on real metal, and closed. What moved,
and where:

- **Lab records + the graduation:** `~/GolemOne/Install/Preinstall/testing/`
  (PLAN.md with the scoreboard, changes.md the finding ledger, the
  per-machine files, the constitution and the lab playbook).
- **Maintainer documentation** (architecture, operations, debugging,
  extending, testing): `~/GolemOne/Install/Preinstall/`.
- **The live program continues** in `../installing/` — the installing
  rounds, on the first-install dogfood's foundation.

What stays here, because the build consumes it: `flake.nix` + the
`.nix` modules, `mockup/install-cli` (the surface's source of truth),
`run-vm.sh` (machine zero), and `fixtures/` (the eval matrix reads it —
do not move it).

One operational rule worth repeating at the door (the round-6 lesson):
**`nix flake update` before every ISO build** — the `golem` input is a
locked `path:` flake and `nix build` never re-reads it on its own.
