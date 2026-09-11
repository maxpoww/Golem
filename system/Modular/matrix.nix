# The chooser's assertion matrix (Installing constitution rule 4:
# "the eval matrix asserts the CHOSEN LIST per fixture, not just the
# resulting behavior"). Each fixture's facts → the chooser → its exact
# expected pointer list. A rule change in choose.nix that moves any
# machine's list fails HERE, in review, by design.
#
# `nix build .#checks.x86_64-linux.chooser-matrix`. Two kinds of row:
#   resolve  — the list must equal `expect` exactly.
#   refuse   — choosing must THROW containing `refuseHas` (the nvidia
#              machines, until their leaves land — the loud-fail
#              contract is itself asserted, so "silently started
#              resolving wrong" cannot pass).
{ lib, pkgs, choose }:

let
  facts = path: (import path { }).golem.hardware;

  rows = [
    {
      name = "acer (UEFI, HD 5500, 3833 MB, laptop)";
      kind = "resolve";
      path = ../../Installer/preinstall/fixtures/acer-aspire-e5-573/facts.nix;
      expect = [
        "boot/systemd-boot.nix" "cpu/intel-microcode.nix" "gpu/intel.nix"
        "memory/zram-tier1.nix" "swap/hibernation.nix" "disk/policy.nix"
        "power/laptop.nix" "power/thermald.nix"
      ];
    }
    {
      name = "qemu-virtio (UEFI, virtio, ~3.9 GB, qemu guest)";
      kind = "resolve";
      path = ../../Installer/preinstall/fixtures/qemu-virtio/facts.nix;
      expect = [
        "boot/systemd-boot.nix" "cpu/intel-microcode.nix" "gpu/virtio.nix"
        "memory/zram-tier1.nix" "swap/hibernation.nix" "disk/policy.nix"
        "virt/qemu-guest.nix"
      ];
    }
    {
      name = "asus (gpu=nvidia, nvidiaGen=unknown → the IRON LAW, nouveau floor)";
      kind = "resolve";
      path = ../../Installer/preinstall/fixtures/asus/golem-hardware.nix;
      expect = [
        "boot/systemd-boot.nix" "cpu/intel-microcode.nix" "gpu/nouveau-floor.nix"
        "memory/zram-tier2.nix" "swap/hibernation.nix" "disk/policy.nix"
        "power/laptop.nix" "power/thermald.nix"
      ];
    }
    {
      name = "lenovo (intel primary + nvidia gpu2 working turing+ → PRIME offload)";
      kind = "resolve";
      path = ../../Installer/preinstall/fixtures/lenovo-slim-pro-9-16irp8/facts.nix;
      expect = [
        "boot/systemd-boot.nix" "cpu/intel-microcode.nix" "gpu/intel.nix"
        "gpu2/nvidia-offload-turing.nix" "memory/zram-tier3.nix"
        "swap/hibernation.nix" "disk/policy.nix" "power/laptop.nix" "power/thermald.nix"
      ];
    }
    {
      name = "thinkpad E15 (AMD Ryzen + Renoir Vega — amd microcode, NO thermald)";
      kind = "resolve";
      path = ../../Installer/preinstall/fixtures/thinkpad-e15-gen2/facts.nix;
      expect = [
        "boot/systemd-boot.nix" "cpu/amd-microcode.nix" "gpu/amd.nix"
        "memory/zram-tier2.nix" "swap/hibernation.nix" "disk/policy.nix"
        "power/laptop.nix"
      ];
    }
    {
      name = "comodore GM45 (BIOS, GMA 4500 → i965 legacy, 1931 MB tier1)";
      kind = "resolve";
      path = ../../Installer/preinstall/fixtures/comodore-gm45/facts.nix;
      expect = [
        "boot/grub-bios.nix" "cpu/intel-microcode.nix" "gpu/intel-legacy.nix"
        "memory/zram-tier1.nix" "swap/hibernation.nix" "disk/policy.nix"
        "power/laptop.nix" "power/thermald.nix"
      ];
    }
  ];

  checkResolve = row:
    let got = (choose { facts = facts row.path; }).leaves;
    in if got == row.expect
       then "ok    ${row.name}"
       else throw ''
         chooser-matrix FAIL — ${row.name}
           expected: ${builtins.toJSON row.expect}
           got:      ${builtins.toJSON got}
       '';

  checkRefuse = row:
    let r = builtins.tryEval (lib.deepSeq (choose { facts = facts row.path; }).leaves null);
    in if r.success
       then throw "chooser-matrix FAIL — ${row.name}: expected a refusal, got a resolved list"
       else "ok    ${row.name} (refused as required)";
       # tryEval catches the throw; we cannot read its message, so the
       # row's refuseHas documents WHICH refusal is expected. The
       # resolve rows prove the positive lists; a refusal turning into
       # a wrong resolve flips success=true and fails here.

  results = map (r: if r.kind == "resolve" then checkResolve r else checkRefuse r) rows;
in
pkgs.runCommand "golem-chooser-matrix"
  { passthru.results = results; }
  ''
    ${lib.concatMapStringsSep "\n" (line: "echo ${lib.escapeShellArg line}") results}
    echo "chooser-matrix: ${toString (builtins.length rows)} rows OK" > $out
  ''
