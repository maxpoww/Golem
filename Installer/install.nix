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
# LUKS is a branch of step 2, exactly as this header predicted it would be
# (built 2026-09-05). --luks gives ESP + one LUKS2 container with LVM
# inside it holding swap and root; without it, the original three-partition
# layout, untouched. Everything after the partitioning is identical because
# both branches label their root `golem` and their swap `swap`.
#
# ONE container rather than two, because HIBERNATION IS LOCKED: resume has
# to read the swap from initrd, and separate volumes would mean either two
# passphrase prompts per boot or a keyfile with nowhere safe to live.
#
# THE DEFAULT INSTALL IS DECIDED (Max, 2026-09-05) and it is the plain
# branch: no encryption, ext4, a swap partition sized for hibernation, the
# whole disk erased. Encryption is a deliberate detour behind the disk
# step's "Advanced" row, not a question every stranger is asked.
#
# --rehearse IS THE SAME INSTALL WITH THE DESTRUCTIVE VERBS INTERCEPTED
# (Max, 2026-09-06: test the whole process on the five lab laptops before
# wiring the real installation). Every command that would change the disk
# goes through one runner, run(), which executes in a real install and
# records in a rehearsal — the SAME control flow either way, so the
# rehearsal cannot drift from the installer it rehearses (PLAN.md's
# harness-lying lesson: a hand-written fake would be the harness lying).
# What still executes in a rehearsal is everything read-only and the real
# work the flow exists for: the probe, the seed copy, the three dropped
# files, and step 5 as an EVALUATION of the exact system the install would
# build. The whole run leaves a bundle in /var/log/golem-rehearsal/ —
# plan, command transcript, checks, the dropped files, the eval verdict —
# for the dev box to pull over SSH and audit. It ends with `##golem
# rehearsed`, never 6/6: 6/6 is the surface's reboot trigger and a
# rehearsal has nothing to reboot into.
#
# DESTRUCTIVE (unless --rehearse). The named disk is repartitioned without
# recovery. --yes is required for a non-interactive run precisely so that
# a mistyped device in a script cannot quietly eat a machine.
{ pkgs, golemSrc, overrideArgs }:

