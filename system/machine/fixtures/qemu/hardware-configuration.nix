# (A test fixture: what nixos-generate-config writes, cut to the two lines an
# evaluation needs.)
{ ... }:
{
  nixpkgs.hostPlatform = "x86_64-linux";
  fileSystems."/" = { device = "/dev/disk/by-label/standard"; fsType = "ext4"; };
  fileSystems."/boot" = { device = "/dev/disk/by-label/ESP"; fsType = "vfat"; };
}
