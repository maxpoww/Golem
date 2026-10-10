# A phone as this computer's CAMERA (the desktop's "Use as camera" on a
# plugged-in Android; launcher desktop.rs, home half in system/home/phone.nix).
#
# scrcpy feeds the phone's camera into a loopback camera device, and the
# relay hands that on to the apps. The device is a kernel module with one
# line of options — it lived only in the fat system/configuration.nix and in
# the dev box's own layer, so on every INSTALLED Golem the menu row did
# nothing at all ("no loopback camera device on this system"; found testing
# the Acer with a Samsung, 2026-10-10).
#
#   exclusive_caps=1   apps only list it as a camera while it is being fed
#   video_nr=10        a number no real camera takes (/dev/video10)
{ config, ... }:

{
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModprobeConfig = ''
    options v4l2loopback exclusive_caps=1 card_label="Android WebCam" video_nr=10
  '';
}
