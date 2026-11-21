#!/usr/bin/env bash
# recover-standing-test.sh: the standing files of the machine layer survive
# going back (recover-standing.sh). Runs as any user, no root, no Nix:
#   bash system/Modular/base/recover-standing-test.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=recover-standing.sh
source "$here/recover-standing.sh"
asowner() { "$@"; }
me=$(id -un)
fails=0; n=0
check() { n=$((n + 1)); if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fails=$((fails + 1)); fi; }

t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
setup() {
  rm -rf "$t"/*; mkdir -p "$t/repo/hosts/target" "$t/left/etc/golem/machine" "$t/trusted"
  git -C "$t/repo" init -q; git -C "$t/repo" -c user.email=t@t -c user.name=t commit -q --allow-empty -m base
  echo '{ }' > "$t/repo/hosts/target/machine.nix"
}
lab='{ standard.lab.door = true; }'

# 1. The left system had lab.nix; the version gone back to did not: it comes back, staged, trusted.
setup; echo "$lab" > "$t/left/etc/golem/machine/lab.nix"
(cd "$t/repo" && keep_standing "$t/left" hosts/target "$t/trusted" "$me") >/dev/null
check "1 the flag comes back" '[ "$(cat "$t/repo/hosts/target/lab.nix")" = "$lab" ]'
check "  staged (a flake sees it)" 'git -C "$t/repo" diff --cached --name-only | grep -qx hosts/target/lab.nix'
check "  trusted for the seal" 'cmp -s "$t/trusted/lab.nix" "$t/left/etc/golem/machine/lab.nix"'

# 2. The left system had none: nothing is made up.
setup
(cd "$t/repo" && keep_standing "$t/left" hosts/target "$t/trusted" "$me") >/dev/null
check "2 no flag where the machine had none" '[ ! -e "$t/repo/hosts/target/lab.nix" ] && [ ! -e "$t/trusted/lab.nix" ]'

# 3. The version gone back to already has it: left as it is, not trusted twice.
setup; echo "$lab" > "$t/left/etc/golem/machine/lab.nix"; echo '# its own' > "$t/repo/hosts/target/lab.nix"
(cd "$t/repo" && keep_standing "$t/left" hosts/target "$t/trusted" "$me") >/dev/null
check "3 a restored flag is not replaced" '[ "$(cat "$t/repo/hosts/target/lab.nix")" = "# its own" ] && [ ! -e "$t/trusted/lab.nix" ]'

# 4. Only the owner's checkout had it (not the left system): not kept, not trusted.
setup; echo "$lab" > "$t/owner-made-lab.nix"
(cd "$t/repo" && keep_standing "$t/left" hosts/target "$t/trusted" "$me") >/dev/null
check "4 an owner-made flag is not taken as the machine's" '[ ! -e "$t/repo/hosts/target/lab.nix" ] && [ ! -e "$t/trusted/lab.nix" ]'

# 5. The left system's copy is a link into the store (as /etc/golem/machine is): followed.
setup; mkdir -p "$t/store"; echo "$lab" > "$t/store/lab.nix"; rmdir "$t/left/etc/golem/machine"; ln -s "$t/store" "$t/left/etc/golem/machine"
(cd "$t/repo" && keep_standing "$t/left" hosts/target "$t/trusted" "$me") >/dev/null
check "5 through a link, as in the store" '[ -f "$t/repo/hosts/target/lab.nix" ] && [ ! -L "$t/repo/hosts/target/lab.nix" ] && [ -f "$t/trusted/lab.nix" ]'

echo "passed $((n - fails))/$n"
[ "$fails" = 0 ]
