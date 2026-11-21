#!/usr/bin/env bash
# golem-machine-scaffold — a NEW machine's folder, from the template and the
# installer's answers (docs/system/Layout.md, stage 3: what golem-install
# calls where it used to write hosts/target/machine.nix).
#
#   golem-machine-scaffold --to /mnt/etc/nixos --standard <Standard source> \
#     --owner ana --hostname thinkpad --fullname "Ana Pérez" \
#     --locale es_AR.UTF-8 --timezone America/Argentina/Buenos_Aires \
#     --kb-layout latam --kb-model pc105 --kb-console la-latin1 \
#     --facts <facts.json | golem-hardware.nix> --hardware-config <file> \
#     [--kb-variant V] [--kb-options O] [--kb-font F] [--profile desktop|minimal] \
#     [--luks-uuid UUID] [--grub-device /dev/disk/by-id/…]
#
# It only writes the folder: no lock (the caller pins the Standard on the
# medium), no build. Every answer is written as a Nix STRING, escaped here:
# a name with a quote, a backslash or ${ in it stays a name.
#
# All or nothing: the folder is made beside its place and moved in at the
# end, so a run that fails leaves nothing behind and can be run again. A
# folder that is already there (nixos-generate-config's) is kept: its stock
# configuration.nix is set aside as configuration.nix.before-golem.
set -euo pipefail

to=""; golem=""; profile=desktop; facts=""; hwconf=""
owner=""; hostname=""; fullname=""; locale="en_US.UTF-8"; timezone="UTC"
kb_layout="us"; kb_variant=""; kb_options=""; kb_model="pc104"; kb_console="us"; kb_font=""
luks_uuid=""; grub_device=""
while [ $# -gt 0 ]; do
  case "$1" in
    --to) to=$2 ;; --standard) golem=$2 ;; --profile) profile=$2 ;;
    --facts) facts=$2 ;; --hardware-config) hwconf=$2 ;;
    --owner) owner=$2 ;; --hostname) hostname=$2 ;; --fullname) fullname=$2 ;;
    --locale) locale=$2 ;; --timezone) timezone=$2 ;;
    --kb-layout) kb_layout=$2 ;; --kb-variant) kb_variant=$2 ;; --kb-options) kb_options=$2 ;;
    --kb-model) kb_model=$2 ;; --kb-console) kb_console=$2 ;; --kb-font) kb_font=$2 ;;
    --luks-uuid) luks_uuid=$2 ;; --grub-device) grub_device=$2 ;;
    *) echo "golem-machine-scaffold: unknown argument: $1" >&2; exit 2 ;;
  esac
  shift 2
done
die() { echo "golem-machine-scaffold: $*" >&2; exit 1; }

[ -n "$to" ] && [ -n "$golem" ] || die "--to <folder> and --standard <Standard source> are needed"
template="$golem/system/machine/template"
[ -f "$template/configuration.nix" ] || die "no template in $golem (system/machine/template)"
[ -n "$owner" ] && [ -n "$hostname" ] || die "--owner and --hostname are needed"
[[ "$owner" =~ ^[a-z_][a-z0-9_-]*$ ]] || die "the owner's login name must be lower-case letters, digits, _ or -"
[[ "$hostname" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?$ ]] || die "the computer's name must be letters, digits or -"
case "$profile" in desktop|minimal) ;; *) die "--profile is desktop or minimal" ;; esac
[ -f "$facts" ] || die "--facts <the census's file> is needed"
[ -f "$hwconf" ] || die "--hardware-config <nixos-generate-config's file> is needed"
[ ! -e "$to/flake.nix" ] || die "$to/flake.nix exists: this machine already has its folder"
[ ! -e "$to/configuration.nix.before-golem" ] || die "$to/configuration.nix.before-golem is in the way: move it first"

# A value as the inside of a Nix "…" string.
nixstr() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//\$\{/\\\$\{}
  printf '%s' "$s"
}

command -v nix-instantiate >/dev/null || case "$facts" in *.json) ;; *) die "nix-instantiate is needed to read $facts" ;; esac

