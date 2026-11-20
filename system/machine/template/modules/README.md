# Your own modules

Every `.nix` file in this folder is part of this computer's system: it is
imported automatically, in name order, after Golem and after
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

## Changing one of Golem's modules

Most of the time you do not need to: an option set in `configuration.nix`
already wins over Golem's default (`lib.mkForce` when Golem insists).

When you do, Golem's own files are in `../golem/`, and they are yours to
edit as root: change the file, `sudo nixos-rebuild switch`. An update keeps
your change: it merges the new Golem into the files as you left them. Only
where you and the new version changed the same lines does Golem's win, and
then your file is set aside, not lost (`/var/lib/golem/local-edits/`).
`sudo golem-status` lists what this computer changed.

Or leave Golem's file alone and carry a whole version of your own here:

```nix
# /etc/nixos/modules/gaming.nix  — my version of Golem's Gaming module
{ golemSource, ... }:   # where this computer's Golem is
{
  disabledModules = [ "${golemSource}/system/modules/gaming.nix" ];
  # ... the contents of ../golem/system/modules/gaming.nix, edited ...
}
```
