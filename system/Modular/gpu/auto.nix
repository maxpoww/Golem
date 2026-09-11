# gpu/auto — the census could not name the GPU vendor. Every userspace
# VA-API driver ships so runtime detection has something to pick from
# (inert unless libva selects them); the open KMS stack drives the
# screen. The conservative floor — chosen only when gpu=auto. Lifted
# from hardware.nix's auto branch.
{ pkgs, ... }:

{
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    intel-vaapi-driver
    libvdpau-va-gl
  ];
}
