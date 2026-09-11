# gpu/nvidia-preturing — PRIMARY nvidia GPU, Maxwell/Pascal/Volta.
# Chosen when gpu=nvidia and nvidiaGen=pre-turing. The legacy_580 driver,
# no PRIME (primary).
{ ... }:

{
  imports = [ ./nvidia/preturing-driver.nix ];
}
