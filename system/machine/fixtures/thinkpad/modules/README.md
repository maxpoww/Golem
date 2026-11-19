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

Golem's own modules are in `../golem/` and are read-only. To change one,
copy it here and tell the system to use your copy instead of Golem's:

```nix
# /etc/nixos/modules/gaming.nix  — my version of Golem's Gaming module
{ golemSource, ... }:   # the Golem this computer runs (what ../golem points at)
{
  disabledModules = [ "${golemSource}/system/modules/gaming.nix" ];
  # ... the contents of ../golem/system/modules/gaming.nix, edited ...
}
```

Most of the time you do not need this: an option set in `configuration.nix`
already wins over Golem's default (`lib.mkForce` when Golem insists).
