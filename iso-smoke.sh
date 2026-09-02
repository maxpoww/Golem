#!/usr/bin/env bash
# iso-smoke.sh — the "it can't happen" gate for the Golem ISO.
#
# Every showstopper we shipped got through because it was committed on
# reasoning and never checked against real behavior:
#   * greetd died — /bin/sh missing (nixos-init stopped creating it)
#   * wifi dead   — wpa_supplicant force-disabled out from under NetworkManager
#   * desktop cramped — the dev's HiDPI panel hardcoded as the default
# None of these failed `nix eval`. Two needed a real boot; one needed a Lua
# parser. This script is the standing check so a distro-breaker fails HERE,
# not on a stranger's first boot.
#
#   ./iso-smoke.sh          static checks — fast, no GPU, CI-able
#   ./iso-smoke.sh --boot   also boot the ISO in qemu (headless) and assert
#                           the session comes up (needs a GPU; opens no window)
#
# Exit non-zero on the first failure. Green means the three known classes of
# distro-breaker are absent from the built image.
set -uo pipefail

GOLEM="/home/max/Golem"
cd "$GOLEM" || exit 1
ISO_ATTR=".#nixosConfigurations.golem-iso.config"
fail() { printf '\033[31m✗ %s\033[0m\n' "$1"; exit 1; }
ok()   { printf '\033[32m✓ %s\033[0m\n' "$1"; }

command -v nix >/dev/null || fail "nix not found"

echo "── static checks ──"

# 1. All configs evaluate (catches Nix-level breakage).
for c in golem golem-vm golem-iso; do
  nix eval --raw ".#nixosConfigurations.$c.config.system.build.toplevel.drvPath" >/dev/null 2>&1 \
    || fail "$c does not evaluate"
done
ok "all three configs evaluate"

# Resolve a tool from nixpkgs. A package can have SEVERAL outputs (lua5_4 and
# xorriso both ship a `-man` beside the binaries) and `--print-out-paths` prints
# them ALL, one per line — so the naive "$(…)/bin/x" builds a two-line path that
# never exists. That bit the boot check: qemu launched with an empty -kernel and
# the guest's silence was reported as "the session never came up", i.e. the gate
# failed for its own reason and looked like a real distro breaker. Pick the
# output that actually holds the binary.
tool() { # tool <flake-attr> <binary>
  local p
  while read -r p; do
    [ -x "$p/bin/$2" ] && { printf '%s\n' "$p/bin/$2"; return 0; }
  done < <(nix build --no-link --print-out-paths "$1" 2>/dev/null)
  return 1
}

# 2. hyprland.lua parses as Lua. `nix eval` never touches this — the config is
#    read at runtime, so a stray brace ships silently and greets the user with
#    an error banner. Parse it with a real Lua compiler.
LUAC="$(tool nixpkgs#lua5_4 luac)"
[ -x "$LUAC" ] || fail "could not get luac to check hyprland.lua"
"$LUAC" -p system/home/hyprland.lua 2>/dev/null \
  || fail "hyprland.lua has a Lua syntax error (would banner on the user's screen)"
ok "hyprland.lua parses"

# 3. /bin/sh will exist on a fresh root. greetd (and libc system()) exec a
#    hardcoded /bin/sh; nixos-init no longer creates it, so we do via tmpfiles.
nix eval "$ISO_ATTR.systemd.tmpfiles.rules" --json 2>/dev/null | grep -q '/bin/sh' \
  || fail "no tmpfiles rule creates /bin/sh — greetd will ENOENT on first boot"
ok "/bin/sh is provisioned (tmpfiles)"

# 4. NetworkManager has its supplicant backend — a stranger can get online.
#    NM sets networking.wireless.enable=true (dbusControlled) as its backend;
#    a mkForce false anywhere deletes wpa_supplicant.service and kills wifi.
[ "$(nix eval "$ISO_ATTR.networking.wireless.enable" 2>/dev/null)" = "true" ] \
  || fail "networking.wireless.enable is false — NM has no supplicant, no wifi"
nix eval --raw "$ISO_ATTR.systemd.units.\"wpa_supplicant.service\".text" >/dev/null 2>&1 \
  || fail "wpa_supplicant.service is absent from the ISO closure"
ok "wpa_supplicant present (wifi can work)"

# 5. The session actually gets launched, and oomd guards low RAM.
[ "$(nix eval "$ISO_ATTR.services.greetd.enable" 2>/dev/null)" = "true" ] \
  || fail "greetd is not enabled — nothing starts the desktop"
