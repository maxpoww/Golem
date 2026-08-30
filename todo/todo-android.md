# todo-android — W-A Golem × Android (see android.md; starts after S2)

## P1 — Presence
- [ ] Read the kdeconnect protocol docs + mine Valent/mconnect for details
- [ ] Fork `kdeconnect-android` (GPL-3, Kotlin); build it unmodified first
- [ ] Rebrand: name **Golem**, icon, Golem design language pass
- [ ] Desktop: `collectors/phone.rs` in options-engine (discovery + pairing
      + TLS; through the Brain, no side channel)
- [ ] Phone pill in the topbar (battery/signal) — first phone surface
- [ ] Notifications → OPTIONS notif box (+ dismiss/reply)
- [ ] Universal clipboard both ways (feeds the share-card pipeline)
- [ ] File send both ways; find-my-phone (ring)
- [ ] Pairing UX test: non-technical person pairs in under a minute
- [ ] Distribute: F-Droid first, Play Store second ($25 dev account)

## P2–P4 (break down on entry)
- [ ] P2: SMS/RCS, call relay, contacts sync, media control
- [ ] P3: scrcpy mirroring, phone-as-webcam, instant hotspot, proximity unlock
- [ ] P4: photo sync, shared OPTIONS surfaces, cross-device DND
