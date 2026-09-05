# golem-install — install flow v1 (GolemInstall.md §6, PLAN.md).
#
#   golem-install --disk /dev/sda --owner max --full-name "Max Power"
#
# WHAT IT DOES, in the order the spec's one rule demands (facts in,
# evaluation out — never assembled configuration prose):
#
#   1. size the hibernation swap by ASKING THE FLAKE for the rule
#      (lib.golem.swapForHibernationMB) rather than reimplementing it here
#   2. partition GPT: ESP + swap + root, labelled ESP / swap / golem
#   3. seed the flake checkout into the owner's home on the new root
#   4. drop the three per-machine files into its hosts/target/:
#        golem-hardware.nix          the probe's facts
#        hardware-configuration.nix  nixos-generate-config's filesystems
#        machine.nix                 the human choices
#   5. build (or accept) the toplevel and nixos-install it
#
# LUKS is deliberately absent. Whole-disk encryption is a default-on/off
# call Max has not made (PLAN.md decision backlog); v1 ships the
# unencrypted path so the flow can be proven, and encryption lands as a
# branch of step 2 rather than a rewrite of the whole script.
#
# DESTRUCTIVE. The named disk is repartitioned without recovery. --yes is
# required for a non-interactive run precisely so that a mistyped device
# in a script cannot quietly eat a machine.
{ pkgs, golemSrc, overrideArgs }:

