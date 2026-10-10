# Night test, 2026-10-10 — the desktop, the card, the task pill, Android, on three laptops

Max: "testea todo… varias veces, depura todo… mañana vamos a cortar una nueva iso."
Machines: Acer E5-573 (+ Samsung A11 on the cable), MacBook Air 6,2 (+ Pixel 8 Pro),
ASUS X550LC (no phone). Final state: launcher 9f159dd, Golem 6322a91, waveview c04f9ca
on all three (pushed, lab-pulled, rebooted).

## Bugs found and fixed (all pushed and on the laptops)

1. **"Use as camera" did nothing on an installed Golem.** The loopback camera device
   (v4l2loopback, "Android WebCam", /dev/video10) existed only in the fat config and in
   the dev box's own layer. New leaf `system/Modular/desktop/phone.nix`. After it: both
   phones appear in PipeWire as a camera ("golem-phone-cam | Pixel 8 Pro"), two lenses
   each, stop cleans up.
2. **The first press on the desktop could not drag.** Taking the keyboard on the PRESS
   made the compositor release the button 4 ms later: after working in a window, the
   first press on an icon selected it but never dragged it, and the rubber band never
   started (8 drags in a row: every other one dead). The keyboard is taken on release.
   After the fix: 9/9.
3. **A Wi-Fi sync could hang for good** (`adb pull` on one video, no byte for 7 minutes,
   task pill frozen). A copy that brings nothing for 45 s is cut; the rest comes at the
   next sync.
4. **A phone given a name kept its old folder** — every photo was copied a second time.
   The folder its imports made is adopted.
5. **Right after Apply the first sync went over Wi-Fi with the cable in** (the phone's
   adb restarts). The cable gets 8 s to come back.
6. **A renamed file lost its ending** ("notes" typed over "notes.txt"). It keeps it.
7. **At 00:01 a notification of 23:58 read "1d"** (notifications and clipboard): the
   last 24 h read as clock times.
8. NEW: **an icon let go on a folder goes into it** (it used to land beside the folder).

## What was run, and passed, on each machine

| | Acer | MacBook | ASUS |
|---|---|---|---|
| desktop by script (files appear, move + dock restart keeps it, select, band, hide/show, import ×2 with name clash, menus, properties, open, delete) | ok ×1 | ok ×1 | ok ×3 |
| desktop with a REAL pointer (kernel-level): move an icon, drop into a folder, rubber band + group drag, drag to the dock's bin, rename in place, drag INTO Nautilus | ok | ok (bin: my coordinate missed) | ok ×2 |
| drag OUT of Nautilus onto the desktop | ok | ok | ok |
| card: title-bar button, drop a file on it, type a note, click = paste into its window, wheel slides/throws it, off/on, gone with its window; by script: add/remove/pin/pages/paste ×5/restore after a dock restart | ok | ok | ok |
| task pill: tasks, box, collapse (real click), cancel | ok | ok | ok |
| regression battery (OPTIONS frames + 14 deep scenarios incl. suspend, lock, compositor crash), with the phone attached | ok ×2 | ok ×2 | ok ×2 |
| parity | 0 findings (1 after the deliberate crash: the GTK portal unit reads "failed" until something asks for it — it then starts again) | same | same |

## Android (Acer + Samsung A11, MacBook + Pixel 8 Pro)

- Phone appears on the desktop; menu rows; Properties; Open (Nautilus on MTP); Open in
  terminal (cwd = the MTP mount); Mirror screen (scrcpy window, closes clean).
- Use as camera: see bug 1; after the fix, on and off, two lenses each.
- Use phone's internet (Samsung): on → rndis interface, address, default route, ping to
  the internet through it; the menu row becomes "Stop phone's internet"; off → MTP and
  the icon come back.
- Import photos: Samsung 73 files / 467 MB; Pixel 2081 files / 38 GB in ~18 min
  (~35 MB/s). Cancel from the task pill after 90 s → "Import stopped. Click to view 230
  imported photos"; import again resumed (1851 new). 24 random files compared with the
  phone by size: 24 equal. Import again: "No new photos."
- A file dragged ONTO the phone icon (real pointer) arrives in its Download folder
  (checked with adb; my test file removed again).
- Configure: box renders with the phone's real sizes; name typed; kinds; Apply allows
  Wi-Fi (adb tcpip) and syncs; Cancel saves nothing. Sync: Samsung 112 files, Pixel
  2334 files; a new file on the phone came at the next sync; syncs after a reboot ran
  over the cable with "0 new".
- NEVER run: "Clean now", "remove after sync" (they delete from the phone), Eject (it
  would have unplugged the phone for the night).

## Left as found / for Max

- Both test phones are configured on their laptop with sync ON (hourly) and their files
  are in ~/Phones there (MacBook: 41 GB of the Pixel). Sync was switched OFF again at
  the end of the night; the folders were left.
- Small things, not changed: while a task runs the bar is redrawn at each progress step
  and the colour sampler captures about once a second; after the pill collapses the hand
  cursor stays where the pill was until the pointer moves; the phone's menu and the
  notification box overlap when both are open; "Stop using" / auto-mount of a re-plugged
  stick (asked earlier).
- Not testable here: auto brightness (no laptop has a light sensor — it is not
  installed on any of them, as designed), the foot drag-out patch by hand (only that
  foot starts and the card pastes into it), two monitors.
