# Focus→Visibility notification fix

A tiny Chrome extension that makes **Facebook / Messenger / Instagram** fire
desktop notifications on Linux/Wayland (Hyprland), where they otherwise only
play an in-page sound.

## Why this is needed

- Those sites post a *system* notification only when the page is
  `document.visibilityState === "hidden"`.
- On Windows/macOS Chromium marks an unfocused/covered window "occluded"
  (hidden). On **Linux/Wayland Chromium does no occlusion tracking**
  ([Chromium docs](https://chromium.googlesource.com/chromium/src/+/master/docs/windows_native_window_occlusion_tracking.md)),
  so a mapped window is always "visible" → they never notify.
- WhatsApp works because it gates on **focus/blur**, which Chromium *does*
  report on Linux.

This extension bridges the gap: it reports the page as `hidden` whenever the
browser window is **not focused**, so FB/Messenger behave like WhatsApp.

## Install (unpacked)

1. Open `chrome://extensions`.
2. Toggle **Developer mode** (top-right) on.
3. Click **Load unpacked** and select this folder (`~/notification-fix`).
4. Reload the Facebook / Messenger tabs.

## Test

With the tabs open, switch focus to another window (don't view them) and send
yourself a message — it should now appear as a system notification (and in
OPTIONS with the avatar).

## Uninstall

Remove it from `chrome://extensions`. Nothing else is touched.
