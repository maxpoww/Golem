# FRAGMENT (not a chooser target). PRIME render offload — added by the
# gpu2 nvidia-offload leaves on top of a driver blob. The bus ids are
# pure per-host DATA (like golem.owner or the grub device), read from
# the census facts the installer wrote — the one place this library
# touches golem.hardware, and it is interpolation, not a decision (the
# chooser already decided this is a hybrid with a working nvidia gpu2).
# mkOverride 900 on offload.enable: upstream nvidia.nix config-defines it
# false at 1000, which would tie and conflict — 900 beats that and still
# yields to any plain per-host definition (100). Ported from
# gpu-nvidia.nix's prime block.
{ config, lib, ... }:

let
  cfg = config.golem.hardware;
in
{
  hardware.nvidia.prime = {
    offload = {
      enable = lib.mkOverride 900 true;
      enableOffloadCmd = lib.mkOverride 900 true;
    };
    intelBusId = lib.mkDefault cfg.intelBusId;
    nvidiaBusId = lib.mkDefault cfg.nvidiaBusId;
  };
}