dest=$to
mkdir -p "$(dirname "$dest")"
to=$(mktemp -d "$dest.new.XXXXXX")
trap 'rm -rf "$to"' EXIT

mkdir -p "$to/modules" "$to/machine"
install -m 644 "$template/flake.nix" "$to/flake.nix"
install -m 644 "$template/modules/README.md" "$to/modules/README.md"
install -m 644 "$template/machine/README.md" "$to/machine/README.md"
install -m 644 "$hwconf" "$to/hardware-configuration.nix"

# The lines only some machines have, as the installer wrote them in machine.nix.
extra=""
if [ -n "$kb_font" ]; then
  extra+=$'\n'"  standard.keyboard.consoleFont = \"$(nixstr "$kb_font")\";"$'\n'
fi
if [ -n "$luks_uuid" ]; then
  extra+=$'\n'"  # Unlocked once in initrd; swap and root are LVM inside it,"
  extra+=$'\n'"  # which is what lets hibernation resume from an encrypted swap."
  extra+=$'\n'"  boot.initrd.luks.devices.standard.device = \"/dev/disk/by-uuid/$(nixstr "$luks_uuid")\";"$'\n'
fi
if [ -n "$grub_device" ]; then
  extra+=$'\n'"  # BIOS/legacy boot: GRUB embeds into this disk's BIOS-boot"
  extra+=$'\n'"  # partition. by-id so it survives device-name reshuffles."
  extra+=$'\n'"  boot.loader.grub.device = \"$(nixstr "$grub_device")\";"$'\n'
fi

# The template, each @mark@ replaced by its answer. Line by line and by plain
# string replacement with patsub_replacement off: an `&` in an answer is an
# `&`, not "what was matched" (bash 5.2).
shopt -u patsub_replacement 2>/dev/null || true
out=""
while IFS= read -r line || [ -n "$line" ]; do
  if [ "$line" = "@machine_extra@" ]; then
    out+="$extra"$'\n'
    continue
  fi
  line=${line//@owner@/$(nixstr "$owner")}
  line=${line//@hostname@/$(nixstr "$hostname")}
  line=${line//@fullname@/$(nixstr "$fullname")}
  line=${line//@locale@/$(nixstr "$locale")}
  line=${line//@timezone@/$(nixstr "$timezone")}
  line=${line//@kb_layout@/$(nixstr "$kb_layout")}
  line=${line//@kb_variant@/$(nixstr "$kb_variant")}
  line=${line//@kb_options@/$(nixstr "$kb_options")}
  line=${line//@kb_model@/$(nixstr "$kb_model")}
  line=${line//@kb_console@/$(nixstr "$kb_console")}
  out+="$line"$'\n'
done < "$template/configuration.nix"
printf '%s' "$out" > "$to/configuration.nix"

# The facts, as data: the census's JSON as it is, or its older Nix form
# evaluated alone.
case "$facts" in
  *.json) install -m 644 "$facts" "$to/machine/facts.json" ;;
  *)
    nix-instantiate --eval --strict --json \
      --argstr file "$(readlink -f "$facts")" \
      --expr '{ file }: (import file { }).standard.hardware' \
      > "$to/machine/facts.json" || die "could not read the facts from $facts"
    ;;
esac
grep -q '^[[:space:]]*{' "$to/machine/facts.json" || die "the facts did not come out as an object"

printf '{ "profile": "%s", "hostname": "%s" }\n' "$profile" "$hostname" > "$to/machine/install.json"
chmod 755 "$to" "$to/modules" "$to/machine"

# In place, whole. (What was already in the folder stays, but for a
# configuration.nix that is not this one.)
mkdir -p "$dest"
if [ -e "$dest/configuration.nix" ]; then
  mv -f "$dest/configuration.nix" "$dest/configuration.nix.before-golem"
fi
cp -a "$to/." "$dest/"
chmod 755 "$dest"
echo "golem-machine-scaffold: $dest is this machine's folder. Next: pin its Standard (flake.lock) and build $dest#default."
