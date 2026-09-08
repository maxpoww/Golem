# What Golem audits, and what it decides

The census in one page. Facts come from `../system/hardware-detect.nix`;
the decisions come from the modules in `../system/hardware/`, and every
one of them is asserted in the eval matrix
(`..#checks.x86_64-linux.facts-matrix`).

MiniGolem runs all of this by itself at boot — `audit.nix` — and leaves
the result in `/var/log/golem-audit/summary.txt`.

## 1. What Golem measures (14 facts)

| Fact | Read from |
|---|---|
| `cpuModel` | `/proc/cpuinfo` model name (names the machine in the report) |
| `cores` | distinct `physical id`:`core id` pairs — **physical** cores |
| `threads` | `nproc` — logical CPUs |
| `ramMB` | `/proc/meminfo` MemTotal |
| `gpu` | PCI vendor of each DRM card — nvidia > amd > intel > virtio |
| `intelLegacy` | Intel PCI device id `< 0x1600` (pre-Broadwell) |
| `nvidiaGen` | nvidia device id: `≥0x1e00` turing+, `≥0x1340` pre-turing, else **unknown** |
| `nvidiaBusId` + `intelBusId` | PCI slots — only when *both* GPUs exist (hybrid laptop) |
| `hasBluetooth` | 3 ways, any one convicts: sysfs class ∨ rfkill ∨ USB class `e0` |
| `cpuVendor` | `/proc/cpuinfo` vendor_id |
| `chassis` | DMI chassis_type, battery presence as fallback |
| `vmGuest` | DMI sys_vendor / product_name |
| `fingerprint` | USB vendor id `138a` / `06cb` / `27c6` |
| `panelDpi` | eDP EDID physical width vs native mode |

## 2. What it decides, and from what

| Decision | Based on |
|---|---|
| zram size, swappiness, cache pressure, dirty ratios, page-cluster | `ramMB` (4 tiers) |
| nix `max-jobs` / `cores` | `ramMB` — 1 job on tight RAM so rebuilds don't freeze |
| hibernation swap size | `ramMB` → RAM + 10% (2 GiB floor) |
| resume device + lid → suspend-then-hibernate | swap exists **and** `chassis = laptop` |
| video driver, open kmod, driver branch, PRIME offload | `gpu` + `nvidiaGen` + both bus ids |
| VA-API driver (`iHD` vs `i965`) | `intelLegacy` |
| CPU microcode | `cpuVendor` |
| bluez + blueman | `hasBluetooth` |
| upower + power-profiles-daemon | `chassis = laptop` |
| thermald | `chassis = laptop` **and** `cpuVendor = intel` |
| guest tools (qemu/vmware/vbox/hyperv) | `vmGuest` |
| fprintd | `fingerprint` |
| Hyprland eDP scale | `panelDpi` |

## 3. Deliberately *not* fact-driven

- **BFQ scheduler** — a udev rule on `queue/rotational`, so it follows the
  actual disk and catches hotplugged ones.
- **fstrim** — on everywhere; silently skips devices without discard.

Gating these on install-time facts would only add test permutations and
miss disks plugged in later (the anti-over-gating rule, spec §5).

## The rule that governs all of it

**Uncertain detection lands on the safe stack.** `nvidiaGen = "unknown"` →
no proprietary driver, stay on nouveau/modesetting. `hasBluetooth`
defaults to *true* — a machine we cannot read keeps bluez rather than
losing its radio. `ramMB = 0` → exactly the pre-module defaults.

A stranger's first boot must never be a black screen.
