# Golem OS — Features a finished OS needs

> Compiled 2026-08-29 from macOS (Tahoe 26), Windows 11 (2026), Ubuntu/Fedora,
> GNOME (50), and KDE Plasma 6 — plus what any laptop/touchscreen user simply
> expects. This is the *universe of user needs*, not a commitment: items get
> promoted from here into `optionsmodules.md` / `roadmap.md` when we decide to
> build them. Being useful is the point — a user should never hit "Golem can't
> do that basic thing."
>
> Legend: **✔** Golem has it today · **~** partial · (blank) missing

## 1. First contact
- ~ Installer (guided disk/user/language flow) — *S9 planned*
- ~ First-run onboarding / welcome tour (GNOME Tour, Windows OOBE) — *S8 planned*
- Migration/import from another OS (files, browser data, photos)
- Live/demo session (try before installing)

## 2. Shell & desktop
- ✔ App launcher + search (openbox)
- ✔ Dock / taskbar with pinned + running apps
- ✔ App store / software center (Install section; GNOME Software, MS Store)
- ✔ Notifications center + Do Not Disturb
- ✔ Clipboard manager with history (macOS added it to Spotlight in Tahoe!)
- ✔ Topbar with clock / window / controls
- ~ System-wide search (apps ✔; need: files content, settings, actions — Spotlight-style)
- Window management: snap/tiling layouts (Win11 Snap, macOS Stage Manager), alt-tab, overview/exposé
- Virtual desktops / workspaces (+ touchpad gestures between them)
- Quick settings panel (wifi/bt/volume/brightness in one flick — every OS has this)
- Lock screen + login screen (greeter)
- Wallpapers: per-monitor, dynamic (time-of-day), user photos
- Widgets / glanceable info (Win11 Widgets, macOS desktop widgets) — *maybe = OPTIONS itself*
- Session restore (reopen windows after reboot)
- Sound effects / audio feedback (device plug/unplug etc.)

