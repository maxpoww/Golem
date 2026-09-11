# The Installing constitution

The preinstall constitution's heirs, adjusted for the one thing that
changed: **disks get written now.** When these rules and convenience
disagree, these rules win.

## 1. No disk is touched without its blessing

An install erases a disk. Max blesses machines one at a time, by name,
knowing what is on the disk ("wipe it" — the ASUS precedent). A
blessing covers ONE machine forever, not a class, not a session. The
VM's qcow2s are pre-blessed by nature. Everything unblessed keeps the
full preinstall guarantee: writes-completed = 0, UUIDs identical,
proven in the record.

## 2. One frozen ISO per round — and the round runs the WHOLE roster

No ISO change lands mid-round; every machine in a round meets the same
image. **A round is not finished until every machine on the roster has
had its turn with that ISO** (installed, or explicitly deferred with a
recorded reason — e.g. no blessing, or hardware blocking it). Partial
rounds do not close, and no new work (next ISO, next stage, new
features) starts ahead of the remaining machines — that ordering is
what makes the rounds mean anything. (Written plainly 2026-09-11 after
the technician drifted toward the offline installer with hp, thinkpad
and macbook untouched — Max caught it.) A fix a machine teaches goes
to [changes.md](changes.md), not into a reburn. When the round closes: work the queue top to bottom,
`nix flake update` (the locked-path-input rule — a cut without it
ships a stale seed), rebuild, **verify the built artifact carries the
round's markers**, VM-gate, then reflash. The live-fix refinement
survives: a queued fix may be nix-copied onto a machine to verify on
metal, marked as such — the stick stays frozen.

## 3. The VM gates every ISO, and every FIRST

Machine zero goes first — for images and for firsts. No branch (BIOS,
LUKS, a new stage, a new module class) meets metal before the VM has
run it end to end. The rounds 4/5 gate-record gap is not repeated: no
gate without its vm.md entry.

## 4. Modules are dumb, the chooser is the only brain

A module is a leaf: concrete values, zero conditionals, its own
parameters stated in its header. All logic lives in the chooser, whose
output — `hosts/target/modules.nix` — is the machine's identity. A
formula creeping into a leaf is a finding. The eval matrix asserts the
CHOSEN LIST per fixture, not just the resulting behavior: a wrongly
omitted module is worse than a wrongly dormant one ever was.

## 5. Stages climb by rebuild, never by reinstall

Stage 0 must leave every machine reachable (SSH), rebuildable (seed +
appliers), and recognizable (Golem's zsh at the tty). Stage 1 and 2
arrive as module additions applied by rebuild on a proven rung. A
machine that needs reinstalling to advance is a finding against
stage 0.

## 6. First boot is audited, always, the same way

Hostname · root device · `is-system-running` · zero failed units ·
memory tier vs RAM · `resume=` wired · owner uid/profile · appliers
active · the seed's lock pinning the intended waverunner · the seal's
state — then the DockMenu harness (`aging-check.sh`, `state-census.sh`
before/after every session). A pass is recorded with its numbers; "it
booted" is not a record.

## 7. Suspect the harness first

Unchanged, and paid for again during round 5: root SSH creating
`user@0`, store paths picked by glob, a flaky router convicting three
machines, a phone's randomized MAC. Rule out the rig before blaming
Golem — and drive installed machines from the owner's session, never
leave a root SSH holding a switch.

## 8. Record passes too — and the human hour

Every install entry records what WORKED with numbers (install minutes,
closure size, first-boot seconds, eval times). After stage 1, every
machine gets a human hour in the chair before its round closes — the
first install proved the chair catches what the harness cannot (#43,
#46, #48 were all Max's chair).

## 9. The number line is one line

Findings continue the global ledger (#62 onward here; #1–#61 live in
the preinstall archive and DockMenu). Round-scoped surface items are
`I<round>-<n>`. The raw experience stays in the machine's file; the
CHANGE it implies goes to changes.md, tagged with its status, moved
when applied. Fixes that live in waverunner ride the launcher → lock →
seed pipeline (#41): a fix is not real until the seed carries it.

## 10. Honesty clauses inherited whole

The reveal says only true things; `ok:true` means the effect exists
(#35c's verify_effect — every new question maps its observable);
success without verification is the lie this lab exists to prevent.
