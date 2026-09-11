# gpu2/nvidia-offload-turing — a SECOND nvidia GPU that passed the wake
# test, Turing+ (a hybrid laptop: intel primary drives the screen, this
# chip does work on demand via PRIME). Chosen when gpu2=nvidia,
# gpu2Health=working, nvidiaGen=turing+. The turing driver blob + PRIME
# offload. (Lab: the lenovo Slim Pro 9i, RTX 4050.)
{ ... }:

{
  imports = [
    ../gpu/nvidia/turing-driver.nix
    ../gpu/nvidia/prime-offload.nix
  ];
}
