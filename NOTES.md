# NOTES

- todo2 "Max's eyes + a day of daily use (window pill behaves identically)":
  blocked — needs Max personally daily-driving the live session for a day and
  judging the pill's feel. No test or screenshot substitutes for the owner's
  eyes here, so it can't be closed by an agent.

- todo3 (all six migration/new-module items — intellihide, window-pills,
  notifications, clipboard, notes, media): blocked — every one is Rust work in
  the waverunner tree (`github:maxpoww/launcher`, local checkout outside
  ~/Golem), which is only a pinned flake input here. This repo holds no engine
  collectors, no Mind providers and no surfaces, and the agent session is
  sandboxed to ~/Golem, so none can be edited or tested from here. They need a
  session rooted at the waverunner checkout.
- todo3 "Refine per-module when picked": blocked — contingent by its own
  wording on a module first being picked from optionsmodules.md, and S3 has not
  opened (roadmap ARC 1 is at S7, under the fix-don't-grow freeze). Writing the
  per-module DoD checklists now would be guessing at picks Max hasn't made.
