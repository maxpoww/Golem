# tools/latest — what Standard uses, against the latest NixOS and Hyprland

The documentation of NixOS's options and of Hyprland's configuration is
generated from their source. So "is this still how it is done?" is asked of
the source, by a program, instead of read off a web page by a person:

```sh
tools/latest/check.sh        # from the repo root; needs nix and python3
```

It downloads the latest `nixos-unstable` and the latest Hyprland (about
50 MB, nothing is built) and prints what Standard uses of each that is gone,
renamed, or of another type there. Exit status 1 if anything is. Run it
before moving a pin: `flake.lock`'s nixpkgs, or Hyprland's version
(`system/Modular/desktop/hyprland-overlay.nix`).

| File | What |
|---|---|
| `check.sh` | The whole check. |
| `nixos-options.nix` | Finds every NixOS option that `system/modules/*.nix`, `desktop/phone.nix` and `system/machine/layout.nix` define, by walking what the files return down to the pinned NixOS's option tree; then looks each up in the latest NixOS: there, visible (a renamed option stays as a hidden alias), the same type. Also the packages those files name, and the catalog's programs by attribute. |
| `hyprland.py` | Reads what the configuration does under the recording mock (`system/home/hypr/test/mock.lua`): the options it sets, the keys of every rule, bind, monitor, animation and curve; and the `hl.*` functions and events its Lua names. Looks each up in the source of the Hyprland Standard runs and of the latest. Options Standard's own patches add are read from the patches. |

What it cannot say: whether a value still MEANS the same (a default that
moved, an option whose effect changed). For that, read the release notes of
what moved; this narrows them to what Standard touches.

## 2026-11-19

NixOS 26.05 (pinned, rev f1e5c35) against nixos-unstable 26.11pre (0490633):
the 54 NixOS options Standard's files define are all there, visible, of the same
type; the 7 packages named outright exist; none of the catalog's 343 package
attributes is missing from either (9 are there and do not evaluate in the
pin: system/modules' warnings name them).

Hyprland 0.55.4 (running) against 0.57.0 (main, 9927f2e): the 63 options the
configuration sets are all there; the 26 `hl.*` functions, the rule effects
and matches, bind options, events, animation leaves and curve types it names
are all there. One option changed type: `decoration:shadow:color`, a colour
in 0.55 and a gradient in 0.57 — whose parser still takes the number Standard
gives it (`0x661a1a1a`: a Lua number reads as its decimal string, which
`parseColor` accepts).
