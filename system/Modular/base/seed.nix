# base/seed — the seed's UPSTREAM, and adopting it (parity P10, 2026-09-30).
#
# The installer seeds the owner's checkout as a plain copy of the ISO's tree
# (Installer/preinstall/install.nix, `cp -a`): there is no network at install
# time, and a `path:` flake sees every file. But the self-update loop
# (base/autoupdate.nix) can only fast-forward a GIT checkout with an upstream
# branch, so every install ran "seed has no upstream — nothing to pull" daily
# and never updated; and with no git the build could not name its revision.
#
# `golem-seed-adopt` turns the copy into that checkout, once, when the network
# is there (first-boot and autoupdate both call it after golem-wait-online):
#   1. clone golem.upstream.url, branch golem.upstream.branch;
#   2. sit on the INSTALLED revision when it is known and published (so the
#      first autoupdate is a real fast-forward from what the machine runs),
#      else on the branch head;
#   3. carry this machine's own files over and stage them (`git add -f`: a
#      git flake only sees tracked or staged files; hardware-configuration,
#      machine.nix and friends are gitignored upstream on purpose);
#   4. swap the directories, hand the checkout to the owner, re-seal.
# Idempotent: a seed that already has .git is left alone. Offline: it stays a
# copy and the next run tries again. The helpers that write generated files
# into the checkout (waverunner-apply, postinstall) stage them the same way.
{ config, lib, pkgs, ... }:

let
  cfg = config.golem.upstream;
  owner = config.golem.owner;
  flakeDir = config.golem.flakeDir;
  # Declared by the desktop's waverunner-apply.nix; a stage-0 base has no such
  # option, hence the fallback to the desktop's path.
  appsFile = config.golem.appsFile or "hosts/target/apps.nix";

  adopt = pkgs.writeShellApplication {
    name = "golem-seed-adopt";
    runtimeInputs = [ pkgs.git pkgs.coreutils pkgs.findutils pkgs.util-linux ];
    text = ''
      dir=${lib.escapeShellArg (toString flakeDir)}
      url=${lib.escapeShellArg cfg.url}
      branch=${lib.escapeShellArg cfg.branch}
      owner=${lib.escapeShellArg owner}
      [ -n "$url" ] || exit 0
      # The seed GONE — ~/Golem is a folder in the owner's home, and an owner
      # who does not know it deletes it (ASUS dogfood, 2026-10-02): updates
      # failed forever and dock installs had nowhere to write. Rebuild it
      # from the root-owned blessed snapshot (the last sealed tree, machine
      # files included); the adopt below then makes it a checkout of the
      # upstream again, exactly as on an installer's first boot.
      blessed=/var/lib/golem/blessed
      if [ ! -d "$dir" ] && [ -f "$blessed/flake.nix" ]; then
        cp -a "$blessed" "$dir"
        chown -R "$owner": "$dir"
        chmod 755 "$dir"
        echo "golem-seed-adopt: $dir was missing — rebuilt from the sealed snapshot"
        uid=$(id -u "$owner")
        if [ -S "/run/user/$uid/bus" ]; then
          runuser -u "$owner" -- env DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
            ${pkgs.libnotify}/bin/notify-send -a Golem "Golem restored its system folder" \
            "The Golem folder in your home is the system's own source; it was missing and has been put back." || true
        fi
      fi
      [ -d "$dir" ] || { echo "golem-seed-adopt: no seed at $dir" >&2; exit 1; }
      if [ -d "$dir/.git" ]; then
        exit 0 # already a checkout
      fi

      # Every git write below runs AS THE OWNER (the checkout is theirs; a
      # root-written .git breaks their next pull). The parent is their home.
      asowner() { runuser -u "$owner" -- "$@"; }
      tmp="$dir.adopt"
      rm -rf "$tmp"
      if ! asowner git clone --quiet --branch "$branch" "$url" "$tmp" 2>/dev/null; then
        echo "golem-seed-adopt: cannot reach $url — the seed stays a plain copy for now"
        rm -rf "$tmp"
        exit 0
      fi

      rev=$(/run/current-system/sw/bin/nixos-version --configuration-revision 2>/dev/null || true)
      rev=''${rev%-dirty}
      if [[ "$rev" =~ ^[0-9a-f]{40}$ ]] && git -C "$tmp" cat-file -e "$rev^{commit}" 2>/dev/null; then
        asowner git -C "$tmp" checkout -q -B "$branch" "$rev"
        asowner git -C "$tmp" branch -q --set-upstream-to="origin/$branch" "$branch"
        echo "golem-seed-adopt: at the installed revision $rev; autoupdate fast-forwards from here"
      else
        echo "golem-seed-adopt: the installed revision is not known upstream — taking $branch's head"
      fi

      # This machine's own files, never upstream's: the installer's drops,
      # the answers, the owner's app list (and their last-good twins).
      carry() {
        local f="$1"
        [ -e "$dir/$f" ] || return 0
        mkdir -p "$tmp/$(dirname "$f")"
        cp -p "$dir/$f" "$tmp/$f"
        chown "$owner:" "$tmp/$f"
        asowner git -C "$tmp" add -f "$f"
      }
      for f in $(cd "$dir" && find hosts/target -maxdepth 1 -type f 2>/dev/null); do
        [ "$f" = hosts/target/default.nix ] || carry "$f"
      done
      for f in system/postinstall-generated.nix system/postinstall-generated.nix.last-good \
               system/home/waverunner-packages.nix system/home/waverunner-packages.nix.last-good \
               ${lib.escapeShellArg appsFile} ${lib.escapeShellArg (appsFile + ".last-good")}; do
        carry "$f"
      done

      mv "$dir" "$dir.pre-adopt"
      mv "$tmp" "$dir"
      rm -rf "$dir.pre-adopt"
      echo "golem-seed-adopt: $dir is now a checkout of $url ($branch), this machine's files staged"
      ${config.golem.seal.bless}/bin/golem-bless >/dev/null 2>&1 || true
    '';
  };
in
{
  options.golem.upstream = {
    url = lib.mkOption {
      type = lib.types.str;
      default = "https://github.com/maxpoww/Golem";
      description = "Where an installed Golem pulls its updates from (a git URL); empty = never adopt.";
    };
    branch = lib.mkOption {
      type = lib.types.str;
      default = "main";
      description = "The branch installs follow.";
    };
  };
  options.golem.seed.adopt = lib.mkOption {
    type = lib.types.package;
    readOnly = true;
    description = "golem-seed-adopt: turn the seeded copy into a checkout of the upstream.";
  };

  config = lib.mkIf (flakeDir != null) {
    golem.seed.adopt = adopt;
    environment.systemPackages = [ adopt ];
  };
}
