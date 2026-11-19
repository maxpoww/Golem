# system/modules — the Modules

The dock's **Modules** (Gaming, Development, Music Production…) as NixOS
modules: one file per module. Each one installs the programs the owner
switched on **and sets the system up for them** — the service, the port, the
device rule, the kernel bit a forum thread would otherwise walk someone
through. Design: [docs/system/GolemModules.md](../../docs/system/GolemModules.md).

The tree is imported once, by the desktop stage
(`system/Modular/desktop/default.nix`), and is off until asked: a machine that
chose nothing evaluates to the system it was without it.

## The option shape

```nix
golem.modules.gaming.enable = true;           # the module: its plumbing + the recommended programs
golem.modules.gaming.install = "all";         # what `enable` takes: "recommended" | "all" | "chosen"
golem.modules.gaming.lutris.enable = true;    # one program more
golem.modules.gaming.steam.enable = false;    # one of the recommended, refused
golem.modules."3d-printing".enable = true;    # (an id that starts with a digit is quoted)
```

A program said outright (`true` or `false`) wins over the module's `install`.
A program that is not in the catalog is an evaluation error that lists the
ones that are.

## Three ways in, one result

| Way in | What happens |
|---|---|
| The dock: Modules → Apply, or a drag into the grid | The programs land in the owner's installed apps (`hosts/target/apps.nix`). Each file's **program setup** is keyed on the *installed program's name*, so the system side comes with it. |
| By hand, in the machine's configuration | The options above. The programs go to the same place the dock's go (the owner's home packages, low priority). |
| The machine's selection file: `golem.modules.listPath` — `/etc/nixos/machine/modules.list` on a machine of the new layout (`system/machine`) | One `<module>` or `<module>.<tool>` per line, `#` for comments. Read as **data**: a line is a name that is looked up, never evaluated. A line that names nothing is skipped with a warning. |

## The two rules

1. **The catalog is data, and it has one source**: the dock's
   `crates/daemon/assets/modules.json`, read from the pinned `waverunner`
   input (`golem.modules.catalog`). Which programs a module offers, and which
   "Install recommended" takes, is never written in Nix. "Recommended" only
   ever takes editorial entries, never a paid placement. A program nixpkgs
   lacks (or that does not evaluate there today) is skipped with a warning.
2. **What is written here by hand is what a program needs to WORK** — what
   its upstream or the NixOS manual says: a service, a port, a device rule.
   Never a preference, never tuning (the one exception is a module's own
   *plumbing*, which only an explicit switch turns on: Music Production's
   low-latency clock). And **no group that is root**: the selection is
   written without a password, so it may give the owner nothing they did not
   have. Docker is rootless; virtual machines run in the owner's own libvirt
   session; `kvm` and `dialout` are the only groups given.

## How a module file is written

```nix
{ config, lib, pkgs, ... }:
let
  m = import ./lib.nix { inherit lib; };
  inherit (m.scope config) owner has any on;
in
{
  imports = [ (m.mkModule { id = "gaming"; description = "…"; }) ];   # options, packages, checks

  config = lib.mkMerge [
    # PLUMBING: the module is on (switched on, or one of its programs is).
    (lib.mkIf (on "gaming") { hardware.graphics.enable32Bit = true; })
    # PROGRAM SETUP: the program is installed, however it got there.
    { programs.steam = lib.mkIf (has "steam") { enable = true; }; }
  ];
}
```

- `has "name"` uses the name `lib.getName` gives the package, which is not
  always the attribute's (`opentabletdriver` is `OpenTabletDriver`,
  `zoom-us` is `zoom`, `retroarch` is `retroarch-with-cores`).
- A program that sits in several modules has its setup in **one** file.
- Never add to the owner's home packages under a `has` condition (the
  condition reads them): what a program needs beside itself goes to
  `environment.systemPackages`.
- A new module: its file, a line in `default.nix`'s imports and one in
  `lib.nix`'s `categories` (id → the catalog's name).
- A module's own Hyprland rules or keys: `system/home/hypr/golem/modules/<id>.lua`.
  Nothing to wire: the home layer loads the file of every module that is on
  (`golem.modules.active`, read by `system/home/hyprland.nix`).

## Testing

```sh
G=git+file:///home/max/Golem
nix build --no-link "$G#checks.x86_64-linux.modules-matrix"   # evaluation only
```

`matrix.nix` composes the desktop on real fixtures and asserts: nothing on
until asked; each program with its system; a dragged program the same as a
switched one; every module with every program evaluates and gives no group
that is root; the selection file's hostile lines do nothing.
`system/Modular/desktop-matrix.nix` keeps the older checks of the same code.
