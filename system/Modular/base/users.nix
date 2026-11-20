# base/users — the owner, stage 0. Data-driven from golem.owner (the
# installer's knob); groups here are the stage-0 set — the desktop leaf
# adds its own (adbusers, uinput) beside the subsystems that create
# them. GECOS mkDefault: the installer's machine.nix personalizes it
# (the "conflicting definition values: Max / Max Power" lesson).
{ config, pkgs, lib, ... }:

{
  users.users.${config.golem.owner} = {
    isNormalUser = true;
    # The password seed: a root-only file, never the system source (below).
    hashedPasswordFile = "/var/lib/golem/secrets/owner-password-hash";
    description = lib.mkDefault "Max";
    shell = pkgs.bashInteractive;
    # Not "input" (2026-11-12): it lets every program the owner runs read
    # every keyboard and mouse directly (/dev/input/event*), keystrokes and
    # passwords included, past the compositor. Nothing in Golem needs it:
    # Hyprland opens the devices through the login seat (logind), games get
    # their controllers by the seat's own rules (uaccess), and the phone's
    # virtual gamepad writes through uinput, its own group (desktop leaf).
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
    ];
  };

  # The dev/deploy loop: the owner rebuilds without a password. Build
  # always runs before switch; generations are the net.
  # THE OWNER'S PASSWORD NEVER ENTERS THE SYSTEM SOURCE (2026-10-01).
  # machine.nix used to carry `hashedPassword`, and everything in the flake is
  # copied into the world-readable Nix store: the hash sat in every
  # generation's users-groups.json and in every source copy (12 on the
  # ThinkPad), readable by any process — an offline-guessing target that
  # /etc/shadow exists to prevent. Accounts are mutable here (NixOS's default:
  # the declared hash is used only when the account is CREATED, /etc/shadow
  # is the truth after that), so the hash is only a seed for creation: it
  # lives in a root-only file the installer writes, outside the store
  # (`hashedPasswordFile` in the account above).
  # Keep that file equal to the account's real password, before the users
  # step reads it: an existing machine gets the file from /etc/shadow (no
  # hand migration), a later `passwd` is followed, and an account that ever
  # had to be created again would get the CURRENT password, not install day's.
  # A fresh install has no shadow entry yet: the installer's file stands.
  system.activationScripts.golemOwnerSecret = {
    text = ''
      f=/var/lib/golem/secrets/owner-password-hash
      h=$(${pkgs.gnugrep}/bin/grep "^${config.golem.owner}:" /etc/shadow 2>/dev/null | ${pkgs.coreutils}/bin/cut -d: -f2 || true)
      case "$h" in
        \$*)
          if [ ! -f "$f" ] || [ "$(${pkgs.coreutils}/bin/cat "$f")" != "$h" ]; then
            ${pkgs.coreutils}/bin/install -d -m 0700 /var/lib/golem /var/lib/golem/secrets
            ( umask 077; printf '%s\n' "$h" > "$f.tmp" && ${pkgs.coreutils}/bin/mv "$f.tmp" "$f" )
          fi ;;
      esac
    '';
  };
  # (Only the classic users script reads the file at activation; sysusers and
  # userborn define no such script to order against.)
  system.activationScripts.users = lib.mkIf
    (!config.systemd.sysusers.enable && !config.services.userborn.enable)
    { deps = [ "golemOwnerRename" "golemOwnerSecret" ]; };
  system.activationScripts.golemOwnerSecret.deps = [ "golemOwnerRename" ];

  # THE OWNER'S NAME FOLLOWS golem.owner (2026-11-15). The installer copies a
  # system built for everybody, whose account has the name it was built with;
  # the name the person typed arrives with machine.nix in the first rebuilt
  # generation. Without this step NixOS would delete the old account and
  # create an empty new one beside the old home. Instead: every system writes
  # its owner's name in /etc/golem/owner (the installer reads it to know which
  # account exists) and records it in /var/lib/golem/owner once activated; a
  # generation whose owner differs from the record RENAMES that account, same
  # uid, same password, and moves its home, before the users step looks. It
  # works both ways, so booting the older generation renames it back.
  # Only when no program of that account is running: in practice at boot
  # (first-boot and autoupdate stage with `boot`). A live `switch` that
  # changes golem.owner under a running session is refused before it starts
  # (the pre-switch check below).
  environment.etc."golem/owner".text = "${config.golem.owner}\n";

  # …AND NO SYSTEM OF THE NEW NAME STARTS UNDER THE OLD ACCOUNT'S SESSION
  # (2026-11-20). The step below waits for a restart when the account is in
  # use. NixOS's users step does not wait: on a live `switch` it made the new
  # name a SECOND, empty account (the next uid) and dropped the old one, and
  # the restart then found nothing to rename — the owner's first session,
  # its files and its settings, left in /home/<old>, owned by nobody. Any
  # live switch in the first session after an install did it: the browser
  # updating itself, an app from the dock, an answer to a post-install
  # question (found by the layout's VM install: Seam's lane fired eleven
  # minutes in).
  # So such a switch is REFUSED, by NixOS's own pre-switch check, whoever
  # asks for it: that system can only start at a restart. golem-rebuild
  # (golem-seal.nix) turns the refusal into what its caller can still have,
  # the new system staged for the next start. ($1 the new system, $2 the
  # action; /run/golem-owner-waits says why, for golem-rebuild.)
  system.preSwitchChecks.golemOwner = ''
    case "''${2:-}" in switch | test) ;; *) exit 0 ;; esac
    new=${lib.escapeShellArg config.golem.owner}
    rec=/var/lib/golem/owner
    old=""
    if [ -f "$rec" ]; then old=$(${pkgs.coreutils}/bin/head -n1 "$rec"); fi
    valid() { printf '%s' "$1" | ${pkgs.gnugrep}/bin/grep -qE '^[a-z][a-z0-9_-]{0,31}$'; }
    if [ -z "$old" ] || [ "$old" = "$new" ]; then exit 0; fi
    if ! valid "$old" || ! valid "$new"; then exit 0; fi
    if ! ${pkgs.gnugrep}/bin/grep -q "^$old:" /etc/passwd; then exit 0; fi
    if ${pkgs.gnugrep}/bin/grep -q "^$new:" /etc/passwd; then exit 0; fi
    uid=$(${pkgs.gnugrep}/bin/grep "^$old:" /etc/passwd | ${pkgs.coreutils}/bin/cut -d: -f3)
    case "$uid" in "" | *[!0-9]*) exit 0 ;; esac
    if [ "$uid" -lt 1000 ]; then exit 0; fi
    if ! ${pkgs.procps}/bin/pgrep -u "$uid" > /dev/null 2>&1; then exit 0; fi
    printf '%s\n' "''${1:-}" > /run/golem-owner-waits
    echo "golem-owner: this system's owner is '$new' and '$old' is logged in: the account is renamed at a restart, so this system can only start at one."
    echo "golem-owner: stage it and restart:  sudo rebuild-golem boot   (or: sudo nixos-rebuild boot)"
    exit 1
  '';
  system.activationScripts.golemOwnerRename = {
    text = ''
      (
        set -u
        PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.gnused pkgs.gnugrep pkgs.jq pkgs.procps pkgs.findutils ]}
        new=${lib.escapeShellArg config.golem.owner}
        rec=/var/lib/golem/owner
        old=
        [ -f "$rec" ] && old=$(head -n1 "$rec")
        record() {
          [ "$old" = "$new" ] && return 0
          install -d -m 0700 /var/lib/golem
          printf '%s\n' "$new" > "$rec.tmp" && mv "$rec.tmp" "$rec"
        }
        valid() { printf '%s' "$1" | grep -qE '^[a-z][a-z0-9_-]{0,31}$'; }
        if [ -z "$old" ] || [ "$old" = "$new" ] || ! valid "$old" || ! valid "$new"; then
          record; exit 0
        fi
        # Nothing to rename, or nowhere to rename it to: the record follows.
        grep -q "^$old:" /etc/passwd || { record; exit 0; }
        if grep -q "^$new:" /etc/passwd; then
          echo "golem-owner: both '$old' and '$new' exist; nothing renamed" >&2
          record; exit 0
        fi
        uid=$(grep "^$old:" /etc/passwd | cut -d: -f3)
        [ "$uid" -ge 1000 ] 2>/dev/null || { record; exit 0; }
        if pgrep -u "$uid" >/dev/null 2>&1; then
          echo "golem-owner: '$old' is in use; it becomes '$new' at a restart" >&2
          exit 0
        fi

        home=$(grep "^$old:" /etc/passwd | cut -d: -f6)
        newhome=$home
        if [ "$home" = "/home/$old" ]; then
          newhome=/home/$new
          if [ -e "$newhome" ] || [ -L "$newhome" ]; then
            rmdir "$newhome" 2>/dev/null \
              || mv -T "$newhome" "$newhome.before-rename.$(date +%s)" || exit 0
          fi
          if [ -d "$home" ]; then mv -T "$home" "$newhome" || exit 0; fi
        fi

        # Same file, same mode and owner, swapped in whole.
        edit() {
          f=$1; shift
          [ -f "$f" ] || return 0
          sed "$@" "$f" > "$f.golem-tmp" \
            && chmod --reference="$f" "$f.golem-tmp" && chown --reference="$f" "$f.golem-tmp" \
            && mv "$f.golem-tmp" "$f"
        }
        edit /etc/passwd -e "/^$old:/{s|^$old:|$new:|;s|:$home:|:$newhome:|}"
        edit /etc/shadow -e "s|^$old:|$new:|"
        edit /etc/subuid -e "s|^$old:|$new:|"
        edit /etc/subgid -e "s|^$old:|$new:|"
        for f in /etc/group /etc/gshadow; do
          edit "$f" -E -e ":a;s/([:,])$old(,|\$)/\1$new\2/;ta"
        done
        # NixOS's own books: the uid stays with the name, and the name stays
        # "declared" (else the users step would treat it as a stranger).
        for f in /var/lib/nixos/uid-map /var/lib/nixos/auto-subuid-map; do
          [ -f "$f" ] || continue
          jq -c --arg o "$old" --arg n "$new" \
            'if has($o) and (has($n) | not) then .[$n] = .[$o] | del(.[$o]) else . end' \
            "$f" > "$f.golem-tmp" && mv "$f.golem-tmp" "$f"
        done
        edit /var/lib/nixos/declarative-users -E -e "s/(^| )$old( |\$)/\1$new\2/"
        for d in /var/lib/AccountsService/users /var/lib/AccountsService/icons \
                 /var/lib/systemd/linger /nix/var/nix/profiles/per-user /nix/var/nix/gcroots/per-user; do
          if [ -e "$d/$old" ] && [ ! -e "$d/$new" ]; then mv -T "$d/$old" "$d/$new" || true; fi
        done
        # Links inside the home that pointed into the old home by full path.
        if [ "$newhome" != "$home" ] && [ -d "$newhome" ]; then
          find "$newhome" -xdev -type l \( -lname "$home/*" -o -lname "*/per-user/$old/*" \) -print0 2>/dev/null \
            | while IFS= read -r -d "" l; do
                t=$(readlink "$l"); o=$(stat -c %u:%g "$l")
                case "$t" in
                  "$home"/*) t="$newhome''${t#"$home"}" ;;
                  *) t=$(printf '%s' "$t" | sed "s|/per-user/$old/|/per-user/$new/|") ;;
                esac
                ln -sfn "$t" "$l" && chown -h "$o" "$l"
              done
        fi
        record
        echo "golem-owner: the account '$old' is now '$new' (home $newhome)" >&2
      ) || true
    '';
  };

  # A machine file that still declares the hash (written by an installer
  # before 2026-10-01) keeps working and says so; golem-autoupdate removes it.
  warnings = lib.optional (config.users.users.${config.golem.owner}.hashedPassword != null)
    "golem: the owner's password hash is declared in the system source (hosts/target/machine.nix) and is therefore world-readable in the Nix store; remove that line — the account keeps its password (see base/users.nix).";

  # No passwordless sudo on an install (GolemSecurity: "sudo requires a
  # password, no NOPASSWD anywhere in shipped config"). A NOPASSWD rule for
  # nixos-rebuild here was a root escalation for any program running as the
  # owner: `sudo nixos-rebuild switch --flake <its own flake>` (or
  # `nixos-rebuild edit`) — no password, and the seed's seal never asked.
  # Found by golem-deep on the MacBook, 2026-10-01. Unattended rebuilds run
  # as root services (waverunner-apply, golem-autoupdate, seam-update); the
  # owner's own rebuild-golem asks for the password, which is the consent
  # its golem-bless relies on. (The dev box keeps its own NOPASSWD dev loop
  # in system/configuration.nix.)
}
