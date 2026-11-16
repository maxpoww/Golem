# Golem OS — Features a finished OS needs

> Compiled 2026-08-29 from macOS (Tahoe 26), Windows 11 (2026), Ubuntu/Fedora,
> GNOME (50), and KDE Plasma 6 — plus what any laptop/touchscreen user simply
> expects. This is the *universe of user needs*, not a commitment: items get
> promoted from here into `OPTIONS/modules.md` / `roadmap.md` when we decide to
> build them. Being useful is the point — a user should never hit "Golem can't
> do that basic thing."
>
> Legend: **✔** Golem has it today · **~** partial · (blank) missing.
> Marks checked against the code of `main` on 2026-11-16 (Golem `355bb22`,
> launcher `0ddf6d60`); a line in italics under an item says what is there and
> what is not. Eight items could not be settled from the code and keep their
> old mark: sound effects, media-key popups, webcam, audio hotplug,
> touchscreen, camera app, dictionary data on an install, the §11 ✔ line.

## 1. First contact
- ✔ Installer (guided disk/user/language flow)
  *The installer ISO: disk, user, six languages, encrypted disk.*
- First-run onboarding / welcome tour (GNOME Tour, Windows OOBE) — *not built*
- Migration/import from another OS (files, browser data, photos)
- Live/demo session (try before installing)

