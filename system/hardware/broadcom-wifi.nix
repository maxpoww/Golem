# Broadcom wifi — the `broadcomWifi` fact's consumer. Broadcom (PCI 0x14e4)
# wireless is the wifi that does not just work; this brings it up unasked,
# which matters because Intel MacBooks (BCM4360) are a north-star target and
# their wifi has to work out of the box.
#
# TWO drivers can claim these cards and they do not coexist:
#   - brcmfmac  in-tree, needs redistributable firmware (every Golem carries
#               it via enableAllFirmware) — the clean default for most parts,
#               incl. the BCM4360, and what the installer MEDIUM rides on.
#   - broadcom_sta (wl)  the UNFREE out-of-tree module — historically the
#               reliable driver for the BCM4360 on MacBooks, where brcmfmac
#               has been flaky across revisions.
#
# We enable wl on the INSTALLED system (Max: "auto-enable unfree"): its
# modprobe rules blacklist the in-tree SoftMAC drivers (b43/brcmsmac/bcma/
# ssb) so wl wins the card. The medium stays on brcmfmac+firmware — round 2
# tests whether that alone lights up the MacBook (no dongle); round 4 tests
# wl on the installed system. If brcmfmac proves solid on the metal, this is
# where we would reconsider dropping the unfree module.
{ config, lib, ... }:

{
  config = lib.mkIf config.golem.hardware.broadcomWifi {
    boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
    boot.kernelModules = [ "wl" ];
    # broadcom-sta is flagged INSECURE in nixpkgs (upstream is unmaintained),
    # on top of being unfree. We ship it on purpose — it is the reliable
    # BCM4360 driver a MacBook needs — so permit it by NAME rather than the
    # versioned permittedInsecurePackages string, which carries the kernel
    # version and would break on every kernel bump. Scoped to this module,
    # so only a machine with a Broadcom radio ever relaxes the policy.
    nixpkgs.config.allowInsecurePredicate =
      pkg: lib.getName pkg == "broadcom-sta";
  };
}
