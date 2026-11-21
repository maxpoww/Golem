# Your own modules

Every `.nix` file in this folder is part of this computer's system: it is
imported automatically, in name order, after the system and after
`../configuration.nix`. Golem never writes here.

Use it for anything that deserves its own file: a printer, a VPN, a service
you run, a whole module of your own.

```nix
# /etc/nixos/modules/printer.nix
{ pkgs, ... }:
{
  services.printing.drivers = [ pkgs.brlaser ];
}
```

Then `sudo nixos-rebuild switch`.

## Changing one of Standard's modules

Most of the time you do not need to: an option set in `configuration.nix`
already wins over Standard's default (`lib.mkForce` when Standard insists).

When you do, Standard's own files are in `../standard/`, and they are yours to
edit as root: change the file, `sudo nixos-rebuild switch`. Golem keeps your
change when it updates: it merges the new version into the files as you left
them. Only where you and the new version changed the same lines does the new
version win, and then your file is set aside, not lost
(`/var/lib/golem/local-edits/`).
`sudo golem-status` lists what this computer changed.

Or leave Standard's file alone and carry a whole version of your own here:

```nix
# /etc/nixos/modules/gaming.nix  — my version of Standard's Gaming module
{ standardSource, ... }:   # where this computer's Standard is
{
  disabledModules = [ "${standardSource}/system/modules/gaming.nix" ];
  # ... the contents of ../standard/system/modules/gaming.nix, edited ...
}
```
