# OPTIONS — Modules

<!-- Max's file: add module names as ideas come. One name per line. -->

## Live (built before the Brain, need re-wiring)

- window-pills
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
- battery
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
