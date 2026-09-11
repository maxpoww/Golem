# quirks/broadcom-wl — Broadcom (PCI 0x14e4) wifi, the card that does not
# just work. Chosen when broadcomWifi=true (additive — a quirk, not a
# group). The unfree out-of-tree `wl` module is the ONLY working driver
# for the BCM4360 (Intel MacBooks, a north-star target); its modprobe
# rules blacklist the in-tree SoftMAC drivers so it wins the card. The
# installer medium stays on brcmfmac — the install is offline and never
# needs MacBook wifi; the installed system is where wl matters. Ported
# verbatim from system/hardware/broadcom-wifi.nix (2026-09-10), minus the
# broadcomWifi mkIf (the chooser decided). (Lab: the MacBook — the boss
# fight, #5.)
{ config, lib, ... }:

{
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  boot.kernelModules = [ "wl" ];
  # broadcom-sta is flagged INSECURE (unmaintained upstream) AND unfree.
  # Permit it by NAME, not the versioned string (which carries the kernel
  # version and breaks on every bump). Scoped to this leaf — only a
  # Broadcom machine relaxes the policy.
  nixpkgs.config.allowInsecurePredicate =
    pkg: lib.getName pkg == "broadcom-sta";
}
