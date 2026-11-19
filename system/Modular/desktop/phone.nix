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
#
# ONE LINE OF OPTIONS FOR EVERY LOOPBACK CAMERA (2026-11-19). The module
# takes its devices from its one `options` line; a second line (what
# programs.obs-studio.enableVirtualCamera would add) fights the first. So
# whoever needs a loopback camera names it in golem.loopbackCameras and the
# line is written here, once, from all of them. With the phone's alone it is
# the line it always was.
{ config, lib, ... }:

let
  cams = lib.sort (a: b: a.nr < b.nr) config.golem.loopbackCameras;
  list = f: lib.concatMapStringsSep "," f cams;
in
{
  options.golem.loopbackCameras = lib.mkOption {
    internal = true;
    default = [ ];
    description = ''
      The loopback camera devices this system has: /dev/video<nr>, shown to
      the apps as <label>. Each is listed as a camera only while something
      feeds it.
    '';
    type = lib.types.listOf (lib.types.submodule {
      options = {
        nr = lib.mkOption { type = lib.types.ints.unsigned; description = "The device's number."; };
        label = lib.mkOption { type = lib.types.strMatching "[^,\"]+"; description = "Its name in the apps."; };
      };
    });
  };

  config = {
    golem.loopbackCameras = [ { nr = 10; label = "Android WebCam"; } ];

    assertions = [{
      assertion = lib.allUnique (map (c: c.nr) cams);
      message = "golem.loopbackCameras: two loopback cameras ask for the same device number";
    }];

    boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
    boot.kernelModules = [ "v4l2loopback" ];
    boot.extraModprobeConfig =
      if builtins.length cams == 1 then ''
        options v4l2loopback exclusive_caps=1 card_label="${(builtins.head cams).label}" video_nr=${toString (builtins.head cams).nr}
      '' else ''
        options v4l2loopback devices=${toString (builtins.length cams)} exclusive_caps=${list (_: "1")} card_label="${list (c: c.label)}" video_nr=${list (c: toString c.nr)}
      '';
  };
}
