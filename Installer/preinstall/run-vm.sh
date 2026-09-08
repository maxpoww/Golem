#!/usr/bin/env bash
# Boot the minimal installer ISO in a throwaway VM.
# KVM + virtio-gl per the repo's qemu convention (GRIND.md guardrails).
#
#   ./run-vm.sh                          window on the desktop, no disk
#   ./run-vm.sh --headless               no window — the lab loop's mode,
#                                        drive it entirely over SSH
#   ./run-vm.sh --disk golem.qcow2:40G   attach a target disk, creating it
#                                        at that size if absent
#
# The VM deliberately gets 4096 MB: that is the lab's tight-RAM class (row
# 1, the Acer, has 3833 MB usable). Testing the census at 8 GB would hide
# exactly the memory pressure the low tier exists to survive.
#
# hostfwd: the lab loop drives the medium over SSH — in the VM that's
# `ssh -p 2222 nixos@127.0.0.1` (key-only, the golem-vm-loop key).
# monitor: the boot menu waits forever by design, so the automated loop
# presses Enter for it:  echo sendkey ret | socat - unix:/tmp/golem-vm-hmp
set -euo pipefail
cd "$(dirname "$0")"

ISO="result/iso/golem-installer.iso"
HEADLESS=false
UEFI=false
NOCD=false
DISK=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --headless) HEADLESS=true; shift ;;
    --uefi)     UEFI=true; shift ;;
    --no-cd)    NOCD=true; shift ;;
    --disk)     DISK="${2:?--disk needs FILE[:SIZE]}"; shift 2 ;;
    --iso)      ISO="${2:?--iso needs a path}"; shift 2 ;;
    -h|--help)  sed -n '2,22p' "$0"; exit 0 ;;
    *)          echo "run-vm.sh: unknown argument '$1'" >&2; exit 2 ;;
  esac
done

args=(
  -enable-kvm -cpu host -smp 4 -m 4096
  -nic user,model=virtio-net-pci,hostfwd=tcp:127.0.0.1:2222-:22
  -monitor unix:/tmp/golem-vm-hmp,server,nowait
  -name "Golem installer (minimal)"
  # The guest-agent channel. virt-guest.nix turns qemu-guest-agent on when
  # the census says vmGuest="qemu", and without this device the unit is
  # enabled but can never start — the first installed system showed it
  # "inactive (dead)" and that looked like a Golem bug when it was a
  # missing virtio-serial port (same class as the -vga none miss above).
  -device virtio-serial
  -chardev socket,path=/tmp/golem-vm-qga,server=on,wait=off,id=qga0
  -device virtserialport,chardev=qga0,name=org.qemu.guest_agent.0
)

if [ "$NOCD" = false ]; then
  [ -e "$ISO" ] || { echo "no ISO at $ISO — nix build .#iso -o result first" >&2; exit 1; }
  args+=(-cdrom "$ISO" -boot d)
fi

# Golem installs systemd-boot and wants EFI variables
# (system/configuration.nix:100). qemu's default is SeaBIOS, so an
# installed Golem simply has nothing to boot from in a default VM —
# --uefi is REQUIRED to test the install, not a nicety. OVMF_VARS is
# copied per-VM because the firmware writes the boot entry into it, and a
# store path is read-only.
if [ "$UEFI" = true ]; then
  ovmf=$(nix build --no-link --print-out-paths nixpkgs#OVMF.fd)
  vars="ovmf-vars.fd"
  if [ ! -e "$vars" ]; then
    cp "$ovmf/FV/OVMF_VARS.fd" "$vars"
    chmod +w "$vars"
    echo "created $vars (per-VM EFI variable store)" >&2
  fi
  args+=(
    -drive "if=pflash,format=raw,unit=0,readonly=on,file=$ovmf/FV/OVMF_CODE.fd"
    -drive "if=pflash,format=raw,unit=1,file=$vars"
  )
fi

if [ -n "$DISK" ]; then
  file="${DISK%%:*}"
  size="${DISK#*:}"; [ "$size" = "$DISK" ] && size="40G"
  if [ ! -e "$file" ]; then
    echo "creating target disk $file ($size)" >&2
    nix shell nixpkgs#qemu --command qemu-img create -f qcow2 "$file" "$size" >&2
  fi
  # The serial gives the disk a /dev/disk/by-id alias, like every real
  # disk. Without one the BIOS install branch found no by-id path and the
  # round-2 engine died resolving it (changes.md #19) — the rig should
  # look like hardware, but keep the no-serial case in mind when #19's
  # engine fix needs verifying. (qemu removed -drive serial=; it lives on
  # the -device now.)
  args+=(-drive "file=$file,if=none,id=target,format=qcow2"
         -device "virtio-blk-pci,drive=target,serial=golemtarget")
fi

if [ "$HEADLESS" = true ]; then
  # No WINDOW, but still a GPU. `-vga none` with nothing in its place
  # leaves /sys/class/drm empty, and the census then honestly reports
  # gpu="auto" — a headless run that quietly tests a machine no one will
  # ever own (caught 2026-09-04, first live decide run). virtio-gpu-pci
  # without a display keeps the guest's hardware realistic.
  # Caveat: this gives SeaBIOS/syslinux nothing to draw on, so a headless
  # BIOS boot screendumps as "Display output is not active". The system
  # boots and the census runs fine; only the BIOS *boot menu* is invisible.
  # To photograph that one, swap in `-vga std`.
  args+=(-display none -vga none -device virtio-gpu-pci -serial null)
else
  args+=(-device virtio-vga-gl -display gtk,gl=on)
fi

exec nix shell nixpkgs#qemu --command qemu-system-x86_64 "${args[@]}"
