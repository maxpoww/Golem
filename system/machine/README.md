# system/machine — one computer, from its own folder

The `/etc/nixos` layout (design: [docs/system/Layout.md](../../docs/system/Layout.md)).
A machine is a small root-owned folder; Standard is root's own editable copy
inside it (`/etc/nixos/standard`). Nothing of the system lives in a home
directory.

| File | What |
|---|---|
| `default.nix` | `mkMachine` (`lib.standard.machine`): `dir → { system; nixosConfigurations; }`. The desktop's composition with the machine's files read from `dir`, the facts and lists read as data, the chooser run at evaluation. Also `.layoutModules profile`: the layout's own leaves, for the medium's baked systems (flake.nix). |
| `../../machine.nix` | **What a machine's `flake.nix` calls** (`import ./standard/machine.nix ./.`). ⚠ Never move it. |
| `from-lock.nix` | Standard evaluated with the pins of its OWN `flake.lock`, no flake around it: why a machine's flake has no inputs (one pin file, the one an update moves). |
| `layout.nix` | The leaf every such machine gets: no checkout in a home (`standard.flakeDir = null` switches off the seal and all that existed for it), the folder kept with each generation (`/etc/golem/machine`), and the commands `rebuild-golem`, `golem-update` (the new version merged into root's copy, this machine's edits kept, built from a root-only try first), `golem-recover`, `golem-status`, `golem-machine-checkout`. |
| `update.nix` | The nightly update: `golem-update --nightly` under the unit names of the old layout (`golem-autoupdate`, `golem-update-now`), the notices, the boot-menu check. |
| `first-boot.nix` | The one build after an install (`golem-update --converge`), only where the installer left `/var/lib/golem/first-boot.pending`. |
| `apps.nix` | The dock's installs: the owner's `packages.list` (data) → `machine/apps.list`, built from a root-only try first. |
| `answers.nix` | The post-install answers → `machine/answers.list`, the same way. (The asking is `../postinstall.nix`.) |
| `lists.nix` | Readers for `machine/*.list`: text in, one name a line, every name looked up — never imported. |
| `checkout.sh` | `golem-machine-checkout`: Standard as root's checkout on a machine (git's data in `/var/lib/golem/golem.git`), from a repository or from plain files (the installer's medium). |
| `scaffold.sh` | A NEW machine's folder from the template and the installer's answers. |
| `relocate.sh` | A checkout-in-a-home machine's files (`hosts/target`) → a folder. The installer uses it on what it gathered; it writes the folder only. |
| `template/` | The folder as it is made: `flake.nix`, `configuration.nix`, `modules/`, `machine/`. Also the flake's `templates.default`. |
| `fixtures/` | Two folders made from the template (a ThinkPad on the desktop with apps, modules, own modules and a replaced Standard module; a VM on the base alone) for the checks. |
| `check.nix` | `checks.machine-layout`: both fixtures composed, through the flake and through `machine.nix`, and asserted. |
| `test/` | `checks.machine-update`: the update driven on a made-up upstream, in a namespace of its own (`update.sh`), with the rebuild alone replaced by a stand-in (`commands.nix`). |

## Trying it

```sh
G=git+file:///home/max/Golem
nix build --no-link "$G#checks.x86_64-linux.machine-layout" "$G#checks.x86_64-linux.machine-update"

# A folder exactly like a machine's (nothing but the folder is written):
bash system/machine/scaffold.sh --to /tmp/m/etc/nixos --standard . --owner ana --hostname casa \
  --facts Installer/preinstall/fixtures/thinkpad-e15-gen2/facts.nix \
  --hardware-config system/machine/fixtures/thinkpad/hardware-configuration.nix
bash system/machine/checkout.sh --root /tmp/m --from . --branch main
nix eval --raw path:/tmp/m/etc/nixos#nixosConfigurations.casa.config.system.build.toplevel.drvPath
```

The real `nixos-rebuild` on such a folder, with no arguments, from an
unprivileged shell: a user + mount namespace with the folder bound on
`/etc/nixos` and the machine's hostname (`unshare -r -m -u`, then
`nixos-rebuild dry-build`).

## What a medium needs

A machine installed from a medium takes its first update from the branch
installs follow (`standard.upstream.branch`, `stable`). The layout has to be on
that branch before such a medium is handed to anyone.
