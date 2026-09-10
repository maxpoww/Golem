# Extending — adding to the preinstaller without breaking its promises

Every addition inherits the constitution (`testing/constitution.md`):
the reveal says only true things, nothing writes outside an install,
and a change ships only when the artifact provably carries it.

## Add a census fact

1. **Probe it** in `~/Golem/system/hardware-detect.nix` — facts are
   measured, never guessed, and triangulated when one source can lie
   (the `hasBluetooth` pattern: sysfs ∨ rfkill ∨ USB class). Grow a
   fact only when a machine demands it (the GolemInstall.md §4 rule) —
   speculative facts rot.
2. **Fixture it**: capture the demanding machine's census + evidence
   into `fixtures/<machine>/` so the fact is testable forever without
   the metal.
3. **Consume it** in a decision module (`~/Golem/system/hardware/…`) —
   facts in, evaluation out; no assembled configuration prose.
4. **Reveal it** only if a stranger can act on it, as
   `name · driver — verdict`; a device that is not there gets NO row.
   Uncertain tails render dim (`hw_row` handles this — don't invent a
   second style).
5. Mind the generations: device-id heuristics must be checked against
   ancient parts (#12), probes against runtime-PM timing (#23/#17c),
   and anything nvidia against the iron-law floor where module
   internals are null (#22).

## Add a decision row

Decision modules live beside the facts; every decision is asserted in
the eval matrix against the fixtures. The confirm screen shows the
decision in that machine's own words (`summary.txt` → decide rows) and
in the user's language — a new row means six translations (see below).

## Add a surface step or key

`mockup/install-cli` is the single source (`setup.nix` just wraps it).
Rules learned the hard way:

- Every string goes through the `S[lang:key]` table + `t` — English
  hardcoded anywhere WILL surface in a Spanish run (#18, the reh_bar
  lesson).
- Every screen must answer: what does ENTER do, what does ESC do, what
  does F1 do — and say so in the guide line. An advertised key that
  does nothing is a finding (#31); an unadvertised key that does
  something confusing is too (R5-3).
- New named keys go into `read_key`, and the welcome's head-start
  catch-all only accepts single characters — key NAMES must never
  become filter text (R5-3's guard; keep it).
- Fixed-height blocks only; every redraw bug lives in a variable-height
  erase (`pick_block`'s comment).
- Ctrl-C means what F1 means: leave once, cleanly, temp files gone
  (#34 — the trap pair at the script's tail owns cleanup).

## Add a postinstall question

The ask framework is the pattern for every "the installer shouldn't
decide this" case (#33):

1. Generate the question from FACTS in `postinstall-questions.nix` —
   id, options, a default that is safe when nobody ever answers, and
   body text a stranger can act on. The unanswered default must build
   a working system (the `hold` principle).
2. The target consumes answers via `golem.postinstall.answers` — the
   generated module is imported path-conditionally
   (`~/Golem/system/postinstall.nix`, #35). Never bypass that seam.
3. **Map the observable**: add the `id:option → expected unit/rival`
   pair to `verify_effect` in postinstall.nix — an unmapped answer
   verifies vacuously and can lie about success (#35c). This is not
   optional; it is what made #35 impossible to repeat.
4. Test both directions on metal, including answer → re-answer (the
   35d lesson: undoing a hardware action needs its own path — a
   removed PCI device does not come back without a rescan).

## Add a language

Six exist (en/es/fr/de/it/pt). A seventh = a full `S[xx:*]` block
(every key — the build should fail loud on a missing one), an INVITE
line, and a console-font check for the script (the #13 lesson: boxes on
the console are a finding; the keymap must round-trip too, #6/#7).

## The discipline (how changes ship)

- Findings go to `testing/changes.md` (the number line continues even
  though preinstall graduated — DockMenu already extends it). One
  entry: what/why/where/size, tagged with its status.
- **One frozen ISO per round.** Fixes apply to SOURCE mid-round and
  ship in the NEXT cut; a live-fix may be nix-copied onto a booted
  machine as a RAM overlay to verify (marked as such), but the stick
  never reburns mid-round.
- Machine-side (waverunner) fixes: commit in `~/launcher`, push, bump
  `~/Golem`'s lock — permanence rides the seed, nothing else (#41).
- Every cut: `nix flake update`, gate on the VM, verify the built
  artifact carries this round's markers (OPERATIONS.md).
