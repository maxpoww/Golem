# Method — how the OPTIONS work is run

*What [constitution.md](constitution.md) demands, this file organizes.
Nothing here is a design law: the pillars own what OPTIONS is, and
[UXRules.md](UXRules.md) owns how an OPTION behaves. These are the work
disciplines — what counts as proof, what earns a module, what we refuse
to do even when it would be quicker.*

**Provenance is marked.** *(agreed)* = settled in Max's words somewhere
in the record, with the citation. **[PROPOSED]** = a rule the work has
visibly been following that nobody has said out loud; it holds until Max
strikes it, and it should be struck or confirmed rather than left open.
*(pillar N)* = a direct consequence of the constitution, carrying its
authority.

---

## 1. The Brain is the only sense *(pillar 2; DoD line 4)*

A module perceives through a collector in `options-engine` and is driven
by the Mind's `OptionSet`. It does not poll the compositor itself, read
`/sys` itself, or keep a private copy of a fact the engine already holds.

Two readings of the world drift, and the drift is invisible until a user
sees a pill that disagrees with their screen. It also makes the Mind
unable to rank, damp, cap or fade an offer it does not know exists — so
a self-sensing surface is permanently exempt from pillar 3 and pillar 4
by accident.

**A degrade path is allowed; a second brain is not.** window-pills keeps
its `hyprctl` poll *only* for when the compositor layer is dark. Plumbing
that runs in parallel with the Brain on the normal path is a finding.

## 2. Conduct outranks the feature *(agreed — UXRules, all six laws agreed 2026-09-04)*

A module that breaks a UX law is not shipped and then fixed; it is not
shipped. The gate is the twelve-line definition of done in
[modules.md](modules.md), all twelve lines — **and above it the
acceptance test**, which an OPTION can fail while passing all twelve:
does the user feel clever, or directed?

This is the law most quietly broken, because DoD lines 1–5 are things you
*build* and lines 6–12 are things you *check*. Building feels like
progress; checking feels like delay. The bar only reads as one object if
every module paid the whole price.

## 3. The tempo lives in one file *(agreed — UXRules §3)*

One rate, one settle threshold, one leave-hold, in `animation.rs`,
imported. A module-local rate constant is a defect **while it is still
equal** — it is equal only until someone tunes one of them. The audit
that produced §3 found six modules that had independently declared the
same number, which is exactly the state that reads as fine until module
twelve picks its own.

## 4. Proven means seen *(agreed — DoD line 5)*

An offer is real when it has been **sensed → surfaced → triggered → the
effect observed**, with a screenshot. Not "the provider returns the
affordance", not "the unit test is green". The catalog already writes in
this vocabulary and must keep doing it: *CONFIRMED live*, *engine-tested*
and *SUSPECTED* are different words on purpose.

**The two proving grounds are different instruments** and neither
replaces the other **[PROPOSED]**:

- **The golem-vm** is where a slice is *validated* — batched, screenshot,
  repeatable. All 45 catalog slices were proven here.
- **Real machines** are where the surface is *lived in* — Max's dev box
  daily, the ASUS, the 2013 Air. This is where the findings the VM cannot
  produce come from, and `settle.rs` is the proof: the flapping bar that
  produced the appear-dwell was seen on the Air, watching a video, with
  `follow_mouse = 2` rewriting the OptionSet every one to three seconds.
  No VM session would have found it.

So: validate in the VM, but a *law* about how the bar feels is only ever
earned in a chair. And the slowest hardware still owes us its verdict —
a 5400rpm Haswell with the GL fallback renderer has never run this.

## 5. A blocked signal is documented, never faked *(pillar 2)* **[PROPOSED]**

Where the signal is genuinely absent, the answer is a written
investigation and an honest absence — never a heuristic in a sensor's
clothes. The record does this twice and both are the model: file-manager
selection (catalog §6, investigated, no clean signal) and the browser
active-tab URL (§8 — an extension needs a store upload, CDP is a local
security exposure, so neither is taken).

Where a *weaker* inference is worth having, it ships labelled as one: the
reading-mode heuristic reads the window title, is documented as a
fallback, and uses strong markers only, so a false positive merely adds
harmless offers.

## 6. Local-only is what makes pillar 2 permissible *(agreed — ACTIONS constitution §VI.1)*

`options-engine` has no network dependency and must never acquire one —
auditable in `Cargo.toml` in ten seconds. Gestures, not content: the
Brain may know *that* you do a thing, never *what* the thing contained.
Detectors live on counters and medians, not timestamped diaries.

The framing matters. Pillar 2 asks the system to read everything you do,
which is only acceptable because nothing can leave the machine. **"Can't"
beats "doesn't"** — the architecture is the policy. The day a crate lands
that could reach the network, pillar 2 stops being a design and becomes a
promise, which is a weaker thing.

## 7. A module grows when a use demands it *(pillar 3)* **[PROPOSED]**

Speculative modules rot. The roster in [modules.md](modules.md) is a list
of *candidates*, not a backlog owed to anyone; a name leaves it when a
real context makes it the obviously right thing to surface. keyboard,
language and timezone are the shape this takes when it works — surfaces
over settled, CI-enforced data, not research.

## 8. Findings continue the one number line *(agreed — Installing constitution §9, DockMenu FINDINGS.md)*

#1–#61 in the preinstall archive and DockMenu's FINDINGS.md, #62–#67
Installing's, this program from **#68** in [changes.md](changes.md). One
sequence across the lab, so a finding can be named in one syllable in any
room.

## 9. Suspect the harness first *(agreed — Installing constitution §7)*

The VM is a virtio GPU on a fast host; the dev box is an i9 with Vulkan.
The machines this ships to are Haswell on spinning rust with the GL
fallback. Before jank becomes a finding against a module, rule out the
rig — renderer path, VM compositing, a screenshot tool that changed the
frame it measured.

## 10. Honesty clauses, inherited whole *(agreed — Installing constitution §10)*

The surface says only true things. A pill that offers an action can
perform it; a state shown matches what is on screen (§5); an offer whose
way back is stale withdraws rather than lying about what it undoes (§4).
Success without verification is the failure this lab exists to prevent.

---

## Working agreements

**Max is the idea guy** — scope, admission calls, which proposed rules
stand and which are struck, when a module has earned its way off the
roster. The technician builds what is agreed, records numbers rather than
adjectives, and never lets a pass go unrecorded.

## The loop

[../GRIND.md](../../../work/GRIND.md) is the mandate an autonomous session resumes
from: take the top unfinished item, build it completely (sensed → pill →
the action performs), validate 3–4 items per batched VM session with a
screenshot, `cargo test --workspace` green, commit locally, tick the item
with its hash, update [catalog.md](catalog.md) if it is a slice, take the
next. A defect or a debt goes to [changes.md](changes.md) with a number —
not into a commit message where it dies.

Waverunner-side fixes ride the launcher → Golem lock → seed pipeline
(#41): a fix is not real on a machine until the seed carries it.
