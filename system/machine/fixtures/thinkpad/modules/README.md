# Your own modules

Every `.nix` file in this folder is part of this computer's system: it is
imported automatically, in name order, after Standard and after
`../configuration.nix`. Standard never writes here.

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

Standard's own modules are in `../standard/` and are read-only. To change one,
copy it here and tell the system to use your copy instead of Standard's:

```nix
# /etc/nixos/modules/gaming.nix  — my version of Standard's Gaming module
{ standardSource, ... }:   # the Standard this computer runs (what ../standard points at)
{
  disabledModules = [ "${standardSource}/system/modules/gaming.nix" ];
  # ... the contents of ../standard/system/modules/gaming.nix, edited ...
}
```

Most of the time you do not need this: an option set in `configuration.nix`
already wins over Standard's default (`lib.mkForce` when Standard insists).
