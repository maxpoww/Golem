# golem-hw-evidence — dump this machine's raw hardware truth, once.
#
# The lab's multiplier (PLAN.md): detection is a pure function of
# evidence, so each machine's dump becomes a committed fixture the probe
# is re-verified against forever — no re-boot needed when the parse logic
# changes for a later machine.
#
#   golem-hw-evidence            # write /tmp/evidence-<id>/ and print path
#   golem-hw-evidence -t         # ...and a .tar.gz next to it (for scp)
#
# Read-only. Every collector is best-effort (|| true): a source missing on
# some machine must never abort the dump — an absent file IS evidence.
{ pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "golem-hw-evidence";
      runtimeInputs = with pkgs; [
        coreutils
        pciutils # lspci
        usbutils # lsusb
        dmidecode
        iproute2 # ip
        kmod # lsmod
        util-linux # rfkill, lsblk
        gnutar
        gzip
      ];
      text = ''
        # Root matters: dmidecode, lspci -vv and lsusb -v all degrade
        # silently without it (lab rows 0+1 were first dumped as nixos and
        # lost the whole SMBIOS table that way). Warn, don't refuse — a
        # degraded dump of a machine you no longer have beats none.
        [ "$(id -u)" = 0 ] \
          || echo "golem-hw-evidence: not root — dmidecode/lspci -vv/lsusb -v will be incomplete" >&2

        # Machine id: DMI product name, else hostname — used for the dir name.
        id=$(tr -cd '[:alnum:]._-' < /sys/class/dmi/id/product_name 2>/dev/null || true)
        [ -n "$id" ] || id=$(hostname)
        out="/tmp/evidence-$id"
        # A fresh dump, always: a leftover dir would mix two runs' files,
        # and a leftover tarball from ANOTHER user makes tar's O_CREAT fail
        # under fs.protected_regular even as root (hit on the Acer, row 1).
        # Sticky /tmp also blocks a non-root run from clearing root's
        # leftovers — surface that case instead of half-dumping.
        rm -rf "$out" "$out.tar.gz" || {
          echo "golem-hw-evidence: cannot clear stale $out (another user's?) — remove it or run as root" >&2
          exit 1
        }
        mkdir -p "$out"

        run() { # run NAME CMD... — one file per collector, failure recorded
          name="$1"; shift
          { "$@" || echo "EXIT:$? (absent on this machine?)"; } \
            > "$out/$name" 2>&1
        }

        run lspci-nnk.txt      lspci -nnk
        run lspci-vv.txt       lspci -vv
        run lsusb.txt          lsusb
        run lsusb-v.txt        lsusb -v
        run dmidecode.txt      dmidecode
        run cpuinfo.txt        cat /proc/cpuinfo
        run meminfo.txt        cat /proc/meminfo
        run lsmod.txt          lsmod
        run rfkill.txt         rfkill list
        run ip-link.txt        ip -d link
        run lsblk.txt          lsblk -o NAME,SIZE,TYPE,TRAN,ROTA,MODEL
        run uname.txt          uname -a
        run efi.txt            ls /sys/firmware/efi

        # sysfs trees the probe reads — captured as path→value lines so a
        # fixture can replay them without a fake sysfs.
        sysdump() { # sysdump NAME GLOB...
          name="$1"; shift
          for f in "$@"; do
            # -f, not -r: connector nodes make card*/device/device resolve
            # to a DIRECTORY (readable, so -r passed → junk lines + tr noise
            # in the first Acer dump); only regular files are evidence here.
            [ -f "$f" ] && printf '%s=%s\n' "$f" "$(tr -d '\n' < "$f")"
          done > "$out/$name" || true
        }
        sysdump drm.txt /sys/class/drm/card*/device/{vendor,device,class} \
                        /sys/class/drm/card*/device/uevent
        # Panel evidence for the panelDpi fact: connector status, mode
        # list (first = native), and the EDID's physical-size bytes
        # (21=h, 22=v, cm) — the EDID itself is binary, so only the two
        # bytes the probe reads are recorded, as text.
        sysdump drm-conn.txt /sys/class/drm/card*-*/status \
                             /sys/class/drm/card*-*/modes
        for e in /sys/class/drm/card*-*/edid; do
          [ -r "$e" ] || continue
          printf '%s=%s\n' "$e" \
            "$(od -An -tu1 -j21 -N2 "$e" 2>/dev/null | tr -s ' ')"
        done > "$out/edid.txt" || true
        sysdump dmi.txt /sys/class/dmi/id/{sys_vendor,product_name,product_family,chassis_type,board_vendor,bios_vendor,bios_version}
        sysdump power.txt /sys/class/power_supply/*/type
        sysdump bluetooth.txt /sys/class/bluetooth/*/address
        sysdump net.txt /sys/class/net/*/device/uevent
        sysdump input.txt /sys/class/input/input*/name

        if [ "''${1:-}" = "-t" ]; then
          tar -C /tmp -czf "$out.tar.gz" "$(basename "$out")"
          echo "$out.tar.gz"
        fi
        echo "$out"
      '';
    })
  ];
}
