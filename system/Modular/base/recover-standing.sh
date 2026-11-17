# shellcheck shell=bash
# Sourced by golem-recover (base/recover.nix) and by recover-standing-test.sh.
#
# STANDING FILES of the machine layer: choices that belong to the MACHINE,
# not to a version, so going back never takes them away. Today one: lab.nix,
# the lab testbed's flag (system/Modular/lab/lab-door.nix: the dev box's SSH
# keys and the lab Wi-Fi). Max, 2026-11-16: the door and the network stay on
# the notebooks. Going back restores the machine layer from the older
# version's own copy, and a version made before the flag existed has none:
# the MacBook lost its lab.nix that way on 2026-11-16.
#
# Only a file the system being LEFT carried is kept: root built that system,
# so its copy (in the store) is one root vouches for. A lab.nix that only the
# owner's checkout has is an edit like any other, and is not kept or trusted.
standing_files=(lab.nix)

# keep_standing <system left> <machine layer dir> <trusted dir> <owner>
#   For each standing file the left system carried that the machine layer
#   lacks now: put it back from the left system's copy, stage it, and add it
#   to <trusted dir> (what golem-seal-heal may take as the machine's own).
keep_standing() {
  local from="$1/etc/golem/machine" layer="$2" trusted="$3" owner="$4" b
  for b in "${standing_files[@]}"; do
    if [ ! -f "$from/$b" ] || [ -e "$layer/$b" ]; then
      continue
    fi
    install -m 0644 -o "$owner" -g "$(id -gn "$owner")" "$from/$b" "$layer/$b"
    asowner git add -f "$layer/$b"
    cp -L "$from/$b" "$trusted/$b"
    echo "golem-recover: kept $layer/$b (a choice of this machine, not of a version)"
  done
}
