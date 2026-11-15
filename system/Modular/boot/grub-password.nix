# boot/grub-password — the boot menu asks a password only to be CHANGED
# (Max, 2026-11-12: approved "GRUB password: only when editing boot entries").
#
# Without one, anyone at the keyboard could press `e` at the menu, add
# `init=/bin/sh` to the kernel line and have a root shell with no password
# (the security study's GRUB road). Now:
#  - every entry boots as before, no password: "Start Golem", each of the
#    "Previous Versions" (and the submenu itself — GRUB guards a submenu like
#    an entry), so a rollback from the menu stays one key;
#  - editing an entry (`e`) or GRUB's command line (`c`) asks for the user
#    "golem" and this machine's boot password.
#
# THE PASSWORD: made on the machine the first time its bootloader is installed,
# random, and kept root-only in /var/lib/golem/secrets — never in the flake or
# the store. `sudo golem-boot-password` shows it, for the rare day someone needs
# to edit a boot line. Its letters are the ones that sit on the same keys in
# QWERTY, QWERTZ and AZERTY, because GRUB reads every keyboard as US.
#
# HOW: NixOS's own `boot.loader.grub.users` reads a password file BEFORE
# anything of ours runs, and a missing file kills the bootloader install —
# every machine's first nightly update (`boot`, no activation) would have
# failed on it. So, like the menu's words (grub-patched.nix), the lines go
# into the generated grub.cfg right after the generator, every install, and
# the password is made there if it is not there yet.
{ config, lib, pkgs, ... }:

let
  secrets = "/var/lib/golem/secrets";
  # The grub Golem installs (patched by the overlay); null-safe, unlike
  # system.build.grub on a "nodev" install.
  grub = pkgs.grub2;
  show = pkgs.writeShellScriptBin "golem-boot-password" ''
    if [ "$(id -u)" != 0 ]; then echo "golem-boot-password: run with sudo" >&2; exit 1; fi
    if [ ! -s ${secrets}/boot-password ]; then
      echo "golem-boot-password: none yet (it is made with the next bootloader install)" >&2; exit 1
    fi
    echo "The boot menu asks this only to edit an entry (e) or open GRUB's command line (c)."
    echo "  user:     golem"
    echo "  password: $(cat ${secrets}/boot-password)"
  '';
in
{
  boot.loader.grub.subEntryOptions = "--class nixos --unrestricted";
  environment.systemPackages = [ show ];

  boot.loader.grub.extraInstallCommands = lib.mkAfter ''
    cfg=/boot/grub/grub.cfg
    if [ -f "$cfg" ] && ! ${pkgs.gnugrep}/bin/grep -q '^set superusers=' "$cfg"; then
      if [ ! -s ${secrets}/boot-password.pbkdf2 ]; then
        ${pkgs.coreutils}/bin/mkdir -p ${secrets}
        ${pkgs.coreutils}/bin/chmod 700 ${secrets}
        pw=$(${pkgs.coreutils}/bin/tr -dc 'bcdefghijklnoprstuvx' < /dev/urandom | ${pkgs.coreutils}/bin/head -c 16)
        hash=$(printf '%s\n%s\n' "$pw" "$pw" | ${grub}/bin/grub-mkpasswd-pbkdf2 | ${pkgs.gnused}/bin/sed -n 's/^.* is \(grub\.pbkdf2\.[^ ]*\)$/\1/p')
        case "$hash" in
          grub.pbkdf2.*)
            (umask 077
             printf '%s\n' "$pw" > ${secrets}/boot-password.new
             printf '%s\n' "$hash" > ${secrets}/boot-password.pbkdf2.new
             ${pkgs.coreutils}/bin/mv ${secrets}/boot-password.new ${secrets}/boot-password
             ${pkgs.coreutils}/bin/mv ${secrets}/boot-password.pbkdf2.new ${secrets}/boot-password.pbkdf2)
            ;;
          *) echo "grub-password: could not make the boot password — the menu stays open this time" >&2 ;;
        esac
        unset pw
      fi
      if [ -s ${secrets}/boot-password.pbkdf2 ]; then
        hash=$(${pkgs.coreutils}/bin/cat ${secrets}/boot-password.pbkdf2)
        # Every entry and submenu boots without the password, whatever the
        # generator gave it (a guarded submenu would lock the entries inside
        # it, --unrestricted or not): only changing them asks.
        ${pkgs.gnused}/bin/sed -i -E -e '/^ *(menuentry|submenu) "/{/--unrestricted/!s/ \{$/ --unrestricted {/}' "$cfg"
        ${pkgs.gawk}/bin/awk -v h="$hash" 'NR == 1 { print; print "set superusers=\"golem\""; print "password_pbkdf2 golem " h; next } { print }' \
          "$cfg" > "$cfg.golem-tmp"
        # Root-only where the filesystem has modes (a FAT /boot has none):
        # never fatal, a failed bootloader install would cost far more.
        ${pkgs.coreutils}/bin/chmod 600 "$cfg.golem-tmp" 2>/dev/null || true
        ${pkgs.coreutils}/bin/mv "$cfg.golem-tmp" "$cfg"
      fi
    fi
  '';
}
