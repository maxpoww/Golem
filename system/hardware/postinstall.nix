# Post-install ASK questions — what Golem defers to the owner because it
# cannot decide honestly before a desktop exists (postinstall/postinstall.md,
# changes.md #33's home).
#
# FACTS IN, QUESTION LIST OUT — the same one-rule shape decide.nix uses for
# decisions (and the same mkTarget evaluation, for the same reason: read the
# DEFAULTED facts off the evaluated config rather than trusting only the
# keys the probe happened to emit), kept as a SEPARATE file because a
# question's trigger is a fact condition whose ANSWER is deliberately not
# decided here — that is the whole point of deferring it.
# golem-postinstall-questions (Installer/preinstall/postinstall-questions.nix) calls
# this at install time with the probe's freshly written golem-hardware.nix;
# golem-install drops the result into hosts/target/postinstall-questions.json
# — the fourth dropped file, alongside golem-hardware.nix/
# hardware-configuration.nix/machine.nix. The installed system's
# golem-postinstall-ask (system/postinstall.nix) reads it back after first
# login.
#
# A question's `id` is the ONLY thing that ties it to an answer — see
# system/postinstall.nix's golem.postinstall.answers (a plain id → chosen
# option id map) and whatever module consumes that id (gpu-second.nix for
# "gpu2-failing-action"). Adding a question here and a read of
# `config.golem.postinstall.answers.<id> or <default>` in the consuming
# module is the ENTIRE cost of a new question — no other file changes,
# which is what "a small framework, not a one-off" (changes.md #33) means
# in practice.
{ lib, mkTarget }:

# factsModule: the probe's golem-hardware.nix, imported (or an attrset) —
# same shape decide.nix takes.
factsModule:

let
  # What the install flow WILL create — copied from decide.nix rather than
  # shared, on purpose: this file has no other reason to know about disks,
  # and the shape is five lines that never change independently of the
  # partition scheme decide.nix already documents.
  plannedDisk = {
    nixpkgs.hostPlatform = "x86_64-linux";
    fileSystems."/" = { device = "/dev/disk/by-label/golem"; fsType = "ext4"; };
    fileSystems."/boot" = { device = "/dev/disk/by-label/ESP"; fsType = "vfat"; };
    swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];
  };

  facts = (mkTarget [ plannedDisk factsModule ]).config.golem.hardware;
in
lib.flatten [
  # #33 — a second GPU that failed the boot audit's force-cold wake test
  # (gpu2Health == "failing") is NOT necessarily unable to do work; it only
  # failed to survive being put to sleep and woken back up. gpu-second.nix
  # holds it available-but-fault-free (power/control=on, never autosuspend)
  # until this question is answered — see that file for the holding state,
  # and postinstall/postinstall.md §5 for the full case history (Max: "that
  # is not possible, the 720m works").
  (lib.optional
    (facts.gpu2Health == "failing" && facts.gpu2BusAddr != null)
    {
      id = "gpu2-failing-action";
      title = "Your second GPU didn't wake up during setup";
      body = ''
        Golem tested your second graphics card (${facts.gpu2}) by putting
        it to sleep and waking it back up during setup, and it did not
        wake up cleanly. That does not necessarily mean it cannot do
        work — only that it cannot be trusted to sleep.

        For now Golem is keeping it available and simply never letting it
        sleep, so it costs a little battery but stays usable. Now that you
        are on your real desktop, you are in a much better position to
        judge this than the installer was.
      '';
      options = [
        { id = "hold"; label = "Keep it available (uses a little more power)"; }
        { id = "off"; label = "Turn it off (saves battery, GPU unavailable)"; }
      ];
      # What happens if this is never answered — matches gpu-second.nix's
      # own fallback for an unrecognized/missing answer, spelled out here
      # so the two cannot silently drift apart.
      default = "hold";
    })
]