[ "$(nix eval "$ISO_ATTR.systemd.oomd.enable" 2>/dev/null)" = "true" ] \
  || fail "systemd-oomd is off — an 8 GB machine can freeze under pressure"
ok "greetd + oomd enabled"

# 6. No specific panel hardcoded as the default (the catch-all must be present).
grep -q 'output = ""' system/home/hyprland.lua \
  || fail "no generic monitor catch-all — a hardcoded panel will misconfigure others"
ok "monitors auto-configure (generic catch-all present)"

echo "── static checks passed ──"

[ "${1:-}" = "--boot" ] || { echo "run with --boot to also verify the session boots"; exit 0; }

echo "── boot check (qemu) ──"

ISO="$(nix build --no-link --print-out-paths .#iso 2>/dev/null)/iso/golem.iso"
[ -f "$ISO" ] || fail "ISO build failed"
QEMU="$(tool nixpkgs#qemu_kvm qemu-system-x86_64)"
XORRISO="$(tool nixpkgs#xorriso xorriso)"
SOCAT="$(tool nixpkgs#socat socat)"
for t in "$QEMU" "$XORRISO" "$SOCAT"; do
  [ -x "$t" ] || fail "boot check needs qemu, xorriso and socat; one is missing"
done

work=$(mktemp -d); trap 'rm -rf "$work"; kill "${qpid:-0}" 2>/dev/null' EXIT
"$XORRISO" -osirrox on -indev "$ISO" -extract /isolinux/isolinux.cfg "$work/cfg" >/dev/null 2>&1
K=$(grep -m1 LINUX "$work/cfg" | awk '{print $2}' | sed 's|^/boot/||')
I=$(grep -m1 INITRD "$work/cfg" | awk '{print $2}' | sed 's|^/boot/||')
INIT=$(grep -m1 APPEND "$work/cfg" | grep -oE 'init=[^ ]+')
# Never boot a half-built command line: without these, qemu comes up with no
# kernel and the guest's silence reads as "the session never came up" — a gate
# failing for its own reason is worse than no gate.
[ -n "$K" ] && [ -n "$I" ] && [ -n "$INIT" ] \
  || fail "could not read kernel/initrd/init from the ISO's isolinux.cfg"
sock="${XDG_RUNTIME_DIR:-/tmp}/iso-smoke-ser.sock"
rm -f "$sock"

"$QEMU" -enable-kvm -cpu host -m 4096 -smp 2 \
  -kernel "$K" -initrd "$I" \
  -append "$INIT nohibernate root=fstab lsm=landlock,yama,bpf loglevel=4 fbcon=map:0 console=ttyS0,115200" \
  -cdrom "$ISO" -device virtio-vga-gl -display egl-headless \
  -serial "unix:$sock,server,nowait" -name "iso-smoke" >/dev/null 2>&1 &
qpid=$!
echo "booting (up to 4 min)..."
sleep 200

# Wake the tty first (the autologin shell may still be settling), then send the
# probe and hold the connection open long enough to read the reply.
ask() {
  { printf '\r\n'; sleep 2; printf '%s\r\n' "$1"; sleep 9; } \
    | timeout 20 "$SOCAT" -t 15 - "UNIX-CONNECT:$sock" 2>/dev/null
}
res=$(ask 'echo SMOKE greetd=$(systemctl is-active greetd) hypr=$(pgrep -c Hyprland) wr=$(pgrep -c waverunner) supp=$(systemctl is-active wpa_supplicant) binsh=$(test -e /bin/sh && echo yes || echo no)')
# The serial line ECHOES what we typed, so the first "SMOKE …" match is the
# command itself, with its $(…) still unexpanded — reading that one made the
# gate report a dead session on an ISO that had booted perfectly. Take the
# answer: the last line that no longer carries an unexpanded substitution.
line=$(grep -o 'SMOKE .*' <<<"$res" | grep -v '[$]' | tail -1)
[ -n "$line" ] || fail "no response from the booted guest (session never came up?)"
echo "$line"
grep -q 'greetd=active' <<<"$line" || fail "greetd not active in the booted ISO"
grep -q 'hypr=1'         <<<"$line" || fail "Hyprland not running in the booted ISO"
grep -q 'wr=1'           <<<"$line" || fail "waverunner not running in the booted ISO"
grep -q 'supp=active'    <<<"$line" || fail "wpa_supplicant not active in the booted ISO"
grep -q 'binsh=yes'      <<<"$line" || fail "/bin/sh missing in the booted ISO"
ok "booted ISO: greetd + Hyprland + waverunner + wpa_supplicant + /bin/sh all good"
echo "── boot check passed ──"