## 2. Shell & desktop
- ✔ App launcher + search (the dock's box)
- ✔ Dock / taskbar with pinned + running apps
- ✔ App store / software center (Install section; GNOME Software, MS Store)
- ✔ Notifications center + Do Not Disturb
- ✔ Clipboard manager with history (macOS added it to Spotlight in Tahoe!)
- ✔ Topbar with clock / window / controls
- ✔ System-wide search (Spotlight-style)
  *Apps, files and what is inside them, settings, an app's actions.*
- ✔ Window management: snap/tiling layouts (Win11 Snap, macOS Stage Manager), alt-tab, overview/exposé
  *Tiling, Stage (Super+Enter), Super+Tab, the overview (Super+R).*
- ✔ Virtual desktops / workspaces (+ touchpad gestures between them)
  *3 and 4 finger swipes, Super+1…9.*
- ✔ Quick settings panel (wifi/bt/volume/brightness in one flick — every OS has this)
  *The gear's box.*
- ~ Lock screen + login screen (greeter)
  *Has: the lock screen. Missing: a graphical login (text greeter; branch login-live).*
- ~ Wallpapers: per-monitor, dynamic (time-of-day), user photos
  *Has: your pictures, videos, a wallpaper that follows the colours. Missing: per monitor, by time of day.*
- Widgets / glanceable info (Win11 Widgets, macOS desktop widgets) — *maybe = OPTIONS itself*
- ~ Session restore (reopen windows after reboot)
  *Has: Files and Seam reopen, windows keep their places. Missing: other apps.*
- Sound effects / audio feedback (device plug/unplug etc.)

## 3. Settings panels (the full inventory every OS converges on)
- ~ Network (wi-fi, ethernet, VPN, proxy, hotspot)
  *Has: Wi-Fi, wired, VPN, hotspot. Missing: proxy.*
- ✔ Bluetooth (pair, battery of devices)
- ~ Displays (arrangement, resolution, scale/fractional, rotation, HDR, night light)
  *Has: everything but HDR.*
- ~ Sound (devices, volumes per-app, input test, alerts)
  *Has: devices, volume per app, microphone, equalizer. Missing: an input test, alert sounds.*
- ~ Power & battery (profiles, charge limit, battery health, what-drains-it)
  *Has: profiles, charge limit, health. Missing: what drains it.*
- ~ Appearance / theming (accent, dark mode, fonts, cursor, corners)
  *Has: palettes, dark mode, transparency, pointer size. Missing: fonts, corners.*
- ~ Users & accounts (avatar, password, admin, guest)
  *Has: picture, password, fingerprint. Missing: a second user, guest.*
- ~ Date & time (auto timezone, formats)
  *Has: time zone, 12/24 h. Missing: automatic time zone.*
- ~ Language & region (i18n, input methods)
  *Has: seven languages, changed live. Missing: region formats, input methods.*
- ~ Keyboard (layouts, shortcuts editor, compose)
  *Has: layouts, switch keys, repeat. Missing: a shortcuts editor, compose.*
- ~ Mouse & touchpad (speed, gestures, natural scroll)
  *Has: speed, tap, natural scroll, left hand. Missing: choosing the gestures.*
- Touchscreen & pen/tablet (calibration, gestures, button re-binding — Plasma 6.3)
- ✔ Printers & scanners
- ✔ Default apps / file associations
- ✔ Notifications per-app settings
- ~ Privacy & permissions (camera/mic/location per-app)
  *Has: who is using the camera and microphone now. Missing: per-app permissions, location.*
- ~ Accessibility (see §9)
  *See §9.*
- ✔ Storage (what's using disk, cleanup)
- ~ Apps (installed list, uninstall, per-app info)
  *Has: the apps grid, uninstall. Missing: a page for an installed app.*
- Online accounts (mail/calendar/cloud sync)
- ~ Updates & recovery (see §13)
  *Has: the Updates page, automatic rollback after a crash loop. Missing: a versions page, a go-back button.*
- ✔ About (device name, specs, OS version)

## 4. Connectivity & sharing
- ~ Wi-fi join/manage (incl. captive portals!), ethernet, mobile broadband
  *Has: Wi-Fi with sign-in pages, wired. Missing: mobile broadband.*
- ✔ VPN (WireGuard/OpenVPN at least)
- ✔ Personal hotspot
- ~ Firewall (on by default, simple UI)
  *Has: on by default. Missing: any UI.*
- ~ Phone integration (KDE Connect / Phone Link / Continuity: notifications,
  SMS, calls relay, shared clipboard, file send)
  *Has: files over USB and Wi-Fi, screen mirror, the phone as camera (Android, adb). Missing: notifications, SMS, calls, clipboard.*
- ~ Nearby/local file sharing (AirDrop-style)
  *Has: files over Bluetooth. Missing: an AirDrop-style share (LocalSend only if installed).*
- Network speed test (Win11 2026 taskbar feature)
- Casting / screen mirroring (Miracast/Chromecast)
- Remote desktop (be one / view one — GNOME Connections, Plasma 6.1)

## 5. Hardware & laptop reality
- ✔ Battery management: profiles (powersave/balanced/performance), charge
  limiting, health reporting, low-battery warnings + auto-suspend
  *Charge limit where the hardware has one.*
- ✔ Lid/suspend/hibernate behavior, wake handling
- ~ Brightness (+ auto via ambient sensor), keyboard backlight
  *Has: brightness with Auto, keyboard backlight keys. Missing: a keyboard backlight control.*
- Function/media keys with OSD (volume/brightness popups)
- ~ Fingerprint reader + face unlock (Windows Hello sets the bar)
  *Has: fingerprint. Missing: face unlock.*
- Webcam: works everywhere + privacy indicator dot when in use
- ~ External displays hotplug (remember arrangements per-dock/setup)
  *Has: hotplug, each screen's choices kept. Missing: a layout per set of screens.*
- Audio device hotplug + smart switching (headphones in → route)
- ~ USB/SD hotplug: auto-mount, "safely remove", plug sounds
  *Has: automount, eject. Missing: plug sounds.*
- Touchscreen: tap/scroll/pinch everywhere, on-screen keyboard, rotation
- Pen/stylus support (calibration, pressure)
- ~ Thermals: fan awareness, throttle visibility
  *Has: temperatures. Missing: fan, throttling.*
- Color management / ICC profiles; color-blindness filters (Plasma 6)
- ~ Game niceties: HDR, VRR, game mode (Win11 Auto HDR precedent)
  *Has: VRR, GameMode with Steam. Missing: HDR.*

## 6. Core everyday apps (the "no user left stranded" set)
- ~ Files/file manager (copy/move, trash, archives, network shares, split
  view — Nautilus/Dolphin)
  *Has: Golem Files (copy, move, bin, archives, tabs, Quick Look). Missing: split view, network shares.*
- ✔ Web browser (ship a default; webapps catalog ✔ complements)
  *Seam.*
- ✔ Text editor (simple, instant)
- ✔ Terminal (foot ships; Golem's promise = you never *need* it)
- Calculator
- Calendar (+ event notifications)
- ~ Clock: alarms, timers, stopwatch, world clocks
  *Has: a sleep timer. Missing: alarms, stopwatch, world clocks.*
- Weather
- Camera/webcam app (photo + video capture — GNOME Snapshot, Windows Camera)
- ✔ Image viewer (fast, with basic crop/rotate)
  *Loupe; Quick Look's pencil crops and turns.*
- Photos management (library, import from phone/SD)
- ~ Video player + audio/music player
  *Has: mpv plays both. Missing: a music library.*
- Sound recorder
- ✔ PDF/document viewer (+ fill & sign — users always need sign)
  *Papers; Quick Look marks and signs a PDF.*
- ~ Notes
  *Has: the card keeps text and voice notes beside a window. Missing: a notes app.*
- ✔ Dictionary (EN/ES offline — ahead of most OSes!)
- ~ Screenshot + screen recorder (region/window, annotate — Spectacle sets the bar)
  *Has: Print Screen, a region to the clipboard (file, window, whole screen: branch tarde-1116). Missing: annotate, recording.*
- ✔ Archive manager (zip/unzip in Files)
- ~ Maps (nice-to-have — GNOME Maps)
  *Has: Google Maps in the webapp catalogue.*
- Contacts (nice-to-have; matters more with phone integration)
- ~ Mail client (decide: ship vs webapp route)
  *Has: Gmail, Outlook, Proton Mail in the webapp catalogue. Missing: the decision.*
- ~ System monitor (CPU/RAM/net per-app; force-quit!)
  *Has: CPU and memory per app, force quit. Missing: network per app.*
- ✔ Disks/disk utility (format USB sticks — normal-people need this)
- ~ Document scanner (Simple Scan)
  *Has: Simple Scan arrives with the first scanner.*
- ✔ Character/emoji picker (system-wide input, not just an app)
- Help/documentation app

## 7. Security & privacy
- ~ Full-disk encryption (offered at install)
  *Has: offered at install. Missing on main: the fix that makes it boot (branch release-candidate).*
- ~ Password manager / keyring (+ browser integration)
  *Has: the browser's password manager. Missing: a system keyring (branch login-live).*
- ~ Per-app permissions (camera/mic/location/files) + active-use indicators
  *Has: in-use readout. Missing: per-app permissions.*
- Sandboxed app model where possible
- ✔ Automatic security updates (see §13 — Nix superpower)
- ✔ Screen lock on idle/lid; require password policy
- Parental controls / screen time (the "family PC" case)
- Find my device (someday)
- Verified boot chain (someday; TPM story)

## 8. Updates, backup & maintenance (Golem's home turf — Nix superpowers)
- ~ OS updates: atomic, background, rollback-able (nixos-rebuild generations
  = better than every OS listed; needs a "roll back" button)
  *Has: daily background updates, an Updates page, automatic rollback after a crash loop. Missing: a go-back button.*
- ✔ Declarative app install/remove
- ~ System snapshots / restore points (generations UI!)
  *Has: Previous Versions in the boot menu. Missing: a page in the session.*
- User-data backup (Time Machine sets the bar; ship a simple scheduled backup)
- ✔ Storage cleanup (GC old generations — friendly "free up space")
- Crash reporting / diagnostics users can send
- ~ Battery/system health reports
  *Has: battery and drive health in the gear's pages. Missing: a report.*

## 9. Accessibility (the "everyone" section — every OS ships ALL of this)
- ~ Screen reader (hard on wgpu/layer-shell — research early, §S11)
  *Has: an Orca switch. Missing: the shell itself is not read.*
- ✔ Magnifier/zoom (macOS Tahoe added camera-magnifier)
- ~ High contrast, large text, bold text modes
  *Has: text size. Missing: high contrast, bold.*
- ~ Reduce motion / reduce transparency (our frosted glass needs an off switch)
  *Has: less motion, a transparency slider. Missing: a reduce-transparency switch.*
- Sticky/slow/bounce keys, mouse keys
- On-screen keyboard
- ~ Voice control + dictation (someday)
  *Has: dictation (hold Super+Space) where the speech engine is installed. Missing: voice control.*
- Captions (someday)
- Color-blindness filters

## 10. Input & language
- ✔ Multiple keyboard layouts + fast switcher
- IME for CJK etc. (fcitx5/ibus — "everyone" includes 2B CJK users)
- ✔ Emoji + special characters, system-wide
- Spellcheck system-wide; autocorrect on touch
- ✔ Full i18n of the shell
  *Es, es_ES, pt, pt_PT, fr, de, it.*
- RTL language support (someday)

## 11. The OPTIONS edge (features others have as afterthoughts, we have as soul)
- ✔ Context-aware affordances (the whole Brain/Mind design)
- ✔ Link share-cards, ✔ clipboard enrichment, ✔ offline dictionary
- ~ Focus/flow protection (DND that understands *what you're doing* — better
  than macOS Focus modes because it's sensed, not scheduled)
  *Has: do not disturb, quiet hours; the engine senses a call or a presentation. Missing: the link between them.*
- ✔ Media "now playing" controls surfaced when logical
- ~ Smart suggestions (screencast/deploy/battery/git providers already exist)
  *Has: the providers exist in the engine. Missing: none is switched on (the Mind offers nothing yet).*
- Diegetic onboarding (S8) — the tour IS the OS teaching itself

---

### How to read this file
Golem's real gaps on 2026-11-16, by weight: **the small everyday apps (§6:
calculator, calendar, weather, camera, photos, recorder, contacts, help),
accessibility (§9: high contrast, sticky keys, on-screen keyboard, captions,
colour filters), backup (§8), an input method (§10), casting and remote
desktop (§4), and the first-run tour.** Settings (§3) and laptop plumbing
(§5), the gaps of September, are mostly built. Most §6 items are a curation
decision (`apps.md`: build / curate / webapp). §8 is where Golem can *lead*,
not catch up: a versions page with "roll back" is a feature no mainstream OS
matches, and it is still not built.

### Sources
- [GNOME Core Applications — Wikipedia](https://en.wikipedia.org/wiki/GNOME_Core_Applications)
- [GNOME Settings — apps.gnome.org](https://apps.gnome.org/Settings/)
- [Windows 11 features Q1 2026 — Windows Central](https://www.windowscentral.com/microsoft/windows-11/9-new-windows-11-features-microsoft-delivered-in-the-first-quarter-of-2026)
- [Windows 11 built-in apps 2026 — Windows Central](https://www.windowscentral.com/microsoft/windows-11/windows-11s-built-in-apps-are-about-to-get-a-boost-heres-whats-already-in-testing)
- [Features coming to Windows 11 in 2026 — Windows Latest](https://www.windowslatest.com/2026/04/09/full-list-of-features-coming-to-windows-11-in-2026/)
- [macOS Tahoe 26 — Apple Newsroom](https://www.apple.com/newsroom/2025/06/macos-tahoe-26-makes-the-mac-more-capable-productive-and-intelligent-than-ever/)
- [macOS Tahoe updates — Apple Support](https://support.apple.com/en-us/122868)
- [KDE MegaRelease 6 — kde.org](https://kde.org/announcements/megarelease/6/)
- [Plasma 6.3 — alternativeto.net](https://alternativeto.net/news/2025/2/kde-plasma-6-3-improves-fractional-scaling-system-monitoring-panel-cloning-and-much-more/)