pkgs.writeShellApplication {
  name = "golem-install";
  runtimeInputs = with pkgs; [
    coreutils gptfdisk dosfstools e2fsprogs util-linux
    nix nixos-install-tools gnused
  ];
  text = ''
    disk=""; owner="max"; fullname=""; hostname="Golem"
    system=""; labkey=""; assume_yes=false
    prepare_only=false; skip_prepare=false
    src="${golemSrc}"

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --disk)      disk="''${2:?}"; shift 2 ;;
        --owner)     owner="''${2:?}"; shift 2 ;;
        --full-name) fullname="''${2:?}"; shift 2 ;;
        --hostname)  hostname="''${2:?}"; shift 2 ;;
        --system)    system="''${2:?}"; shift 2 ;;
        --lab-ssh)   labkey="''${2:?}"; shift 2 ;;
        --src)       src="''${2:?}"; shift 2 ;;
        --yes)       assume_yes=true; shift ;;
        # The two halves, separable. A machine whose store cannot hold the
        # system closure (every machine — the medium's store is a tmpfs
        # overlay in RAM) needs the closure delivered to the TARGET disk
        # after it is mounted and before nixos-install runs. In the lab
        # that delivery is `nix copy` from the dev box; on a product stick
        # it would be a prebuilt closure carried in the image. Both want
        # the same seam, so the seam is a flag rather than a fork.
        --prepare-only) prepare_only=true; shift ;;
        --skip-prepare) skip_prepare=true; shift ;;
        -h|--help)
          echo "usage: golem-install --disk DEV [--owner NAME] [--full-name STR]"
          echo "                     [--hostname NAME] [--system PATH] [--lab-ssh KEY] [--yes]"
          echo "                     [--prepare-only | --skip-prepare]"
          exit 0 ;;
        *) echo "golem-install: unknown argument '$1'" >&2; exit 2 ;;
      esac
    done

    [[ -n "$disk" ]] || { echo "golem-install: --disk is required" >&2; exit 2; }
    [[ -b "$disk" ]] || { echo "golem-install: $disk is not a block device" >&2; exit 2; }
    [[ "$(id -u)" == 0 ]] || { echo "golem-install: must run as root" >&2; exit 2; }
    [[ -n "$fullname" ]] || fullname="$owner"

    # ── 1. The swap size, from the flake's rule ───────────────────────
    ram_mb=$(( $(grep -m1 MemTotal /proc/meminfo | grep -oE '[0-9]+') / 1024 ))
    swap_mb=$(nix eval --offline --no-write-lock-file --raw \
      ${overrideArgs} \
      "path:$src#lib.golem.swapForHibernationMB" \
      --apply "f: toString (f $ram_mb)" 2>/dev/null)
    [[ "$swap_mb" =~ ^[0-9]+$ ]] || {
      echo "golem-install: could not get the swap rule from the flake" >&2; exit 1; }

    echo "── plan ─────────────────────────────────────────"
    echo "  disk        $disk  ($(lsblk -ndo SIZE "$disk" | tr -d ' '))"
    echo "  RAM         $ram_mb MB"
    echo "  ESP         512 MiB       label ESP"
    echo "  swap        $swap_mb MiB  label swap   (hibernation, locked)"
    echo "  root        rest          label golem"
    echo "  owner       $owner ($fullname)"
    echo "  hostname    $hostname"
    echo "  encryption  none (LUKS pending Max's call)"
    echo

    if [[ "$assume_yes" != true && "$skip_prepare" != true ]]; then
      echo "This ERASES $disk completely. Type ERASE to continue:"
      read -r reply
      [[ "$reply" == "ERASE" ]] || { echo "aborted"; exit 1; }
    fi

    # ── 2. Partition ──────────────────────────────────────────────────
    # nvme0n1 → nvme0n1p1, sda → sda1: the kernel inserts a 'p' only when
    # the disk name ends in a digit.
    part() { if [[ "$disk" =~ [0-9]$ ]]; then echo "''${disk}p$1"; else echo "''${disk}$1"; fi; }

    seed="/mnt/home/$owner/Golem"

    if [[ "$skip_prepare" == true ]]; then
      mountpoint -q /mnt || { echo "golem-install: --skip-prepare but /mnt is not mounted" >&2; exit 1; }
      [[ -d "$seed" ]] || { echo "golem-install: --skip-prepare but no seed at $seed" >&2; exit 1; }
      echo "resuming: /mnt mounted, seed present — install step only"
    else

    swapoff -a || true
    umount -R /mnt 2>/dev/null || true
    wipefs -a "$disk"
    sgdisk --zap-all "$disk"
    sgdisk -n1:0:+512M   -t1:ef00 -c1:ESP   "$disk"
    sgdisk -n2:0:+"$swap_mb"M -t2:8200 -c2:swap  "$disk"
    sgdisk -n3:0:0       -t3:8300 -c3:golem "$disk"
    partprobe "$disk" 2>/dev/null || true
    udevadm settle

    mkfs.fat -F32 -n ESP "$(part 1)"
    mkswap -L swap "$(part 2)"
    mkfs.ext4 -F -L golem "$(part 3)"
    udevadm settle

    mount /dev/disk/by-label/golem /mnt
    mkdir -p /mnt/boot
    mount /dev/disk/by-label/ESP /mnt/boot
    # ON before nixos-generate-config: that is how the swap partition ends
    # up in hardware-configuration.nix's swapDevices, which is what wires
    # boot.resumeDevice and the lid's suspend-then-hibernate. An install
    # that skips this boots WITHOUT hibernation and nothing complains.
    swapon /dev/disk/by-label/swap

    # ── 3. Seed the checkout ──────────────────────────────────────────
    mkdir -p "$seed"
    cp -a "$src"/. "$seed"/
    chmod -R u+w "$seed"

    # ── 4. The three dropped files ────────────────────────────────────
    mkdir -p "$seed/hosts/target"
    golem-hw-detect > "$seed/hosts/target/golem-hardware.nix"

    nixos-generate-config --root /mnt
    cp /mnt/etc/nixos/hardware-configuration.nix "$seed/hosts/target/"
    # nixos-generate-config also drops a stock configuration.nix. Golem is
    # a flake distro; leaving a second, channel-shaped config on the disk
    # is only an invitation to rebuild the wrong thing.
    rm -f /mnt/etc/nixos/configuration.nix

    {
      echo "# The human choices for this machine, written by golem-install."
      echo "# Everything else about this system comes from the flake."
      echo "{ ... }:"
      echo "{"
      echo "  golem.owner = \"$owner\";"
      echo "  networking.hostName = \"$hostname\";"
      echo "  users.users.$owner.description = \"$fullname\";"
      if [[ -n "$labkey" ]]; then
        echo
        echo "  # --lab-ssh: this machine is a lab testbed, reachable from the"
        echo "  # dev box. Golem ships no sshd by default; this is NOT what a"
        echo "  # stranger's install gets."
        echo "  services.openssh.enable = true;"
        echo "  services.openssh.settings.PasswordAuthentication = false;"
        echo "  users.users.$owner.openssh.authorizedKeys.keys = [ \"$labkey\" ];"
        echo "  users.users.root.openssh.authorizedKeys.keys = [ \"$labkey\" ];"
      fi
      echo "}"
    } > "$seed/hosts/target/machine.nix"

    echo "── dropped into hosts/target ────────────────────"
    ls -1 "$seed/hosts/target"
    echo

    fi # end of prepare

    if [[ "$prepare_only" == true ]]; then
      echo "prepared: disk partitioned, /mnt mounted, seed at $seed."
      echo "deliver the system closure to /mnt, then re-run with"
      echo "  golem-install --disk $disk --owner $owner --skip-prepare --system PATH"
      exit 0
    fi

    # ── 5. Build and install ──────────────────────────────────────────
    if [[ -z "$system" ]]; then
      echo "building golem-target (this is the long part)…"
      system=$(nix build --offline --no-write-lock-file --no-link --print-out-paths \
        ${overrideArgs} \
        "path:$seed#nixosConfigurations.golem-target.config.system.build.toplevel")
    fi
    echo "installing system: $system"

    nixos-install --root /mnt --system "$system" --no-root-password --no-channel-copy

    # The seed is the installed machine's own flake (golem.flakeDir), so it
    # must belong to the owner, not to root — rebuild-golem runs as them.
    uid=$(chroot /mnt id -u "$owner" 2>/dev/null || echo "")
    gid=$(chroot /mnt id -g "$owner" 2>/dev/null || echo "")
    if [[ -n "$uid" && -n "$gid" ]]; then
      chown -R "$uid:$gid" "/mnt/home/$owner"
    else
      echo "note: user '$owner' not found in the installed system — seed left root-owned" >&2
    fi

    echo
    echo "── done ─────────────────────────────────────────"
    echo "  installed to $disk; seed checkout at /home/$owner/Golem"
    echo "  reboot and remove the medium."
  '';
}
