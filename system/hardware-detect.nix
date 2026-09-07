# golem-hw-detect — read this machine's hardware and emit the Nix that
# tunes Golem for it. The S9 installer runs this on the TARGET, before the
# first build, so first boot comes up correctly sized and with the right GPU
# driver (see system/hardware.nix for what the emitted options drive).
#
#   golem-hw-detect            # print golem-hardware.nix to stdout
#   golem-hw-detect -o DIR     # write DIR/golem-hardware.nix and, via
#                              # nixos-generate-config, DIR/hardware-configuration.nix
#
# Pure read-only detection except for the files it is asked to write. Safe
# to run on a live machine to preview what the installer would generate.
{ pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "golem-hw-detect";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.gnugrep
        pkgs.nixos-install-tools
        pkgs.util-linux # rfkill — one leg of the bluetooth triangulation
      ];
      text = ''
        outdir=""
        if [[ "''${1:-}" == "-o" && -n "''${2:-}" ]]; then
          outdir="$2"
        fi

        # ── CPU: model, physical cores, logical threads ──────────────────
        # `nproc` counts LOGICAL cpus. Reporting that as "cores" told the
        # lab the Acer's i5-5200U had 4 cores when it has 2 (Max, caught
        # 2026-09-05) — a dual-core with SMT reads identically to a real
        # quad unless you look at the topology.
        #
        # Physical cores are counted from SYSFS, not /proc/cpuinfo: every
        # logical CPU on a shared physical core lists the same siblings in
        # thread_siblings_list, so the number of DISTINCT lists is the
        # physical-core count. sysfs is chosen deliberately over cpuinfo
        # because this pipeline then needs only cat/sort/grep — all from
        # coreutils and gnugrep, which are in runtimeInputs above. The
        # cpuinfo version parsed with awk (gawk), which was NOT declared and
        # so resolved only from the ambient PATH: it read 2 in an
        # interactive shell but was "command not found" under the boot
        # audit's clean systemd PATH — the ONLY context that feeds the
        # census — where the pipeline collapsed and the guard fell back to
        # threads. The Acer's audit reported cores=4 on real metal (caught
        # 2026-09-06, first live boot of the rehearsal stick) while every
        # SSH re-check said 2. A tool must not reach outside its own closure
        # for something this basic. Where sysfs has no topology (some exotic
        # kernels), fall back to threads rather than inventing a number.
        threads=$(nproc)
        cores=$(cat /sys/devices/system/cpu/cpu[0-9]*/topology/thread_siblings_list \
          2>/dev/null | sort -u | grep -c . || true)
        [[ "$cores" =~ ^[0-9]+$ ]] && (( cores > 0 )) || cores=$threads

        cpu_model=$(grep -m1 '^model name' /proc/cpuinfo | cut -d: -f2- \
          | sed 's/^ *//; s/ \+/ /g' || true)
        [ -n "$cpu_model" ] || cpu_model="unknown"

        # ── RAM (MiB) ────────────────────────────────────────────────────
        ram_kb=$(grep -m1 MemTotal /proc/meminfo | grep -oE '[0-9]+')
        ram_mb=$(( ram_kb / 1024 ))

        # ── GPU vendor, from the PCI vendor id of each DRM card ───────────
        # Priority nvidia > amd > intel > virtio: on a hybrid laptop the
        # discrete nvidia is the one that needs the non-default driver, and
        # a machine with both an iGPU and a dGPU should pick the dGPU here.
        gpu="auto"
        have_intel=0
        intel_legacy=false
        nv_dev=""
        nv_slot=""
        intel_slot=""
        # sysfs uevent → "PCI:bus:dev:fn" as X11 BusID wants it — DECIMAL,
        # while PCI_SLOT_NAME (0000:01:00.0) is hex. printf %d converts.
        slot_of() {
          local s
          s=$(grep -m1 '^PCI_SLOT_NAME=' "$1/uevent" 2>/dev/null | cut -d= -f2)
          [[ -n "$s" ]] || return 0
          s=''${s#*:}
          printf 'PCI:%d:%d:%d' "0x''${s%%:*}" "0x$(cut -d: -f2 <<<"$s" | cut -d. -f1)" "0x''${s##*.}"
        }
        for v in /sys/class/drm/card[0-9]*/device/vendor; do
          [[ -r "$v" ]] || continue
          id=$(tr -d '[:space:]' < "$v")
          case "$id" in
            0x10de)
              gpu="nvidia"
              nv_dev=$(tr -d '[:space:]' < "$(dirname "$v")/device" 2>/dev/null || true)
              nv_slot=$(slot_of "$(dirname "$v")")
              ;;
            0x1002) [[ "$gpu" == "nvidia" ]] || gpu="amd" ;;
            0x8086)
              have_intel=1
              intel_slot=$(slot_of "$(dirname "$v")")
              # iHD (intel-media-driver) does hardware video decode only on
              # Broadwell+ (Gen8+); older parts need the LEGACY i965 driver,
              # or iHD silently gives no decode — which is why a 2013 HD 5000
              # CPU-decodes VP9 and cooks the chip.
              #
              # The test is NOT a single threshold, because Intel's device
              # ids do not grow monotonically with generation. Ironlake→
              # Haswell sit below 0x1600 (0x0042–0x0d26); Broadwell (0x16xx),
              # Skylake+ (0x1900+) and everything newer (0x3exx CoffeeLake,
              # 0x9bxx CometLake, 0x46xx TigerLake…) sit above it and are fine
              # on iHD. BUT the ancient GMA family (Gen3/4 — GMA 900 through
              # X4500, 2005–2009) has ids in 0x2500–0x2e99, ABOVE 0x1600
              # despite being the OLDEST — so a lone < 0x1600 test marked a
              # GMA 4500 (0x2a42) as iHD-capable and got no decode (Comodore,
              # round 1). Both ranges are legacy. (Braswell 0x22b0 is Gen8 and
              # iHD-capable, and sits below 0x2500, so it is correctly not
              # caught.) Display is unaffected either way — the kernel i915
              # driver handles all of these.
              dev=$(tr -d '[:space:]' < "$(dirname "$v")/device" 2>/dev/null || true)
              if [[ -n "$dev" ]] && { (( dev < 0x1600 )) \
                   || { (( dev >= 0x2500 )) && (( dev <= 0x2e99 )); }; }; then
                intel_legacy=true
              fi
              ;;
            0x1af4|0x1234|0x15ad) [[ "$gpu" == "auto" ]] && gpu="virtio" ;;
          esac
        done
        if [[ "$gpu" == "auto" && "$have_intel" == 1 ]]; then
          gpu="intel"
        fi

        # ── NVIDIA generation, by device-id range (the iron law, spec §8) ─
        # NVIDIA ids are monotonic by generation: Turing starts at 0x1e00
        # (TU102) — everything at or above runs the open GSP module and the
        # current branch. 0x1340 (first Maxwell GM108M) up to 0x1dff is
        # Maxwell/Pascal/Volta — the 580 legacy branch's territory. Below
        # that (Kepler and older), or an unreadable id, stays "unknown" and
        # gpu-nvidia.nix leaves the machine on the nouveau/modesetting
        # floor: uncertain detection must land safe, never black-screen.
        nvidia_gen="unknown"
        if [[ "$gpu" == "nvidia" && -n "$nv_dev" ]]; then
          if (( nv_dev >= 0x1e00 )); then
            nvidia_gen="turing+"
          elif (( nv_dev >= 0x1340 )); then
            nvidia_gen="pre-turing"
          fi
        fi

        # ── Bluetooth: triangulate, never trust one path ─────────────────
        # Lab row 1 (Acer E5-573) lesson: /sys/class/bluetooth read empty in
        # one dump while rfkill showed hci0 — a USB radio can register late
        # or lose a race with udev. Three legs, any one convicts:
        # the sysfs class, an rfkill bluetooth row, or a USB interface of
        # class e0 (wireless controller — how btusb radios present).
        has_bt=false
        if [[ -n "$(ls -A /sys/class/bluetooth 2>/dev/null)" ]]; then
          has_bt=true
        elif rfkill list bluetooth 2>/dev/null | grep -q .; then
          has_bt=true
        else
          for c in /sys/bus/usb/devices/*/bInterfaceClass; do
            [[ -r "$c" && "$(cat "$c")" == "e0" ]] && { has_bt=true; break; }
          done
        fi

        # ── CPU vendor → microcode ───────────────────────────────────────
        cpu_vendor="unknown"
        case "$(grep -m1 '^vendor_id' /proc/cpuinfo | grep -oE '[A-Za-z]+$' || true)" in
          GenuineIntel) cpu_vendor="intel" ;;
          AuthenticAMD) cpu_vendor="amd" ;;
        esac

        # ── Chassis: DMI type, battery as the fallback tell ──────────────
        # SMBIOS chassis types: 8-11/14/31/32 are the portable family;
        # 3-7/15/16 the desktop family. Anything else stays unknown unless
        # a battery gives the laptop away.
        chassis="unknown"
        ct=$(tr -d '[:space:]' < /sys/class/dmi/id/chassis_type 2>/dev/null || true)
        case "$ct" in
          8|9|10|11|14|31|32) chassis="laptop" ;;
          3|4|5|6|7|15|16)    chassis="desktop" ;;
        esac
        if [[ "$chassis" == "unknown" ]] \
           && grep -qs '^Battery$' /sys/class/power_supply/*/type; then
          chassis="laptop"
        fi

        # ── VM guest: DMI vendor strings → that hypervisor's tools ──────
        vm_guest="none"
        sv=$(tr -d '\n' < /sys/class/dmi/id/sys_vendor 2>/dev/null || true)
        pn=$(tr -d '\n' < /sys/class/dmi/id/product_name 2>/dev/null || true)
        case "$sv" in
          QEMU*)                    vm_guest="qemu" ;;
          "VMware, Inc."*)          vm_guest="vmware" ;;
          "innotek GmbH"*)          vm_guest="virtualbox" ;;
          "Microsoft Corporation"*) [[ "$pn" == "Virtual Machine" ]] && vm_guest="hyperv" ;;
        esac

        # ── Fingerprint reader: USB vendors that mean fingerprint ───────
        # Validity 138a, Synaptics 06cb, Goodix 27c6 — on USB these
        # vendors are fingerprint hardware in practice. A false positive
        # costs an idle fprintd; nothing works until a finger is enrolled.
        has_fp=false
        for u in /sys/bus/usb/devices/*/idVendor; do
          [[ -r "$u" ]] || continue
          case "$(cat "$u")" in
            138a|06cb|27c6) has_fp=true; break ;;
          esac
        done

        # ── Internal panel DPI: native mode vs EDID physical width ──────
        # eDP only — external monitors are the user's business. EDID byte
        # 21 is the horizontal image size in cm; the first line of `modes`
        # is the native mode. DPI = px * 2.54 / cm. Gate on connector
        # STATUS, not file size: sysfs stats binary attrs (edid) as 0
        # bytes even when they read fine (Slim Pro 9i, 2026-09-04), and a
        # hybrid exposes a second, dead eDP on the dGPU that status
        # correctly rules out.
        panel_dpi=0
        for c in /sys/class/drm/card[0-9]*-eDP-*; do
          [[ "$(cat "$c/status" 2>/dev/null)" == "connected" ]] || continue
          wcm=$(od -An -tu1 -j21 -N1 "$c/edid" 2>/dev/null | tr -d ' ')
          px=$(head -1 "$c/modes" 2>/dev/null | cut -dx -f1)
          if [[ -n "$wcm" && -n "$px" ]] && (( wcm > 0 )); then
            panel_dpi=$(( px * 254 / (wcm * 100) ))
          fi
          break
        done

        # ── Firmware: how this machine boots ────────────────────────────
        # /sys/firmware/efi exists iff the kernel booted UEFI. The medium
        # boots the way the machine's firmware is set, so this is also how
        # the INSTALLED system must boot: uefi → systemd-boot, bios → GRUB.
        # 3 of the 5 lab machines boot BIOS (round 1), so this is not an
        # edge case. Nothing else gates on how we booted, so it is read here.
        firmware="bios"
        [[ -d /sys/firmware/efi ]] && firmware="uefi"

        # ── Broadcom wifi: the driver a stranger cannot guess ───────────
        # Broadcom (PCI vendor 0x14e4) wireless is the wifi that does not
        # just work — brcmfmac wants redistributable firmware and some parts
        # want the unfree broadcom_sta (wl) module. Detect the card so the
        # installed system enables the driver unasked; the Intel-MacBook
        # BCM4360 is exactly this, and it is a north-star target. Wireless
        # PCI class is 0x0280xx; ethernet (0x0200xx) does not count.
        broadcom_wifi=false
        for d in /sys/bus/pci/devices/*; do
          [[ -r "$d/vendor" && -r "$d/class" ]] || continue
          [[ "$(cat "$d/vendor")" == "0x14e4" ]] || continue
          case "$(cat "$d/class")" in 0x0280*) broadcom_wifi=true; break ;; esac
        done

        # ── Emit ─────────────────────────────────────────────────────────
        # nvidia-only facts appear only on nvidia machines: a facts file is
        # data a human should be able to read top to bottom, so intel boxes
        # don't carry nvidia noise. PRIME bus ids only when detection saw
        # BOTH GPUs (a hybrid) — a desktop's dGPU drives displays directly.
        gen() {
          cat <<EOF
        # Generated by golem-hw-detect on $(date -u +%Y-%m-%dT%H:%M:%SZ).
        # The target machine's detected hardware — imported by the installer
        # so Golem builds tuned for THIS box. Safe to regenerate.
        { ... }:
        {
          golem.hardware = {
            cpuModel = "$cpu_model";
            cores = $cores;
            threads = $threads;
            ramMB = $ram_mb;
            gpu = "$gpu";
            intelLegacy = $intel_legacy;
            firmware = "$firmware";
        EOF
          if [[ "$gpu" == "nvidia" ]]; then
            echo "    nvidiaGen = \"$nvidia_gen\";"
            if [[ -n "$nv_slot" && -n "$intel_slot" ]]; then
              echo "    nvidiaBusId = \"$nv_slot\";"
              echo "    intelBusId = \"$intel_slot\";"
            fi
          fi
          [[ "$vm_guest" != "none" ]] && echo "    vmGuest = \"$vm_guest\";"
          [[ "$has_fp" == true ]] && echo "    fingerprint = true;"
          [[ "$broadcom_wifi" == true ]] && echo "    broadcomWifi = true;"
          (( panel_dpi > 0 )) && echo "    panelDpi = $panel_dpi;"
          cat <<EOF
            hasBluetooth = $has_bt;
            cpuVendor = "$cpu_vendor";
            chassis = "$chassis";
          };
        }
        EOF
        }

        if [[ -n "$outdir" ]]; then
          mkdir -p "$outdir"
          gen > "$outdir/golem-hardware.nix"
          echo "wrote $outdir/golem-hardware.nix (ramMB=$ram_mb cores=$cores gpu=$gpu)" >&2
          # The rest of the machine's hardware (filesystems, kernel modules,
          # microcode) is nixos-generate-config's job — the installer folds
          # both files into the flake it builds.
          nixos-generate-config --no-filesystems --dir "$outdir" 2>/dev/null \
            && echo "wrote $outdir/hardware-configuration.nix" >&2 \
            || echo "note: nixos-generate-config skipped (needs root / a target root)" >&2
        else
          gen
        fi
      '';
    })
  ];
}
