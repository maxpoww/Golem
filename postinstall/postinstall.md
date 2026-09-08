# PostInstall — questions the owner answers on the real machine, as a spec

> Design doc for a new subsystem. Written 2026-09-08 at Max's direction
> ("can we keep it all and then ask the user on the post installation?"),
> prompted by the ASUS's fault-on-resume dGPU (changes.md #33). Companion
> to `GolemInstall.md` (what the installer decides) and `GolemModules.md`
> (what the owner adds later); this is the third case — what the installer
> deliberately REFUSES to decide, and hands to the owner instead.
>
> Status: SPEC. Nothing below is built. First real case is #33. Target:
> round 5.

## 1. The idea

Some decisions cannot be made honestly at install time. The installer
runs in a console, offline, before there is a desktop — it can PROBE
hardware but it cannot let the owner *see* the result and judge it. For
most things that is fine: the census measures a fact, Golem picks the
safe config, done. But a few decisions are genuinely the owner's, and
only answerable once they are sitting in their real session:

- a discrete GPU that fails a suspend/resume wake-test but very likely
  works while awake — keep it (costs battery) or power it off? (#33)
- …and, in time, others: an ambiguous external display, a dual-boot
  clock offset, a "this laptop runs hot, cap the CPU?" — the class is
  "Golem could guess, but the owner can just LOOK."

The rule Golem already lives by (surface honestly, let the owner decide)
extended past first boot: **when the install can't decide something
truthfully, it doesn't guess silently and it doesn't nag — it leaves the
machine in a safe holding state and asks ONE clear question the first
time the owner is in a position to answer it.**

## 2. The one rule

**A post-install question is asked once, answered once, and remembered.**
Not a recurring nag, not a settings panel the owner has to go find — a
single prompt the first time it is relevant, with a safe default already
in force so ignoring it costs nothing. Answering it writes the choice
into the machine's own config (the flake) and it never asks again.

## 3. Shape of a question

Each post-install question is a small record with four parts, mirroring
how the hardware module library keys on facts:

- **trigger** — a fact from the install/audit that says this question
  applies to THIS machine (e.g. `gpu2Health == "failing"` with a
  gpu2 present). No trigger, no question — a machine it does not apply
  to never sees it.
- **holding state** — what Golem does in the meantime, chosen so that
  NOT answering is safe and non-destructive. For #33: the dGPU is held
  usable-but-fault-free (runtime PM forced off), not powered off.
- **prompt** — plain language, the observation and the trade, never a
  hardware judgement. For #33: "your second GPU (NVIDIA GT 720M) failed
  a sleep/wake test during setup. Keep it available (uses more power) or
  power it off (saves battery)?"
- **apply** — what each answer writes into the flake, and the rebuild
  that makes it real.

## 4. Where it lives (sketch — decide at build time)

The install already writes `hosts/target/` (facts, machine.nix). A
post-install question set is a fifth thing the install can leave behind:
the list of questions this machine triggered, unanswered. Then on the
installed system, a first-desktop-login surface (greetd → Hyprland →
waverunner is the stack; the exact host — a greeter card, a first-run
waverunner panel, or a one-shot notification — is an open UX call)
reads that list, asks each, applies the answers, and clears the list.

Cross-refs to settle when building:
- the **holding state** is set by the same modules that would have made
  the final decision (#33: `system/hardware/gpu-second.nix`).
- the **apply** path is a rebuild, same machinery as GolemModules and
  waverunner-apply — reuse it, don't invent a second one.

## 5. First case — #33, the fault-on-resume dGPU

The whole subsystem exists because of one concrete machine (the ASUS
X550LC, GF117M "GT 720M"): the force-cold health probe correctly reads
it `failing` — it throws PRIVRING faults on autosuspend→resume — but
Max: "that is not possible, the 720M works." Both true: "failing" is a
wake-test result, not "cannot do work." The installer must not throw the
GPU away over that.

- **trigger:** `golem.hardware.gpu2Health == "failing"` and a
  `gpu2BusAddr` present.
- **holding state:** dGPU kept available, runtime PM forced off
  (`power/control = on`) so it never hits the resume fault — replaces
  gpu-second.nix's current unconditional power-off for `failing`.
- **prompt:** keep available (power) vs power off (battery).
- **apply:** the answer sets whether gpu-second.nix powers it off or
  holds it PM-forced-on, then rebuilds.
- **note:** whether the 720M's offload actually WORKS could not be
  confirmed in the lab (console-only, no compositor/GL/Vulkan; nouveau
  has no Vulkan below Turing). The owner's real desktop is exactly the
  place that question gets answered — which is the whole point of
  deferring it.

## 6. Not in scope (yet)

The catalog of future questions, the exact first-boot host surface, and
the persisted-answer format are all open. This doc is the concept and
the first case; the framework gets designed for real when round 5 builds
#33.
