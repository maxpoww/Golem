#!/bin/sh
# lab-pull.sh — bring a lab machine's Golem checkout to GitHub's main the way
# the nightly auto-update does: a clean fast-forward from upstream, then
# re-seal (golem-bless), then switch. Run AS ROOT on the machine:
#
#     ssh root@<ip> 'sh -s' < tools/deploy/lab-pull.sh
#
# Why the bless: the install helper (waverunner-apply) only rebuilds a seed
# that matches its blessed manifest. A pull without the bless left the
# ThinkPad refusing every app install from the dock (DaVinci Resolve,
# 2026-10-01). The bless happens ONLY when the tree is exactly upstream:
# a fast-forward pull and no local edits beyond the machine's own staged
# hosts/target files — never a local change (that is the owner's to bless).
# hosts/target is the machine's own layer in ANY state: the installer
# rewrites apps.nix.last-good after each install without re-staging it, so
# after an adopt it reads "AM" (ASUS, 2026-10-02) — not an owner edit.
set -eu
attr="${GOLEM_ATTR:-golem-desktop}"
owner=$(stat -c %U /home/*/Golem 2>/dev/null | head -1)
dir=$(ls -d /home/*/Golem | head -1)
cd "$dir"
runuser -u "$owner" -- git pull -q --ff-only
head=$(git rev-parse HEAD); up=$(git rev-parse origin/main)
[ "$head" = "$up" ] || { echo "lab-pull: HEAD $head is not origin/main $up — not blessing" >&2; exit 1; }
# Tracked changes other than the machine's own files mean a local edit.
if git status --porcelain --untracked-files=no | grep -v -E '^[AM ][AM ] hosts/target/' | grep -q .; then
  echo "lab-pull: local edits in the checkout — not blessing:" >&2
  git status --porcelain --untracked-files=no | grep -v -E '^[AM ][AM ] hosts/target/' >&2
  exit 1
fi
golem-bless
nixos-rebuild switch --flake "$dir#$attr"
