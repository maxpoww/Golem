# boot/flat-units — systemd's unit directories as real files, not symlinks.
#
# WHY (Acer E5-573, Hitachi spinning disk, night dogfood 2026-10-03): NixOS
# builds /etc/systemd/system as a directory of SYMLINKS, one per unit, each
# into its own store path (unit-foo.service/, unit-bar.service/, …). systemd
# reads every one at boot, right after switch-root, and on a cold rotating
# disk each is a separate lookup in the huge /nix/store directory plus its
# own inode and data block — several seeks apiece. Measured on the Acer
# (cold cache, 634 unit files): through the symlinks 13.3 s (8.9 s of it the
# lookups alone); the same files as copies in one directory 0.84 s. The boot
# showed it: 11 s of silence between the initrd's "Journal stopped" and the
# real root's "Journal started".
#
# So every generated unit tree (system, user, initrd) gets the files copied
# in. What stays a symlink, on purpose:
#   - aliases (a link whose name differs from its target's: dbus-org…service
#     → systemd-logind.service) — systemd reads the link to know it IS an
#     alias; a copy would be a second, separate unit;
#   - the relative links of .wants/.requires/.upholds (by name, no lookup);
#   - masks (→ /dev/null).
# Drop-ins (foo.service.d/overrides.conf → …/foo.service) are plain config
# fragments: always copied.
#
# Done by wrapping nixpkgs' own generateUnits (passed to every module as
# `utils`), so it follows whatever NixOS puts in the trees.
{ lib, config, pkgs, modulesPath, ... }:

let
  orig = import (modulesPath + "/../lib/utils.nix") { inherit lib config pkgs; };

  flatten = tree: pkgs.runCommand "${tree.name}-flat" { preferLocalBuild = true; allowSubstitutes = false; } ''
    cp -a ${tree} $out
    chmod -R u+w $out
    find $out -type l -print0 | while IFS= read -r -d "" l; do
      t=$(readlink "$l")
      case "$t" in /nix/store/*) ;; *) continue ;; esac
      real=$(readlink -f "$l")
      [ -f "$real" ] || continue
      case "$(basename "$(dirname "$l")")" in
        *.d) cp --remove-destination "$real" "$l" ;;
        *) if [ "$(basename "$t")" = "$(basename "$l")" ]; then cp --remove-destination "$real" "$l"; fi ;;
      esac
    done
    chmod -R a-w $out
  '';
in
{
  _module.args.utils = lib.mkForce (lib.recursiveUpdate orig {
    systemdUtils.lib.generateUnits = args: flatten (orig.systemdUtils.lib.generateUnits args);
  });
}
