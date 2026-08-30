# Golem OS — The App Set

> Every app Golem ships with, and HOW we get each one. Three strategies:
> **BUILD** (ours, OPTIONS-native — only where the soul lives),
> **CURATE** (ship an existing open-source app, themed/configured to fit —
> Nix makes this one line), **WEBAPP** (our Chrome webapp catalog — already
> built). Get-it-done rule: we BUILD only what nobody else can build.

## BUILD — Golem-native (the soul; each is/becomes an OPTIONS module)

| App | Status |
|---|---|
| Settings (config UI) | roadmap S6 |
| Notes | stub exists (clipboard footer pencil) |
| Dictionary | ✔ shipped (EN/ES offline) |
| Clipboard manager | ✔ shipped |
| Screenshot + annotate | grim plumbing ✔, UI missing |
| Time Machine for the OS (generations/updates UI, "roll back" button) | our headline feature — no OS has it |
| Software center | ✔ shipped (Install section) |
| Installer + onboarding tour | roadmap S8/S9 |
| System monitor / force-quit | as an OPTIONS module (surface when something misbehaves) |
| Golem (Android companion) | see `android.md` |

## CURATE — ship, theme, done (default: GNOME Circle/core apps — simple,
## touch-friendly, libadwaita-consistent; swap individual picks if one fits better)

| Need | Pick | Notes |
|---|---|---|
| Files | Nautilus | real file manager (trash, archives, shares); replaces our Files listing long-term |
| Text editor | GNOME Text Editor | instant, simple |
| Calculator | GNOME Calculator | |
| Calendar | GNOME Calendar | + evolution-data-server = shared calendar/contacts backend for online accounts |
| Clock (alarms/timers) | GNOME Clocks | |
| Weather | GNOME Weather | |
| Camera | Snapshot | webcam photo/video |
| Image viewer | Loupe | fast, touch gestures |
| Video player | Showtime (or Celluloid/mpv if codecs fight) | |
| Music/audio | Decibels (files) / Amberol (library) | pick one after trying |
| PDF viewer | Papers | + fill & sign |
| Document scanner | Simple Scan | |
| Sound recorder | GNOME Sound Recorder | |
| Disks/USB format | GNOME Disks | |
| Archive manager | File Roller (Nautilus-integrated) | |
| Contacts | GNOME Contacts | matters once android.md lands |
| Maps | GNOME Maps | nice-to-have tier |
| Emoji/characters | GNOME Characters + fcitx5 emoji | must ALSO be system-wide input |
| Terminal | foot ✔ (already ships) | promise stays: never *required* |
| Browser | **decision needed**: Firefox (default, privacy story) vs Chromium (webapp engine already) — lean Firefox default + Chromium present for webapps | |

## WEBAPP — the catalog carries these (✔ system already built)

Mail (Gmail/Proton), Office (Docs/Office365), Spotify, YouTube, WhatsApp,
Telegram, Discord, Figma, Photopea… — the long tail. Rule: if the web
version is what most people use anyway, it's a webapp, not a package.

## Explicitly NOT shipped (decided)

- Mail client (webapp route; revisit only if users demand offline mail)
- Photos library manager (no good candidate; Loupe + Files + android.md
  photo sync covers v1; revisit)
- Office suite native (LibreOffice stays one drag away in the Install
  section — not preinstalled)

## The work this file implies (scheduled as roadmap S5 → `todo/todo5.md`)

1. One nix module: `golem-apps.nix` listing the CURATE column (trivial).
2. Theming pass: make libadwaita apps look at home (accent, fonts, corners).
3. Default-apps/mime wiring (xdg): every file type opens in the right pick.
4. Per-app touch check (features.md §5 touchscreen).
5. Replace launcher's Files section with Nautilus handoff when curated in.
