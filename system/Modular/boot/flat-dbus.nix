# boot/flat-dbus — the bus's configuration in one folder, as flat-units does for units.
#
# WHY (ASUS X550LC, spinning disk, 2026-10-31): the bus reads every package's
# folders at each start, three of them a package (forty packages, most of the
# folders not even there), each a lookup in the huge /nix/store and its own
# inodes: 1329 reads for 8 MB of little files, and basic.target waits for it,
# then the user's bus does it again.
#
# So system.conf and session.conf name one folder of this store path instead, with
# the files copied in. A service in two packages stays the first one's, as the bus
# has it; a policy keeps its package's place in the order (the number before its
# name). The conf is NixOS's own otherwise.
{ lib, config, pkgs, ... }:

let
  cfg = config.services.dbus;

  # What the dbus module makes (services/system/dbus.nix, configDir).
  nixos = pkgs.makeDBusConf.override {
    inherit (cfg) apparmor;
    dbus = cfg.dbusPackage;
    suidHelper = "${config.security.wrapperDir}/dbus-daemon-launch-helper";
    serviceDirectories = cfg.packages;
  };

  flat = pkgs.runCommand "dbus-1-flat" { preferLocalBuild = true; allowSubstitutes = false; } ''
    mkdir -p $out
    for bus in system session; do
      services=$out/$bus-services policies=$out/$bus.d
      mkdir $services $policies
      sed -E 's/></>\n</g' ${nixos}/$bus.conf > lines
      n=0
      grep -oE '<(servicedir|includedir)>/nix/store/[^<]+' lines > dirs
      while IFS='>' read -r tag dir; do
        n=$((n + 1))
        [ -d "$dir" ] || continue
        case "$tag" in
          '<servicedir')
            for f in "$dir"/*.service; do
              [ -e "$f" ] || continue
              [ -e "$services/$(basename "$f")" ] || cp -L "$f" "$services/"
            done ;;
          *)
            for f in "$dir"/*.conf; do
              [ -e "$f" ] || continue
              cp -L "$f" "$policies/$(printf %03d $n)-$(basename "$f")"
            done ;;
        esac
      done < dirs
      awk -v one="<servicedir>$services</servicedir>\n<includedir>$policies</includedir>" '
        /^[[:space:]]*<(servicedir|includedir)>\/nix\/store\// { if (!done) { print one; done = 1 } next }
        { print }' lines > $out/$bus.conf
    done
    chmod -R a-w $out
  '';
in
{
  environment.etc."dbus-1".source = lib.mkForce flat;
}
