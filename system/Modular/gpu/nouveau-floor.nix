# gpu/nouveau-floor — THE IRON LAW (GolemInstall.md §8). Chosen when
# gpu=nvidia but nvidiaGen=unknown: an nvidia GPU we could not classify
# stays on the modesetting/nouveau floor that boots on everything. An RTX
# on nouveau is a bug report; a black screen is a dead distro — so the
# unclassified case gets NO proprietary driver, deliberately. nouveau is
# in-kernel and modesetting drives it; nothing to name here. The leaf
# exists so the pointer list is total and says WHY this machine has no
# nvidia driver. (Lab: the asus's GF117M, nvidiaGen=unknown.)
{ ... }:

{
}
