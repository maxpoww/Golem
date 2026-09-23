# Golem's boot bar — Plymouth, styled as the OPTIONS status bar.
#
# Max, 2026-09-23: "can we add the same bar as the status bar loading on boot?
# … lets show our bar everywhere." The quiet boot (base/core.nix) gives a black
# screen from kernel handoff to the compositor; this fills that screen with the
# one thing Golem already speaks in — the accent bar — filling as the machine
# comes up, with the service that is starting flying past underneath (the boot
# echo of the installer's flying filenames).
#
# THE #65 TAX, PAID DELIBERATELY. base/core.nix drops `splash` and
# `fbcon=map:1` because the acer (first metal) has only fb0 and `fbcon=map:1`
# pointed the console at a fb1 that does not exist → a DEAD screen. Plymouth
# needs `splash`, so this re-adds `splash` ONLY (never fbcon=map:1): Plymouth
# renders through DRM/KMS and falls back to text if a GPU can't, so `splash`
# alone does not take the console away the way the mapping did. The oldest lab
# GPUs (GM45 GMA) are the ones to watch on metal — if one comes up dark, this
# module is the lever to pull.
{ config, lib, pkgs, ... }:

let
  # The theme: a script module drawing the bar. Two 1px colour tiles the script
  # scales — accent (xterm-256 #180, the surface's one accent) and a dim track.
  golemPlymouth = pkgs.runCommand "golem-plymouth-theme"
    { nativeBuildInputs = [ pkgs.imagemagick ]; }
    ''
      d=$out/share/plymouth/themes/golem
      mkdir -p "$d"
      cp ${./golem-plymouth/golem.script} "$d/golem.script"
      # The accent is NOT xterm #180's true #d7af87 — the console renders fg 180
      # as the VGA fallback #AA5500 (sampled off the installer bar, srgb 170,85,0),
      # and THAT orange is the bar Max sees. Plymouth draws true colour, so we
      # hard-code the orange the surface actually shows, or the boot bar and the
      # installer bar are two different colours (Max, 2026-09-23: "the color is
      # not the [one] we want").
      magick -size 1x1 xc:'#AA5500' "$d/accent.png"
      magick -size 1x1 xc:'#3a3a3a' "$d/track.png"     # dim track
      {
        echo "[Plymouth Theme]"
        echo "Name=Golem"
        echo "Description=Golem boot bar"
        echo "ModuleName=script"
        echo ""
        echo "[script]"
        echo "ImageDir=$d"
        echo "ScriptFile=$d/golem.script"
      } > "$d/golem.plymouth"
    '';
in
{
  boot.plymouth = {
    enable = true;
    themePackages = [ golemPlymouth ];
    theme = "golem";
  };

  # Plymouth needs `splash` (and only splash — never fbcon=map:1, see the #65
  # note). The bar is just progress now (Max dropped the flying service line),
  # so we no longer re-enable systemd.show_status — base's quiet stays quiet.
  boot.kernelParams = lib.mkAfter [ "splash" ];
}
