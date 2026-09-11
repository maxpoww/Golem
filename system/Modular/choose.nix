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
    nvidiaGen = facts.nvidiaGen or "unknown";
    gpu2 = facts.gpu2 or "none";
    gpu2Health = facts.gpu2Health or "unknown";
    cpuVendor = facts.cpuVendor or "unknown";
    firmware = facts.firmware or "uefi";
    broadcomWifi = facts.broadcomWifi or false;
    fingerprint = facts.fingerprint or false;
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
    # PRIMARY nvidia (boot_vga nvidia: a desktop or a muxed laptop),
    # branched on the generation the census classified.
    else if f.gpu == "nvidia" && f.nvidiaGen == "turing+"
    then { group = "gpu"; leaf = "gpu/nvidia-turing.nix"; why = "gpu=nvidia, nvidiaGen=turing+ (open module)"; }
    else if f.gpu == "nvidia" && f.nvidiaGen == "pre-turing"
    then { group = "gpu"; leaf = "gpu/nvidia-preturing.nix"; why = "gpu=nvidia, nvidiaGen=pre-turing (legacy_580)"; }
    else if f.gpu == "nvidia"
    then { group = "gpu"; leaf = "gpu/nouveau-floor.nix"; why = "gpu=nvidia, nvidiaGen=unknown — THE IRON LAW (nouveau floor)"; }
    else refuse "gpu" "gpu=${f.gpu} — unrecognized primary GPU vendor";

  # The SECOND GPU on a hybrid machine. Failing (any vendor) → the #33
  # hold/off leaf; a working nvidia → PRIME offload by generation; a
  # working amd → mesa handles it; unknown health → nothing (verdict
  # discipline, #17).
  gpu2 =
    if f.gpu2 == "none"
    then [ ]
    else if f.gpu2Health == "failing"
    then [ { group = "gpu2"; leaf = "gpu2/failing.nix"; why = "gpu2=${f.gpu2}, gpu2Health=failing (#33 hold/off)"; } ]
    else if f.gpu2 == "nvidia" && f.gpu2Health == "working" && f.nvidiaGen == "turing+"
    then [ { group = "gpu2"; leaf = "gpu2/nvidia-offload-turing.nix"; why = "gpu2=nvidia working, turing+ (PRIME offload)"; } ]
    else if f.gpu2 == "nvidia" && f.gpu2Health == "working" && f.nvidiaGen == "pre-turing"
    then [ { group = "gpu2"; leaf = "gpu2/nvidia-offload-preturing.nix"; why = "gpu2=nvidia working, pre-turing (PRIME offload)"; } ]
    else if f.gpu2 == "amd" && f.gpu2Health == "working"
    then [ { group = "gpu2"; leaf = "gpu2/amd-offload.nix"; why = "gpu2=amd working (mesa handles offload)"; } ]
    else [ ];  # working nvidia of unknown gen (iron law → no offload driver), or unknown health
  gpu2Skip =
    if f.gpu2 == "none"
    then [ { group = "gpu2"; why = "gpu2=none — single-GPU machine"; } ]
    else if gpu2 == [ ]
    then [ { group = "gpu2"; why = "gpu2=${f.gpu2}/${f.gpu2Health}, nvidiaGen=${f.nvidiaGen} — no offload driver (iron law / verdict discipline)"; } ]
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

  # Quirks are ADDITIVE (a machine can have several, or none) — each is
  # its own independent check, not a one-of group.
  quirks =
    (if f.broadcomWifi
     then [ { group = "quirks"; leaf = "quirks/broadcom-wl.nix"; why = "broadcomWifi (BCM4360 → the unfree wl driver)"; } ]
     else [ ])
    ++ (if f.fingerprint
        then [ { group = "quirks"; leaf = "quirks/fingerprint.nix"; why = "fingerprint reader present → fprintd"; } ]
        else [ ]);
  quirksSkip =
    if quirks == [ ]
    then [ { group = "quirks"; why = "no quirks demanded"; } ]
    else [ ];

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
