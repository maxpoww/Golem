# Fits

**An app the owner installs works the moment it lands.** Golem does not ship
these apps; the owner drags them in from the dock. A *fit* is the small piece
of first-run state an app needs to do the one thing it was installed for,
without the owner having to already know the app.

Max, 2026-10-01: "obs is not gonna come installed on Golem. but it have to
work out of the box as soon as a user install it."

## How a fit works

- Code: `system/home/fits.nix` (the home layer). A fit is active only when its
  app is among the installed packages (`home.packages`, which is where the
  dock's `packages.list` ends up through `hosts/target/apps.nix`).
- It is laid down at activation — the same rebuild that installs the app —
  **once**, and only while the app has never been set up. The marker
  `~/.local/state/golem/fits/<app>` records that it was done; after that the
  app's config is the owner's and Golem never touches it again.
- It is plain files the app can rewrite, never a store link.
- It never runs while the app is open.

## OBS Studio

**Before:** OBS opens on an empty scene: a black preview, and Record writes a
black video. On Wayland a screen is only captured after the owner picks it in
the portal's picker, and OBS asks only once a *Screen Capture (PipeWire)*
source exists.

**The fit** (`system/home/fits/obs-studio/`):

- a scene that already holds that source → on first launch the "what to
  share" picker comes up by itself; pick the screen and the preview is live,
  Record records it;
- desktop audio and the microphone (OBS adds them only to collections it
  creates itself; a seeded one without them records in silence);
- OBS's first-run wizard marked done (it asks about streaming versus
  recording and adds no source);
- the scene is in OBS's relative (version 2) form: the source sits on the
  canvas centre, fitted to its height, so one seed serves every screen.

If OBS was opened before and still has only its untouched empty `Untitled`
scene, that scene gets the source (the old file is kept as
`Untitled.json.before-golem`). A scene the owner built is never touched.

**Not covered yet**

- The picker comes up on every launch unless "allow a restore token" is
  ticked in it. Making that the default (`allow_token_by_default` in
  `~/.config/hypr/xdph.conf`) would apply to every app that shares the
  screen: a security choice, not made here.
- The virtual camera needs the `v4l2loopback` kernel module, which Golem does
  not carry.
- OBS's own defaults stay: software x264, a 1920×1080 canvas at most (a 16:10
  screen larger than that is shown with bars at the sides), 1280×720 output.
