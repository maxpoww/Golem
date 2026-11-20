#!/usr/bin/env bash
# golem-machine-checkout — GOLEM on a machine: root's own editable copy.
#
#   golem-machine-checkout --from <repository> [--root /mnt] [--branch stable]
#                          [--rev <commit>] [--url <upstream>]
#   golem-machine-checkout --tree <folder> --url <upstream> [--rev <commit>] …
#
# Makes /etc/nixos/golem (under --root, when the machine's disk is mounted
# somewhere: the installer) a git checkout of Golem that belongs to root:
#
#   /etc/nixos/golem/            the files. Root edits them; a rebuild builds them.
#   /var/lib/golem/golem.git/    git's own data, OUT of /etc/nixos: a rebuild
#                                copies /etc/nixos into the store, and the
#                                history has no business there.
#
# `--from` is where the files come from now (the installer's own copy of the
# repository, or the upstream's address); `--url` is what the checkout will
# ask for updates from then on (default: --from). The checkout sits on
# `--branch`, at `--rev` when given (the installer: the version it was cut
# from), else at the branch's head.
#
# `--tree` is the installer's case: its medium carries Golem's FILES, not
# their history. The folder is copied as it is and git is only told where the
# upstream is; the history arrives with the first update, which finds the
# files' commit in it by .golem-rev (golem-update, system/machine/layout.nix).
#
# .golem-rev (beside the files, never tracked) is the upstream commit the
# files are made of: what the system says it was built from, and where the
# next update starts.
set -euo pipefail

root=""; from=""; tree=""; url=""; branch=stable; rev=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root) root=${2%/} ;; --from) from=$2 ;; --tree) tree=${2%/} ;; --url) url=$2 ;;
    --branch) branch=$2 ;; --rev) rev=$2 ;;
    *) echo "golem-machine-checkout: unknown argument: $1" >&2; exit 2 ;;
  esac
  shift 2
done
die() { echo "golem-machine-checkout: $*" >&2; exit 1; }
[ -n "$from" ] || [ -n "$tree" ] || die "--from <repository> or --tree <folder> is needed"
[ -z "$from" ] || [ -z "$tree" ] || die "--from or --tree, not both"
[ -n "$url" ] || url=$from
[ -n "$url" ] || die "--tree needs --url <upstream>: where the updates will come from"
[ -z "$tree" ] || [ -f "$tree/flake.nix" ] || die "$tree does not hold Golem (no flake.nix)"

co="$root/etc/nixos/golem"
gitdir="$root/var/lib/golem/golem.git"
[ ! -e "$co/flake.nix" ] || die "$co is already there"
[ ! -e "$gitdir" ] || die "$gitdir is already there"

g() { git --git-dir="$gitdir" --work-tree="$co" "$@"; }

install -d -m 755 "$root/etc/nixos" "$co"
install -d -m 700 "$root/var/lib/golem"
trap 'rm -rf "$gitdir" "$co"' ERR

git init --quiet --initial-branch="$branch" --separate-git-dir "$gitdir" "$co"
g remote add origin "$url"
g config "branch.$branch.remote" origin
g config "branch.$branch.merge" "refs/heads/$branch"
if [ -n "$tree" ]; then
  # The files as they are; no history yet. (The medium's are read-only.)
  cp -a "$tree/." "$co/"
  chmod -R u+w "$co"
  rm -rf "$co/.git"
  if [ -z "$rev" ] && [ -f "$tree/.golem-rev" ]; then rev=$(sed 's/-dirty$//' "$tree/.golem-rev"); fi
  [[ "$rev" =~ ^[0-9a-f]{40}$ ]] || rev=""
else
  # From the copy at hand; what it records is the upstream's branch.
  g fetch --quiet --no-tags "$from" "+refs/heads/$branch:refs/remotes/origin/$branch" \
    || die "could not read branch $branch from $from"
  [ -n "$rev" ] || rev=$(g rev-parse "refs/remotes/origin/$branch")
  g cat-file -e "$rev^{commit}" 2>/dev/null || die "$from does not have the commit $rev"
  rev=$(g rev-parse "$rev^{commit}")
  g update-ref "refs/heads/$branch" "$rev"
  g symbolic-ref HEAD "refs/heads/$branch"
  g read-tree --reset -u "$rev"
fi

# As the RUNNING machine will see it (no --root in front), so that a plain
# `git status` in /etc/nixos/golem works for root.
printf 'gitdir: /var/lib/golem/golem.git\n' > "$co/.git"
g config core.worktree /etc/nixos/golem
printf '.golem-rev\nresult\nresult-*\n' >> "$gitdir/info/exclude"
rm -f "$co/.golem-rev"
[ -z "$rev" ] || printf '%s\n' "$rev" > "$co/.golem-rev"

trap - ERR
echo "golem-machine-checkout: Golem ${rev:0:12}${rev:+ }(${branch}${tree:+, its history comes with the first update}) is in $co"
