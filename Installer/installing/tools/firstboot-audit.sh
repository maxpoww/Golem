#!/usr/bin/env bash
# The constitution's rule-6 first-boot audit, for a STAGE-0 machine.
#
#   ./firstboot-audit.sh 192.168.1.109 [user]
#
# Rule 6 says a pass is recorded with its NUMBERS — "it booted" is not a
# record. This prints those numbers in one pass so an install entry can be
# written from the output rather than from memory. Stage-1 items (the
# waverunner lock, the appliers, the DockMenu harness) are deliberately
# absent: a minimal has none of them, and asserting their absence is part
# of the audit, not a gap in it.
#
# Read-only. It runs no command that changes the machine.
set -uo pipefail

IP=${1:?usage: firstboot-audit.sh <ip> [user]}
USER_=${2:-root}
SSHOPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=10"

ssh $SSHOPTS "$USER_@$IP" 'bash -s' <<'REMOTE'
set -uo pipefail
line() { printf '\n── %s\n' "$1"; }

line "identity"
echo "hostname            $(hostname)"
echo "root device         $(findmnt -no SOURCE / 2>/dev/null)"
echo "generation          $(readlink /run/current-system 2>/dev/null | sed 's|.*/||')"
# The revision is NOT a file in the toplevel — it is baked into
# nixos-version. Reading /run/current-system/configuration-revision
# always reported "(none)" and told us nothing (fixed 2026-09-14).
echo "configurationRev    $(nixos-version --json 2>/dev/null | grep -oE '"configurationRevision":"[^"]*"' | cut -d'"' -f4)"

line "health (rule 6: running + ZERO failed units)"
echo "is-system-running   $(systemctl is-system-running 2>/dev/null)"
echo "failed units        $(systemctl list-units --state=failed --no-legend --plain 2>/dev/null | wc -l)"
systemctl list-units --state=failed --no-legend --plain 2>/dev/null | sed 's/^/                    /'
echo "boot time           $(systemd-analyze 2>/dev/null | head -1)"

line "memory tier vs RAM"
echo "RAM                 $(( $(grep -m1 MemTotal /proc/meminfo | grep -oE '[0-9]+') / 1024 )) MB"
swapon --show 2>/dev/null | sed 's/^/                    /'
for k in vm.swappiness vm.vfs_cache_pressure vm.dirty_ratio vm.page-cluster; do
  printf '%-22s%s\n' "$k" "$(sysctl -n $k 2>/dev/null)"
done
echo "nix max-jobs        $(grep -E '^max-jobs' /etc/nix/nix.conf 2>/dev/null | tr -d ' ' || echo '(default)')"

line "hibernation wiring (resume= must be present)"
tr ' ' '\n' < /proc/cmdline | grep -E '^resume=' || echo "resume=             MISSING"
echo "fbcon/splash (#65)  $(tr ' ' '\n' < /proc/cmdline | grep -cE '^(fbcon=map|splash)') occurrences (must be 0)"

line "owner"
owner=$(stat -c %U /home/* 2>/dev/null | head -1)
echo "owner               ${owner:-?} uid=$(id -u "${owner:-root}" 2>/dev/null) shell=$(getent passwd "${owner:-root}" 2>/dev/null | cut -d: -f7)"

line "self-rebuild (stage 0's defining requirement)"
echo "rebuild-golem       $(command -v rebuild-golem >/dev/null 2>&1 && echo present || echo MISSING)"
echo "seed                $([ -d "/home/${owner:-max}/Golem" ] && echo "/home/${owner:-max}/Golem" || echo MISSING)"
echo "seed modules.nix    $([ -f "/home/${owner:-max}/Golem/hosts/target/modules.nix" ] && echo present || echo MISSING)"

line "MINIMAL means minimal (these must all be absent)"
for p in hyprland greetd waybar waverunner; do
  printf '%-20s%s\n' "$p" "$(command -v $p >/dev/null 2>&1 && echo 'PRESENT — not minimal!' || echo absent)"
done

line "hardware leaves, as chosen"
echo "LIBVA               $(grep -oE 'LIBVA_DRIVER_NAME="[^"]*"' /etc/set-environment 2>/dev/null || echo '(unset)')"
echo "thermald            $(systemctl is-active thermald 2>/dev/null)"
# NOTE: `grep -c` already prints 0 and exits 1 when it matches nothing —
# a `|| echo 0` here appends a SECOND line and mangles the report. Found
# by running this script instead of trusting it.
echo "microcode           $(journalctl -b -o cat 2>/dev/null | grep -ciE 'microcode updated|microcode: ') log lines"

line "bootloader (#68 — the GRUB theme is only TRUE on the screen)"
echo "grub theme on disk  $([ -f /boot/theme/theme.txt ] && echo present || echo absent)"
echo "grub.cfg theme line $([ -f /boot/grub/grub.cfg ] && grep -c 'set theme=' /boot/grub/grub.cfg || echo 0)"
echo "bootctl noise (#68) $(journalctl -b -o cat 2>/dev/null | grep -c 'Not booted with UEFI') occurrences (must be 0 on BIOS)"

line "network (#64 — did it rejoin by itself?)"
nmcli -t -f NAME,DEVICE,STATE con show --active 2>/dev/null | sed 's/^/                    /'
for d in /sys/class/net/*/device/driver; do
  [ -e "$d" ] && printf '%-20s%s\n' "$(echo "$d" | cut -d/ -f5)" "$(basename "$(readlink -f "$d")")"
done
REMOTE
