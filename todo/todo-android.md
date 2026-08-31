# todo-android — W-A Golem × Android (see android.md)

> Status 2026-08-31: built from scratch in Kotlin/Compose (NOT a kdeconnect fork —
> deliberate change from the original plan). Speaks KDE Connect protocol v8, interops
> with kdeconnectd 26.04 today. Repo: ~/AndroidStudioProjects/Golem (see its CLAUDE.md
> for protocol gotchas and test recipes).

## P1 — Presence ✅ DONE
- [x] Read the kdeconnect protocol docs + mine implementations for details
- [x] ~~Fork kdeconnect-android~~ → implemented the protocol from scratch instead
- [x] Rebrand: name **Golem**, icon (stone head, amber eyes), adaptive + monochrome
- [ ] Desktop: `collectors/phone.rs` in options-engine (discovery + pairing + TLS;
      through the Brain, no side channel) — NOT STARTED, kdeconnectd stands in for now
- [ ] Phone pill in the topbar (battery/signal) — desktop-side work; the data is
      already flowing (battery readable on desktop D-Bus)
- [x] Notifications → mirrored, with actions + inline reply (RemoteInput)
- [x] Universal clipboard both ways (phone→PC on focus; Android 10+ blocks background)
- [x] File send both ways (checksum-verified) + transfer progress; find-my-phone (ring)
- [x] Pairing with verification code, byte-identical to kdeconnectd
- [ ] Pairing UX test: non-technical person pairs in under a minute
- [ ] Distribute: F-Droid first, Play Store second ($25 dev account)

## P2 — Communication
- [x] SMS: conversation list, per-thread history, new-message push
      (send path implemented but UNTESTED — would text a real person)
- [x] Contacts sync (26 contacts land as vCards in kpeoplevcard; names/photos
      resolve in the desktop SMS app)
- [x] Media control both directions (phone media appears as native desktop MPRIS
      players; desktop players controllable from the phone UI)
- [x] Call notify (ringing / talking / missedCall + contact name resolution)
      — IMPLEMENTED BUT UNVERIFIED: PHONE_STATE is a protected broadcast, so it can
      only be tested with a real incoming call
- [ ] Call audio relay
- [ ] MMS/RCS, attachments (sms.attachment_file / request_attachment)

## P3 — Magic (Continuity tier)
- [ ] Phone mirroring via scrcpy wrapped in our UX
- [ ] Continuity camera (phone as webcam)
- [ ] Instant hotspot
- [ ] Proximity unlock
- [ ] Handoff v1

## P4 — Fusion
- [x] **Run desktop commands from the phone** (runcommand plugin) — the first
      "phone as a surface of the Brain" primitive; verified end-to-end
- [ ] Photo sync, shared OPTIONS surfaces, cross-device DND, app streaming polish

## Near-term polish
- [x] mDNS discovery (advertise + browse + resolve, unicast-identity nudge on find).
      NOTE: the Golem PC runs **no mDNS responder** (avahi/systemd-resolved both
      inactive), so this path is phone-side-only until avahi is enabled on the host.
- [ ] Album art payloads for media controls
- [x] Golem design language pass (amber-on-stone, matches the icon; dynamic color off)
- [x] systemvolume — desktop volume/mute/default-sink from the phone (verified;
      useful when the PC mutes itself and you're not at the keyboard)
- [x] remote input (phone as touchpad + keyboard) — phone side DONE and sending
      correctly, but **blocked on the desktop**: kdeconnectd needs the
      `org.freedesktop.portal.RemoteDesktop` portal, and xdg-desktop-portal-hyprland
      1.3.12 doesn't implement it (only Screenshot/ScreenCast/GlobalShortcuts).
      → `golem-connectd` should inject input via uinput/evdev instead; that also
      removes a dependency kdeconnectd can't satisfy on this WM.
- [x] Strip the exported SelfTestReceiver dev harness from release builds
      (moved to `app/src/debug/`; verified absent from the release APK manifest)
- [ ] **No version control yet** — the whole app is untracked; `git init` + first commit
- [ ] applicationId is still `com.example.golem`; needs a real id before F-Droid
- [ ] Runtime permission flow polish (SMS/contacts currently granted via adb)
