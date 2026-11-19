# modules/trading-finance — Trading & Finance: charts, brokers and exchanges
# (web apps), your money, wallets.
#
# No plumbing. PROGRAM SETUP: a hardware wallet is a USB device the owner
# must be allowed to open (Ledger's udev rules), or one that speaks through
# its bridge (Trezor's daemon).
{ config, lib, ... }:

let
  m = import ./lib.nix { inherit lib; };
  inherit (m.scope config) has;
in
{
  imports = [
    (m.mkModule {
      id = "trading-finance";
      description = "Trading & Finance: charts, brokers and exchanges (web apps), your money, wallets.";
    })
  ];

  config = {
    hardware.ledger.enable = lib.mkIf (has "ledger-live-desktop") true;
    services.trezord.enable = lib.mkIf (has "trezor-suite") true;
  };
}
