#!/usr/bin/env bash
# golem-relocate — a machine installed BEFORE the /etc/nixos layout, moved to
# it (docs/system/Layout.md, stage 4).
#
# What it had, inside the owner's checkout:        What it gets:
#   ~/Golem/hosts/target/machine.nix                 /etc/nixos/configuration.nix   (the same lines, now the owner's file)
#   ~/Golem/hosts/target/hardware-configuration.nix  /etc/nixos/hardware-configuration.nix
#   ~/Golem/hosts/target/golem-hardware.nix          /etc/nixos/machine/facts.json  (the same facts, as data)
#   ~/Golem/hosts/target/modules.nix                 — (the chooser runs at every build now)
#   ~/Golem/hosts/target/apps.nix                    /etc/nixos/machine/apps.list   (the same names, one a line)
#   ~/Golem/hosts/target/lab.nix                     /etc/nixos/modules/lab.nix
#   ~/Golem/system/postinstall-generated.nix         /etc/nixos/machine/answers.list
#   (the checkout's commit)                          /etc/nixos/flake.lock          (the same Standard, pinned)
#
# It only WRITES THE FOLDER. It builds nothing and switches nothing: the
# caller (the update, or a person) then runs `nixos-rebuild boot --flake
# <to>#default`, and removes the old checkout when that system has started.
# The folder is made beside its place and moved in whole; an existing
# /etc/nixos with a flake.nix is left alone.
#
#   golem-relocate --from ~/Golem [--to /etc/nixos] [--standard <Standard source>] [--profile desktop|minimal]
#
# --standard: where the template is read from (the Standard that will run:
#          /etc/nixos/standard on a system built with this layout, or a checkout).
# Needs: bash, coreutils, grep, sed, nix-instantiate (to read the facts).
set -euo pipefail

from=""; to=/etc/nixos; golem=""; profile=desktop
while [ $# -gt 0 ]; do
  case "$1" in
    --from) from=$2; shift 2 ;;
    --to) to=$2; shift 2 ;;
    --standard) golem=$2; shift 2 ;;
    --profile) profile=$2; shift 2 ;;
    *) echo "golem-relocate: unknown argument: $1" >&2; exit 2 ;;
  esac
done
die() { echo "golem-relocate: $*" >&2; exit 1; }

[ -n "$from" ] || die "--from <the checkout> is needed"
[ -n "$golem" ] || golem=$from
target="$from/hosts/target"
template="$golem/system/machine/template"
[ -f "$template/flake.nix" ] || die "no template in $golem (system/machine/template): not a Standard with the /etc/nixos layout"
for f in machine.nix golem-hardware.nix hardware-configuration.nix; do
  [ -f "$target/$f" ] || die "$target/$f is missing: not an installed Standard's checkout"
done
case "$profile" in desktop|minimal) ;; *) die "--profile is desktop or minimal" ;; esac
[ ! -e "$to/flake.nix" ] || die "$to/flake.nix exists: this machine already has its folder"

parent=$(dirname "$to")
new=$(mktemp -d "$parent/.$(basename "$to").relocate.XXXXXX")
trap 'rm -rf "$new"' EXIT
mkdir -p "$new/modules" "$new/machine"

# ── the entry point and the two READMEs, as the installer writes them ──
install -m 644 "$template/flake.nix" "$new/flake.nix"
install -m 644 "$template/modules/README.md" "$new/modules/README.md"
install -m 644 "$template/machine/README.md" "$new/machine/README.md"

# ── configuration.nix: the template's head, then machine.nix as it is ──
# (machine.nix IS a module of plain settings: the installer's answers, and
# whatever the owner added since. Nothing in it is rewritten.)
{
  sed -n '1,/^{ config, lib, pkgs, \.\.\. }:$/p' "$template/configuration.nix" | sed '$d'
  echo "#"
  echo "# (Moved here from the old layout's hosts/target/machine.nix on $(date -I).)"
  cat "$target/machine.nix"
} > "$new/configuration.nix"

install -m 644 "$target/hardware-configuration.nix" "$new/hardware-configuration.nix"
[ ! -f "$target/lab.nix" ] || install -m 644 "$target/lab.nix" "$new/modules/lab.nix"

# ── the facts, as data ──
# (golem-hardware.nix is the census's own output: a module that only sets
# standard.hardware. Evaluated alone, with nothing but its own text.)
nix-instantiate --eval --strict --json \
  --argstr file "$target/golem-hardware.nix" \
  --expr '{ file }: (import file { }).standard.hardware' \
  > "$new/machine/facts.json" \
  || die "could not read the facts from $target/golem-hardware.nix"
grep -q '^{' "$new/machine/facts.json" || die "the facts did not come out as an object"

# ── the stage, and the name it answers to ──
hn=$(sed -n 's/^[[:space:]]*networking\.hostName[[:space:]]*=[[:space:]]*"\([A-Za-z0-9-]*\)";.*/\1/p' "$target/machine.nix" | head -1)
if [ -n "$hn" ]; then
  printf '{ "profile": "%s", "hostname": "%s" }\n' "$profile" "$hn" > "$new/machine/install.json"
else
  printf '{ "profile": "%s" }\n' "$profile" > "$new/machine/install.json"
fi

# ── the apps installed from the dock: the names, one a line ──
# (The generated apps.nix lists each as an indented, quoted name; the same
# shape system/home/app-list.nix reads. Every other line is not a name.)
if [ -f "$target/apps.nix" ]; then
  {
    echo "# The programs installed from the dock: one nixpkgs name per line."
    grep -E '^[[:space:]]+"?[a-zA-Z0-9][a-zA-Z0-9._-]*"?[[:space:]]*$' "$target/apps.nix" \
      | sed -E 's/^[[:space:]]+"?//; s/"?[[:space:]]*$//' || true
  } > "$new/machine/apps.list"
fi

# ── the answers given after the install: the same lines, read as data ──
if [ -f "$from/system/postinstall-generated.nix" ]; then
  {
    echo "# The answers given to Standard's questions after the install (\"question\" = \"answer\";)."
    grep -E '^[[:space:]]*"[A-Za-z0-9._-]+"[[:space:]]*=[[:space:]]*"[A-Za-z0-9._-]+";[[:space:]]*$' \
      "$from/system/postinstall-generated.nix" || true
  } > "$new/machine/answers.list"
fi

# ── the questions Standard is deliberately not answering for this machine ──
if [ -f "$target/postinstall-questions.json" ]; then
  install -m 644 "$target/postinstall-questions.json" "$new/machine/questions.json"
fi

# ── in place, whole ──
# (An /etc/nixos that holds only what the installer left — a stray
# hardware-configuration.nix — is kept beside the new one, never deleted.)
if [ -d "$to" ]; then
  mv "$to" "$to.before-relocate.$(date +%s)"
fi
chmod 755 "$new"
mv "$new" "$to"
trap - EXIT
echo "golem-relocate: $to is this machine's folder now."
echo "golem-relocate: next: Standard beside it ($to/standard: golem-machine-checkout), then nixos-rebuild boot --flake $to#default"
