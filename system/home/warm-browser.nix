# home/warm-browser — on a spinning disk, Seam's files are read ahead once the desktop is up.
#
# WHY (the ASUS X550LC, 2026-11-03; Max: "ayer quise abrir yt, seam, chrome, todo lo que
# abrió, abrió en negro, sin contenido, y todo tildado"): a cold Seam reads about a gigabyte of
# files, most of them small, from a disk that seeks for each. Its YouTube window came at 25 to
# 30 s, empty, and the page near 50 s; he opened it again, then turned the machine off. With
# Seam's files read ahead (1.2 GB, 102 s at the disk's idle priority, 90 s after the login) the
# window came at 8 s and the page at 25 to 30 s.
#
# What is read: Seam's own files, every shared library its closure holds, its profile without
# the web cache (1 GB there), the font cache. Once a boot; the kernel lets the pages go when
# memory is wanted. Nothing on an SSD (the next start is fast there anyway) or under 6 GB.
{ pkgs, lib, ... }:

let
  warm = pkgs.writeShellScript "golem-warm-browser" ''
    set -u
    export PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.findutils pkgs.gnugrep pkgs.util-linux pkgs.gawk ]}:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin
    src=$(findmnt -no SOURCE /nix/store 2>/dev/null || findmnt -no SOURCE /)
    src=''${src%%[*}
    [ "$(lsblk -ndo ROTA "$src" 2>/dev/null | head -1 | tr -d ' ')" = 1 ] || exit 0
    awk '/^MemTotal:/ { exit !($2 >= 6 * 1024 * 1024) }' /proc/meminfo || exit 0
    seam=$(command -v seam) || exit 0
    wrapper=$(readlink -f "$seam")
    list=$(mktemp)
    trap 'rm -f "$list"' EXIT
    grep -aoE '/nix/store/[a-z0-9]{32}-seam-[0-9.]+' "$wrapper" | sort -u | while IFS= read -r root; do
      find -L "$root" -type f 2>/dev/null
    done >> "$list"
    nix-store -qR "$wrapper" 2>/dev/null | while IFS= read -r p; do
      find "$p" -type f \( -name '*.so' -o -name '*.so.*' \) 2>/dev/null
    done >> "$list"
    prof=$HOME/.local/share/seam
    find "$prof" -maxdepth 1 -type f -size -64M 2>/dev/null >> "$list"
    for d in startupCache extensions security_state safebrowsing settings storage/permanent storage/default sessionstore-backups; do
      find "$prof/$d" -type f -size -64M 2>/dev/null
    done >> "$list"
    find "$HOME/.cache/fontconfig" -type f 2>/dev/null >> "$list"
    n=0
    while IFS= read -r f; do
      [ -f "$f" ] && cat "$f" > /dev/null 2>&1 && n=$((n + 1))
    done < <(sort -u "$list")
    echo "golem-warm-browser: $n files read ahead"
  '';
in
{
  systemd.user.services.golem-warm-browser = {
    Unit.Description = "Golem: Seam's files read ahead (spinning disk)";
    Service = {
      Type = "oneshot";
      ExecStart = "${warm}";
      Nice = 19;
      IOSchedulingClass = "idle";
      CPUSchedulingPolicy = "idle";
    };
  };
  systemd.user.timers.golem-warm-browser = {
    Unit.Description = "Golem: Seam's files read ahead, after the login";
    Timer.OnStartupSec = "90s";
    Install.WantedBy = [ "timers.target" ];
  };
}
