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

- todo4 (the five module items — wi-fi, bluetooth, audio, brightness+power,
  displays): blocked for the same reason as todo3 — each is a collector +
  Mind provider + surface in the waverunner tree (`github:maxpoww/launcher`,
  checkout at ~/launcher), and this session is sandboxed to ~/Golem, so
  ~/launcher cannot even be listed. Only the stopgap-retirement half of each
  module (dropping networkmanagerapplet, blueman, pavucontrol, brightnessctl
  from `system/`) lives in this repo, and retiring a stopgap before its module
  exists would just break the machine. They need a session rooted at the
  waverunner checkout. `system-landscape.md` is the prep work done from here.
  Second, softer blocker: all five are downstream of the surface-pattern
  decision below, which is Max's.
- todo4 "Decide surface pattern: topbar pills vs a 'system' box": blocked —
  a design-language call on OPTIONS' coherence, which is the owner's, not an
  agent's. It also decides the module boundaries (does a bluetooth headset
  belong to the bluetooth module or the audio one?), so guessing it wrong
  would misshape all five modules above. `system-landscape.md` §7 collects
  the constraints the decision has to satisfy — pairing and wi-fi joining
  block on the user and need something box-shaped, volume/brightness/battery
  are glanceable scalars that want to rest visible, and a connected headset
  surfaces in two modules at once.
