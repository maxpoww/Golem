#!/bin/sh
# lab-pull.sh — bring a lab machine's Golem checkout to the branch it follows
# the way the nightly auto-update does: a clean fast-forward from upstream,
# then re-seal (golem-bless), then switch. Run AS ROOT on the machine:
#
#     ssh root@<ip> 'sh -s' < tools/deploy/lab-pull.sh
#
# Installs follow "stable" (what the update lane published, updates/). To try
# main on a lab machine BEFORE the lane publishes it:
#
#     ssh root@<ip> 'GOLEM_LAB_BRANCH=main sh -s' < tools/deploy/lab-pull.sh
#
# The nightly update moves it back to stable, and waits there until stable
# has caught up with what the machine already runs.
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
if [ -n "${GOLEM_LAB_BRANCH:-}" ]; then
  runuser -u "$owner" -- git fetch -q origin "+refs/heads/$GOLEM_LAB_BRANCH:refs/remotes/origin/$GOLEM_LAB_BRANCH"
  runuser -u "$owner" -- git branch -q --set-upstream-to="origin/$GOLEM_LAB_BRANCH"
fi
# The machine's own Seam pin: seam-update bumps seam/sources.json in place
# when Mozilla ships (Acer, 2026-10-14: 158.0 over upstream's 157.0.1) and the
# lab refused every deploy from then on. Same rule as golem-autoupdate: set it
# aside, pull, and put it back only if it is still NEWER than upstream's —
# a machine pin is the lane's state, like hosts/target, never an owner edit.
pin=seam/sources.json; heldpin=""
if ! git diff --quiet HEAD -- "$pin" 2>/dev/null; then
  heldpin=$(mktemp); cat "$pin" > "$heldpin"
  runuser -u "$owner" -- git checkout -q HEAD -- "$pin"
fi
runuser -u "$owner" -- git pull -q --ff-only || { [ -n "$heldpin" ] && cat "$heldpin" > "$pin" && runuser -u "$owner" -- git add "$pin"; exit 1; }
if [ -n "$heldpin" ]; then
  held=$(sed -n 's/.*"version": *"\([0-9.]*\)".*/\1/p' "$heldpin")
  upv=$(sed -n 's/.*"version": *"\([0-9.]*\)".*/\1/p' "$pin")
  if [ "$held" != "$upv" ] && [ "$(printf '%s\n%s\n' "$held" "$upv" | sort -V | tail -1)" = "$held" ]; then
    cat "$heldpin" > "$pin"; runuser -u "$owner" -- git add "$pin"
    echo "lab-pull: kept this machine's newer Seam pin ($held over upstream's $upv)"
  fi
  rm -f "$heldpin"
fi
head=$(git rev-parse HEAD); up=$(git rev-parse '@{u}')
[ "$head" = "$up" ] || { echo "lab-pull: HEAD $head is not upstream's $(git rev-parse --abbrev-ref '@{u}') $up — not blessing" >&2; exit 1; }
# Tracked changes other than the machine's own files mean a local edit.
own='^[AM ][AM ] (hosts/target/|seam/sources\.json$)'
if git status --porcelain --untracked-files=no | grep -v -E "$own" | grep -q .; then
  echo "lab-pull: local edits in the checkout — not blessing:" >&2
  git status --porcelain --untracked-files=no | grep -v -E "$own" >&2
  exit 1
fi
golem-bless
# golem-rebuild: the one rebuild lock, and the version's published cache.
if command -v golem-rebuild >/dev/null 2>&1; then
  golem-rebuild switch --flake "$dir#$attr"
else
  nixos-rebuild switch --flake "$dir#$attr"
fi
