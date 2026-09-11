# gpu2/nvidia-offload-preturing — a SECOND nvidia GPU that passed the
# wake test, Maxwell/Pascal/Volta. Chosen when gpu2=nvidia,
# gpu2Health=working, nvidiaGen=pre-turing. The legacy_580 driver blob +
# PRIME offload. (No lab machine yet — written for coverage; a fixture
# lands when a machine demands it.)
{ ... }:

{
  imports = [
    ../gpu/nvidia/preturing-driver.nix
    ../gpu/nvidia/prime-offload.nix
  ];
}
