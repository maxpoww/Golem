# Golem × Android — the "Golem" companion app

> The goal, in one line: **a Golem PC + any Android phone must feel like one
> device — the way Mac + iPhone does.** The Android app is called **Golem**
> (it IS part of THE Golem: the phone becomes a collector and a surface of
> the same Brain). This is our answer to Continuity/Handoff, and it's a
> fight we can win: Google has no desktop, Apple has no openness — the
> Linux+Android fusion seat is EMPTY.

## Get-it-done strategy: stand on giants, brand the fusion

We do NOT invent a protocol. The **KDE Connect protocol** is open, proven,
GPL, and has a decade-mature **Android app we can fork** (plugins:
notifications, clipboard, SMS, calls, MPRIS, file transfer, find-my-phone,
presenter, battery). Fork → rebrand **Golem** → strip to our UX → extend.
Desktop side: a **`phone` collector in options-engine** speaking the same
protocol (reference implementations to mine: kdeconnectd headless, Valent
(C/GObject), mconnect). Phone state flows into `ContextState`; OPTIONS
surfaces it — a phone pill in the topbar, phone-aware affordances. That's
the difference from KDE Connect: they built a settings module; **we're
plugging the phone into a Mind.**

## Feature ladder (each rung = shippable)

### P1 — Presence (fork + rebrand + basics)
- Pair phone ↔ PC (QR code, LAN, TLS — protocol gives us this)
- Notifications mirrored to the OPTIONS notif box (+ dismiss/reply)
- **Universal clipboard** (copy phone → paste PC and back; feeds our
  share-card pipeline: copy a link on the phone → hero card on the desktop)
- File send both ways; photo lands in ~/Pictures
- Battery/signal as a topbar **phone pill** (first phone OPTIONS surface)
- Find my phone (ring it)

### P2 — Communication (the Phone-Link tier)
- SMS/RCS from the desktop (protocol has SMS plugin)
- Call notify + relay audio where possible (matches macOS Tahoe's new Phone app)
- Contacts sync (into GNOME Contacts/evolution-data-server)
- Media control both directions (MPRIS plugin)

### P3 — Magic (the Continuity tier — where we beat KDE Connect)
- **Phone mirroring**: full phone screen + control in a window, via
  **scrcpy** (mature, open) wrapped in our UX — Apple shipped iPhone
  Mirroring in 2024; we match it with better latency over USB/wifi
- **Continuity camera**: phone as webcam (Android 14+ has native USB webcam
  mode; wifi via scrcpy video pipe) — kills the "Linux webcam is bad" problem
- **Instant hotspot**: one click on the PC, phone tethers (no touching the phone)
- **Proximity unlock**: phone near + unlocked → Golem PC unlocks
- Handoff v1: open the phone's current page/doc on the PC ("continue here")

### P4 — Fusion (the ecosystem tier)
- Photo sync: phone camera roll appears in the PC photo flow automatically
- Shared OPTIONS: the phone as a *surface* too — the Brain pushes the right
  affordance to whichever screen you're looking at
- Cross-device focus/DND (one Do-Not-Disturb state, both devices)
- App streaming polish: pin a phone app to the Golem dock, opens mirrored

## Technical skeleton

- **Android**: fork `kdeconnect-android` (Kotlin, GPL-3). Rebrand, restyle
  to Golem design language, keep plugin architecture. Distribute: F-Droid
  first (free, no gatekeeper), Play Store second ($25 one-time dev account).
- **Desktop**: `collectors/phone.rs` in options-engine + a small
  `golem-connectd` (or embed) speaking kdeconnect protocol v7/v8 (JSON
  packets, TLS, mDNS/UDP discovery on :1716). Rust has partial crates;
  mine Valent/mconnect for protocol details rather than trusting crates.
- **Surfaces**: phone pill (topbar), notif box integration, clipboard
  integration — all through the Mind, no hand-built side channel.
- **scrcpy** and **adb** ship as curated packages, wrapped by our UX.

## Constraints & honesty

- Google is hostile terrain: SMS/notification-access permissions get
  audited on Play; F-Droid keeps us uncensorable.
- iPhone is out of scope (Apple locks everything we'd need). Target says it:
  **Golem PC + Android phone** is the open ecosystem. That's the pitch.
- Roadmap placement: own workstream **W-A**, can start after S2 (the spine)
  since the phone collector *requires* the Brain↔Body wiring — one more
  reason the spine comes first. P1 is small enough to be an early win.

## Definition of done (per rung)
Paired in <1 min by a non-technical person · works on LAN with zero config ·
survives sleep/reconnect · every feature reaches the desktop THROUGH the
Brain (collector → Mind → surface) · phone battery cost negligible.
