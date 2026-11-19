# system/machine — one computer, from its own folder

The `/etc/nixos` layout (design: [docs/system/Layout.md](../../docs/system/Layout.md)).
A machine is a small root-owned folder; Golem is the pinned input its
`flake.nix` names. Nothing of the system lives in a home directory.

| File | What |
|---|---|
| `default.nix` | `mkMachine`: `dir → { system; nixosConfigurations; }`. The same composition as `golem-desktop`, with the machine's files read from `dir`, the facts and lists read as data, the chooser run at evaluation. Exported as `lib.golem.machine`. |
| `layout.nix` | The NixOS leaf every such machine gets: no checkout (`golem.flakeDir = null`, which switches off the seal and every helper that existed for it), `/etc/nixos/golem` → the Golem source, the folder kept with each generation (`/etc/golem/machine`), and the commands `rebuild-golem`, `golem-update`, `golem-recover`. |
| `lists.nix` | Readers for `machine/*.list`: text in, one name a line, every name looked up — never imported. |
| `template/` | The folder as the installer writes it: `flake.nix`, `configuration.nix` (the `@…@` marks are the installer's answers), `modules/`, `machine/`. Also the flake's `templates.default`. |
| `scaffold.sh` | A NEW machine's folder from the template and the installer's answers (each written as an escaped Nix string). What `golem-install` will call where it writes `hosts/target/machine.nix` today. Writes the folder only. |
| `relocate.sh` | A machine installed before this layout → its folder (`~/Golem/hosts/target` → `/etc/nixos`). Writes the folder only; builds and switches nothing. |
| `fixtures/` | Two folders made from the template (a ThinkPad on the desktop with apps, own modules and a replaced Golem module; a VM on the base alone) for the check. |
| `check.nix` | `checks.x86_64-linux.machine-layout`: both fixtures composed and asserted. |

## Trying it

```sh
G=git+file:///home/max/Golem
nix build --no-link "$G#checks.x86_64-linux.machine-layout"

# A folder exactly like a machine's, evaluated the way nixos-rebuild asks:
cp -r system/machine/fixtures/thinkpad /tmp/etc-nixos
sed -i 's|github:maxpoww/Golem/stable|git+file:///home/max/Golem|' /tmp/etc-nixos/flake.nix
nix flake lock path:/tmp/etc-nixos
nix eval --raw path:/tmp/etc-nixos#nixosConfigurations.thinkpad-ana.config.system.build.toplevel.drvPath

# An old-layout machine's files, moved (reads --from, writes --to, nothing else):
bash system/machine/relocate.sh --from ~/Golem --to /tmp/new-etc-nixos --golem ~/Golem
```

## What is not here yet (Layout.md, stages 2–4)

The nightly update's waves and notices, the dock's app installs and Modules
page, the post-install questions and Seam's update lane still write to the
old layout: on a machine built by `mkMachine` they are off, and the update is
`golem-update` by hand. The installer does not write this layout yet, and no
machine is moved to it automatically.
