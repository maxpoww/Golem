# gpu/nvidia-turing — PRIMARY nvidia GPU, Turing+ (drives the screen: a
# desktop or a muxed laptop). Chosen when gpu=nvidia and nvidiaGen=turing+.
# The driver blob, no PRIME (this chip IS the display, not an offload
# target).
{ ... }:

{
  imports = [ ./nvidia/turing-driver.nix ];
}