## 3. Settings panels (the full inventory every OS converges on)
- Network (wi-fi, ethernet, VPN, proxy, hotspot)
- Bluetooth (pair, battery of devices)
- Displays (arrangement, resolution, scale/fractional, rotation, HDR, night light)
- Sound (devices, volumes per-app, input test, alerts)
- Power & battery (profiles, charge limit, battery health, what-drains-it)
- Appearance / theming (accent, dark mode, fonts, cursor, corners)
- Users & accounts (avatar, password, admin, guest)
- Date & time (auto timezone, formats)
- Language & region (i18n, input methods)
- Keyboard (layouts, shortcuts editor, compose)
- Mouse & touchpad (speed, gestures, natural scroll)
- Touchscreen & pen/tablet (calibration, gestures, button re-binding — Plasma 6.3)
- Printers & scanners
- Default apps / file associations
- Notifications per-app settings
- Privacy & permissions (camera/mic/location per-app)
- Accessibility (see §9)
- Storage (what's using disk, cleanup)
- Apps (installed list, uninstall, per-app info)
- Online accounts (mail/calendar/cloud sync)
- Updates & recovery (see §13)
- About (device name, specs, OS version)

## 4. Connectivity & sharing
- Wi-fi join/manage (incl. captive portals!), ethernet, mobile broadband
- VPN (WireGuard/OpenVPN at least)
- Personal hotspot
- Firewall (on by default, simple UI)
- Phone integration (KDE Connect / Phone Link / Continuity: notifications,
  SMS, calls relay, shared clipboard, file send)
- Nearby/local file sharing (AirDrop-style)
- Network speed test (Win11 2026 taskbar feature)
- Casting / screen mirroring (Miracast/Chromecast)
- Remote desktop (be one / view one — GNOME Connections, Plasma 6.1)

## 5. Hardware & laptop reality
- Battery management: profiles (powersave/balanced/performance), charge
  limiting, health reporting, low-battery warnings + auto-suspend
- Lid/suspend/hibernate behavior, wake handling
- Brightness (+ auto via ambient sensor), keyboard backlight
- Function/media keys with OSD (volume/brightness popups)
- Fingerprint reader + face unlock (Windows Hello sets the bar)
- Webcam: works everywhere + privacy indicator dot when in use
- External displays hotplug (remember arrangements per-dock/setup)
- Audio device hotplug + smart switching (headphones in → route)
- USB/SD hotplug: auto-mount, "safely remove", plug sounds
- Touchscreen: tap/scroll/pinch everywhere, on-screen keyboard, rotation
- Pen/stylus support (calibration, pressure)
- Thermals: fan awareness, throttle visibility
- Color management / ICC profiles; color-blindness filters (Plasma 6)
- Game niceties: HDR, VRR, game mode (Win11 Auto HDR precedent)

## 6. Core everyday apps (the "no user left stranded" set)
- ~ Files/file manager (home listing exists; need real manager: copy/move,
  trash ✔, archives, network shares, split view — Nautilus/Dolphin)
- Web browser (ship a default; webapps catalog ✔ complements)
- Text editor (simple, instant)
- ✔ Terminal (foot ships; Golem's promise = you never *need* it)
- Calculator
- Calendar (+ event notifications)
- Clock: alarms, timers, stopwatch, world clocks
- Weather
- Camera/webcam app (photo + video capture — GNOME Snapshot, Windows Camera)
- Image viewer (fast, with basic crop/rotate)
- Photos management (library, import from phone/SD)
- Video player + audio/music player
- Sound recorder
- PDF/document viewer (+ fill & sign — users always need sign)
- Notes (~ stub exists in clipboard footer)
- ✔ Dictionary (EN/ES offline — ahead of most OSes!)
- Screenshot + screen recorder (region/window, annotate — Spectacle sets the bar)
- Archive manager (zip/unzip in Files)
- Maps (nice-to-have — GNOME Maps)
- Contacts (nice-to-have; matters more with phone integration)
- Mail client (decide: ship vs webapp route)
- System monitor (CPU/RAM/net per-app; force-quit!)
- Disks/disk utility (format USB sticks — normal-people need this)
- Document scanner (Simple Scan)
- Character/emoji picker (system-wide input, not just an app)
- Help/documentation app

## 7. Security & privacy
- Full-disk encryption (offered at install)
- Password manager / keyring (+ browser integration)
- Per-app permissions (camera/mic/location/files) + active-use indicators
- Sandboxed app model where possible
- Automatic security updates (see §13 — Nix superpower)
- Screen lock on idle/lid; require password policy
- Parental controls / screen time (the "family PC" case)
- Find my device (someday)
- Verified boot chain (someday; TPM story)

## 8. Updates, backup & maintenance (Golem's home turf — Nix superpowers)
- ~ OS updates: atomic, background, rollback-able (nixos-rebuild generations
  = better than every OS listed; needs a friendly UI + "roll back" button)
- ✔ Declarative app install/remove
- System snapshots / restore points (generations UI!)
- User-data backup (Time Machine sets the bar; ship a simple scheduled backup)
- Storage cleanup (GC old generations — friendly "free up space")
- Crash reporting / diagnostics users can send
- Battery/system health reports

## 9. Accessibility (the "everyone" section — every OS ships ALL of this)
- Screen reader (hard on wgpu/layer-shell — research early, §S11)
- Magnifier/zoom (macOS Tahoe added camera-magnifier)
- High contrast, large text, bold text modes
- Reduce motion / reduce transparency (our frosted glass needs an off switch)
- Sticky/slow/bounce keys, mouse keys
- On-screen keyboard
- Voice control + dictation (someday)
- Captions (someday)
- Color-blindness filters

## 10. Input & language
- Multiple keyboard layouts + fast switcher
- IME for CJK etc. (fcitx5/ibus — "everyone" includes 2B CJK users)
- Emoji + special characters, system-wide
- Spellcheck system-wide; autocorrect on touch
- Full i18n of the shell (Spanish first ✔ dictionary lead)
- RTL language support (someday)

## 11. The OPTIONS edge (features others have as afterthoughts, we have as soul)
- ✔ Context-aware affordances (the whole Brain/Mind design)
- ✔ Link share-cards, ✔ clipboard enrichment, ✔ offline dictionary
- Focus/flow protection (DND that understands *what you're doing* — better
  than macOS Focus modes because it's sensed, not scheduled)
- Media "now playing" controls surfaced when logical
- Smart suggestions (screencast/deploy/battery/git providers already exist)
- Diegetic onboarding (S8) — the tour IS the OS teaching itself

---

### How to read this file
Golem's real gaps, by weight: **settings panels (§3), hardware/laptop
plumbing (§5), the everyday app set (§6), accessibility (§9).** Most §2–§5
items are OPTIONS modules waiting to be named in `optionsmodules.md`; most
§6 items are a curation decision — **decided in `apps.md`** (build / curate /
webapp) and scheduled as roadmap S5. §8 is where
Golem can *lead*, not catch up: generations UI + "roll back" is a feature no
mainstream OS matches.

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
