# THE CHOOSER — the only brain in the Modular world (Installing spec).
#
# Pure nix, no nixpkgs: `import ./choose.nix { facts = {…}; }` where
# facts is the golem.hardware attrset (a fixture's, or the census's:
# `(import golem-hardware.nix { }).golem.hardware`). Returns:
#
#   pointers  [ { group; leaf; why; } … ]   the chosen leaves, in order
#   skipped   [ { group; why; } … ]         groups honestly left empty
#   rendered  the hosts/target/modules.nix text
#
# CONTRACTS (spec.md): total — every group resolves or records its ∅;
# an unmatchable machine THROWS with the fact that stumped it (a loud
# fail at choose time beats a silent wrong default at boot). Explained
# — every pointer carries its why, and the why is written into the
# rendered file. Asserted — flake checks pin every lab fixture to its
# exact pointer list; changing a rule here moves a list there, visibly.
#
# Relocated logic, not new logic: every rule below is the mkIf/formula
# it replaces, from configuration.nix (bootloader), hardware.nix
# (microcode, GPU), hardware/memory.nix (the tiers),
# hardware/power-laptop.nix (chassis+thermald), hardware/virt-guest.nix.
{ facts }:

let
  f = {
    ramMB = facts.ramMB or 0;
    gpu = facts.gpu or "auto";
    intelLegacy = facts.intelLegacy or false;
    gpu2 = facts.gpu2 or "none";
    gpu2Health = facts.gpu2Health or "unknown";
    cpuVendor = facts.cpuVendor or "unknown";
    firmware = facts.firmware or "uefi";
    broadcomWifi = facts.broadcomWifi or false;
    chassis = facts.chassis or "unknown";
    vmGuest = facts.vmGuest or "none";
  };

  refuse = group: why:
    throw "golem-hw-choose: no ${group} leaf matches this machine (${why}) — write the leaf, then point at it";

  # ── the rules, one group at a time ─────────────────────────────────
  boot =
    if f.firmware == "bios"
    then { group = "boot"; leaf = "boot/grub-bios.nix"; why = "firmware=bios"; }
    else { group = "boot"; leaf = "boot/systemd-boot.nix"; why = "firmware=uefi"; };

  cpu =
    if f.cpuVendor == "intel"
    then [ { group = "cpu"; leaf = "cpu/intel-microcode.nix"; why = "cpuVendor=intel"; } ]
    else if f.cpuVendor == "amd"
    then [ { group = "cpu"; leaf = "cpu/amd-microcode.nix"; why = "cpuVendor=amd"; } ]
    else [ ];
  cpuSkip =
    if cpu == [ ]
    then [ { group = "cpu"; why = "cpuVendor=unknown — no microcode without a vendor"; } ]
    else [ ];

  gpu =
    if f.gpu == "intel" && f.intelLegacy
    then { group = "gpu"; leaf = "gpu/intel-legacy.nix"; why = "gpu=intel, intelLegacy (pre-Skylake → i965)"; }
    else if f.gpu == "intel"
    then { group = "gpu"; leaf = "gpu/intel.nix"; why = "gpu=intel (Broadwell+ → iHD)"; }
    else if f.gpu == "amd"
    then { group = "gpu"; leaf = "gpu/amd.nix"; why = "gpu=amd"; }
    else if f.gpu == "virtio"
    then { group = "gpu"; leaf = "gpu/virtio.nix"; why = "gpu=virtio"; }
    else if f.gpu == "auto"
    then { group = "gpu"; leaf = "gpu/auto.nix"; why = "gpu=auto — vendor unknown, ship every VA driver"; }
    else refuse "gpu" "gpu=${f.gpu} — the nvidia leaves land when an nvidia machine enters the Installing rounds";

  gpu2 =
    if f.gpu2 == "none"
    then [ ]
    else refuse "gpu2" "gpu2=${f.gpu2}/${f.gpu2Health} — the gpu2 leaves (hold/off/offload) land when the hp enters";
  gpu2Skip =
    if f.gpu2 == "none"
    then [ { group = "gpu2"; why = "gpu2=none — single-GPU machine"; } ]
    else [ ];

  memory =
    if f.ramMB == 0
    then { group = "memory"; leaf = "memory/zram-tier0.nix"; why = "ramMB unknown — conservative baseline"; }
    else if f.ramMB < 6144
    then { group = "memory"; leaf = "memory/zram-tier1.nix"; why = "ramMB=${toString f.ramMB} < 6144"; }
    else if f.ramMB <= 16384
    then { group = "memory"; leaf = "memory/zram-tier2.nix"; why = "ramMB=${toString f.ramMB} in 6144..16384"; }
    else { group = "memory"; leaf = "memory/zram-tier3.nix"; why = "ramMB=${toString f.ramMB} > 16384"; };

  swap = { group = "swap"; leaf = "swap/hibernation.nix"; why = "hibernation is a locked decision"; };
  disk = { group = "disk"; leaf = "disk/policy.nix"; why = "runtime per-device rule — the one always-leaf"; };

  power =
    if f.chassis == "laptop"
    then [ { group = "power"; leaf = "power/laptop.nix"; why = "chassis=laptop"; } ]
      ++ (if f.cpuVendor == "intel"
          then [ { group = "power"; leaf = "power/thermald.nix"; why = "chassis=laptop + cpuVendor=intel"; } ]
          else [ ])
    else [ ];
  powerSkip =
    if power == [ ]
    then [ { group = "power"; why = "chassis=${f.chassis} — battery plumbing gains a desktop nothing"; } ]
    else [ ];

  virt =
    if f.vmGuest == "qemu"
    then [ { group = "virt"; leaf = "virt/qemu-guest.nix"; why = "vmGuest=qemu"; } ]
    else if f.vmGuest == "none"
    then [ ]
    else refuse "virt" "vmGuest=${f.vmGuest} — that hypervisor's leaf lands when its machine enters";
  virtSkip =
    if f.vmGuest == "none"
    then [ { group = "virt"; why = "vmGuest=none — physical machine"; } ]
    else [ ];

  quirks =
    if f.broadcomWifi
    then refuse "quirks" "broadcomWifi — the broadcom-wl leaf lands with the macbook"
    else [ ];
  quirksSkip =
    [ { group = "quirks"; why = "no quirks demanded"; } ];

  pointers =
    [ boot ] ++ cpu ++ [ gpu ] ++ gpu2 ++ [ memory swap disk ]
    ++ power ++ virt ++ quirks;

  skipped = cpuSkip ++ gpu2Skip ++ powerSkip ++ virtSkip ++ quirksSkip;

  renderPointer = p:
    "    # ${p.why}\n    ../../system/Modular/${p.leaf}";
  renderSkip = s: "${s.group} (${s.why})";

  rendered = ''
    # hosts/target/modules.nix — written by golem-hw-choose. THE MACHINE:
    # every import below is a leaf the census pointed at, each with its
    # why. Change it by re-choosing (or by an owner's deliberate edit) —
    # the eval matrix pins the lab machines' lists, so drift is visible.
    { ... }:
    {
      imports = [
    ${builtins.concatStringsSep "\n" (map renderPointer pointers)}
      ];
      # not chosen: ${builtins.concatStringsSep " · " (map renderSkip skipped)}
    }
  '';
in
{
  inherit pointers skipped rendered;
  # The bare leaf list — what the matrix assertions compare.
  leaves = map (p: p.leaf) pointers;
}
