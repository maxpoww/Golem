#!/usr/bin/env bash
# golem deep probe, ROOT half: the machine's health and maintenance state.
# Plain bash; every probe is bounded and tolerant. Sections open with
# "===<name>===". Pair with deep-user.sh (the session half).
set -u
section() { printf '\n===%s===\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }
OWNER=${GOLEM_OWNER:-max}

section meta
echo "host=$(hostname) product=$(cat /sys/class/dmi/id/product_name 2>/dev/null) kernel=$(uname -r) up=$(uptime -p 2>/dev/null)"
echo "system=$(readlink /run/current-system) booted=$(readlink /run/booted-system)"
echo "generations=$(ls -d /nix/var/nix/profiles/system-*-link 2>/dev/null | wc -l)"
echo "config-revision=$(nixos-version --configuration-revision 2>/dev/null)"

section failed_units
systemctl --failed --no-legend --plain 2>/dev/null
echo "-- restarts (units that died and came back this boot):"
# journald's one restart every boot is the initrd → root handoff, not a death
for u in $(systemctl list-units --type=service --no-legend --plain 2>/dev/null | awk '{print $1}' | grep -v '^systemd-journald.service$'); do
  n=$(systemctl show "$u" -p NRestarts --value 2>/dev/null); [ "${n:-0}" -gt 0 ] && echo "$u restarts=$n"
done | head -10

section timers
systemctl list-timers --all --no-legend --plain 2>/dev/null | awk '{print $NF, $1, $2, $3}' | grep -E 'golem|nix-gc|fstrim|seam|logrotate|nixos-upgrade' | sed -E 's#/nix/store/[^ ]+##'

# The self-maintenance loop: can this machine keep itself up to date?
section maintenance
d=/home/$OWNER/Golem
if git -C "$d" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "seed: git repo, remote=$(git -C "$d" remote get-url origin 2>/dev/null || echo NONE) head=$(git -C "$d" rev-parse --short HEAD 2>/dev/null)"
else echo "seed: NOT a git repo ($d) -> autoupdate cannot pull"; fi
echo "first-boot stamp: $([ -e /var/lib/golem/first-boot.done ] && echo done || echo MISSING)"
echo "seal manifest: $([ -e /var/lib/golem/seed.manifest ] && wc -l < /var/lib/golem/seed.manifest || echo MISSING) files"
have golem-seal-check && { golem-seal-check >/tmp/seal.out 2>&1 && echo "seal check: ok" || { echo "seal check: FAIL"; head -3 /tmp/seal.out; }; }
echo "-- golem-autoupdate last run:"
journalctl -u golem-autoupdate --no-pager -o cat -n 6 2>/dev/null | cut -c1-140
echo "-- golem-first-boot: $(systemctl show golem-first-boot -p Result --value 2>/dev/null)"
echo "-- waverunner-apply: path=$(systemctl is-active waverunner-apply.path 2>/dev/null) last=$(systemctl show waverunner-apply -p Result --value 2>/dev/null)"
echo "-- seam-update: timer=$(systemctl is-active seam-update.timer 2>/dev/null) last=$(systemctl show seam-update -p Result --value 2>/dev/null) $(journalctl -u seam-update --no-pager -o cat -n 2 2>/dev/null | tail -1 | cut -c1-100)"
echo "-- rebuild-golem: $(command -v rebuild-golem || echo MISSING)"

section crashes
have coredumpctl && coredumpctl list --no-pager --since "$(date -d @$(( $(date +%s) - $(cut -d. -f1 /proc/uptime) )) '+%F %T')" 2>/dev/null | awk 'NR>1{print $NF}' | sed -E 's#/nix/store/[^/]+/##' | sort | uniq -c | sort -rn | head -8
echo "-- kernel: $(journalctl -k -b --no-pager -o cat 2>/dev/null | grep -ciE 'segfault|general protection|oom-kill|Out of memory')  segfault/oom lines"

section journal_errors
echo "-- system errors this boot (deduplicated, top 12):"
journalctl -b -p err --no-pager -o cat 2>/dev/null | grep -vE '^\s*$|Stack trace|^#[0-9]' | sed -E 's/[0-9a-f]{32}/H/g; s/[0-9]+/N/g' | sort | uniq -c | sort -rn | head -12 | cut -c1-150
echo "-- 'Failed to start' / timed out:"
journalctl -b --no-pager -o cat 2>/dev/null | grep -E 'Failed to start|Timed out|start-limit-hit|Start request repeated too quickly' | sed -E 's/[0-9]+/N/g' | sort | uniq -c | sort -rn | head -6 | cut -c1-140
echo "-- firmware:"
journalctl -k -b --no-pager -o cat 2>/dev/null | grep -iE 'firmware.*(fail|missing|not found)|failed to load' | sort -u | head -5 | cut -c1-140
echo "-- throttling: $(journalctl -k -b --no-pager -o cat 2>/dev/null | grep -ciE 'throttl|thermal event|critical temperature') lines"

section boot
have systemd-analyze && { systemd-analyze time 2>/dev/null; systemd-analyze blame 2>/dev/null | head -6; }

section storage
df -h / /boot /nix /home /tmp 2>/dev/null | awk 'NR==1||!seen[$1$6]++' | sed -E 's/  +/ /g'
echo "boot files: $(ls /boot 2>/dev/null | wc -l) entries, kernels=$(ls /boot/kernels /boot/EFI/nixos 2>/dev/null | grep -c . )"
echo "nix store: $(du -sh /nix/store 2>/dev/null | cut -f1)  gc: $(systemctl is-active nix-gc.timer 2>/dev/null) optimise: $(systemctl is-active nix-optimise.timer 2>/dev/null) fstrim: $(systemctl is-active fstrim.timer 2>/dev/null)"
echo "encryption: $(lsblk -o TYPE 2>/dev/null | grep -c crypt) crypt dev(s)"
echo "tmp: $(findmnt -no FSTYPE /tmp 2>/dev/null || echo 'on root')"
echo "substituters: $(nix show-config 2>/dev/null | grep -E '^substituters' | cut -c1-140)"

section memory
free -m | awk '/^Mem:/{printf "ram %d MB, used %d, avail %d\n",$2,$3,$7}'
have zramctl && zramctl 2>/dev/null | awk 'NR>1{print "zram", $1, $3, "used", $4}'
swapon --show=NAME,SIZE,USED,PRIO --noheadings 2>/dev/null | sed 's/^/swap /'
echo "swappiness=$(cat /proc/sys/vm/swappiness) resume=$(grep -oE 'resume=[^ ]+' /proc/cmdline || echo none)"
echo "psi: $(head -1 /proc/pressure/memory 2>/dev/null)"

section power
echo "governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null) driver=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver 2>/dev/null) epp=$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null)"
echo "profile=$(cat /sys/firmware/acpi/platform_profile 2>/dev/null) ppd=$(systemctl is-active power-profiles-daemon 2>/dev/null) tlp=$(systemctl is-active tlp 2>/dev/null) thermald=$(systemctl is-active thermald 2>/dev/null) upower=$(systemctl is-active upower 2>/dev/null)"
for b in /sys/class/power_supply/BAT*; do [ -d "$b" ] && echo "battery: $(cat $b/status 2>/dev/null) $(cat $b/capacity 2>/dev/null)% health=$(( $(cat $b/energy_full 2>/dev/null || cat $b/charge_full 2>/dev/null || echo 0) * 100 / ($(cat $b/energy_full_design 2>/dev/null || cat $b/charge_full_design 2>/dev/null || echo 1)) ))% thresholds=$(cat $b/charge_control_start_threshold 2>/dev/null)-$(cat $b/charge_control_end_threshold 2>/dev/null)"; done
echo "lid: HandleLidSwitch=$(grep -hE '^HandleLidSwitch=' /etc/systemd/logind.conf /etc/systemd/logind.conf.d/* 2>/dev/null | tail -1 | cut -d= -f2) (default suspend) ExternalPower=$(grep -hE '^HandleLidSwitchExternalPower=' /etc/systemd/logind.conf 2>/dev/null | cut -d= -f2)"
echo "idle: IdleAction=$(grep -hE '^IdleAction=' /etc/systemd/logind.conf 2>/dev/null | cut -d= -f2)"
echo "wifi powersave: $(iw dev 2>/dev/null | awk '/Interface/{print $2}' | head -1 | xargs -I{} iw dev {} get power_save 2>/dev/null)"
have sensors && sensors 2>/dev/null | grep -iE 'Package id 0|Tctl|CPU|Core 0' | head -2

section security
echo "sshd: $(systemctl is-active sshd 2>/dev/null) PasswordAuth=$(sshd -T 2>/dev/null | grep -i '^passwordauthentication' | awk '{print $2}') PermitRootLogin=$(sshd -T 2>/dev/null | grep -i '^permitrootlogin' | awk '{print $2}')"
echo "authorized keys: owner=$(wc -l < /home/$OWNER/.ssh/authorized_keys 2>/dev/null || echo 0) root=$(wc -l < /root/.ssh/authorized_keys 2>/dev/null || echo 0)"
echo "firewall: $(systemctl is-active firewall 2>/dev/null) nft rules=$(nft list ruleset 2>/dev/null | grep -c 'accept\|drop')"
echo "owner password: $(passwd -S $OWNER 2>/dev/null | awk '{print $2}')  root password: $(passwd -S root 2>/dev/null | awk '{print $2}')"
echo "sudo for owner:"; sudo -l -U $OWNER 2>/dev/null | grep -E '^\s+\(' | head -5
echo "polkit rules: $(ls /etc/polkit-1/rules.d/ 2>/dev/null | tr '\n' ' ')"

section services
for u in NetworkManager bluetooth udisks2 upower power-profiles-daemon thermald cups avahi-daemon fwupd greetd polkit dbus; do
  printf '%-22s %s\n' "$u" "$(systemctl is-active "$u" 2>/dev/null)"
done

section hardware
lspci 2>/dev/null | grep -iE 'VGA|3D|Display|Network|Wireless|Audio' | sed -E 's/^[0-9a-f:.]+ //' | cut -c1-100
echo "drm: $(ls /sys/class/drm 2>/dev/null | grep -E '^card[0-9]+$' | tr '\n' ' ')  video: $(ls /dev/video* 2>/dev/null | tr '\n' ' ')"
echo "bluetooth: $(bluetoothctl list 2>/dev/null | wc -l) adapter(s), rfkill blocked: $(rfkill list 2>/dev/null | grep -c 'yes')"
echo "backlight: $(ls /sys/class/backlight 2>/dev/null | tr '\n' ' ') kbd: $(ls /sys/class/leds 2>/dev/null | grep kbd | tr '\n' ' ')"
echo "input groups on /dev/input: $(stat -c '%G' /dev/input/event0 2>/dev/null) uinput: $(stat -c '%G %a' /dev/uinput 2>/dev/null)"
