# OPTIONS — Modules

<!-- Max's file: add module names as ideas come. One name per line.
     OPTIONS is a living layer — modules grow, change, multiply. During
     Arc 1 (the ISO push) ideas are COLLECTED here, not built; building
     resumes in Arc 2 (S3). Known-incomplete modules (clipboard,
     dictionary…) get their finish-up notes here too. -->

## Live (built before the Brain, need re-wiring)

- window-pills — **sensed+shown via Brain (2026-08-30, S2)**: the collector
  in the engine perceives the active window and the topbar pill is driven
  from `ContextState.window` (title/address/class/fullscreen) over the
  `brain.rs` bridge; the old hyprctl poll survives only as the degrade path
  when the compositor layer is dark. Still open for the full DoD: **Decided**
  (no Mind provider yet) and **Wired to the Brain** via `OptionSet` rather
  than the raw context snapshot — both are S3's Mind/OptionSet work.
- clipboard
- notifications
- dictionary
- intellihide

## Planned

- notes
- media
- git
- deploy
- selection
- battery — **v2 SHIPPED 2026-08-30, first new module through the Spine**
  (Max's ladder spec): ≤10% discharging → one notification + the bell's
  accent goes RED (replacing unread amber); ≤7% → the red bell beats
  (~2s breath); ≤5% → suspend; woken still ≤5% unplugged → warning-triangle
  awareness symbol for 5s then HIBERNATE, repeating every wake until
  plugged in. Senses only via the Brain; notification via busctl →
  options-notify (verified). Grow later: % readout, charging surface,
  Mind-ranked "plug in" affordance, power profiles.
- system-health
- phone (the W-A collector — see android.md)
- network (wi-fi)
- bluetooth
- audio
- displays
- power
- screenshot

## Ideas

- (add here)
- search-reveals-location: a search hit that lives inside a box should say
  so / open its box — "rankable but unbrowsable" apps feel disappeared
  (the LocalSend case, 2026-08-30)

---

## Definition of done — a module is checked only when ALL of this is true

1. **Sensed** — it has a collector in the engine (the Brain can perceive it).
2. **Decided** — it has a provider in the Mind (the Brain proposes it only
   when its use is logical, and it goes away when not).
3. **Shown** — it has a surface in waverunner (box, pill, panel…) that
   follows the design language (motion, materials, Shinings).
4. **Wired to the Brain** — the surface is driven by the engine's
   `OptionSet`, NOT by its own hand-made sensing. No duplicate plumbing
   left in the daemon.
5. **Seen** — verified on the live session (verify-ui screenshot), idle at
   rest, clippy/tests clean.
6. **Frictionless** — it appears at the right moment, gets out of the way,
   and never interrupts flow. If it needs a manual to use, it's not done.
7. **Repeatable** — if the action can sensibly be done twice, doing it twice
   must not require re-aiming. Verified by: act, don't move the pointer, act
   again, land the same control. (The Leader — `OptionUXRules.md` §1.)
8. **Still** — its animations must not move another OPTION while the pointer is
   on the surface. Verified by: rest the pointer on a neighbour, let the OPTION
   grow, collapse or re-rank on its own, and watch the neighbour not move.
   (The Still Bar — `OptionUXRules.md` §2.)
9. **On tempo** — it animates on the shared rate, settle and leave-hold from
   `animation.rs`; it declares no rate of its own and multiplies nobody's.
   Verified by: search the module for a rate or a hold constant — there isn't
   one, unless it is an auto-withdraw dwell, which is a different thing.
   (One Material — `OptionUXRules.md` §3.)
10. **Reversible** — if using it takes away the way back, it leaves the way
    back. Verified by: use it, don't move the pointer, and undo it with one
    click; then use it again and walk away, and confirm nothing is left on
    screen. (Sticky OPTIONS — `OptionUXRules.md` §4.)
11. **Exclusive** — if it presents a state among several, exactly one is true
    at a time, pressing the active one returns to the base state, and the state
    shown matches what is on screen. Verified by: reach every state from every
    other state, and get out of each one by pressing it again.
    (One Kills the Other — `OptionUXRules.md` §5.)
12. **One motion** — the change it makes goes out as a single act, and the user
    never sees a state on the way that nobody asked for. Verified by: watch it
    happen. If you can count the steps, it is not done.
    (A Transition Is One Motion — `OptionUXRules.md` §6.)
