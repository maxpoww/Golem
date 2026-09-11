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
      name = "asus (nvidia hybrid — must REFUSE until nvidia leaves land)";
      kind = "refuse";
      path = ../../Installer/preinstall/fixtures/asus/golem-hardware.nix;
      refuseHas = "no gpu leaf matches";
    }
    {
      name = "lenovo (nvidia gpu2 working — must REFUSE until gpu2 leaves land)";
      kind = "refuse";
      path = ../../Installer/preinstall/fixtures/lenovo-slim-pro-9-16irp8/facts.nix;
      refuseHas = "no gpu2 leaf matches";
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