pkgs.writeShellApplication {
  name = "golem-install";
  runtimeInputs = with pkgs; [
    coreutils gptfdisk dosfstools e2fsprogs util-linux
    nix nixos-install-tools gnused
    cryptsetup lvm2
    diffutils gnutar gzip
  ];
  text = ''
    disk=""; owner="max"; fullname=""; hostname="Golem"
    system=""; labkey=""; assume_yes=false
    prepare_only=false; skip_prepare=false; rehearse=false
    src="${golemSrc}"

    # The keyboard step's answer, already derived into its four values by
    # the time it reaches here: the installer surface asks ONE question
    # ("is this your keyboard") and the row behind the answer knows the
    # console keymap, the XKB layout, its variant and the group toggle.
    # Defaults are the module defaults, so omitting them changes nothing.
    kb_layout="us"; kb_variant=""; kb_options=""; kb_console="us"
    kb_model="pc104"; kb_font=""
    # Steps 1 and 2's answers: the language, and the timezone the language
    # proposed and the user confirmed against a clock.
    locale="en_US.UTF-8"
    timezone="UTC"
    answers=""
    passhash=""
    luks=false; luks_key=""; luks_uuid=""

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
        --kb-layout)  kb_layout="''${2:?}"; shift 2 ;;
        --kb-variant) kb_variant="''${2-}"; shift 2 ;;
        --kb-options) kb_options="''${2-}"; shift 2 ;;
        --kb-model)   kb_model="''${2:?}"; shift 2 ;;
        --kb-console) kb_console="''${2:?}"; shift 2 ;;
        --kb-font)    kb_font="''${2-}"; shift 2 ;;
        --locale)     locale="''${2:?}"; shift 2 ;;
        --timezone)   timezone="''${2:?}"; shift 2 ;;
        # A HASH, never a password. The surface hashes it the moment it is
        # typed; nothing downstream of that screen has ever seen the text,
        # and a flag is visible in `ps` to every user on the machine.
        --password-hash) passhash="''${2:?}"; shift 2 ;;
        --luks)       luks=true; shift ;;
        --luks-key)   luks_key="''${2:?}"; shift 2 ;;
        # The surface's answers file (install-cli --out). One flag instead
        # of seven, so the two ends of the install actually join rather than
        # being re-typed into each other by whoever is driving.
        --answers)
          answers="''${2:?}"; shift 2
          [[ -r "$answers" ]] || { echo "golem-install: cannot read $answers" >&2; exit 2; }
          # shellcheck disable=SC1090
          . "$answers"
          locale="''${GOLEM_LOCALE:-$locale}"
          timezone="''${GOLEM_TIMEZONE:-$timezone}"
          kb_layout="''${GOLEM_KB_LAYOUT:-$kb_layout}"
          kb_variant="''${GOLEM_KB_VARIANT-$kb_variant}"
          kb_options="''${GOLEM_KB_OPTIONS-$kb_options}"
          kb_model="''${GOLEM_KB_MODEL:-$kb_model}"
          kb_console="''${GOLEM_KB_CONSOLE:-$kb_console}"
          kb_font="''${GOLEM_KB_FONT-$kb_font}"
          owner="''${GOLEM_OWNER:-$owner}"
          hostname="''${GOLEM_HOSTNAME:-$hostname}"
          passhash="''${GOLEM_PASS_HASH:-$passhash}"
          [[ "''${GOLEM_LUKS:-no}" == yes ]] && luks=true
          luks_key="''${GOLEM_LUKS_KEYFILE:-$luks_key}"
          ;;
        # The two halves, separable. A machine whose store cannot hold the
        # system closure (every machine — the medium's store is a tmpfs
        # overlay in RAM) needs the closure delivered to the TARGET disk
        # after it is mounted and before nixos-install runs. In the lab
        # that delivery is `nix copy` from the dev box; on a product stick
        # it would be a prebuilt closure carried in the image. Both want
        # the same seam, so the seam is a flag rather than a fork.
        --prepare-only) prepare_only=true; shift ;;
        --skip-prepare) skip_prepare=true; shift ;;
        --rehearse)     rehearse=true; shift ;;
        -h|--help)
          echo "usage: golem-install --disk DEV [--owner NAME] [--full-name STR]"
          echo "                     [--hostname NAME] [--system PATH] [--lab-ssh KEY] [--yes]"
          echo "                     [--kb-layout L] [--kb-variant V] [--kb-options O]"
          echo "                     [--locale L] [--timezone ZONE]"
          echo "                     [--kb-model M] [--kb-console KEYMAP] [--kb-font F]"
          echo "                     [--answers FILE]   (install-cli --out)"
          echo "                     [--luks --luks-key FILE]"
          echo "                     [--prepare-only | --skip-prepare]"
          echo "                     [--rehearse]       (record, evaluate, write nothing)"
          exit 0 ;;
        *) echo "golem-install: unknown argument '$1'" >&2; exit 2 ;;
      esac
    done

    [[ -n "$disk" ]] || { echo "golem-install: --disk is required" >&2; exit 2; }
    [[ -b "$disk" ]] || { echo "golem-install: $disk is not a block device" >&2; exit 2; }
    [[ "$(id -u)" == 0 ]] || { echo "golem-install: must run as root" >&2; exit 2; }
    [[ -n "$fullname" ]] || fullname="$owner"
    if [[ "$rehearse" == true && ( "$prepare_only" == true || "$skip_prepare" == true ) ]]; then
      echo "golem-install: --rehearse rehearses the WHOLE flow — it cannot split at prepare" >&2
      exit 2
    fi

    # nvme0n1 → nvme0n1p1, sda → sda1: the kernel inserts a 'p' only when
    # the disk name ends in a digit. (Defined up here because the plan and
    # the preflight both name partitions before any is created.)
    part() { if [[ "$disk" =~ [0-9]$ ]]; then echo "''${disk}p$1"; else echo "''${disk}$1"; fi; }

    # ── The rehearsal seam ────────────────────────────────────────────
    # ONE runner for every command that would change the disk: a real
    # install executes and logs, a rehearsal logs what it WOULD have run.
    # The transcript is written in BOTH modes so a later real install on
    # the same machine can be diffed line-for-line against its rehearsal.
    logdir=/var/log/golem-install
    if [[ "$rehearse" == true ]]; then
      logdir=/var/log/golem-rehearsal
      rm -rf "$logdir"
    fi
    mkdir -p "$logdir"
    TR="$logdir/transcript.txt"
    CHK="$logdir/checks.txt"
    [[ "$rehearse" == true ]] && : > "$CHK"
    printf '%s\n' "── golem-install $(date -Is) $([[ "$rehearse" == true ]] && echo REHEARSAL) ──" >> "$TR"

    findings=0
    run() {
      if [[ "$rehearse" == true ]]; then
        printf '%s\n' "would  $*" >> "$TR"
      else
        printf '%s\n' "run    $*" >> "$TR"
        "$@"
      fi
    }
    note()       { printf '%s\n' "note   $*" >> "$TR"; }
    check_ok()   { printf '%s\n' "ok     $*" >> "$CHK"; }
    check_warn() { printf '%s\n' "warn   $*" >> "$CHK"; }
    # A failed check means the install cannot produce a booting machine.
    # Real mode stops on the spot — nothing destructive has happened yet
    # when these run. A rehearsal RECORDS it and keeps going: it exists to
    # collect findings, and dying at the first one on lab machine 3 would
    # hide findings 2 through n.
    check_fail() {
      printf '%s\n' "FAIL   $*" >> "$CHK"
      findings=$((findings + 1))
      if [[ "$rehearse" != true ]]; then
        echo "golem-install: $*" >&2
        exit 1
      fi
    }

    # ── The never-silent-death trap ───────────────────────────────────
    # Under errexit any failing command kills this script; before this
    # trap existed the TUI could only say "the installation stopped — the
    # log is above" over a log that said NOTHING (round 2, VM: the by-id
    # loop died exactly that way, one line before its own fallback). The
    # trap names the line and the command on stderr AND in the transcript,
    # and leaves a status file, so every future death is diagnosable from
    # the bundle alone. errtrace extends it into functions.
    set -o errtrace
    on_err() {
      err_status=$1; err_line=$2; err_cmd=$3
      echo "golem-install: died at line $err_line (exit $err_status): $err_cmd" >&2
      printf '%s\n' "died   line $err_line (exit $err_status): $err_cmd" >> "$TR"
      echo "error: line $err_line: $err_cmd (exit $err_status)" > "$logdir/status"
    }
    trap 'on_err "$?" "$LINENO" "$BASH_COMMAND"' ERR
    # Fallback for deaths ERR cannot see (nounset, plain exit n): any
    # nonzero exit that left no status gets a generic one.
    on_exit() {
      exit_status=$?
      if (( exit_status != 0 )) && [[ ! -f "$logdir/status" ]]; then
        echo "error: exit $exit_status (see transcript)" > "$logdir/status"
      fi
    }
    trap on_exit EXIT

    # ── 1. The swap size, from the flake's rule ───────────────────────
    ram_mb=$(( $(grep -m1 MemTotal /proc/meminfo | grep -oE '[0-9]+') / 1024 ))
    swap_mb=$(nix eval --offline --no-write-lock-file --raw \
      ${overrideArgs} \
      "path:$src#lib.golem.swapForHibernationMB" \
      --apply "f: toString (f $ram_mb)" 2>/dev/null)
    [[ "$swap_mb" =~ ^[0-9]+$ ]] || {
      echo "golem-install: could not get the swap rule from the flake" >&2; exit 1; }

    if [[ "$luks" == true && ! -r "$luks_key" ]]; then
      echo "golem-install: --luks needs --luks-key FILE (install-cli writes one)" >&2
      exit 2
    fi

    # How this machine boots decides the whole first partition and the
    # bootloader (see the census firmware fact). The installer runs on the
    # machine it installs, so it reads /sys/firmware/efi directly — same
    # source as the probe. UEFI → ESP + systemd-boot; BIOS → a 1 MiB
    # BIOS-boot partition + GRUB. GPT on both, so a BIOS disk can still grow
    # into dual-boot later (MBR's 4-partition limit could not).
    firmware="bios"; [[ -d /sys/firmware/efi ]] && firmware="uefi"
    # BIOS + LUKS would need GRUB to unlock the container (cryptomount) and
    # is not built yet — refuse rather than produce an unbootable disk.
    if [[ "$firmware" == "bios" && "$luks" == true ]]; then
      echo "golem-install: encryption on a BIOS/legacy machine is not supported yet" >&2
      exit 2
    fi

    {
      echo "── plan ─────────────────────────────────────────"
      if [[ "$rehearse" == true ]]; then
        echo "  mode        REHEARSAL — nothing will be written to $disk"
      fi
      echo "  disk        $disk  ($(lsblk -ndo SIZE "$disk" | tr -d ' '))"
      echo "  RAM         $ram_mb MB"
      echo "  firmware    $firmware  ($([[ "$firmware" == uefi ]] && echo 'systemd-boot' || echo 'GRUB'))"
      if [[ "$firmware" == uefi ]]; then
        echo "  ESP         512 MiB       label ESP"
      else
        echo "  bios-boot   1 MiB         (GRUB core, no filesystem)"
      fi
      echo "  swap        $swap_mb MiB  label swap   (hibernation, locked)"
      echo "  root        rest          label golem"
      echo "  owner       $owner ($fullname)"
      echo "  hostname    $hostname"
      if [[ "$luks" == true ]]; then
        echo "  encryption  LUKS2 on $(part 2), swap and root inside it"
      else
        echo "  encryption  none"
      fi
      echo
    } > "$logdir/plan.txt"
    cat "$logdir/plan.txt"

    # ── Preflight: what must be true before a byte moves ──────────────
    # Grown FOR the rehearsal, run in BOTH modes: every check the lab
    # teaches hardens the real install for free, because they are the
    # same code path.
    #
    # The bootloader follows the firmware (both are now supported): UEFI
    # installs systemd-boot to the ESP, BIOS installs GRUB to the disk via
    # the BIOS-boot partition. This was a hard FAIL in round 1 (systemd-boot
    # is UEFI-only and BIOS support did not exist); round 2 made BIOS a real
    # path, so it is an ok line now, not a blocker.
    if [[ "$firmware" == uefi ]]; then
      check_ok "firmware: booted UEFI — systemd-boot to the ESP"
    else
      check_ok "firmware: booted BIOS/legacy — GRUB to $disk (BIOS-boot partition)"
    fi

    # The medium must never be its own target: lsblk resolves the disk
    # behind /iso (the mounted stick). Absent /iso means a dev box, where
    # the check has nothing to say.
    if medium_part=$(findmnt -no SOURCE /iso 2>/dev/null); then
      medium_pk=$(lsblk -no PKNAME "$medium_part" 2>/dev/null | head -1 || true)
      medium_disk="$medium_part"
      [[ -n "$medium_pk" ]] && medium_disk="/dev/$medium_pk"
      if [[ "$medium_disk" == "$disk" ]]; then
        check_fail "target: $disk is the medium this system booted from"
      else
        check_ok "target: $disk is not the boot medium ($medium_disk)"
      fi
    else
      check_ok "target: no /iso mount (not on the medium) — self-install check has nothing to say"
    fi

    # The full system closure is ~18.8 GiB; a root that cannot hold it
    # fails at the very end of nixos-install, which is the worst possible
    # place to find out.
    disk_mb=$(( $(blockdev --getsize64 "$disk") / 1048576 ))
    first_mb=512; [[ "$firmware" == bios ]] && first_mb=1
    root_mb=$(( disk_mb - first_mb - swap_mb ))
    if (( root_mb >= 20480 )); then
      check_ok "fit: root gets $root_mb MiB after boot+swap (the closure needs ~19 GiB)"
    else
      check_fail "fit: root would get $root_mb MiB of $disk_mb — the system closure alone is ~19 GiB"
    fi

    # Below a 4 GB machine the local eval/build cannot complete — it
    # thrashes the box into a swap spiral instead of failing (Comodore at
    # 1931 MB, Dell at 1790 MB, rounds 1-2). A sticker-4 GB machine
    # reports ~3700-3850 MB to the kernel after reserved memory, so the
    # cutoff sits at 3300: above every sticker-2/3 GB box, below the
    # lowest proven pass (3718 MB — evals 31-171 s). The message speaks
    # sticker language (Max, 2026-09-07). A rehearsal records the FAIL
    # and later SKIPS the eval so the machine stays responsive and the
    # rest of the flow still gets exercised; a real install refuses here
    # (check_fail exits in real mode). Prebuilt-closure delivery for
    # these machines is the round-4 question.
    ram_ok=true
    if (( ram_mb < 3300 )); then
      ram_ok=false
      check_fail "ram: this machine has $ram_mb MB — installing Golem needs about 4 GB of RAM"
    else
      check_ok "ram: $ram_mb MB is enough to evaluate the system locally"
    fi

    if [[ "$assume_yes" != true && "$skip_prepare" != true && "$rehearse" != true ]]; then
      echo "This ERASES $disk completely. Type ERASE to continue:"
      read -r reply
      [[ "$reply" == "ERASE" ]] || { echo "aborted"; echo "aborted" > "$logdir/status"; exit 1; }
    fi

    # ── 2. Partition ──────────────────────────────────────────────────
    # A rehearsal redirects every target write into a shadow tree inside
    # the bundle; the real install's paths are untouched. $mnt is the ONLY
    # thing that differs — the code below is the same in both modes.
    mnt=/mnt
    if [[ "$rehearse" == true ]]; then
      mnt="$logdir/mnt"
      mkdir -p "$mnt"
    fi
    seed="$mnt/home/$owner/Golem"

    if [[ "$skip_prepare" == true ]]; then
      mountpoint -q /mnt || { echo "golem-install: --skip-prepare but /mnt is not mounted" >&2; exit 1; }
      [[ -d "$seed" ]] || { echo "golem-install: --skip-prepare but no seed at $seed" >&2; exit 1; }
      echo "resuming: /mnt mounted, seed present — install step only"
    else

    # Phase markers carry a KEY, not label text: the surface maps the key
    # to a translated string at display time (changes.md #18b — literal
    # English here painted "Evaluating the system" onto a Spanish run).
    echo "##golem 1/6 format"
    run swapoff -a || true
    run cryptsetup close golem 2>/dev/null || true
    run umount -R /mnt 2>/dev/null || true
    run wipefs -a "$disk"
    run sgdisk --zap-all "$disk"

    if [[ "$luks" == true ]]; then
      # ── ENCRYPTED LAYOUT: ESP + one LUKS container + LVM inside ──────
      #
      # ONE container, not two, and LVM inside it — because HIBERNATION IS
      # LOCKED (memory.nix) and hibernation needs the swap readable from
      # initrd. Separate LUKS volumes for root and swap would mean either
      # typing the passphrase twice at every boot, or a keyfile for swap
      # that has to live somewhere — and the only place it could live is
      # the root that is not open yet. One container unlocked once gives
      # both, which is why the swap moves inside instead of staying its
      # own partition.
      #
      # The ESP stays outside and unencrypted, as it must: the firmware
      # reads it before anything can ask for a passphrase.
      run sgdisk -n1:0:+512M -t1:ef00 -c1:ESP   "$disk"
      run sgdisk -n2:0:0     -t2:8309 -c2:crypt "$disk"
      run partprobe "$disk" 2>/dev/null || true
      run udevadm settle

      run cryptsetup luksFormat --type luks2 --batch-mode \
        --key-file "$luks_key" "$(part 2)"
      run cryptsetup open --key-file "$luks_key" "$(part 2)" golem
      # The passphrase has done its job. It was written to a 0600 file on
      # the medium's tmpfs — RAM, never a disk — and it goes now rather
      # than at the end, so no later failure can leave it lying around.
      # A rehearsal keeps it: it opened no container, and shredding it
      # would eat the passphrase a real run right after might want.
      if [[ "$rehearse" == true ]]; then
        note "keyfile kept (rehearsal opened nothing): $luks_key"
      else
        shred -u "$luks_key" 2>/dev/null || rm -f "$luks_key"
      fi

      run pvcreate /dev/mapper/golem
      run vgcreate golemvg /dev/mapper/golem
      run lvcreate -L "''${swap_mb}M" -n swap golemvg
      run lvcreate -l 100%FREE -n root golemvg
      run udevadm settle

      run mkfs.fat -F32 -n ESP "$(part 1)"
      run mkswap -L swap /dev/golemvg/swap
      run mkfs.ext4 -F -L golem /dev/golemvg/root
      # The UUID of the CONTAINER, not of anything inside it: that is what
      # initrd has to be told to unlock, and it is stable across reboots
      # where /dev/sda2 is not.
      if [[ "$rehearse" == true ]]; then
        luks_uuid="REHEARSAL-0000-0000-0000-000000000000"
        note "luks uuid is a placeholder — the real install reads it from blkid after luksFormat"
      else
        luks_uuid=$(blkid -s UUID -o value "$(part 2)")
      fi
    elif [[ "$firmware" == uefi ]]; then
      run sgdisk -n1:0:+512M   -t1:ef00 -c1:ESP   "$disk"
      run sgdisk -n2:0:+"$swap_mb"M -t2:8200 -c2:swap  "$disk"
      run sgdisk -n3:0:0       -t3:8300 -c3:golem "$disk"
      run partprobe "$disk" 2>/dev/null || true
      run udevadm settle

      run mkfs.fat -F32 -n ESP "$(part 1)"
      run mkswap -L swap "$(part 2)"
      run mkfs.ext4 -F -L golem "$(part 3)"
    else
      # ── BIOS/legacy LAYOUT: GPT + a BIOS-boot partition + GRUB ──────
      # GPT even on BIOS (not MBR) so the disk can grow into dual-boot; a
      # 1 MiB partition of type ef02 (no filesystem) is where GRUB embeds
      # core.img, since a GPT disk has no post-MBR gap for it. There is no
      # ESP — BIOS firmware does not read one — and no separate /boot: GRUB
      # reads /boot straight off the root ext4. So: bios-boot, swap, root.
      run sgdisk -n1:0:+1M     -t1:ef02 -c1:bios  "$disk"
      run sgdisk -n2:0:+"$swap_mb"M -t2:8200 -c2:swap  "$disk"
      run sgdisk -n3:0:0       -t3:8300 -c3:golem "$disk"
      run partprobe "$disk" 2>/dev/null || true
      run udevadm settle

      run mkswap -L swap "$(part 2)"
      run mkfs.ext4 -F -L golem "$(part 3)"
    fi
    run udevadm settle

    # by-label works for both layouts: the encrypted branch labels its
    # logical volumes `golem` and `swap` exactly as the plain branch labels
    # its partitions, so everything downstream of here is identical.
    # The mount TARGETS are spelled /mnt, not $mnt: in a real install the
    # two are the same, and in a rehearsal the mounts are recorded, not
    # executed — and the transcript must describe what the REAL install
    # would do, or it can never be diffed against a real run's transcript
    # (the first VM calibration recorded the shadow path here, which is a
    # transcript lying about the install it rehearses).
    echo "##golem 2/6 fs"
    run mount /dev/disk/by-label/golem /mnt
    # The ESP is mounted only on UEFI (plain or LUKS). On BIOS there is no
    # ESP: /boot lives on the root fs GRUB already reads, so nothing to mount.
    if [[ "$firmware" == uefi ]]; then
      mkdir -p "$mnt/boot"
      run mount /dev/disk/by-label/ESP /mnt/boot
    fi
    # ON before nixos-generate-config: that is how the swap partition ends
    # up in hardware-configuration.nix's swapDevices, which is what wires
    # boot.resumeDevice and the lid's suspend-then-hibernate. An install
    # that skips this boots WITHOUT hibernation and nothing complains.
    run swapon /dev/disk/by-label/swap

    # ── 3. Seed the checkout ──────────────────────────────────────────
    # Real work in both modes: the rehearsal copies into its shadow tree,
    # which is what lets step 5 evaluate the seed exactly as the real
    # install would.
    echo "##golem 3/6 seed"
    mkdir -p "$seed"
    cp -a "$src"/. "$seed"/
    chmod -R u+w "$seed"
    note "seed: $(du -sm "$seed" | cut -f1) MiB at $seed"

    # ── 4. The three dropped files ────────────────────────────────────
    echo "##golem 4/6 probe"
    mkdir -p "$seed/hosts/target"
    golem-hw-detect > "$seed/hosts/target/golem-hardware.nix"

    # The boot audit measured this machine ~a boot ago; the line above
    # measured it just now. They must agree, or detection is racing
    # something — the exact instability the three-boots-deep check on lab
    # row 1 existed to rule out. A warning, not a failure: unplugging a
    # USB radio between boot and install is legitimate.
    # The "# Generated by" header carries the probe's timestamp, which
    # differs on every run by construction — compare the FACTS (the first
    # VM calibration warned on nothing but the two timestamps).
    if [[ -f /var/log/golem-audit/golem-hardware.nix ]]; then
      if diff -q <(grep -v '^# Generated' /var/log/golem-audit/golem-hardware.nix) \
                 <(grep -v '^# Generated' "$seed/hosts/target/golem-hardware.nix") >/dev/null; then
        check_ok "facts: the probe now matches the boot audit fact for fact"
      else
        check_warn "facts: the probe now DIFFERS from the boot audit — hardware changed since boot, or detection is unstable:"
        diff <(grep -v '^# Generated' /var/log/golem-audit/golem-hardware.nix) \
             <(grep -v '^# Generated' "$seed/hosts/target/golem-hardware.nix") >> "$CHK" || true
      fi
    fi

    if [[ "$rehearse" == true ]]; then
      # The real install lets nixos-generate-config MEASURE the mounted
      # target. Nothing is mounted here, so the file is assembled from a
      # measured half and a guaranteed half: --show-hardware-config reads
      # this machine's kernel modules without wanting a root, and the
      # filesystems are what the partitioning above guarantees by
      # construction — both branches label root `golem`, boot `ESP`, swap
      # `swap`. The real file will name the same devices by-uuid; the
      # header inside says so, so nobody mistakes synthesis for
      # measurement.
      hw=$(nixos-generate-config --show-hardware-config --no-filesystems)
      {
        printf '%s\n' "''${hw%\}}"
        echo "  # REHEARSAL SYNTHESIS — the real install measures these from the"
        echo "  # mounted target and writes by-uuid paths. Same devices, found a"
        echo "  # different way; the labels are guaranteed by the partitioning."
        echo "  fileSystems.\"/\" = { device = \"/dev/disk/by-label/golem\"; fsType = \"ext4\"; };"
        # UEFI has an ESP mounted at /boot; BIOS keeps /boot on the root fs
        # (GRUB reads it there), so no /boot filesystem entry.
        if [[ "$firmware" == uefi ]]; then
          echo "  fileSystems.\"/boot\" = { device = \"/dev/disk/by-label/ESP\"; fsType = \"vfat\"; options = [ \"fmask=0022\" \"dmask=0022\" ]; };"
        fi
        echo "  swapDevices = [ { device = \"/dev/disk/by-label/swap\"; } ];"
        echo "}"
      } > "$seed/hosts/target/hardware-configuration.nix"
      note "hardware-configuration.nix synthesized: measured modules + by-label filesystems ($firmware)"
    else
      nixos-generate-config --root /mnt
      cp /mnt/etc/nixos/hardware-configuration.nix "$seed/hosts/target/"
      # nixos-generate-config also drops a stock configuration.nix. Golem is
      # a flake distro; leaving a second, channel-shaped config on the disk
      # is only an invitation to rebuild the wrong thing.
      rm -f /mnt/etc/nixos/configuration.nix
    fi

    {
      echo "# The human choices for this machine, written by golem-install."
      echo "# Everything else about this system comes from the flake."
      echo "{ ... }:"
      echo "{"
      echo "  golem.owner = \"$owner\";"
      echo "  networking.hostName = \"$hostname\";"
      echo "  users.users.$owner.description = \"$fullname\";"
      echo
      echo "  # The language step's answer. Drives i18n.defaultLocale and"
      echo "  # which locales get generated — an ungenerated locale falls"
      echo "  # back to C at first boot without saying so."
      echo "  golem.locale.defaultLocale = \"$locale\";"
      echo "  golem.locale.timeZone = \"$timezone\";"
      # Without this the account has NO password at all — which is what
      # every install produced before the You step existed, since
      # nixos-install also runs --no-root-password.
      if [[ -n "$passhash" && "$passhash" != "!unhashed" ]]; then
        echo "  users.users.$owner.hashedPassword = \"$passhash\";"
      fi
      # The container's UUID, so initrd knows what to ask a passphrase for.
      # nixos-generate-config does NOT write this: it describes filesystems
      # it can see through an already-open mapper, not the thing that has to
      # be opened first — so a machine installed without this line comes up
      # in an initrd emergency shell, encrypted and unbootable.
      if [[ -n "$luks_uuid" ]]; then
        echo
        echo "  # Unlocked once in initrd; swap and root are LVM inside it,"
        echo "  # which is what lets hibernation resume from an encrypted swap."
        echo "  boot.initrd.luks.devices.golem.device = \"/dev/disk/by-uuid/$luks_uuid\";"
      fi
      # On BIOS the target installs GRUB, which needs the DISK to embed into
      # (the config default is a placeholder). This names the real target
      # disk — the by-id path, stable across reboots where /dev/sda is not.
      if [[ "$firmware" == bios ]]; then
        # errexit-safe on purpose: the round-2 form ended in a bare
        # `[[ ]] && { }` whose false guard returned 1 out of the command
        # substitution, and errexit killed the engine mid-file — on the
        # first disk with no by-id alias (VM, changes.md #19). An `if`
        # never leaks the guard's status; -e covers the unmatched-glob
        # literal.
        disk_byid=""
        for l in /dev/disk/by-id/*; do
          if [[ -e "$l" && "$(readlink -f "$l")" == "$disk" ]]; then
            disk_byid="$l"
            break
          fi
        done
        [[ -n "$disk_byid" ]] || disk_byid="$disk"
        echo
        echo "  # BIOS/legacy boot: GRUB embeds into this disk's BIOS-boot"
        echo "  # partition. by-id so it survives device-name reshuffles."
        echo "  boot.loader.grub.device = \"$disk_byid\";"
      fi
      echo
      echo "  # The keyboard step's one answer. Four values, three sinks:"
      echo "  # console.keyMap, services.xserver.xkb.*, and Hyprland's own"
      echo "  # input block — wired from these in system/configuration.nix"
      echo "  # and system/home/home.nix. A comma in layout means a second"
      echo "  # Latin group so a non-Latin script can still type a URL."
      echo "  golem.keyboard = {"
      echo "    layout = \"$kb_layout\";"
      echo "    variant = \"$kb_variant\";"
      echo "    options = \"$kb_options\";"
      echo "    model = \"$kb_model\";"
      echo "    consoleKeyMap = \"$kb_console\";"
      # Only when the script needs one — null keeps the kernel default,
      # which is the right font for every Latin keymap.
      [[ -n "$kb_font" ]] && echo "    consoleFont = \"$kb_font\";"
      echo "  };"
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
      echo "##golem prepared"
      echo "prepared: disk partitioned, /mnt mounted, seed at $seed."
      echo "deliver the system closure to /mnt, then re-run with"
      echo "  golem-install --disk $disk --owner $owner --skip-prepare --system PATH"
      exit 0
    fi

    # ── 5. Build and install ──────────────────────────────────────────
    if [[ "$rehearse" == true ]]; then
      # The rehearsal's payload: INSTANTIATE the exact system the real
      # install would build — from the seeded checkout, with the three
      # dropped files in place, through the same pin table, offline, on
      # this machine's own RAM. On the 4 GB class the eval is itself a
      # measurement: a machine that cannot evaluate its own system cannot
      # run a product install's build step either, and that is worth
      # knowing before any disk is touched.
      echo "##golem 5/6 eval"
      if [[ "$ram_ok" != true ]]; then
        # The ram check above already FAILed; running the eval anyway
        # would thrash the machine into the exact swap spiral the check
        # exists to prevent — and bury findings 2..n with it.
        note "eval SKIPPED: $ram_mb MB cannot evaluate the target without thrashing (see the ram check)"
      else
      t0=$SECONDS
      if drv=$(nix eval --offline --no-write-lock-file --raw \
          ${overrideArgs} \
          "path:$seed#nixosConfigurations.golem-target.config.system.build.toplevel.drvPath" \
          2>"$logdir/eval.err"); then
        check_ok "eval: the target system instantiates in $(( SECONDS - t0 ))s → $drv"
        echo "$drv" > "$logdir/toplevel.drv"
        # On success the file holds only nix's input-override narration —
        # noise that contradicts "read checks.txt first". It stays when
        # the eval fails, because then it IS the finding's trace.
        rm -f "$logdir/eval.err"
      else
        check_fail "eval: the target system does NOT evaluate — eval.err has the trace"
      fi
      fi
      note "would nixos-install --root /mnt --system <built toplevel> --no-root-password --no-channel-copy"
      note "would chown the seed to $owner, then reboot on the 6/6 marker"

      # The bundle: everything the dev box needs to audit this machine's
      # would-be install. The dropped files are copied out of the shadow
      # seed because the seed itself goes — it is a full checkout in RAM,
      # and its job (feeding the eval) is done.
      cp -a "$seed/hosts/target" "$logdir/target"
      if [[ -n "$answers" && -r "$answers" ]]; then
        cp "$answers" "$logdir/answers"
      fi
      rm -rf "$mnt"
      if (( findings == 0 )); then
        echo ok > "$logdir/status"
      else
        echo "findings: $findings" > "$logdir/status"
      fi
      tmptar=$(mktemp /tmp/golem-rehearsal.XXXXXX)
      tar czf "$tmptar" -C "$logdir" .
      mv "$tmptar" "$logdir/rehearsal.tar.gz"

      echo "##golem rehearsed $findings"
      echo "── rehearsed ────────────────────────────────────"
      echo "  nothing was written to $disk"
      echo "  findings: $findings   report: $logdir"
      echo "  read checks.txt first; rehearsal.tar.gz is ready to pull"
      exit 0
    fi

    echo "##golem 5/6 install"
    if [[ -z "$system" ]]; then
      echo "building golem-target (this is the long part)…"
      system=$(nix build --offline --no-write-lock-file --no-link --print-out-paths \
        ${overrideArgs} \
        "path:$seed#nixosConfigurations.golem-target.config.system.build.toplevel")
    fi
    echo "installing system: $system"

    run nixos-install --root /mnt --system "$system" --no-root-password --no-channel-copy

    # The seed is the installed machine's own flake (golem.flakeDir), so it
    # must belong to the owner, not to root — rebuild-golem runs as them.
    uid=$(chroot /mnt id -u "$owner" 2>/dev/null || echo "")
    gid=$(chroot /mnt id -g "$owner" 2>/dev/null || echo "")
    if [[ -n "$uid" && -n "$gid" ]]; then
      run chown -R "$uid:$gid" "/mnt/home/$owner"
    else
      echo "note: user '$owner' not found in the installed system — seed left root-owned" >&2
    fi

    echo
    # The 6/6 marker is the surface's REBOOT TRIGGER: golem-setup restarts
    # the machine only after seeing it, so it must mean "nixos-install
    # succeeded", never "the script got to the end of prepare".
    echo "##golem 6/6 done"
    echo "── done ─────────────────────────────────────────"
    echo "  installed to $disk; seed checkout at /home/$owner/Golem"
    echo "  reboot and remove the medium."
  '';
}
