# actions-40.md — batch 01, the shipping register

*The full action blocks. Schema: conditions.md §2 (nine fields, in order). Source:
`actions-40-draft.md` §1 for the sentence and the verb, `slop-hunt.md` for every
repair, `cut-50.md` for each V-id's `ABSORBS:` list — which is spent here as gear
material, because an absorbed sibling is not a lost habit, it is a control in the
box.*

**The register is 34, not 40.** F6 drafted 39 (V08 killed on its verb, bench
empty); hunt #1 killed five more — **A06, A12, A22, A23, A30** — and those ids,
together with **A08**, are retired: they are gaps, never reused, never
renumbered, so the lineage stays stable across the file. Written in four units:
**unit 1 (this one) = A01 A02 A03 A04 A05 A07 A09 A10 A11** · unit 2 = A13–A21 ·
unit 3 = A24–A32 · unit 4 = A33–A40.

## The two system laws every `Fires` line below is written against

Ratified in `slop-hunt.md` §4, and they are the reason a block may not simply
assert its own frequency:

1. **THE DAY'S BUDGET — a priority queue, not a gate.** ≤3 action sentences a
   day, never two in an hour, one shared allowance. **Expiring moments** (their
   value dies with the moment) always speak and spend the allowance; **habit
   unlocks** wait, indefinitely and harmlessly, strongest evidence first, and
   never two in the same hour. Unspent allowance does not carry over; a day blown
   through by expiring moments alone tightens tomorrow to one.
2. **ONE MOUTH PER CLUSTER, with back-of-the-queue on refusal.** Where several
   actions fire on the same real-world moment, one speaks and the rest wait for
   the next occurrence; an answered member (yes or no) steps to the back, so each
   occurrence offers the best thing *not yet answered* and the cluster eventually
   falls silent. Clusters touched by this unit: **call start** (A28 > A04 > A03),
   **evening** (the sunset prototype + A38 > A11 > A20 > A40), **the silence
   family** (A04, A09, A17 — no more than one silencing offer a week).

A `Fires` line the queue would not actually permit is a fiction, and hunt #2
(§7.3) is instructed to kill it.

## The three conditions discharged in this unit

Hunt #1 §6 left five conditional survivors; three of them live in this unit and
each is discharged **inside its own block**, in writing, against the real tree:

- **A02** — the clipboard box **cannot** pin an entry today; its footer's only
  durable-store affordance is a dead stub (`ClipHit::NewNote` → *"editor not yet
  wired"*, `clipboard.rs:3153`, GRIND.md, MAX-GATED design call). P5 read that as
  "no durable store exists" and tagged the verb **[new]**; **hunt #2 corrected it to
  [cheap]** — the box already persists every row to `clipboard-history.json`
  (`clipboard.rs:225`, `save_clip_history()` `:1573`, rolled at `MAX_HISTORY`
  `:1201`/`:1437`), so what is missing is a `pinned` flag and a truncation skip, not
  a store. **The register therefore carries two [new] verbs, A29 and A37.** The
  sentence still does not ship until the flag does.
- **A03** — the portal distinguishes the two shares, but **Golem is not a party to
  the exchange**. Action specified in full and **dormant**; the unblock is [cheap]
  work on Golem's *own* portal. Full reasoning in the block.
- **A10** — **a standing form exists** and is now the first offer, per hunt
  doctrine 3. Block carries it; hunt #2 §7.2 checked it rather than killing it —
  and then attacked the *evidence* instead and **relocated it** to the user's own
  hand-cornering gesture, because the alternation P5 counted licenses two opposite
  verbs. See the block, and hunt #2 §2.3.

---

### A01 — the rogue sound
*(V01 U0003 T0004 S0017 H0017) · browsing*

- **Type:** moment
- **Trigger & evidence:** a browser MPRIS player transitions to `is_playing`
  **while its window has already been unfocused for ≥10 s** — `media.is_playing`
  **[live]** and `window.class/address` **[live]** (the media and hyprland
  collectors, catalog §0), plus **the time since that address last held focus,
  which is [cheap] — hunt #2's correction, and it is the load-bearing half.** The
  drafted citation was `behavior.focus_switch_velocity`, and catalog §0 defines
  that field as *window switches per second (churn)*: a rate over all windows, not
  a per-window stopwatch, so it cannot answer "has **this** window been out of
  sight for ten seconds" and tagging the clause [live] on its back was a tag
  attached to the wrong mechanism. The real one is a level deeper in a collector
  that already runs: the engine's hyprland collector keeps a `FocusTracker` which
  already records focus instants in order to compute that very velocity
  (`collectors/hyprland.rs:157–176`), so the ≥10 s test is one more value read out
  of a structure that exists — no new sensing, no new wakeup, no clock of its own.
  The ≥10 s clause is hunt #1's
  repair and it is the whole action: as drafted ("playing while unfocused") the
  trigger was music in a background tab, the single most common media pattern in
  existence, and Golem would have spoken daily about audio the user started on
  purpose. What is sensed here is *sound that began out of sight* — Constitution
  III's specificity requirement, the same clause that forbids "a USB was
  inserted". No counter, no history: the unfocus stopwatch is live context, and
  it is read from events that already arrive, never sampled on a clock.
- **Sentence:** "The sound is coming from your browser, do you want it muted?"
- **Verb(s):** **[mute it]** — `wpctl set-mute <the browser's stream node> 1`; the
  audio collector already enumerates pipewire nodes via `pw-dump`, so resolving
  player → node is **[cheap]**, no new dependency. **[show me]** — `hyprctl
  dispatch focuswindow address:<addr>` **[live]**. Honest limit, carried from F5
  and unrepaired because the sentence already tells the truth: MPRIS and pipewire
  resolve to the **player**, not the tab, so [mute it] mutes the browser and the
  user finishes the job — the sentence says "your browser", never "that tab".
- **Refusal:** right-click = not now, and this player's current playback is
  finished as far as Golem is concerned — no re-offer until a *new* out-of-sight
  playback start. Three refusals and the action retires itself permanently (a user
  who wants background audio has told us three times).
- **Gear:** (a) what [mute it] takes — **this stream** / the whole browser;
  (a) **also offer for any app, not just browsers** — off by default, the home for
  the absorbed U0042 (the thing that suddenly blares is not always a tab);
  (b) how long out of sight counts (default 10 s); (c) don't show this again.
- **Ladder:** assisted = this one sentence. Automatic = *"mute anything that starts
  playing out of sight"*, offered only after two accepted mutes — and deliberately
  NOT the default, because the automatic form silences a thing the user may have
  started deliberately from a keyboard shortcut. This is one of the few actions
  where the hand is better than the rule, and the gear says so.
- **Privacy note:** nothing about the sound is stored. At rest: the shared
  lifecycle row every action has — id, last-offered day, answer, refusal count,
  **and an accept count (u8)** — **≈32 B**. *(The accept count is hunt #2's
  amendment to the shared row, made here because A01 is where the row is defined
  for the whole batch: a dozen blocks offer their automatic rung "after two
  acceptances", and a row that remembers only refusals cannot tell the second yes
  from the first. One byte, inside the same ≈32 B, and it is the only counter in
  the batch that exists to make Golem stop talking.)* No titles, no artists, no
  per-site anything; the player's identity is
  read live at offer time (F4 doctrine 1, name-at-offer-time) and dropped.
- **Fires:** expiring moment, queue rank 1 — when it fires it speaks and spends
  one of the day's three. Honest frequency with the ≥10 s clause in place: **a few
  times a month**, not daily — an autoplaying ad in a tab left open, a video that
  reaches the next item in a playlist, a page restored at launch. Days with none
  are the normal case, which is exactly why it is allowed to interrupt when it
  happens.

---

### A02 — the answer you keep typing
*(V02 U0015 T0018 S0061 H0075) · communication*

- **Type:** habit
- **Trigger & evidence:** the same clipboard content — compared as a **hash**,
  never held as text — appears on the selection stream on **≥3 separate days**.
  `selection.*` is **[live]** (wl-paste, catalog §0); the day-bucketed hash counter
  is **[cheap]**. Three *days*, not three pastes: a copy repeated twice in one
  editing session is one act, and only recurrence across days demonstrates a
  standing answer rather than a task.
- **Sentence:** "You have copied this same text on three different days, do you
  want it kept as a snippet?"

  *(Drafted and written as "you have **pasted** this same text"; changed by hunt
  #2 under the V08 rule, not the voice pass. Golem is a clipboard **watcher** — the
  `selection.*` stream carries offers, i.e. copies — and the block's own trigger
  says so. Which application asked for the data, and when, is knowledge only the
  clipboard's owner has; it is the identical limit that forced A15's evidence to be
  relocated, three blocks down, and A02 must not claim on its face what A15 proves
  cannot be seen. A sentence whose verb-tense outruns the sensor is the prose form
  of a restated condition: nothing in the trigger is wrong, only the word.)*
- **Verb(s):** **[keep it as a snippet]** — writes the live clipboard content into
  the clipboard box as a **pinned row**, retrievable forever at one keystroke.
  **Tag: [cheap] — hunt #2's correction, and it moves a headline number.** P5 wrote
  **[new]** here on the strength of a dead **"New note"** button (`ClipHit::NewNote`
  is a debug-log stub, *"editor not yet wired"*, `clipboard.rs:3153`) and an open
  MAX-GATED note-editor call in GRIND.md, and concluded that **no durable store
  exists behind the box today**. That conclusion is false against the tree. The
  clipboard module already persists its history: `HISTORY_FILE =
  "clipboard-history.json"` (`clipboard.rs:225`), written by `save_clip_history()`
  (`:1573`) from five call sites, loaded back on start, and rolled at `MAX_HISTORY`
  by two truncations (`:1201`, `:1437`). Every clip the box shows is already a row
  in a file Golem writes. What is missing is therefore not a store but
  **permanence**: a `pinned: bool` on a row that is already serialised, and a skip
  for pinned rows at those two truncation sites. That is small work in our own
  tree, which is what [cheap] means in the catalog's legend — the same shape as
  A21's sibling penalty map beside `usage.json`, and the two cannot honestly carry
  different tags. What does **not** change: the flag still has to be written, so
  the sentence still promises retrieval the surface cannot yet perform, and by the
  V08 rule the action **does not speak until it ships** (`Fires` unchanged at
  zero). What changes is the batch's ledger: **the register carries TWO [new]
  verbs, A29 and A37, not three** — recorded here for P9's SUMMARY, and
  `implementation.md` ¶2's "three [new] verbs A02/A29/A37" needs the same one-word
  correction. The note editor stays MAX-GATED and is not needed for this verb.
- **Refusal:** not now = this clip is done; its hash is marked answered and it
  never comes back, however often it recurs. The action itself stays alive for
  other clips, but a second refusal (a different clip) retires snippets entirely —
  the user has said twice that they do not want a snippet store.
- **Gear:** (a) where it goes — the clipboard box's pinned rows (and, once it
  exists, the note file); (b) how many separate days before offering (default 3);
  (b) **never offer for anything copied while a vault is focused** — on by default,
  the same provenance flag A36 uses, so a password can never become a snippet;
  (c) forget this clip / don't offer snippets again.
- **Ladder:** assisted = this clip, kept once. Automatic = *"keep anything I copy
  on three separate days"*, offered only after two accepted snippets — and the
  automatic form is the one place a content store could grow without the user
  watching, so it is opt-in, capped, and listed in the notebook with a per-entry
  forget button.
- **Privacy note:** per tracked clip, at rest: an 8-byte content hash, a day count
  (u8) and a last-seen day index (u16) — **11 B**, in a ring capped at 64 clips,
  **≈700 B total**, overwritten oldest-first. **No clipboard text is ever
  written to disk by the detector.** Text is written only when the user accepts,
  and at that moment it stops being an observation and becomes user-authored
  config the notebook can show and delete (Constitution VI.2 and VI.5).
- **Fires:** **one sentence, ever** — and **zero until the pinned row ships**
  (the flag and the two truncation skips named in the verb line; [cheap], not
  [new], but not yet written). A habit unlock: it waits for a free slot in the day's queue,
  indefinitely and harmlessly, because the hash counter is an aggregate that keeps
  counting while it waits.

---

### A03 — the audience
*(V03 U0023 T0026 S0073 H0093) · communication*

- **Type:** moment — **specified and DORMANT; see the verb line.**
- **Trigger & evidence:** a screencast starts **and is a full-output share**.
  Hunt #1's repair is the second half of that sentence and it is load-bearing: if
  the user is sharing a single window — the common case in a call — the other
  windows are not visible to anyone, "tuck the rest away" is noise, and at worst
  it hides the window they were about to share next.
  **The condition, discharged:** on today's engine the share signal is one boolean
  and it is not even fed — catalog §0 lists `is_screencasting` as *spec'd, not all
  fed* (**[partial]**), §1.7 repeats it, and the only shipped surface is the amber
  screencast warning pill (catalog §4.15). The distinction *does* exist in the
  protocol: a ScreenCast client names what it wants in `SelectSources`
  (monitor / window / virtual) and, from ScreenCast v2 onward, the portal may hand
  back a `source_type` on each stream. But that exchange is a private session
  between the sharing application and the portal, and **Golem is neither party**.
  Reading it would mean becoming a D-Bus monitor on another program's session:
  **[new]**, privileged, and precisely the surveillance posture Constitution VI is
  built to make structurally impossible. The one heuristic available from our own
  side — compare the cast stream's video size against the hyprland monitor list —
  collides exactly where it matters, because a fullscreen window share carries a
  monitor's exact pixel size. **So the action waits rather than guessing**, which
  is what hunt #1 instructed.
- **Sentence:** "Your whole screen is being shared, do you want the rest of the
  windows tucked away until it ends?" *(the drafted sentence said "your screen";
  "your whole screen" is the repair made audible — the sentence now names the
  scope it is conditioned on, doctrine 5.)*
- **Verb(s):** **[tuck the rest away]** — `hyprctl dispatch movetoworkspacesilent
  special:aside,address:<addr>` for every non-shared window, reversed when the cast
  ends **[live]**. The verb has been shippable all along; the *trigger* is what is
  missing. **Unblock, stated so it is actionable rather than aspirational:**
  xdg-desktop-portal-hyprland is **Golem's own component**, not a foreign app — the
  portal holds the source type in its hand at `Start` time and need only publish it
  alongside the existing screencast state. That is **[cheap]** work on our own
  house, and doctrine 6 ("when an app owns the behaviour, flip the app's switch")
  applies to ourselves first. Until it lands, the trigger's output-share test never
  returns true and **A03 never speaks**.
- **Refusal:** not now = silent for the whole of this cast, and the cast is the
  unit — no second offer when a window is added or removed. A refusal also sends
  A03 to the back of the call-start cluster, so the next share offers whatever in
  that cluster is still unanswered. **Two refusals retire it permanently** —
  hunt #2's addition: per-cast silence is not escalation, and Constitution IV
  requires repeated refusals to walk toward silence rather than merely reset. A
  user who has twice declined to hide their windows has told us what their audience
  is allowed to see.
- **Gear:** (a) bring them back when the share ends (on by default); (a) tuck to
  the special workspace / minimise; (b) never tuck these classes — the exception
  list, so the chat window or the notes the user is presenting *from* stay put;
  (c) don't show this again.
- **Ladder:** assisted = this share. Automatic = *"tuck the rest away whenever I
  share the whole screen"*, offered after the second acceptance. The automatic form
  is unusually safe here because it is self-reversing: the windows come back when
  the cast ends, so the worst case of an unattended rule is a tidy desk.
- **Privacy note:** nothing is stored. Not the fact that a share happened, not its
  duration, not what was shared — the action is a pure function of live state plus
  the **≈32 B** lifecycle row. This is the batch's cleanest privacy footprint and
  its only *privacy-positive* action: its entire job is keeping the user's other
  windows off an audience's screen.
- **Fires:** **zero today.** Once the portal publishes source type: an expiring
  moment at queue rank 1, **≤1 per full-output share**, and at call start it yields
  to A28 and A04 by the cluster order — so on a day with a call and a share, A03 is
  the third mouth and usually does not get to speak at all until the two above it
  have been answered. In steady state, for a user who shares their whole screen a
  few times a week: **~1–2 sentences a week, most weeks fewer.**

---

### A04 — quiet the desk
*(V04 U0024 T0027 S0074 H0094) · communication*

- **Type:** moment
- **Trigger & evidence:** `audio.is_mic_active` goes true and stays true past a
  short floor (default 5 s, so a mic test or a blip is not a call) — **[live]**,
  the audio collector, and already the engine's dominant activity signal (catalog
  §0, §1.7). No evidence counter: the world did something specific and unambiguous.
  **How the floor is evaluated, because hunt #2 asked and the answer must not be a
  timer:** the audio collector already runs a 2 s heartbeat alongside its `pw-mon`
  change signal (`collectors/audio.rs:28`, `:121` — *"the heartbeat stays because
  `pw-mon` is a signal, not a"* poll), so "still live at the third heartbeat" is the
  floor, read off wakeups that happen whether or not this action exists. Every other
  interval in this unit is settled at the moment a second event arrives (A01's
  unfocus stamp, A19's 60 s window, A21's 15 s close); A04 is the one place where
  nothing further arrives, and the existing heartbeat is the reason it still owns no
  clock (Constitution VI, discipline 2).
  Hunt #1 kept this one clean and called it the closest sibling to the sunset
  prototype in the batch — specific trigger, reversible verb, cheap refusal.
- **Sentence:** "Your microphone just went live, do you want your desk quiet?"
- **Verb(s):** **[quiet my desk]** — one pill, two effects: notifications held via
  the shipped `audio.call_dnd` daemon action (catalog §4.14, and §4.17 proved the
  same `AffordanceAction::Daemon` path end to end by flipping the notif-state
  `muted` false→true→false), plus `playerctl pause` if anything is playing
  (absorbed U0043). Everything is restored when the mic goes inactive — the verb
  owns its own undo, which is why it can be one click. **Provenance is set here:**
  the queue A04 holds is flagged as *held by Golem*, and that flag is the only
  thing that ever licenses A05 to speak.
- **Refusal:** not now = silent for this call, and A04 goes to the back of the
  call-start cluster so the next call offers whatever is still unanswered there
  (A28's codec repair, or A03 once it wakes). Two refusals retire it: someone who
  wants their desk loud during calls has said so twice.
- **Gear:** (a) what "quiet" includes — hold notifications / pause playback /
  **open a scratchpad for call notes** (the absorbed U0116: notes-during-calls
  belongs in this box, never in its own sentence); (b) how long the mic must be
  live before this counts as a call (default 5 s); (b) **also quiet the desk at the
  hour a call starts most days**, without waiting for the mic — off by default, the
  home for the absorbed U0017 (the recurring standup); (c) every time / ask each
  time / never.
- **Ladder:** assisted = this call. Automatic = *"quiet my desk whenever the mic
  goes live"* — and the automatic form is **the whole value of this action**: once
  signed, A04 stops speaking permanently and the calls simply arrive quiet. The
  offer to graduate is made on the second acceptance, not the first, so the user
  has seen the undo work before they sign a standing rule.
- **Privacy note:** nothing at rest but the **≈32 B** lifecycle row, plus — only if
  the user turns on the standup control — a 24-slot hour histogram of call starts,
  u8 counts, **24 B** *(P5 wrote ≈48 B, which implies u16 buckets; the batch's other
  two hour histograms, A11's and A17's, are u8 at 24 B, and an hour that saw 255
  call starts is not a number anyone needs exactly — hunt #2 makes the three
  identical so the batch's at-rest arithmetic adds up in one width)*, counts only,
  no durations (F4 doctrine 2: no stopwatch over anything,
  and a call length is a fact about a conversation). Nothing about who called, what
  app, or what was said; the mic is sensed as a boolean and nothing else.
- **Fires:** in the assisted phase, **≤1 per call**, and the call is one mouth: A04
  and A05 are a single cluster member until the standing form is signed, so a call
  that hears A04 does not also hear A05. As a member of the silence family it is
  further capped at **one silencing offer a week** across A04/A09/A17. Once
  graduated: **zero, forever.** The action is designed to talk itself out of
  existence.

---

### A05 — the hand-back
*(V05 U0026 T0029 S0076 H0097) · communication*

- **Type:** moment
- **Trigger & evidence:** `audio.is_mic_active` goes false after a long live
  stretch, `notifications.active_count > 0`, **and Golem itself is holding the
  queue it silenced** — both signals **[live]** (catalog §0). The third clause is
  F6's provenance guard and it is not decoration: the `active_count` test is
  necessary and nowhere near sufficient. If A04 was refused, or its standing form
  is off, **Golem silenced nothing and therefore owes nothing** — that is F5
  doctrine 4, the hand-back rule, and it is the reason "here is what arrived
  overnight" was killed while this survived.
- **Sentence:** "Your call is over, do you want to see what I held back?"
- **Verb(s):** **[show me]** — releases the held queue into the notifications box
  that already ships (`optionsmodules.md`: notifications is a live module) and opens
  it on exactly those entries, newest last. It shows *what Golem held*, not the
  day's unread — the difference is the whole action, and the box is scoped to the
  provenance flag A04 set.
- **Refusal:** not now = the queue is released silently into the bell, where it
  behaves like ordinary unread. Nothing is lost by refusing, which is the property
  that makes the refusal genuinely free (Constitution I.4). No re-offer for that
  call, ever — **and a second refusal, necessarily on a later call, retires the
  action permanently** (hunt #2's addition, the same gap A03 had: "silent for this
  occurrence" is a reset, not an escalation). Paired with the first-yes graduation
  in the ladder, this bounds A05 at two sentences in a machine's life in either
  direction, yes or no.
- **Gear:** (a) show the held queue as a list / just open the bell; (b) only after
  calls longer than N minutes (default 5 — a two-minute call holds nothing worth a
  sentence); (c) release quietly from now on, never ask again — the absorbed U0119
  (DND ends with a queue waiting) lives here as the "quiet release" setting rather
  than as a second action.
- **Ladder:** assisted = this sentence. Automatic = *"always open what you held when
  a call ends"*, **offered on the FIRST yes** — hunt #2's repair, and it is the same
  one hunt #1 made to A09 for the same reason, applied here because A05 is the
  batch's only action whose trigger can recur several times in one day for years.
  A05 is an expiring moment, so under the ratified queue it speaks ahead of every
  habit unlock and spends the allowance; a user with three calls a day would have
  A05 eat all three slots daily and, by the budget's own tightening clause, leave
  tomorrow at one — a permanent famine for every other action in the register,
  caused by the one action whose answer never changes. Graduating on the first yes
  converts the recurrence into silence after a single sentence. Note
  the inversion worth recording for `implementation.md`: A05's automatic form is a
  **surface** that opens, not a change to the world — the safest kind of standing
  rule, since its worst failure is a box the user closes.
- **Privacy note:** nothing at rest. The held queue lives in the daemon's memory
  for the duration of the call and dies with it; the provenance flag is a boolean
  on that in-memory queue. Notification *contents* are never persisted by this
  action — they were already on the user's screen, they belong to the sending app,
  and Golem is a doorman, not an archive. **≈32 B** lifecycle row, and that is all.
  One clarification hunt #2 required, because A04's note forbids the stopwatch in
  so many words: the gear's "only after calls longer than N minutes" is measured
  **live, in memory, between the two mic transitions**, and dies with the call.
  F4 doctrine 2 forbids a duration reaching **disk**, where it would become a diary
  of how long the user talks; a length that exists for one comparison and is never
  written is the same thing as no length at all.
- **Fires:** **zero while A04 is still asking** — the call is one mouth and A04 has
  it. After A04's standing form is signed, A05 becomes the call's only sentence:
  **~1 per call with a non-empty held queue**, expiring, queue rank 1 — but **at
  most twice in a life**, because the first yes graduates it and a second no
  retires it. That bound is the repair in the ladder above, and it is the only
  thing that makes the honest frequency printable: without it, a three-call day
  spends the whole allowance on one action and tightens tomorrow to a single
  sentence, every day, forever. With it, the third call of any day is answered by
  the bell's own count, which was always enough.

---

### A07 — pause when I step away
*(V07 U0044 T0049 S0109 H0136) · media*

- **Type:** habit
- **Trigger & evidence:** a **manual pause** followed within seconds by the session
  going idle, **≥3×** across days. `media.is_playing` transitions are **[live]**
  (MPRIS, catalog §0); the idle half is **[cheap] and must be declared honestly:
  idle is not among the engine's nine collectors** — it needs a small new source,
  and hunt #2 narrows which one, because P5 wrote "logind's `IdleHint` **or** the
  compositor's idle-notify" and only the second half is true on a stock Golem.
  `IdleHint` is set by whatever manages the session; nothing in the tree sets it
  (there is no `hypridle`, no `swayidle`, no idle client of any kind — the same
  absence A26 and A33 are dormant on), so a detector reading it would read a
  property that never moves. The compositor's `ext-idle-notify-v1` is the opposite
  case: Hyprland itself is the source, an idle daemon is merely another client of
  it, and the launcher is already a Wayland client, so the work is one protocol
  subscription in a process that is already connected. Event-driven either way, so
  **no detector owns a timer** (Constitution VI, discipline 2) — but only one of
  the two ever fires. *(Handed to hunt #2 unit 2: if the idle **source** is the
  compositor rather than a daemon, A26's and A33's "dormant on an absence" may be
  describing the absence of the wrong thing. Rule on it there; A07 does not
  presume the answer, it only declines to cite the half that cannot work.)* The evidence is a chosen
  act every time: nobody is forced to pause before standing up (hunt doctrine 1).
- **Sentence:** "You pause before you step away from the desk, do you want me to do
  that part?"
- **Verb(s):** **[pause when I step away]** — installs the standing rule: on
  idle-entered, `playerctl pause` if something is playing. **Never auto-resume** —
  returning to a room that starts talking at you is worse than returning to
  silence, and the resume stays the user's hand. Per hunt doctrine 3 the rule *is*
  the first offer; the one-time "pause it now" form is not offered, because the
  user's own three repetitions already climbed that rung.
- **Refusal:** not now = the rule is not written and the action retires for **90
  days**, not forever — a habit demonstrated three times is likely to be
  demonstrated again, and this is one of the few offers where a user's "no" often
  means "not on this machine, this month". One further refusal retires it
  permanently.
- **Gear:** (a) which players it applies to — all / just this class; (b) how long
  idle counts as away (defaults to the session's existing idle timeout, never a
  timer of its own); (c) revoke the rule.
- **Ladder:** the assisted rung was climbed by the user's hands (three manual
  pauses), so this action opens on the standing rule. The rung *above* it — pausing
  on screen-lock as well as idle — is offered only if the user locks manually while
  playback runs, which is a different habit with its own evidence.
- **Privacy note:** at rest, one counter per player class: a u8 coincidence count
  and a u16 last-seen day, **3 B per class**, capped at 16 classes — **≈48 B**. No
  titles, no artists, no timestamps, nothing about what was watched or for how long
  (F4 doctrine 2 forbids the stopwatch, and here it is not even wanted: the
  detector needs a coincidence, not a duration).
- **Fires:** **one sentence, ever.** A habit unlock: it waits for a free slot,
  indefinitely, and never shares an hour with another unlock. In practice it
  arrives somewhere in the first month, on a quiet day.

---

### A09 — game mode
*(V09 U0060 T0066 S0138 H0169) · media*

- **Type:** moment
- **Trigger & evidence:** a window whose class is in the game set goes fullscreen —
  `window.class` + `window.is_fullscreen`, **[live]**, and the shipped
  `window.fullscreen_dnd` affordance (catalog §4.17, confirmed end to end in the
  VM) is this verb's floor. **And "the game set" is a real object, which hunt #2
  had to go and check, because a predicate nobody can name is a restated condition
  wearing a signal's clothes:** the engine already ships the list. `mind/activity.rs`
  carries a games/launchers/emulators class table (`:289–295` — `gamescope` and the
  emulators among them) and the classifier deliberately checks it **before** the
  file-manager table so that `dolphin-emu` is never mistaken for KDE's `dolphin`
  (`:118`, `:486`, `:693`). The set is therefore neither observed nor invented
  here; it is read from the module that already answers "what kind of thing is in
  front of you", and the only new work is asking it at the fullscreen transition.
  **[live]**, no new sensing. The class is read live at the moment it happens; no
  library, no play history, nothing about *which* game or for how long (F4 doctrine
  2 — duration of pleasure is nobody's business, and the absorbed U0059, the
  recurring evening game hour, is deliberately **not** stored as an hour histogram
  for that reason).
- **Sentence:** "A game just took the screen, do you want game mode?"
- **Verb(s):** **[game mode]** — notifications held (the same daemon DND action
  proven at §4.17) **+** `powerprofilesctl set performance` **[cheap]** (the
  absorbed U0153, the manual profile switch). Both restored on exit from
  fullscreen, automatically, by the same code path that set them.
- **Refusal:** not now = silent for this game class **permanently** — a user who
  does not want notifications held during *this* game will not want it next
  Tuesday either. Other game classes still get one offer each, and A09 steps to the
  back of the silence family, so A04 or A17 gets the week's silencing slot instead.
- **Gear:** (a) what game mode does — hold notifications / performance profile (two
  switches, both on); (b) which classes count as a game — **the shipped
  `activity.rs` table, shown and extendable**, because a class list is the only
  part of this that can be wrong, and a user's own game is exactly what a list
  written in advance will miss;
  (c) ask each time / always / never for this class.
- **Ladder:** assisted = this launch. Automatic = *"game mode whenever a game takes
  the screen"*, **offered on the first yes, not the fifth** — this is hunt #1's
  repair and without it A09 was a recurring speaker whose answer never changes,
  asking at every launch forever. After a yes it graduates and goes silent; after a
  no it waits for a different game class.
- **Privacy note:** at rest, a hash of each answered game class plus its answer —
  **9 B per class**, capped at 16, **≈144 B**. Hashes, so the disk never holds a
  readable list of what the user plays; the name in the sentence is read live from
  the focused window (F4 doctrine 1). No launch counts, no session lengths, no
  hours.
- **Fires:** **at most once per game class**, and as a silence-family member it may
  wait weeks behind A04 for the week's single silencing slot. Realistically **one
  or two sentences in the machine's life** for a gamer, **zero** for everyone else
  — which is the ideal shape for an action: invisible to the people it is not for.

---

### A10 — keep it on top
*(V10 U0065 T0072 S0146 H0183) · media*

- **Type:** habit
- **Trigger & evidence:** **RELOCATED by hunt #2, and the relocation is the action
  now.** P5's evidence was the alternation — pause → focus to a terminal or editor
  → resume, ≥3 cycles in one session — and that evidence does not license this
  verb. What the user demonstrated is *pausing*; what the pill offers is *not
  pausing*, with the video running in a corner instead. Both readings of the
  alternation are available from the same signal — "I want to see it while I type"
  and "I must not miss it, so I stop it" — and the block picked one, which is F5
  doctrine 5 exactly: sense the state, never impute the motive. It is also the
  hazard Constitution III names, an offer that guesses what the user might want
  instead of describing what they do. The unambiguous gesture is the one the
  absorbed sibling U0048 already names — **the user putting a playing player into a
  corner by hand** — and it is sensable on code that already runs: `changefloatingmode`
  is in the engine's own subscribed event set (`collectors/hyprland.rs:326`, and in
  the daemon's list at `hypr.rs:39`), and `is_floating` is already parsed into
  context state (`:257`, `:296`). So the trigger is: a **standalone player**
  (mpv, vlc, celluloid, …) is playing, the user floats it and sizes it small while
  focus then moves to a terminal or editor, **≥3× across days** — `media.*` +
  `window.class/address` + `is_floating`, all **[live]**; the corner-ness of the
  geometry is one more field out of the `j/clients` inventory the engine already
  queries (**[cheap]**, and `pinned` is the field it does not parse yet).
  The alternation P5 counted **stays in the block as a strengthener** — it is what
  makes the corner worth offering rather than merely possible — but it no longer
  licenses the sentence on its own. *(Hunt #1 §7.2 told hunt #2 to re-test A10
  without mercy if P5 gave it no standing form. P5 gave it one, so the standing-form
  condition is discharged; this is a different and later attack, and A10 survives it
  as a **conditional survivor**: if unit 2's sweep finds the float gesture is not
  really on the wire, the relocation is a fiction and A10 is the first block struck.)*
  The class restriction is hunt #1's repair, and it is the same
  treatment A24 gets for the charge threshold: MPRIS resolves to the player, not
  the tab, so if the video is a browser tab then "pinned in a corner" would pin the
  entire browser window — not what the sentence promises. **Where the player is a
  tab, this action does not exist.**
- **Sentence:** "You put the player in the corner yourself when you go back to
  work, do you want it to go there on its own?"
  *(Drafted as "…do you want it pinned in a corner?"; P5 rewrote it to offer the
  rule rather than the instance, per hunt doctrine 3, and kept the alternation as
  its subject — "you keep going back and forth between the video and your work".
  Hunt #2 changed the subject, not the register: the sentence now names the act the
  user performed, which is the only thing the relocated trigger can see and the
  only thing Constitution III lets an offer describe. Voice unchanged — a fact
  about what the user does, stated without evaluation, one sentence.)*
- **Verb(s):** **[keep it on top]** — and this is the discharge of hunt #1's
  standing-form condition, which §7.2 was told to kill the action over if it came
  back unanswered. **The standing form exists and is now the first offer:** while a
  standalone player of this class is playing and focus leaves it, the daemon
  floats it, sizes it to a corner box and pins it (`hyprctl dispatch setfloating` /
  `resizewindowpixel` / `pin`, all **[live]**); refocusing the player, or playback
  ending, puts it back exactly as it was. Doctrine 2 is satisfied twice over — the
  per-instance act is three dispatches, not one keybind, and the offer is not the
  per-instance act at all. The absorbed siblings are the shape of the box: U0008
  (the how-to video), U0048 (the manual picture-in-picture) and U0176 (the
  always-on-top window the whole day is arranged around).
- **Refusal:** not now = silent for this player class for **60 days**; the cycle
  counter keeps counting, so if the habit is real the second offer arrives with
  stronger evidence. A second refusal retires the class permanently.
- **Gear:** (a) which corner, and how big; (b) which players — the observed
  standalone classes, editable, browsers explicitly absent and the box says why;
  (b) only while something is actually playing (on by default, so a paused player
  does not squat in the corner); (c) revoke the rule.
- **Ladder:** the user's own three corner-ings were the assisted rung — the rule is
  the first offer (doctrine 3), and after the relocation that is literally true
  rather than argued: the hand has already done this exact thing three times.
  Above the rule: *"and
  keep it on top on every workspace"*, offered only if the user is seen dragging
  the pinned player between workspaces — a different habit, its own evidence.
- **Privacy note:** at rest, per standalone-player class: a u8 count of
  **hand-cornered playbacks** (the relocated evidence), a u8 day count, a u16
  last-seen day — **4 B per class**, capped at 8 classes, **≈32 B**. The
  within-session alternation that strengthens the offer is a memory-only figure and
  dies with the session, so the relocation costs nothing at rest and stores a
  gesture instead of a rhythm. Nothing about the video: no title, no URL, no duration.
- **Fires:** **one sentence, ever, per player class** — practically once. A habit
  unlock in no cluster, so it waits only on the day's budget and the
  no-two-unlocks-in-an-hour rule.

---

### A11 — the whisper cap
*(V11 U0066 T0073 S0147 H0184) · media*

- **Type:** habit
- **Trigger & evidence:** playback **starting quiet** after a recurring late hour,
  on **≥3 nights** — `media.is_playing` transitions + `audio.default_sink_volume` +
  the clock, all **[live]** (catalog §0). **What "quiet" means, because P5 wrote
  "the bottom decile" and hunt #2 could not find the distribution it is a decile
  of:** a threshold that ranks a volume against the user's own habits needs those
  habits stored, and the block stored only an hour histogram — so the word was a
  restated condition, true-sounding and unsupported. Defined here instead, in the
  shape the verb already needs: the detector keeps **two ten-bucket histograms of
  the sink volume at playback start**, one for all starts and one for starts after
  the late hour (u8 counts, 10 B each), and "quiet" is a late start falling below
  the median bucket of the all-day one. Comparative, so it works for the person who
  lives at 20 % and the person who lives at 80 %; aggregate, so no night is
  recoverable; and the same store yields the verb's "observed low level" instead of
  a second number invented for it. What is counted is the *start*, not the listening: no stopwatch runs over
  the evening (F4 doctrine 2), and the detector is a pure function over events that
  already arrive.
- **Sentence:** "You keep the volume low at this hour, do you want it to start out
  quiet after midnight?"
- **Verb(s):** **[start quiet after midnight]** — hunt #1's repair, and the verb
  label is the repair: the drafted "[keep it quiet after midnight]" **capped** the
  sink, and a cap is a ceiling that fights the user on the night they want it loud.
  Enforcement is not a register Golem has. What ships is a *starting point*:
  playback that begins after the hour starts at the user's own observed low level
  (`wpctl set-volume`), once, and **any manual change wins immediately and
  permanently for that session** — Golem does not touch the volume again until the
  next night. The sentence and the verb now say the same thing, which is what
  doctrine 5 asks.
- **Refusal:** not now = silent for **30 nights**, then one more offer if the
  evidence is still accumulating; a second no retires it. The evening cluster's
  back-of-queue rule applies, so a refusal also lets A20 or A40 have the next
  free evening.
- **Gear:** (a) the starting level — the user's own observed level, editable;
  (b) when the quiet hours begin and end (default midnight → 08:00, both moved
  together so the box stays one control); (b) which outputs it applies to —
  speakers only by default, so plugging in headphones does not inherit a level
  chosen for a sleeping household; (c) revoke the rule.
- **Ladder:** the three nights were the assisted rung; the rule is the first offer
  (doctrine 3). The rung above — *"and lower it when the headphones come out"* —
  belongs to A27's device-routing box, not here, and is deliberately not offered:
  one verb, one action.
- **Privacy note:** at rest, a 24-slot hour histogram of *quiet playback starts*
  (u8, **24 B**), the two ten-bucket volume histograms the trigger defines (u8,
  **20 B**), and a u16 last-seen day. **≈47 B** — up from the ≈28 B P5 claimed,
  because the threshold that was doing the work without being stored now is.
  Counts by hour and by bucket, never timestamps: the disk can say
  "late starts are usually quiet", it cannot reconstruct a single night. Nothing
  about what was playing.
- **Fires:** **one sentence, ever** — and it waits for the first evening the
  **sunset mouth is free**, because the evening cluster ranks the live sunset
  prototype (with A38 riding it) above A11. In practice that is the first evening
  after the prototype has been answered and stands, so **days to a couple of weeks
  after the third night of evidence**. Waiting costs nothing: the histogram keeps
  counting, and the offer is no less true a fortnight later.

---

### A13 — the short name
*(V13 U0093 T0100 S0204 H0283) · coding*

- **Type:** habit
- **Trigger & evidence:** the same command string — hashed, never held as text —
  typed at a prompt on **≥3 separate days**. The shipped zsh bridge already sends
  every command: `system/home/zsh.nix` posts
  `{"kind":"shell","last_cmd":…,"exit_code":…,"cwd":…}` down
  `$XDG_RUNTIME_DIR/options/bridge.sock` on `precmd` (catalog §4.11) — **[live]**,
  and the detector is a pure function over messages that already arrive. Two
  filters that are part of the trigger, not the gear: only commands over a length
  floor (default 24 characters — nobody wants an alias for `git`), and only
  commands that **exited 0**, because an alias for a typo is a trap with a name on
  it. Three *days*, not three runs: five retries in one session are one act.
- **Sentence:** "That is the third day you have typed this command out in full, do
  you want a short name for it?"
- **Verb(s):** **[make it `gsu`]** — appends one line, `alias gsu='git status
  -sb'`, to a golem-owned aliases file the shell sources. The name is proposed
  **live at offer time** from the command's own words and checked against the
  names that already exist (the nix `shellAliases` block ships `ls ll la tree cat
  grep diff df edit glog gadog dotfiles build update stream -`), so a Golem alias
  can never shadow one of the user's own; if no free name can be made, the action
  says nothing. Honest limit, in the verb line where it belongs: the shell bridge
  runs one way, so the alias is live in **every shell opened after this one** —
  the terminal you are looking at keeps typing it out.

  **Hunt #1's condition, discharged rather than restated.** The file is
  `~/.config/golem/shell/aliases.zsh`: plain text, one alias per line, user-owned,
  never in the nix store. **Neither it nor the line that sources it exists today**
  — named here so the block is bounded work instead of a wish. What is missing is
  a two-line addition to `initContent` in `system/home/zsh.nix` (`[[ -r $f ]] &&
  source $f`), placed **after** the `shellAliases` block so a Golem line can extend
  what nix set rather than be overwritten by it. That source line is nix-managed;
  the file it reads is not. **Revocation is deleting a readable line with any
  editor and opening a new shell — no rebuild, ever**, which was the whole of the
  condition. Tag: trigger **[live]**, verb **[cheap]**, ours, ~2 lines of nix.
- **Refusal:** not now = this command's hash is marked answered and never offered
  again, however many more days it recurs. The action stays alive for other
  commands; a second refusal, on a different command, retires short names
  entirely — twice is an answer about the idea, not about the command.
- **Gear:** (a) **the name**, editable before accepting — a text field, which is
  also where the absorbed U0097 lands (the ssh target typed every day is an alias
  like any other: `alias box='ssh …'`); (a) **the file, by path**, opened in the
  editor at one click — the home of the absorbed U0107, the cheat-sheet file the
  user keeps by hand: the aliases file *is* the cheat sheet, and Golem never owns
  more of it than the lines the user accepted; (b) how many separate days before
  offering (default 3) and the length floor; (c) forget this command / stop
  offering names.
- **Ladder:** assisted = this name, written once. **The automatic rung is
  deliberately not offered**, and that needs arguing because hunt doctrine 3 ("for
  habit actions the rule is the first offer") points the other way. The doctrine's
  premise is that the user's repetitions already climbed the first rung — true for
  an *act* Golem can repeat, but what is produced here is a **name**, and a name
  nobody chose is not a gift. An engine quietly minting `gsu`, `nrs`, `dcu` into
  the user's shell would be authorship without consent, and the user would meet
  their own vocabulary as a stranger. So A13 is the batch's boundary case:
  **doctrine 3 binds when the verb writes a rule, not when the verb assigns a
  name.** Recorded for hunt #2 and for `implementation.md` ¶5.
- **Privacy note:** per tracked command — an 8-byte hash, a day count (u8), a
  last-seen day index (u16) = **11 B**, in a ring capped at 128 commands,
  **≈1.4 kB**, overwritten oldest-first. **No command text is written by the
  detector** (F4 doctrine 1, name-at-offer-time): the sentence quotes the live
  N+1th typing, which arrives on the bridge at the trigger moment and is dropped
  when the offer closes. Text reaches disk only inside an alias line the user read
  and accepted, and that line is theirs. Plus the shared **≈32 B** lifecycle row.
- **Fires:** habit unlock — it waits for a free slot, and it waits behind its
  cluster, which hunt #2 had to name correctly. P5 called it "the shell mouth", and
  there is no such cluster: draft §3.3 gives A13 and A14 **one shared slot in an
  existing cluster**, and §2.4 — the list §4.2 ratified — puts that slot in the
  **morning** cluster, ranked **A39 > A34 > A13/A14**, because the shell bridge
  fires while the user is warming up. So the true order is: the shell pair speaks
  only once A39 (one unlock, then silent) and A34 (per machine, and only where a
  fingerprint reader was found) are answered; then the pair makes at most one offer
  a week between them, and A14 — which fires once and is finished — usually goes
  first. Honest frequency: **once or twice in the first weeks of real
  terminal use, then rarer and rarer**, because a vocabulary gets aliased and
  stops crossing the threshold. Users who never type long commands never hear it.

---

### A14 — the reflex
*(V14 U0094 T0101 S0205 H0285) · coding*

- **Type:** habit
- **Trigger & evidence:** the `cd` → `ls` pair, adjacent on the bridge stream,
  **≥20 times across ≥3 days** and covering **≥60 %** of all `cd`s — the ratio is
  what licenses the word "almost" in the sentence. Both halves already arrive
  (catalog §4.11, the same shipped zsh hook A13 uses), so the detector counts
  pairs, not commands: **[live]**, no new sensing.
- **Sentence:** "You type `ls` after almost every `cd`, do you want the shell to do
  it for you?"
- **Verb(s):** **[do it for me]** — writes a `chpwd` hook into
  `~/.config/golem/shell/hooks.zsh`, the sibling of A13's aliases file, sourced by
  the same missing two-line addition (A13's verb carries the full standing of that
  file; this block does not repeat it). The hook runs **the user's own `ls`**, not
  a hard-coded one: zsh expands aliases when a function body is parsed, so a file
  sourced after the `shellAliases` block inherits `eza --icons` exactly as the
  user's hands would have got it — the same ordering constraint A13 needs, for a
  second reason. **How the gear's cap is enforced, since hunt #2 found the two
  halves of this verb pulling against each other:** piping the listing through
  `head` would break the promise above — `ls` drops its columns and its colour the
  moment its output is not a terminal, so the capped listing would visibly not be
  the user's own `ls`. The hook therefore **counts first and runs second**: a bare
  zsh glob (`f=(*(N)); (( $#f > cap ))`) is a builtin with no fork, and over the cap
  the hook prints the count and the revocation line **instead of** listing, under it
  runs the user's own command untouched. Tag **[cheap]**, ours.
- **Refusal:** not now = the counters keep counting, but the offer does not return
  until the reflex has been demonstrated again at **twice the evidence** (40
  pairs). A second refusal retires it: someone who declines twice is telling us
  the 300 ms was never the problem.
- **Gear:** the box is mostly one control, because an automatic listing in a
  four-thousand-entry directory is a punishment rather than a service —
  (a) **cap the listing** (default 100 entries); (a) **which listing runs** (`ls`
  by default, `ll` for the people who meant that one); (b) **skip directories over
  N entries** entirely; (c) stop doing this — one click, which deletes the hook
  line.

  And the revocation is surfaced **where it bites**, not only in the notebook: the
  line the cap prints in the listing's place carries it — *"4 000 entries, not
  listed · golem: `ls` after `cd` is on — remove the line in
  ~/.config/golem/shell/hooks.zsh"*. The user who
  has just flooded a terminal can undo the rule at the exact moment they resent
  it. A revocation that lives only in a box the annoyed user is not looking at is
  a revocation in name only.
- **Ladder:** the rule **is** the offer — doctrine 3, textbook: the first rung was
  climbed twenty times by the user's own hands. There is no assisted form, because
  "shall I `ls` for you this once?" is precisely the toll doctrine 2 forbids.
- **Privacy note:** two u16 counters (pairs, total `cd`s) and a last-seen day index
  — **≈6 B**, plus the shared **≈32 B** lifecycle row. Directory names are never
  counted or stored; adjacency is a property of the stream, not of the paths, and
  the `cwd` the bridge carries is used by other modules, never written here.
- **Fires:** **one sentence, ever.** Habit unlock, and the same correction A13's
  `Fires` line carries: the shared shell slot sits in the ratified **morning**
  cluster behind A39 and A34 (draft §2.4, §3.3), not in a cluster of its own, and
  the pair makes at most one offer a week between them. Typically lands in the
  first weeks of real terminal use, and it is the best keystrokes-per-utterance ratio in the batch: one
  sentence deletes a reflex performed dozens of times a day for years.

---

### A15 — arrive plain
*(V15 U0112 T0119 S0237 H0337) · writing*

- **Type:** habit
- **Trigger & evidence:** this block carries hunt #1 §3's **relocated** trigger, and
  exists partly to prove the repair survived into the block. The drafted evidence
  — a rich-text clip followed by a plain-paste keystroke — is **unsensable**: it
  needs either a keystroke (out of scope permanently, Constitution VI) or
  knowledge of which mime type the *receiving* app asked for, which only the
  clipboard's owner knows and Golem is a watcher. What is visible, on code that
  already ships, is the **laundering round-trip**: content copied while `text/html`
  was among the offered types, then the same content — 8-byte hash comparison,
  never text — re-offered seconds later carrying **only** `text/plain*`, from an
  editor-class window. The clipboard module already enumerates an offer's types and
  chooses among them (`best_text_mime(&types)`, `clipboard.rs:493–502`), so both
  halves are **[live]**. Threshold: **≥3 round-trips**, with the source class
  recorded alongside (in practice, the browser).
- **Sentence:** "You strip the formatting out of most things you paste, do you want
  them to arrive plain?"
- **Verb(s):** **[keep browser copies plain]** — the label names the scope, and it
  must: the offer is the standing rule **scoped to the source classes where the
  laundering was actually seen**, so a deliberate rich copy between two documents
  is untouched. Mechanism: when a copy arrives from one of those classes carrying
  `text/html`, the daemon re-offers the selection as `text/plain` only — `wl_copy`
  is shipped and already used to restore clips (`clipboard.rs:408`) and
  wl-clipboard is installed (`system/home/home.nix:58`), so this is **[live]**, a
  spawn, no new architecture. What the verb takes, said out loud because it takes
  something (doctrine 5): while the rule is on, **the formatted version of those
  copies is gone** — the user can no longer change their mind at paste time, which
  is the one thing the manual habit preserved. That trade is the offer, and the
  gear can end it in a click.
- **Refusal:** not now = the source class it was about is answered and never raised
  again; a *different* class that starts laundering can earn one new sentence
  later. Two refusals retire the action.
- **Gear:** (a) **which sources arrive plain** — the observed class(es), each with
  a switch, plus an "everything" row for the user who wants it universal;
  (a) **pause for an hour** — the escape hatch for the one copy you do want rich,
  and the honest counterweight to what the verb takes; (b) how many round-trips
  before offering (default 3); (c) stop stripping.
- **Ladder:** the rule is the first offer (doctrine 3), and there is no per-copy
  form on purpose: the per-copy form is Ctrl+Shift+V, which the user already has
  and has been pressing — re-offering it in a sentence is doctrine 4's error. The
  rung above: extend to every source class, offered only after the rule has run a
  month without a pause.
- **Privacy note:** two stores, and hunt #2 split them because P5's single sentence
  had them contradicting each other — it put a 32-entry hash ring **at rest** at
  **≈350 B** and then said the hashes expire after ~60 s, which cannot both be
  true, and the more alarming of the two readings (a disk ring of content hashes)
  was the one the arithmetic published. What is actually needed: the **comparison
  ring is memory-only** — an 8-byte hash and its offered types, ~32 entries, each
  dropped the moment its ~60 s window closes, never written; and what reaches disk
  is the **evidence**, which is per source class only — a class-id hash (8 B), a
  round-trip counter (u8), a last-seen day (u16) = **11 B**, capped at 8 classes,
  **≈88 B**. The detector needs to remember *that a class launders*, never *what
  was laundered*, so the hash of a clipboard's content has no reason to survive the
  comparison that created it. The comparison is hash-to-hash: no clipboard text
  enters the detector, no rich text is stored, and the class name is resolved live
  at offer time. Plus the **≈32 B** lifecycle row.
- **Fires:** **one sentence, ever** — a second only if a second source class starts
  laundering. Habit unlock, no cluster, waits for a free slot; in practice it lands
  within the first month for anyone who copies out of a browser into an editor,
  and never for anyone who does not.

---

### A16 — the waiting update
*(V16 U0117 T0124 S0256 H0381) · system*

- **Type:** moment
- **Trigger & evidence:** `deploy.stale_generation` / `deploy.not_activated`
  **[live]** (catalog §0 — the deploy collector reads the nix profiles), with the
  **same** pending generation observed on **≥3 separate days**. One clarification
  the block owes rather than inherits: the draft counted "the defer ≥3×", and
  **there is no defer button in Golem to press** — the deploy signal surfaces as an
  indicator, not a prompt (catalog §15 keeps battery and deploy out of the
  surfaced affordances). Counting defers would be counting an act that does not
  exist, which is hunt doctrine 1 read backwards. What is real is the generation
  sitting there across days, so the evidence is **days-pending, an aggregate of
  state**, and the type stays *moment*: Golem speaks about the update, never about
  the user.
- **Sentence:** "This update has been waiting a while, do you want it applied the
  next time you restart?"

  *(Drafted as "when you next shut down"; changed under the V08 rule, not the
  voice pass. Nothing happens at shutdown — `nixos-rebuild boot` installs the
  generation as the boot default immediately and the user meets it at the next
  start. The sentence now promises exactly what the verb does. Flagged so hunt #2
  reads it as a repair, not as drift.)*
- **Verb(s):** **[apply it at the next restart]** — `nixos-rebuild boot` against
  the flake the machine already has. That needs root and the daemon runs as the
  user, so the honest tag is **[cheap]** with the mechanism named: the shape is
  already proven twice in Golem's own tree — a small user-writable intent file, a
  `systemd.path` watching it, a root oneshot doing the work and rolling back to
  last-good on failure (`waverunner-apply`, and `system/postinstall.nix`'s four-part
  loop built deliberately in its image). `boot` rather than `switch` is the safe
  half: nothing about the running system changes, and the previous generation stays
  in the boot menu. Where that unit is absent the action does not exist — on the
  live ISO by design (`hosts/iso.nix`: no flake checkout, so `rebuild-golem` is
  absent), so it never speaks there.
- **Refusal:** not now = **this generation is finished**, the escalation clause hunt
  #1 §1.5 made binding. At most one utterance per pending generation, ever; a
  second "not now" — necessarily on a later generation — silences the action until
  the user applies an update by hand, which is the signal that the channel still
  works. Without this clause A16 is the one action in the batch that could speak
  weekly, forever, about the same fact.
- **Gear:** (a) **what "a while" means** — days pending before it counts (default
  3), which is where the absorbed U0149 lands: the user who suspends for weeks and
  never reboots sets their own wait, and Golem does not moralize about uptime;
  (b) only when a restart is actually required (**kernel/initrd drift**, which is a
  file comparison and not a judgement: the `kernel` and `initrd` symlink targets
  under `/run/booted-system` against the ones under
  `/nix/var/nix/profiles/system` — two `readlink`s in the collector that already
  reads those profiles, so the control has a mechanism rather than an intention)
  or on any drift at all; (c) the escalation shown as a **state, not a switch** — "one offer
  per update · silent after two declines"; (c) don't show this again.
- **Ladder:** assisted = this generation, at the next restart. Automatic = "apply
  updates at the next restart, always", offered after two accepted applies — a
  standing rule NixOS is unusually well suited to, because `boot` is reversible and
  the old generation is one boot-menu entry away. The gear says that in the same
  breath as the offer.
- **Privacy note:** a generation-id hash (8 B), a days-pending counter (u8) and the
  answered-generation marker (8 B) — **≈17 B**, plus the **≈32 B** lifecycle row.
  No package names, no flake contents, no update log; the generation is identified
  by hash and described live.
- **Fires:** it is a moment, but its value does **not** die with the moment — a
  pending update is equally pending tomorrow — so it queues at **rank 2 with the
  habit unlocks** and waits harmlessly for a free slot. (Worth recording for hunt
  #2: the ratified queue ranks by *expiry*, not by type; "expiring moment" is the
  rank, and a non-expiring moment simply waits.) Honest frequency, with the
  escalation clause capping it at one sentence per pending generation: **a few
  times a year.**

---

### A17 — the hour you always guard
*(V17 U0118 T0125 S0257 H0387) · system*

- **Type:** habit
- **Trigger & evidence:** do-not-disturb toggled **by hand** at a recurring hour on
  **≥3 days**. The daemon owns the notification mute (catalog §4.14 —
  `audio.call_dnd` fires an internal `AffordanceAction::Daemon` toggle — and
  `notifications.*` is [live]), so it knows both the state and **who changed it**,
  which is the whole of the evidence here: only the user's own toggles count, never
  Golem's (a call's automatic DND, or the shipped `window.fullscreen_dnd`, §4.17,
  would otherwise let Golem learn its own behaviour and offer it back). Stored as a
  24-bucket hour histogram of manual mutes; ≥3 days in the same bucket.
  **[live]**, and no detector owns a timer: the toggle is an event and the clock is
  the topbar's.
- **Sentence:** "You silence notifications around this time most days, do you want
  that to happen on its own?"
- **Verb(s):** **[every day at this hour]** — writes a standing quiet window into
  the golem-owned rules directory (`~/.config/golem/rules/`, the same place A18's
  layout map and A31's window rules live), evaluated on the tick the topbar clock
  already runs. Start and length are taken from **what was observed** — the median
  start hour, and the median time until the user un-muted — not from a default a
  designer picked. **[cheap]**: the mute itself is a shipped daemon action, only
  the schedule is new, and it adds zero wakeups.
- **Refusal:** not now = the histogram keeps counting, but the offer does not return
  for 30 days, and then only if the hour has held. Two refusals retire it: someone
  who guards an hour by hand and declines twice is telling us the gesture is part
  of the ritual.
- **Gear:** (a) the window — start and length, prefilled from the median;
  (a) **which days** — prefilled weekdays-only if the evidence was weekdays only,
  since the histogram knows; (b) **still show calls and alarms**, on by default —
  where the absorbed U0199 is honoured, because the point of the guarded hour
  before colleagues arrive is quiet work, not unreachability. **That exception has
  a mechanism, and it is the A36 shape:** a notification declares its own `urgency`
  and its own `category` hint (`call`, `alarm`, …) in the spec's hint map, and the
  notifications module already receives both with every notification — so the rule
  reads a **declared type name**, exactly as A36 reads `x-kde-passwordManagerHint`,
  and never the summary, the body or the sender. An app that declares nothing is
  held, which is the safe direction. (c) pause today /
  stop.

  The absorbed U0114 (fullscreen writing) is deliberately **not** a control here:
  the shipped `window.fullscreen_dnd` already covers it, and a duplicate switch
  would be Golem offering to do what Golem already does (F5 doctrine 1). Named so
  the absorption is visibly spent rather than quietly dropped.
- **Ladder:** the rule is the offer (doctrine 3) — the user has raised this hand at
  the same hour for days. Above it: **nothing**. A quiet hour that grows teeth of
  its own — auto-extending, spreading to neighbouring hours — is the surveillance
  register, and this action is the batch's cleanest example of a ladder that
  deliberately stops at the first rung.
- **Privacy note:** a 24-entry u8 hour histogram of manual DND toggles (**24 B**), a
  median duration (u16) and a last-seen day index (u16) — **≈28 B**, plus the
  **≈32 B** lifecycle row. Counts by hour, never timestamps: the disk can say "most
  days around this hour", it cannot reconstruct a single day. Nothing about which
  notifications were silenced, or who sent them.
- **Fires:** **one sentence, ever.** Habit unlock, and the third member of the
  **silence family** (A04, A09, A17), which allows **at most one silencing offer a
  week** across all three — so an hour that comes due in a week when the desk was
  already quieted simply waits. Landing time: a few weeks in, and only for the
  minority who guard an hour by hand at all.

---

### A18 — the layout that follows the app
*(V18 U0122 T0129 S0263 H0415) · system*

- **Type:** habit
- **Trigger & evidence:** the active keyboard layout changes within a few seconds of
  focus arriving at a window of class C, resolving to the same layout for C, on
  **≥3 separate days**. Focus is **[live]** (the hyprland collector already watches
  the focus stream), and `active_layout` is listed **[partial]** in catalog §0 —
  *spec'd, not fed* — so the block says **[cheap]** and names the cost instead of
  claiming [live]: Hyprland's event socket emits `activelayout`, and the daemon is
  already connected to that socket for focus events. One line of plumbing on a
  connection that exists.
- **Sentence:** "You switch the keyboard layout every time you come to this window,
  do you want it to follow the app?"
- **Verb(s):** **[remember the layout per app]** — carrying hunt #1 §1.6's repair,
  **[new] → [cheap]**. No Hyprland feature is needed and none is invented: the
  daemon already sees every focus change, and on focus it runs `hyprctl
  switchxkblayout all <index>` out of a small golem-owned class→layout map at
  `~/.config/golem/rules/layout-by-class` (the rules directory A17's quiet window
  and A31's window rules share). `all` rather than a device name, so a keyboard
  plugged in tomorrow behaves like the built-in one. Two honest limits, in the verb
  line where they belong: the map holds layout **indexes**, so re-ordering the
  configured layouts re-points the rules; and a manual switch always wins for as
  long as that window keeps focus.
- **Refusal:** not now = this class is answered and never raised again; a different
  app can earn one offer later. Two refusals retire the action — the user has said
  twice that the switching is theirs to do.
- **Gear:** (a) **the map** — one row per app, each removable, which is the whole of
  what Golem learned, readable; (b) how many separate days before offering (default
  3); (b) whether the rule applies to **new** windows of that class or only the
  ones already seen; (c) stop following apps.
- **Ladder:** the rule is the offer (doctrine 3). The assisted form — "shall I
  switch the layout for you this time?" — is a toll on a key the user's hand is
  already on, which is doctrine 2 exactly.
- **Privacy note:** per class — a class-id hash (8 B), a layout index (u8), a day
  count (u8) = **10 B**, capped at 16 classes, **≈160 B**, plus the **≈32 B**
  lifecycle row. Window **titles** are never read (only classes), nothing typed is
  ever seen — the layout is a setting, not a keystroke — and the class name is
  resolved live at offer time.
- **Fires:** **one sentence, ever** (a second only for a second app). The batch's
  narrowest audience, by construction rather than by accident: for a monolingual
  user the trigger cannot occur, so the action never exists for them — which is
  what "narrow" should mean (hunt §1.6), rather than an action that speaks to
  everyone about something few people want.

---

### A19 — the fresh screenshot
*(V19 U0124 T0131 S0268 H0429) · system*

- **Type:** habit — **converted from moment** by hunt #1 §1.1, and the conversion is
  the action. A screenshot one second old is an object the user's hands are still
  on, which is OPTIONS territory; the rule underneath it is the only thing ACTIONS
  may say.
- **Trigger & evidence:** a window of an annotator class takes focus **within ~60 s**
  of a new timestamped PNG appearing in the pictures directory, on **≥3 separate
  days**. Golem owns the screenshot control — `grim` writes a timestamped PNG to
  `~/Pictures`, created if needed (catalog §4.26, `decide.rs:1602`) — so when Golem
  took the shot the first half is **[live]**; for shots taken by another binding a
  single-directory inotify watch is **[cheap]** (no polling, no new wakeup). Focus
  and class are [live]. Honest note on the folder: **there is no dedicated
  screenshots directory today**, so the watch is "a new timestamped PNG in the
  pictures directory", and if the user moves screenshots elsewhere the gear's path
  follows them.
- **Sentence:** "You draw on nearly every screenshot you take, do you want them to
  open in the annotator?"
- **Verb(s):** **[open them in the annotator]** — **one** verb. The rule pipes
  Golem's own screenshot output into the class that was observed doing the drawing
  (a spawn of that app with the new file, named at offer time), which is a change
  inside Golem's own house rather than a reach into another program. **The OCR half
  is gone from ACTIONS** — drafted as `[copy its text]`, dropped because it has no
  rule form (nobody wants every screenshot OCR'd) and belongs on the OPTIONS side
  as a per-instance pill, where the user's hands already are. One consequence
  stated plainly because it decides whether the action ever exists: **no annotator
  ships with Golem** (`home.nix` installs grim, slurp and wf-recorder — nothing
  that draws), so on a stock machine the gate never opens. The action comes into
  existence only for a user who installed one themselves, which is precisely the
  user whose hands demonstrated the habit.
- **Refusal:** not now = finished, permanently. There is no next occasion worth
  waiting for: a screenshot habit does not become more true next month, and the
  annotator remains one click away in OPTIONS.
- **Gear:** (a) **which app** opens them, prefilled with the observed one;
  (a) **which captures** the rule covers — full screen, region, or both: where the
  absorbed U0071 lands, since the user who takes region shots many times a day
  would hate a full-screen rule and the reverse; (b) the folder that is watched;
  (c) stop opening them.

  The absorbed U0123 (the OCR habit) is deliberately **not** a control: it left for
  OPTIONS with the dropped pill. Named here so the absorption is visibly spent.
- **Ladder:** the rule is the offer — doctrine 4 in its purest form (when OPTIONS
  already puts the per-instance hand on the object, the ACTION is the standing
  rule). Above it: nothing. An annotator that opens itself is the ceiling of the
  idea.
- **Privacy note:** two u8 counters (screenshots seen, annotator-followed within the
  window) and a last-seen day index — **≈5 B**, plus the **≈32 B** lifecycle row.
  No filenames, no image bytes, no thumbnails; the file's path is read live at the
  moment the rule acts and never written down. This is the smallest at-rest
  footprint in the batch.
- **Fires:** **one sentence, ever.** The draft's highest-frequency speaker —
  screenshots are a several-times-a-day habit — is now among the quietest actions
  in the batch, which is the clearest measure of what the moment→rule conversion
  bought. Habit unlock, no cluster, waits for a free slot.

---

### A20 — true colours
*(V20 U0125 T0132 S0270 H0436) · system*

- **Type:** moment, **gated on demonstrated behaviour** (hunt #1 §1.2)
- **Trigger & evidence:** the gate first, because without it the action imputes a
  motive from a state — opening a photo does not demonstrate wanting colour
  accuracy, and Constitution III calls that the designer demonstrating the need.
  The gate: the user has, **by hand, ≥3 times**, turned the screen's warmth **off**
  while an image viewer/editor class was focused, **and turned it back on
  afterwards**. *(P5 wrote "off or down". Hunt #2 struck "or down": what the engine
  carries is a **boolean** — warmed or not — so a user who merely warms the screen
  less moves nothing the detector can see, and counting a change of degree would be
  counting an event that does not arrive. The gate is the on/off pair, which is
  both sensable and the stronger evidence anyway: turning protection off entirely,
  in front of a photo, three times, is not an ambiguous gesture.)* Sensable on
  shipped code: `sunset.rs` owns the temperature
  (`hyprctl hyprsunset temperature {k} || hyprsunset -t {k}`, identity 6500 K =
  protection off) and the engine already carries "a hyprsunset process is running /
  the screen is warmed" as state (`state.rs:202`) — so a change Golem did not make
  is a change the user made. **[live]** for the state, **[cheap]** for attributing
  it. Once the gate is open, the moment is: the screen is warmed **and** an image
  class takes focus.
- **Sentence:** "Eye protection is on and you have opened a photo, do you want true
  colours for a minute?"
- **Verb(s):** **[true colours for a minute]** — sets the temperature to
  hyprsunset's identity (6500 K) and restores the previous value after the minute,
  or the moment the image window loses focus, whichever comes first. Both halves
  are the daemon's own shipped seam and it knows the exact value it replaced, so
  the restore is exact rather than a guess at "warm". **[live].**
- **Refusal:** not now = silent for the rest of the evening; the next occurrence is
  a different evening. Three refusals retire it — and with the gate in place three
  noes mean the demonstrated behaviour has stopped, not that the offer was
  mistimed.
- **Gear:** (a) how long a minute is (default 60 s); (a) whether to restore on focus
  loss as well as on the timer; (b) **which apps count as looking at a photo** —
  the observed classes, each removable; (c) at most once per evening / don't show
  again.
- **Ladder:** assisted = this minute. Automatic = "hold true colours whenever one of
  these apps is in front", offered after two accepted minutes — genuinely better
  for the person the gate selects for, since a photographer does not want a
  stopwatch. Deliberately not the default: it turns the eye protection off for as
  long as an app is open, which is a much bigger thing than a minute, so the user
  signs it rather than inherits it.
- **Privacy note:** a u8 gate counter, up to four class-id hashes (8 B each) and a
  last-offered evening index (u16) — **≈35 B**, plus the **≈32 B** lifecycle row.
  Nothing about the images, no file paths, no viewing durations (F4 doctrine 2 —
  no stopwatch over leisure); the class is resolved live at offer time.
- **Fires:** an expiring moment — the minute *is* the value — but it sits **third in
  the evening cluster**, behind the live sunset prototype (with A38 riding it) and
  A11, so on any evening where the prototype speaks, A20 does not, and a refusal
  sends it to the back of that order. Honest frequency for the gated audience: **a
  handful of evenings a month**, at most once per evening. For everyone else:
  never, because the gate never opens.

---

### A21 — the wrong first hit
*(V21 U0129 T0136 S0276 H0450) · search/launch*

- **Type:** habit
- **Trigger & evidence:** the launcher fires app X from query Q and the window it
  opened closes **within ~15 s**, **≥3 times for the same (query, app) pair**. Every
  signal is first-party and in-process: the launcher owns the query and the
  activation, the hyprland collector owns the window's life, and the options engine
  lives in the same binary (`crates/options-engine` inside the launcher
  workspace). **[live]**, and nothing outside Golem ever observes it — the privacy
  cost is zero because the query was always the shell's own signal.
- **Sentence:** "The launcher keeps putting \<app\> first and you keep closing it,
  do you want it moved down?"
- **Verb(s):** **[stop putting it first]** — and here the block owes the tree's
  answer rather than a promise. The launcher's ranking store is `UsageDb`: a flat
  `{app-id: count}` JSON at `$XDG_DATA_HOME/waverunner/usage.json` (`usage.rs`),
  consulted by a single sort key (`main.rs:2501` — results ordered by launch
  count). **It has no query dimension**, so "not for this query" cannot be written
  into it as it stands, and demoting the app outright would be wrong: the app is
  wanted, just not for Q. The honest shape is a sibling store — a
  `(query-hash, app-id) → penalty` map beside `usage.json` — and one extra term in
  that one sort key: **[cheap], ours, small, and named here so it cannot be read as
  a wish.** Until it exists the action does not speak.
- **Refusal:** not now = this pair is answered and never raised again; other pairs
  can still earn an offer. Two refusals retire the action — a user who closes
  windows quickly and does not mind is telling us the close was never a complaint.
- **Gear:** (a) **the demotions**, listed as "\<query\> → \<app\>, moved down", each
  removable in one click — the entire learned ranking, readable, which is Law VI.4
  made mechanical; (b) how many fast closes before offering (default 3) and how
  fast a close counts (default 15 s); (c) stop learning from my closes.
- **Ladder:** assisted = this pair, moved down. Automatic = "move things down when I
  keep closing them, and put it in the notebook instead of asking", offered after
  two accepted demotions. This is the one place in the batch where the alternative
  to an ACTION is **silent ranking ML**, which is what every other launcher does:
  the disclosure is the product (VI.4), and even in the automatic form each
  demotion is a line the user can read and delete.
- **Privacy note:** before consent, per pair — a query hash (8 B), an app-id hash
  (8 B), a u8 count = **17 B**, ring of 32, **≈550 B**; plus the **≈32 B** lifecycle
  row. **The query text is never stored by the detector** (F4 doctrine 1): the
  sentence names the app live and quotes the query the user has in front of them.
  At the moment the user accepts, that query becomes user-authored config in the
  demotions file — visible in the gear, deletable in one click — which is the same
  line A02 draws: an observation never becomes text on disk, only a signed rule
  does.
- **Fires:** habit unlock — **once, then rarely.** Most users have exactly one
  pair that annoys them, and each later pair needs its own three fast closes.
  Waits for a free slot in the day's queue, never two unlocks in an hour.

---

### A24 — stop at 80
*(V24 U0141 T0148 S0311 H0505) · power/battery*

- **Type:** habit
- **Trigger & evidence:** the machine is on wall power for essentially the whole
  session, **≥3 sessions**. The drafted evidence was `is_charging` near-constant
  and **the tree says that trigger would almost never fire on the machine this
  action is for**: the system collector counts a battery as charging only when
  `/sys/class/power_supply/*/status` reads the literal *"Charging"* — `"Full"` is
  explicitly false (`charging_from_status`, `system.rs:363–364`, and its own test
  asserts it) — and a laptop that lives on a desk sits at **Full** all day. So the
  evidence is **not-discharging**: `status ∈ {Charging, Full}` sampled on the poll
  the collector already runs (3 s, `system.rs:19`), kept as one fraction-of-session
  number per session; ≥3 sessions above ~90 %. **[live]** signal, **[cheap]**
  aggregate, zero new wakeups — it is the same `read_dir` the collector already
  performs (`system.rs:337–356`).
  **And a second condition, which is hardware, not software:** the action exists
  only where `charge_control_end_threshold` is present in that same battery
  directory — one `.exists()` inside a walk already happening. It is there on most
  ThinkPads and on much recent Lenovo/Dell/ASUS; it is **absent on Intel
  MacBooks**, which are this batch's stated priority hardware. **On the priority
  machine this action never comes into existence at all** — no greyed pill, no
  "unsupported" sentence, no trace: the detector never constructs. Golem also has
  nobody else in the way — `tlp` is deliberately absent from the distro (it fights
  power-profiles-daemon, `system/hardware/power-laptop.nix:12`) — which means no
  conflict and no free persistence either.
- **Sentence:** "This machine lives on the charger, do you want it to stop charging
  at 80%?"
- **Verb(s):** **[stop at 80%]** — and the honest mechanism, because the sysfs node
  is root-owned and the daemon is not: the verb writes one readable line to
  `~/.config/golem/rules/charge-limit` (the same golem-owned rules directory A17's
  quiet window, A18's layout map and A31's window rules use), and a small root unit
  applies it. That unit does not exist yet, but its pattern is proven and shipping
  in this very repo: `waverunner-apply` is a user-writable file watched by
  `systemd.paths` → `PathChanged` → a root oneshot that validates each line before
  acting (`system/waverunner-apply.nix:169–189`, including the reject-invalid-entry
  guard at :98). **[cheap], ours, one nix module and one twenty-line script** — and
  it must also run at boot, because most firmware forgets the threshold across a
  full power cycle. Until that unit exists **the action does not speak**; this is
  the A02 rule applied to hardware, not a promise.
- **Refusal:** not now = this machine is answered for **90 days**, and the offer
  returns only if it is still living on the charger. A second refusal retires it
  permanently — someone who wants a full battery on a desk machine has said so
  twice, and the cost of being wrong is their battery, not ours.
- **Gear:** (a) **the ceiling** — 80 % default, 60 / 80 / 90; (a) **[charge to
  full this once]** — the travel escape, and the home of the absorbed **U0142**
  (unplugging at 100 % out of tenderness): that user was hand-operating a ceiling
  they did not have, and this is the ceiling plus the one-click exception their
  ritual actually needed; (b) how much of a session on wall power counts (default
  90 %); (c) remove the limit / don't offer this again.
- **Ladder:** there is no assisted rung and there must not be one. A one-time "stop
  charging now" is a toll on a thing nobody wants to do repeatedly (doctrine 2);
  the standing threshold **is** the offer (doctrine 3), and the user's own three
  sessions on the charger were the tutorial. Above it: nothing. A ceiling that
  moves itself is a battery policy the user never signed.
- **Privacy note:** per session one on-wall-power fraction (u8) and nothing else;
  ring of 8 sessions = **8 B**, plus a u8 session count and the shared **≈32 B**
  lifecycle row — **≈41 B**. No charge/discharge diary, no times of day, no record
  of when the machine is at a desk versus not, which is a location fact in
  disguise and is exactly why this detector stores a fraction instead of a log.
- **Fires:** **one sentence, ever**, and only on a laptop that both has the knob
  and lives plugged in. Habit unlock: it waits for a free slot in the day's queue,
  indefinitely and harmlessly. For most users of most machines this action is
  silent for the life of the install, which is the correct behaviour for a thing
  that is right once.

---

### A25 — stretch it
*(V25 U0144 T0151 S0314 H0510) · power/battery*

- **Type:** habit
- **Trigger & evidence:** a **manual** move into power-saver — the profile switch,
  or a backlight step down — at a recurring low battery level, median over **≥3
  occurrences** on separate discharges. `metrics.battery_pct` is **[live]**;
  power-profiles-daemon is on for every laptop Golem builds
  (`system/Modular/power/laptop.nix:13`) and its active profile is a D-Bus property
  the engine does not read yet — **[cheap]**, and the notifications collector
  already speaks D-Bus, so it is a subscription, not a dependency. The backlight
  half is the same shape: one more directory in the `/sys` walk the system
  collector already does. Stored as the **median percentage at which the user
  starts saving** — their line, not a number a designer picked.
- **Sentence:** "You start saving the battery around here, do you want that to
  happen on its own from now on?"
- **Verb(s):** **[do it at \<N\>% from now on]**, N prefilled with the user's own
  median — writes one readable line to `~/.config/golem/rules/battery-saver`, and
  the daemon applies it when the number is crossed on battery:
  `powerprofilesctl set power-saver`, a backlight step (`brightnessctl`, installed
  — `system/configuration.nix:475`, `system/home/waverunner-packages.nix:8`), and
  the keyboard backlight off (`brightnessctl -d '*::kbd_backlight' set 0`, the
  absorbed **U0147**). Restored on wall power. **[cheap]**, all of it in the user's
  own session, no root, no rebuild; revocation is deleting the line.
  **This block is the batch's clearest case of doctrine 4** (when the assisted form
  is an OPTION, the ACTION is the rule) and the repair hunt #1 ordered: the
  per-instance hand already ships as `system.battery_dim` (catalog §4.29 —
  *"Dim screen"*, `brightnessctl set 40%`, gated on `has_backlight`, at ≤15 % on
  power), so offering to dim *this time* would be Golem re-selling a pill the user
  can already see. The only thing left worth saying is the standing rule — and note
  what the rule adds beyond the shipped OPTION: it fires at **the user's line**
  (31 %, 45 %, whatever the median says), not at the distro's 15 %, which is the
  whole reason the user was doing it by hand.
- **Refusal:** not now = silence for this discharge cycle and the median keeps
  updating while it waits (an aggregate costs nothing to keep). Re-offer no sooner
  than 60 days, and only if the line has held. Two refusals retire it: doing it by
  hand can itself be the ritual — a moment of noticing the battery — and Golem does
  not get to automate a moment someone keeps for themselves.
- **Gear:** (a) **the level** (prefilled from the median) and **what happens** —
  power-saver / dim to X % / keyboard light off, three switches, where **U0143**
  (the manual dim) and **U0147** are spent; (b) **also start saving as soon as I
  unplug** — off by default, the home of the absorbed **U0155** (unplugging to go
  sit on the couch), because for that user the trigger is the unplug, not the
  number; (b) restore everything when plugged back in — on by default; (c) pause
  today / stop.
- **Ladder:** the rule is the first offer (doctrine 3): the repetitions the user
  performed *were* the assisted rung. Above it: nothing. A saver that creeps
  upward — "you were at 31 %, shall I start at 45 % now?" — is the system
  renegotiating a deal the user already signed.
- **Privacy note:** a median battery percentage (u8), an occurrence count (u8) and
  a last-seen day index (u16) = **4 B**, plus the **≈32 B** lifecycle row. No
  discharge curves, no per-day battery history: the disk can say *"around 31 %"*
  and cannot say what happened on any given Tuesday.
- **Fires:** **one sentence, ever.** Habit unlock, waits in the queue, and it needs
  a laptop, three separate discharges deep enough to reach the user's line, and a
  user who reaches for power-saver by hand at all — realistically a few weeks in,
  for a minority. Zero on desktops: without a battery the detector never
  constructs.

---

### A26 — the wrist
*(V26 U0154 T0161 S0327 H0541) · power/battery*

- **Type:** habit
- **Trigger & evidence:** **resumed from idle with nothing following it** — no
  focus change, no new window, no command through the shell bridge within ~30 s —
  counted **≥3×**. This is hunt #1 §1.7's relocation and it must not be quietly
  reverted: the drafted trigger (a small cursor burst near the idle boundary)
  requires sampling pointer position on a clock, which is a detector owning a
  timer, forbidden outright by Constitution VI's second discipline, and it reads
  intent out of pointer noise it cannot distinguish from a hand resting on a
  trackpad. The pointer is **never sampled**. A real return to work always produces
  a focus change, a window, or a command; a jiggle produces none — so the evidence
  is an absence observed on event streams that already exist.
  **Honest feasibility — and it is the second absence that matters, not the first.
  Idle SENSING is not missing.** Idle is not among catalog §0's nine collectors,
  but that is a fact about the engine's surface, not about its reach: under
  `ext-idle-notify-v1` the **compositor is the idle source** and a daemon is merely
  another client, and the launcher is already a Wayland client
  (`wayland-client 0.31`, `smithay-client-toolkit 0.19`,
  `crates/daemon/Cargo.toml:28–29`), so idle/resume become events on a connection
  that exists — **[cheap]**, zero new wakeups, no timer. What is missing is
  **anything that ACTS on idle.** A sweep of the whole tree finds **no idle manager
  and no locker anywhere in Golem**: no hypridle, no swayidle, nothing in
  `system/` and nothing in the launcher. On a stock Golem today the screen does
  not dim or blank on its own, so there is **no idle boundary to fight** — the
  habit cannot be performed (the counter can never reach three) and the verb would
  inhibit an idle **nothing consumes**. Both mouths fail on that absence, and the
  action cannot come into existence. It is written in full and **dormant**, like
  A02 and A03 — but dormant for a different reason, which hunt #2 settled: A02
  waits on a store Golem intends to build, while A26 waits on a behaviour Golem
  does not yet have. **If batch 1 ships before an idle manager does, A26 is a
  kill, not a wait** (and A33, in unit 4, inherits exactly the same dependency — a
  lock-on-sleep offer presumes a sleep). When a manager does arrive, the trigger
  is already **[cheap]** for the sensing reason above.
- **Sentence:** "You keep the screen awake by hand while you read, do you want it
  to stay awake here?"
- **Verb(s):** **[keep it awake here]** — the standing rule, scoped to the class
  that was focused when the jiggling happened: while a window of that class has
  focus, the daemon holds an idle inhibitor and drops it the moment focus leaves.
  Mechanism, ours and dependency-free: a `zwp_idle_inhibitor_v1` on one of the
  daemon's own layer surfaces — the topbar is already a Wayland surface we own —
  which is **[cheap]** on the same connection as the trigger. Scoped, never global:
  an inhibitor the user cannot see the edges of is a broken idle manager.
- **Refusal:** not now = this class is answered and never raised again; a different
  class must earn its own three resumes. Two refusals anywhere retire the action —
  a reader who declines twice has told us the dimming does not actually bother
  them.
- **Gear:** (a) **the apps that hold the screen awake**, one readable line each,
  each removable in a click; (b) **only while the window is focused** (default) /
  also when it is fullscreen; (c) stop keeping the screen awake.
- **Ladder:** the rule is the offer (doctrine 3) — the user's wrist was the
  assisted rung, performed three times. Above it: nothing. The obvious next rung —
  "keep the screen awake whenever you seem to be reading" — is the system guessing
  at attention, which is the surveillance register and is not available here.
- **Privacy note:** per class an 8 B hash and a u8 count, ring of 16 = **≈150 B**,
  plus the **≈32 B** lifecycle row — **≈182 B** in all. **No pointer data of any
  kind is stored or sampled**, and no timestamps: the count is of a shape of event,
  not of a moment in a day.
- **Fires:** **one sentence, ever** — and **zero until Golem ships an idle
  manager**, which today it does not. Habit unlock, waits in the queue behind
  everything expiring.

---

### A27 — follow my headphones
*(V27 U0067 T0074 S0148 H0188) · audio/devices*

- **Type:** habit
- **Trigger & evidence:** the default sink is moved **by hand** to a device within
  seconds of that device appearing, the same device **≥3×**. Feasibility is better
  than the draft graded it, and the reason is in the collector: the audio collector
  already runs **`pw-mon` as an event watcher** — its own comment says *"no polling
  — so a volume key, a mute, a new stream or a default-device change wakes it
  immediately"* (`audio.rs:156–168`), with a 2 s poll only as the fallback when
  `pw-mon` is missing. Both halves of this evidence — a device arriving, the
  default sink becoming that device — are already in the `pw-dump` the collector
  takes (`audio.rs:188–201`). What is missing is only that the collector keeps the
  default sink's **volume** and not its **identity**. **[cheap], zero new wakeups,
  no new dependency.**
- **Sentence:** "You move the sound over by hand every time these headphones
  arrive, do you want them to take it automatically?"
- **Verb(s):** **[follow my headphones]** — writes one readable line to
  `~/.config/golem/rules/audio-devices` (*"when \<device\> arrives, it takes the
  sound"*), and on the next arrival event the daemon runs `wpctl set-default
  \<id\>`. **[cheap]**: the arrival is already a wakeup, the tool is already in the
  audio path, revocation is deleting the line.
- **Refusal:** not now = this device is answered and never raised again; another
  device can still earn its own three. Two refusals retire the action — someone who
  chooses their output by hand each time is doing it deliberately, and the second
  "no" is the proof.
- **Gear:** (a) **the devices that take the sound when they arrive**, one line
  each, removable — where the absorbed **U0158** (re-picking the output after every
  dock) and **U0160** (the bluetooth connect ritual) live, since a dock's sink and
  a headset's sink are the same rule with different hardware; (b) **also take the
  microphone** — the input side, off by default, the home of the absorbed **U0164**
  (the mic that keeps reverting to the webcam); (b) ask before switching instead of
  just doing it; (c) stop following devices.
- **Ladder:** the rule is the offer (doctrine 3); the user's three manual switches
  were the assisted rung. Automatic above it: *"let any device I always switch to
  take the sound, and put it in the notebook instead of asking"* — offered only
  after two accepted rules, and every device still one readable removable line.
- **Privacy note:** per device an 8 B identity hash and a u8 count, ring of 8 =
  **≈72 B**, plus the **≈32 B** lifecycle row — **≈104 B** in all. **Device names
  are never written at rest** — they are read live at offer time and dropped (the
  name-at-offer-time rule unit 1 set for A01), which matters more here than it
  looks: a Bluetooth device name is often a person's name.
- **Fires:** **one sentence, ever** in practice — most people have one pair of
  headphones and one dock, and the second device rarely gets its own offer because
  the first rule's gear already covers it. Habit unlock; shares the **device
  arrival** cluster with A29, so a desk that triggers both hears one of them and
  the other waits for the next arrival.

---

### A28 — the good sound
*(V28 U0161 T0168 S0341 H0582) · audio/devices*

- **Type:** moment
- **Trigger & evidence:** a Bluetooth headset that is the current sink flips its
  card profile to the call profile (HSP/HFP) as capture starts. `audio.is_mic_active`
  is **[live]** and the mic going live is already a wakeup on the `pw-mon` watcher;
  the profile itself sits on the device object in the same `pw-dump` the collector
  parses and currently ignores — it reads capture streams and the default sink's
  volume, nothing about devices (`audio.rs:188–291`). **[cheap]**: one more field
  out of a document already being parsed. Honest caveat: the profile is read from
  the device's properties in that dump, and where a wireplumber build does not
  surface it there, `wpctl status` does — either way a tool already on the audio
  path, never a new dependency. No counter, no history: this is live state.
- **Sentence:** "Your headset drops to phone-call sound when the microphone is
  used, do you want to keep the good sound and use the laptop's microphone
  instead?"
- **Verb(s):** **[keep the good sound]** — holds the high-quality profile
  (`wpctl set-profile \<device\> \<a2dp index\>`, the index resolved from the
  device's own enumerated profiles) and points capture at the built-in microphone
  (`wpctl set-default \<internal source\>`); both undone when the headset
  disconnects or the mic goes quiet. **[cheap].** The sentence is the long one on
  purpose — it is hunt #1's doctrine 5 repair, **do not hide what the verb takes** —
  because accepting silently moves the user's voice to a different microphone, and
  a user who says yes and then sounds distant was never offered that trade. Longer,
  still one sentence, and now true.
- **Refusal:** not now = this headset keeps the call profile for the rest of this
  connection; the offer may return on a later call. Three refusals for the same
  device retire it permanently — someone who prefers the headset's own microphone
  has a reason Golem does not need to know.
- **Gear:** (a) **which microphone to use instead** — the laptop's (default), this
  headset's, or a named other; (b) **only on calls** (default) / whenever this
  headset is connected; (c) forget this headset / stop offering this.
- **Ladder:** assisted = this call, which is the right first rung here because the
  trade is real and the first acceptance is the user learning what it sounds like.
  Automatic = *"always keep the good sound on this headset"*, offered after two
  accepted calls and written into the same `~/.config/golem/rules/audio-devices`
  file A27 owns — one file, two kinds of line, both readable.
- **Privacy note:** per device an 8 B hash and a u8 accepted count, ring of 4 =
  **≈36 B**, plus the **≈32 B** lifecycle row. **Calls are never counted.** The mic
  state is read as live context and never aggregated into a per-day or per-week
  figure, because a count of calls is a diary of a person's working life in one
  integer — Constitution VI.3 read strictly.
- **Fires:** expiring moment, **rank 1 of the call-start cluster** (A28 > A04 >
  A03): on a call where this fires, A04 and A03 do not speak. At most once per
  call and once per device per session, and only for the subset of users on a
  Bluetooth headset — then the standing rule ends it for good. This is the batch's
  single most-thanked fix and also one of its quietest: two or three sentences
  total, ever.

---

### A29 — remember this desk
*(V29 U0167 T0174 S0347 H0608) · audio/devices*

- **Type:** habit
- **Trigger & evidence:** a monitor is added and the same manual re-arrangement
  follows within seconds, the same layout **≥3×**. The sensing side is **[cheap]**
  and honestly small, and the block's first draft overstated the gap in two places
  hunt #2 cut down: `monitoradded` / `monitorremoved` already arrive on the
  socket2 stream the collector reads, but `parse_event` has no arm for them
  (`hyprland.rs:317–341` — it acts on focus, workspace, submap, layout and
  screencast only) — **and that is the whole of the first absence**. The events
  are **already subscribed and already acted on** elsewhere: they are the daemon's
  `SCREEN_DRIFT` list (`hypr.rs:33`, matched at `:861`, where a monitor arriving
  re-asserts the DRM rebuild's colour matrix). And `j/monitors` is **already
  queried and parsed** — `focused_monitor()`, `hypr.rs:898–900`, into a
  `MonitorInfo` carrying connector, scale and active workspace — but the `.find()`
  filter at `:905` throws away every output but one. What is missing is the
  **set** surviving that filter, plus one match arm per event. The arrangement is
  then a set-hash, an aggregate.
- **Sentence:** "You have arranged these monitors the same way again, do you want
  this desk remembered?"
- **Verb(s):** **[remember this desk]** — and this is the block where the verb has
  to be discharged against the tree rather than promised, because **applying a
  remembered layout at runtime is blocked on Golem's own fork in every obvious
  way.** Verified, three places: `hyprctl keyword monitor` is **rejected** by the
  lua-config Hyprland fork (*"non-legacy parsers"*, `NOTES.md:709–713`,
  `GRIND.md:111–114`); an eval'd `hl.monitor` rule **does not retro-apply** to an
  already-connected output, even after `hyprctl reload`; and `wlr-randr` is not
  installed. The declarative home of monitor state is `system/home/hyprland.lua`
  (`hl.monitor{ output = …, mode = …, scale = … }`, `system-landscape.md:222–230`),
  which is nix-managed — so writing back there would put a user's desk **behind a
  rebuild**, the precise thing A13's condition forbade for shell aliases. The
  honest unblock is the portable protocol the landscape survey already spec'd
  field by field: `zwlr_output_manager_v1` / `zwlr_output_configuration_v1` —
  build, `enable_head`, `apply`, wait for `succeeded`/`failed`
  (`system-landscape.md:203–209`) — implemented in the daemon, which is already a
  Wayland client. And a second false premise from the draft is corrected here too:
  the field is **not** foreign to Golem — `wayland-protocols-wlr` is already a
  dependency (`crates/daemon/Cargo.toml:32`), and the daemon already binds and
  drives a sibling manager end to end (`zwlr_screencopy_manager_v1`,
  `screencopy.rs:31–34`, with the build → submit → wait-for-`Ready`/`Failed`
  handshake at `:978–1013`) — structurally the same shape as output-config's
  `apply` → `succeeded`/`failed`. **The tag is still [new], on firmer ground:
  this is an actuator**, a new module beside `screencopy.rs`, and [cheap] by the
  catalog's legend is a small addition to an existing collector, which this is
  not. **A29 does not speak until it exists** — and the one assumption left is
  named rather than smuggled: Golem's fork changed the config parser, not the
  protocol set, so whether the fork implements wlr-output-management is **one
  `wayland-info` away** from an answer. When it does, the rule is a readable block
  per desk in `~/.config/golem/rules/desks`, keyed by each output's
  make/model/serial and applied on the next arrival of that set.
- **Refusal:** not now = this desk is answered and never raised again; a different
  set of monitors can still earn its own three arrivals. Two refusals retire the
  action.
- **Gear:** (a) **the desks**, one block each, removable — and each block carries a
  plain readable line of what this desk actually does, including **whether it
  charges the laptop**, which is where the absorbed **U0156** (the dock power
  double-check) is spent: the ritual is made of doubt, and a fact in the box ends
  it without Golem ever speaking; (b) **what a desk remembers** — the arrangement,
  the sound output (the absorbed **U0170**, the evening TV input, which is a desk
  whose output happens to be a television), and **what to do with the lid closed**
  (the absorbed **U0165**); (c) stop remembering desks. The absorbed **U0166** (the
  HDMI blink — replugging to make a screen wake) needs no control: applying the
  layout on arrival is the answer to it.
- **Ladder:** the rule is the offer (doctrine 3). Automatic above it: *"remember
  every desk automatically and list them instead of asking"*, offered after two
  accepted desks — allowed here, unlike A17 or A26, because every desk remains one
  readable removable block and a monitor arrangement is not a fact about the
  person.
- **Privacy note:** before consent, per candidate desk an 8 B set-hash and a u8
  count, ring of 4 = **≈36 B**, plus the **≈32 B** lifecycle row — **nothing about
  which monitors**, only that the same set returned. Make/model/serial are written
  only at the moment the user accepts, and then they are user-authored config in a
  file the notebook shows and one click deletes. Same line A02 and A21 drew: an
  observation never becomes text on disk, only a signed rule does.
- **Fires:** **one sentence, ever** per desk, realistically once — on the third
  arrival at the earliest, i.e. week two for a commuter, never for a laptop that
  stays home. Habit unlock, and it shares the **device arrival** cluster with A27,
  so the first docking that would trigger both hears one.

---

### A31 — open it there
*(V31 U0180 T0187 S0382 H0664) · window/workspace*

- **Type:** habit
- **Trigger & evidence:** within seconds of a window of class C opening, the user
  corrects it — moves it to another workspace or monitor, or floats it — and the
  **same correction happens ≥3×**. Feasibility, checked in the collector, and the
  frame corrected by hunt #2: `openwindow` and `movewindow` arrive on the socket2
  stream the daemon already reads and are **not dropped by the process** — both sit
  in the daemon's `RELEVANT` event list (`hypr.rs:35–45`) and already drive the
  stage's `on_layout_changed()`. What has no arm is the **collector's `parse_event`**
  (`hyprland.rs:322–340`), a smaller and truer statement: the events wake the
  machine, and the detector needs two match arms to see them. The **whole window
  inventory** — class, title, pid, workspace, monitor, floating, geometry — has
  existed in `ContextState` since 2026-09-12 (`j/clients`, `hyprland.rs:186–269`,
  finding #83). So the trigger is **[cheap]**: two match arms plus a class→slot
  aggregate. What is stored is the destination, never the journey.
- **Sentence:** "You move \<app\> over here every time it opens, do you want it to
  open there?"
- **Verb(s):** **[open it there from now on]** — and here, unusually for this unit,
  **the fork helps instead of blocking.** `hyprctl keyword` is rejected for the
  non-legacy parsers (see A29), but the daemon already writes **runtime window
  rules through the fork's Lua eval channel**: `eval()` at
  `crates/daemon/src/hypr.rs:1109`, used at :1147–1152 as
  `hl.window_rule({ name = …, match = { … }, … })`, on a path the tree records as
  **verified** (*"a runtime workspace rule BEATS the configured smart-gaps rule
  (verified)"*, :1127). Two consequences belong in the block. First, the rule is
  applied **without touching nix-managed `hyprland.lua`** — no rebuild, which is
  what A13's condition demanded of any rule Golem writes. Second, `hyprctl reload`
  **re-reads the store copy of the config and wipes runtime settings with it** —
  this is how the stage dim once quietly vanished (:1135–1142) — so durability
  cannot live in the compositor: the signed rule is one readable line in
  `~/.config/golem/rules/windows`, re-asserted by the daemon at start and after any
  reload, revocation by deleting the line. **Mechanism [live], wiring [cheap].**
- **Refusal:** not now = this class is answered and never raised again; another app
  must earn its own three corrections. Two refusals retire the action — moving a
  window can be part of how someone thinks, and Golem does not automate thinking.
- **Gear:** (a) **the rules**, one readable line each (*"\<app\> → workspace
  'notes' on the left screen"*), each removable — where the absorbed **U0178**
  (ferrying an app off the wrong monitor) lives, since a rule carries a monitor as
  naturally as a workspace, and **U0179** (one workspace per project) is honoured
  by letting a rule name a workspace rather than a number, which is how that habit
  is actually lived; (b) **what a rule may carry** — workspace, monitor, float,
  the last of which is the absorbed **U0183** (the app that refuses to be tiled);
  (b) how many corrections before offering (default 3); (c) stop learning from my
  window moves.
- **Ladder:** the rule is the offer (doctrine 3). Automatic above it: *"write the
  rule whenever I correct an app three times, and put it in the list instead of
  asking"* — offered after two accepted rules, and even then every rule is a line
  the user can read and delete, which is Law VI.4 doing the work that makes silent
  learning acceptable.
- **Privacy note:** per class an 8 B hash, a slot id (u16) and a u8 count = 11 B,
  ring of 16 = **≈180 B**, plus the **≈32 B** lifecycle row. **No window titles,
  ever** — the inventory carries them, the detector must not: a title is content,
  a class is a gesture (Constitution VI.2), and this is the clearest place in the
  batch where the same collector serves both a legitimate and an illegitimate
  detector.
- **Fires:** habit unlock — **one sentence, then rarely.** Most people have two or
  three apps they place by hand, and each later one needs its own three
  corrections; the queue allows never two unlocks in an hour, so a week that
  produces two waits them out.

---

### A32 — watch it for me
*(V32 U0182 T0189 S0391 H0674) · window/workspace*

- **Type:** moment
- **Trigger & evidence:** the user returns focus **≥3 times within ~15 minutes** to
  the same window whose title carries a changing `NN%` or a strong CI/PR state
  marker. Feasibility, corrected against the collector: cut-50 assumed Golem
  already polls the title, and it does not — the inventory refreshes only on
  focus-shaped events, and Hyprland's own `windowtitle` / `windowtitlev2` events
  are **unparsed** (`hyprland.rs:317–341`). That correction is good news twice
  over: adding the arm makes a background title's change an **event**, so the watch
  this action installs needs **no polling and no timer** — the change wakes Golem,
  Golem never wakes to look, which is Constitution VI's second discipline met
  exactly. **[cheap]**, and if a fork build ever lacks the event, the existing
  `j/clients` refresh is the fallback.
- **Sentence:** "You keep coming back to check on this, do you want me to tell you
  when it changes?"
- **Verb(s):** **[tell me when it changes]** — the daemon watches that window's
  title events and fires **one notification** at the transition (the number reaching
  100 %, the marker flipping), then forgets the watch. Two things follow that are
  worth stating plainly. This is a verb whose product is future speech, which
  doctrine 2 forbids — and hunt #1 **acquitted it on doctrine 2's own boundary**:
  the test is information availability, and a battery percentage is already on the
  topbar (A23, killed for exactly this) while a build's state is visible nowhere
  but in that window. The action replaces repeated manual checking of something not
  otherwise visible, which is the one shape of scheduled speech Golem allows. And
  the speech it installs is a **notification**, not an action utterance — the
  world's voice, not Golem's (Constitution II) — so it does not spend the day's
  budget; the one sentence this action costs is the offer itself. Golem also never
  fetches anything: the tab does the network, the engine reads a title, and the
  engine's incapability to reach the network (VI.1) is untouched.
- **Refusal:** not now = this window is answered and the watch is never offered for
  it again, however many times the user returns. Three refusals retire the action —
  someone who likes checking by hand is enjoying the check, and there is nothing to
  fix.
- **Gear:** (a) **what counts as a change** — reaching 100 % / any change / a state
  word, which is where the absorbed **U0085** (watching CI until it turns green)
  and **U0102** (re-checking a PR page for comments) are spent, since those two
  habits differ only in which transition matters; (b) how many returns before
  offering (default 3, within 15 minutes); (c) tell me with a notification
  (default) or a pill; (c) stop offering to watch things.
- **Ladder:** assisted = this window, and the ladder **deliberately stops there**.
  The automatic form — *"watch anything I keep checking"* — would turn one accepted
  offer into an open-ended notification factory, and Constitution IV's whole
  economy dies the day Golem installs watchers nobody asked for. This is the second
  action in the batch (with A17) whose ladder is one rung by design, and the gear
  says so.
- **Privacy note:** while a watch is alive it holds one window address and one
  matched token (the number or the state word) — **in memory, and it dies with the
  window**. At rest: the **≈32 B** lifecycle row and a u8 count of accepted watches,
  nothing else. **No title text is ever written to disk**, and the return-visit
  counter is per live window, so there is no record that a person kept checking
  anything — which is precisely the fact a diary of this detector would expose.
- **Fires:** expiring moment — the anxiety it answers is happening now, so it
  speaks when it fires and spends one of the day's three. Honest frequency, and it
  splits by who you are: **a few times a week** for someone who runs builds, uploads
  or CI; **essentially never** for everyone else, because ordinary windows do not
  put changing numbers in their titles. It belongs to no cluster.

---

### A33 — the gap before it sleeps
*(V33 U0185 T0192 S0404 H0691) · security*

- **Type:** habit
- **Trigger & evidence:** the user's **own** lock act followed, within a few
  minutes, by the machine going idle — counted **≥3×**. F6's ruling stands and is
  the whole point of the block: **the offer is about the TIMEOUT, not about
  locking.** A hand that locks the screen on the way out of the room is not asking
  for a lock button; it is closing a gap between the moment the desk is abandoned
  and the moment the machine notices, and that gap is what the verb shortens.
  **Honest feasibility, and it is the batch's worst: the absence eats BOTH mouths.**
  A whole-tree sweep (repeated for this unit) finds **no idle manager and no locker
  anywhere in Golem** — no hypridle, no swayidle, no hyprlock, no locker in
  `system/`, none in the launcher. A26 was written dormant on that same absence,
  but A26 at least kept a sensable trigger; here the absence takes the trigger too,
  because with nothing that locks and nothing that sleeps there is **no lock act to
  count and no sleep to hook**. On a stock Golem this action cannot come into
  existence, and it is written in full and **dormant** on that basis. Do not read
  the sentence below as a description of a shipped `hypridle` configuration: there
  is no `hypridle`. When one arrives, the trigger costs nothing (`loginctl`'s
  session `LockedHint` and `ext-idle-notify-v1` are both events on connections the
  daemon already holds — **[cheap]**, no timer, no new wakeup).
- **Sentence:** "You lock the screen by hand whenever you get up, do you want it
  locked as soon as the screen sleeps?"
- **Verb(s):** **[lock as soon as the screen sleeps]** — writes one readable line
  into `~/.config/golem/rules/idle` setting the lock delay after blank to zero,
  which the idle manager reads. Doctrine 6 decides the shape: **the idle manager
  owns this behaviour, so Golem flips its switch** rather than running a locker of
  its own on a timer of its own (a second thing that locks the screen is how two
  lockers end up racing over one session). The verb therefore has an addressee only
  once Golem ships an idle manager; today it has none, and the block says so rather
  than writing config for a program that is not there.
- **Refusal:** not now = the gap is the user's business and stays theirs. Re-offer
  only after **three more** hand-locks and never more than once a month; two
  refusals retire the action permanently — someone who likes locking by hand is
  performing a small ritual of leaving, and there is nothing here to fix.
- **Gear:** (a) **how long after the screen sleeps** — immediately / 30 s / a
  minute; (b) **only on battery** or always; (c) don't offer this again.
- **Ladder:** the rule **is** the first offer (doctrine 3): the hand-locks were the
  tutorial and offering *"lock it now"* would be doctrine 2's toll on a keybind the
  user already owns. Above the rule: nothing. The obvious next rung — locking when
  the user *seems* to have walked away — is presence-guessing, which is the
  surveillance register and is not available to this batch at any price.
- **Privacy note:** one u8 count of lock-then-idle pairs, plus the shared **≈32 B**
  lifecycle row — **≈33 B**. No timestamps, no per-day record: what is stored is
  that a shape of event happened three times, never when, and never how long the
  desk stood empty (which is a diary of a person's absences, F4 doctrine 2's
  neighbour).
- **Fires:** **zero until Golem ships an idle manager and a locker**, which today it
  does not; thereafter **one sentence, ever**. Habit unlock, so it waits behind
  everything expiring. **Flagged for P8 alongside A26: if batch 1 ships before an
  idle manager does, this is a kill, not a wait** — and it is the stronger kill of
  the two, because A26 would at least still be counting.

---

### A34 — another finger
*(V34 U0186 T0193 S0409 H0698) · security*

- **Type:** habit
- **Trigger & evidence:** an **attempt-outcome ratio over a rolling window** — the
  last 20 fingerprint verifications, offering when **≥40 %** of them did not match
  (minimum 10 attempts, so a bad morning cannot trip it). The action **exists only
  where the reader does**: `golem.hardware.fingerprint` is set by USB-vendor
  detection (`system/hardware-detect.nix:351–354`, `hardware.nix:202–209`) and is
  the sole gate on `services.fprintd.enable`
  (`system/hardware/fingerprint.nix:9–10`, `system/Modular/quirks/fingerprint.nix:9`);
  where no reader was found, fprintd never runs and this action never comes into
  existence. **The drafted feasibility is wrong and is corrected here.** cut-50
  tagged the evidence *"fprintd verify outcomes over dbus [cheap]"*, but Golem is
  **not a party to that exchange**: the verify conversation runs between
  `pam_fprintd` and `fprintd` on the system bus, and listening to it means becoming
  a **D-Bus monitor on another program's session** — the exact posture A03 was made
  dormant for, and one we do not get to adopt for a smaller prize. Relocated, and
  the honest tag is worse: the evidence is **fprintd's own outcome lines in the
  journal**, which the owner may read without privilege because the account is in
  `wheel` (`system/Modular/base/users.nix:13–18`) and systemd ACLs the system
  journal to that group. Two outcome shapes are counted — matched, and
  not-matched-or-retried — and **every line is discarded after it is counted**.
  Tag: **[new]** — and hunt #2 made the correction in writing, because the drafted
  tag was a tag error: the catalog's [bridge] legend names **one** socket, Golem's
  own bridge (`$XDG_RUNTIME_DIR/options/bridge.sock`), and fprintd never talks to
  it, so [bridge] never named a mechanism this action uses. This is a **new
  collector** (nothing in the engine reads the journal today — zero matches for
  journal over `crates/options-engine/src`) — and a cheap one: one scoped
  `journalctl -u fprintd.service` line reader on the `pw-mon` watcher pattern the
  audio collector already ships (`audio.rs:156–168`). The posture question P5
  flagged is answered rather than smuggled: reading the journal is **not** the A03
  posture. A03 would become a monitor on a **private session between two other
  programs**, observed without either knowing; the journal is a **published system
  log**, ACL'd to `wheel` by systemd's own design
  (`system/Modular/base/users.nix:13–18`) and read by every administrator on every
  Linux machine. Eavesdropping on a conversation is not the same act as reading a
  notice board.
- **Sentence:** "The fingerprint reader has been missing about half the time, do you
  want to add another finger?" — the sentence is about **the reader**, never about
  the finger or the person holding it, and the number is read **live at offer
  time** from the counter (F4's name-at-offer-time doctrine applied to a quantity).
  The 40 % threshold exists so that *"about half the time"* is true when it is
  said; below it, the sentence would be a small lie and the action stays quiet.
- **Verb(s):** **[add another finger]** — runs `fprintd-enroll` **in the user's own
  session, visibly**, through the seam the launcher already owns:
  `launch::launch(exec, needs_terminal, terminal)` (`main.rs:4303`), the same path
  that starts any terminal-shaped app. Enrolling is a multi-swipe conversation with
  the hardware; it must happen in front of the user's face, and Golem never runs it
  in the background. Where `fprintd-enroll` is not on PATH under
  `services.fprintd.enable`, the fix is one line in our own
  `system/hardware/fingerprint.nix` — our tree, not another project's.
- **Refusal:** not now = silence until the relationship materially worsens: another
  full window of 20 attempts **and** a worse ratio than the one already refused.
  Two refusals retire the action — a person who has decided to live with a
  half-working reader has made a choice, and repeating the offer is nagging about
  hardware.
- **Gear:** (a) **the miss ratio that counts as "missing"** (default 40 % of the
  last 20); (b) count **logins only** or also `sudo` prompts; (c) **forget what I
  know about the reader** — zeroes both counters; (d) don't offer this again.
- **Ladder:** assisted = this one offer, and **the ladder deliberately has no
  automatic rung**. Golem never enrols a fingerprint on its own — the tree already
  states the rule in its own words (*"enrollment stays the owner's explicit act
  (fprintd-enroll), so a false positive is an idle daemon, never surprise
  biometrics"*, `fingerprint.nix:3–5`), and an action that quietly climbed that
  rung would be the single worst thing in this batch.
- **Privacy note:** two u16 counters (attempts, non-matches) over the rolling
  window plus the **≈32 B** lifecycle row — **≈36 B**. **No biometric data is ever
  visible to the engine**: fprintd does not expose templates to anyone, Golem never
  asks, and the journal lines are read for one of two outcome words and thrown
  away — never stored, never dated, never attributed to a finger.
- **Fires:** **one sentence, ever**, and only on a machine that has a reader *and*
  a flaky one — most readers either work or are never used at all. Habit unlock,
  **MORNING cluster rank 2** — behind A39, ahead of A13/A14, the ranking its own
  first member cites — so it waits for a morning whose budget has room and whose
  higher ranks are silent.

---

### A35 — the open vault
*(V35 U0187 T0194 S0411 H0701) · security*

- **Type:** moment
- **Trigger & evidence:** a window of a known vault class is **present and
  unlocked** while the session is plainly in use (other windows taking focus) and
  **no focus visit has reached the vault for ≥4 hours**. **The drafted trigger
  leaned on "the desk idle", which does not exist in Golem** (the A26/A33 absence),
  and this block takes the first of the two ways out rather than inheriting the
  dormancy: **the trigger is re-specified without idle**, off the focus stream
  alone — a window that has not been looked at in four hours, on a desk where other
  windows were, is exactly the observation the offer needs, and it is **[live]** on
  the collector Golem already runs. **What notices the four hours passing is named,
  because it is this trigger's doctrine-9 question answered honestly:** the system
  collector's **3 s tick** (`system.rs:19`, the same one A24 rides) compares
  against a stored last-focus instant — a poll that already runs, so no detector
  books a wakeup of its own. Lock state is read as a **transient
  classification** of the title's shape (a database open vs the bare app name),
  which F4 doctrine 4 permits precisely because only the class survives the read —
  the database's name is never stored. **The honest blind spot, stated for P8:** a
  vault that lives in the tray has **no window**, so this action cannot see it at
  all; it exists only for vaults kept on screen, and P8 should weigh whether that is
  most of them. Second gate: **no vault ships in Golem** (nothing in `system/`
  installs KeePassXC, Bitwarden or any sibling), so like A24's charge threshold this
  action comes into existence only on a machine whose owner installed one.
- **Sentence:** "Your password vault is still unlocked, do you want it locked?" —
  the sentence describes **the door**, never the person. The drafted alternative
  (*"you left your vault open"*) is the textbook scold and was rejected at F6.
- **Verb(s):** **[lock it]** — calls **the vault's own documented lock command**,
  over the session bus the daemon can already speak (`zbus 5` is a dependency,
  `crates/daemon/Cargo.toml:24`); for KeePassXC that is its documented
  `lockAllDatabases` method on its own D-Bus interface. **Condition (i) discharged
  as a rule, not a promise: where an app publishes no documented lock command, this
  action does not exist for that app** — Golem does not aim a signal at another
  program's process to make it do something it did not offer to do, which is the
  same treatment A24 gives absent hardware and A37 gives an absent preference key.
  The per-app command is verified per app and per version before the class is
  admitted, and an unrecognised vault is simply not a vault as far as this action
  is concerned.
- **Refusal:** not now = the door is the user's, and the subject is closed **for the
  rest of the session**; at most one offer a day in any case. Three refusals retire
  the action — a person who leaves the vault open on purpose has a threat model, and
  it is not ours to correct.
- **Gear:** (a) **how long unattended before asking** (default 4 hours); (b) **which
  vaults** — the classes Golem knows a lock command for, each removable; (c) **lock
  it on its own after this long**, the ladder's automatic rung; (d) don't offer this
  again.
- **Ladder:** assisted = **[lock it]**, this once. Automatic = **the vault's own
  idle-lock preference**, turned on in the vault's own settings — **condition (ii)
  discharged**: doctrine 6 says that when an app owns the behaviour Golem flips the
  app's switch, and here it matters more than usual, because a Golem timer racing
  the vault's own timer produces two locks, two prompts and a bug report nobody can
  reproduce. The rung is revocable in the vault's UI, where a vault user already
  looks for it.
- **Privacy note:** per vault class an 8 B hash and one bit of last-seen state, in
  memory, dying with the window; at rest the **≈32 B** lifecycle row plus a u8
  offer count — **≈33 B**. **The database name never leaves the moment it was read**
  (name-at-offer-time), which is why the sentence says *"your password vault"* and
  not the file you keep it in.
- **Fires:** expiring moment — the vault is open **now** — so it speaks when it
  fires and spends one of the day's three, capped at **≤1/day**. Honest frequency:
  a few times a month, and **zero** for anyone whose vault is tray-resident or who
  has not installed one. No cluster.

---

### A36 — the vault clipboard
*(V36 U0188 T0195 S0413 H0710) · security*

- **Type:** moment
- **Trigger & evidence:** **the shipped code already knows what came out of a
  vault, and it knows it better than the draft proposed.** The clipboard module
  detects vault provenance from the **de-facto `x-kde-passwordManagerHint` type
  offered by KeePassXC/Bitwarden and their siblings** and refuses to record such a
  clip at all (`clipboard.rs:518–526`, *"sensitive clip (password-manager hint) —
  not recorded"*) — a check added after a security pass found copied passwords
  landing verbatim in the plaintext on-disk history (DockMenu, 2026-09-09). So
  provenance is **[live] and declared**, not inferred: the offer *tells* us, in a
  type name the clipboard code is already enumerating (`best_text_mime(&types)`,
  `clipboard.rs:493–502`). **Hunt #1's gate on OBSERVED non-clearing is honoured:**
  Golem speaks only after **≥2 occasions** where a vault-born clip was **still the
  current offer after the window elapsed** — an *absence* on an event stream that
  already exists, **settled by the next clipboard offer's arrival**, the second
  event doctrine 9 asks for, so no detector owns a clock and nothing is read,
  hashed or compared. If the vault clears its own clipboard, as most do, the gate never opens
  and **this action never comes into existence**. The fallback for a vault that sets
  no hint is the drafted signal — a clipboard offer arriving while a vault class has
  focus — carrying the **same flag**, which is named once here as the **vault-born**
  flag and reused: A02's gear already points at it, and the batch does not get two
  names for one bit.
- **Sentence:** "That came from your vault, do you want it cleared from the
  clipboard in 30 seconds?"
- **Verb(s):** **[clear it in 30 seconds]** — a **one-shot standing rule**, not a
  per-paste favour: it writes one readable line into
  `~/.config/golem/rules/clipboard`, and from then on any vault-born clip is cleared
  at the timeout with `wl-copy --clear` (wl-clipboard ships, `home.nix:58`, and the
  module already calls `wl_copy` to restore clips, `clipboard.rs:408`) — unless a
  newer offer has replaced it first, in which case there is nothing to clear.
  Revocation is deleting that line.
- **Refusal:** not now **retires it outright**. This is the batch's only single-
  refusal action, and deliberately so: the offer is made once, after evidence, about
  a risk the user may already be managing by hand; a second asking would be Golem
  insisting it knows the user's password hygiene better than they do.
- **Gear:** (a) **the window** — 15 / 30 / 60 seconds; (b) **what counts as
  vault-born** — clips the vault itself marks (default) or also anything copied
  while a vault has focus; (c) stop clearing.
- **Ladder:** **the rule is the first offer** (doctrine 3) and the assisted rung is
  skipped on purpose: a per-paste offer would be multi-daily speech about something
  that usually already works, which is F5 doctrine 5's "never teach the user their
  own tool" wearing a timer.
- **Privacy note:** a u8 count of observed non-clears plus the **≈32 B** lifecycle
  row — **≈33 B**, the smallest evidence store in the batch that still gates an
  offer. **The engine never classifies, hashes or stores vault-born clipboard
  content — its existence is the entire signal**, and the shipped code goes further
  by refusing to record it at all. This is the best privacy-to-effort ratio in the
  batch precisely because the work was already done for another reason.
- **Fires:** **one sentence, ever**, and **zero** for the majority whose vault
  already clears. It is an expiring moment when it does fire (the clip is on the
  clipboard now), so it speaks rather than queues — which is exactly why hunt #1
  amended the day's budget into a priority queue: a safety offer must not be crowded
  out by two habit unlocks.

---

### A37 — on the way out
*(V37 U0192 T0199 S0421 H0732) · security*

- **Type:** habit
- **Trigger & evidence:** the browser's **clear-browsing-data dialog** appears,
  counted **≥3×** across days, read as a window title. The tag has to survive on a
  narrower mechanism than the draft's, which hunt #2 named: `windowtitle` /
  `windowtitlev2` are **unparsed** by the collector, but the clear-browsing-data
  dialog **takes focus**, and a focus event re-reads the title
  (`activewindow` → `RefreshWindow` → `j/activewindow`, `hyprland.rs:326`, `:289`).
  So the trigger is **[live] for modal dialogs and only for those** — exactly the
  reach this action needs. One honest fragility, stated rather than papered
  over: **that title is per-browser, per-version and per-locale** (browsers have
  renamed and re-shaped this dialog more than once, and in some the panel is a
  settings subpage whose title says only *"Settings"*). The detector therefore
  carries a **small per-browser table** of the exact title shape, and **where no
  distinguishing title exists, the trigger does not exist for that browser** — the
  same refusal-to-guess that governs the verb below. This is the constitution's own
  illustration (III/VI.2), and it deserves to be built on a signal that is actually
  there.
- **Sentence:** "You clear your history most times you finish with the browser, do
  you want the browser to do it itself on the way out?"
- **Verb(s):** **[clear it on the way out]** — **Golem never touches the history
  store.** It turns on **the browser's own clear-on-shutdown preference**, scoped to
  history, written **while the browser is not running**, and the browser does the
  deleting it has always known how to do. **The three F6 conditions are carried
  unsoftened, and the tree makes the third one bite hardest:**
  *(i) a documented scoped key, per browser, or the action does not exist there.*
  For Firefox the key is the user's own — the `sanitizeOnShutdown` family in
  `prefs.js` of the default profile, written while closed; `user.js` was considered
  and **rejected**, because it re-asserts at every start and takes the setting away
  from the browser's own UI, which is authorship the user never signed. **For
  Golem's default browser, Chrome, the answer is no.** `programs.chromium` ships
  `google-chrome` as the desktop's browser (`system/home/home.nix:169–171`), and
  Chrome's only documented scoped mechanism is an **enterprise policy**
  (`ClearBrowsingDataOnExitList`, which does take browsing history) — written into
  exactly the directory our own tree already writes for the legacy-video fallback
  (`system/hardware-runtime.nix:84–89`), so the mechanism is proven and reachable.
  It is still refused: a managed policy is root-owned, needs root to revoke, and
  **brands the browser "managed by your organization"** on every settings page — a
  consequence that cannot be disclosed inside one sentence, and a revocation that
  breaks the batch's rule that a signed rule is undone by deleting a line you can
  read. **So A37 exists for Firefox and does not exist for Chrome.**
  *(ii) the sentence and gear name exactly what will be cleared* — and this is not
  pedantry: newer Firefox moved to a clear-on-shutdown family that **bundles
  history with downloads and form data**, so on such a version the offer either
  names the bundle or does not exist, because a user logged out of everything
  tomorrow morning was not offered that.
  *(iii) the write happens only while the browser is closed.* Tag stays **[new]** —
  small, bounded, unshipped.
- **Refusal:** not now = silence until the habit re-proves itself (another **5**
  observed clears) and never more than once a month. Two refusals retire it: a
  person who clears by hand may be enjoying the deliberateness of it, and
  automating a ritual is not always a kindness.
- **Gear:** (a) **exactly what gets cleared** — history, plus anything the installed
  version bundles with it, named; (b) **which browser**, where more than one
  qualifies; (c) **turn it back off** — flips the browser's preference back, so the
  undo lives beside the do; (d) don't offer this again.
- **Ladder:** the rule **is** the offer (doctrine 3), and there is no rung above it:
  the browser is already doing it every time. The rung *below* — Golem clearing the
  history itself — is the one F6 removed, and it stays removed.
- **Privacy note:** a u8 count of observed clear-dialog appearances plus the
  **≈32 B** lifecycle row — **≈33 B**. Golem knows **that** you clear, never
  **what** was cleared: no URL, no title text, no history entry is ever read, and
  the preference write is a boolean in another program's config file. This is
  Constitution VI.2's own example, honoured literally.
- **Fires:** **one sentence, ever** — and **zero on a stock Golem desktop**, because
  the browser that ships is the one this action does not exist for. Habit unlock, no
  cluster, waits behind everything expiring. **Flagged for P8:** the constitution's
  flagship illustration is, on today's Golem, mute — which is a finding about the
  distro's browser choice, not about the action.

---

### A38 — the second knob
*(V38 U0196 T0203 S0430 H0809) · health/ergonomics*

- **Type:** habit — and structurally the odd one: **A38 is a second nested verb on
  an utterance that already exists**, the live sunset prototype
  (`SUNSET_MSG`, `crates/daemon/src/options.rs:137`). It writes no sentence of its
  own, and F6 ruled it the batch's proof that an action can ship as **growth on an
  existing action** rather than as new speech.
- **Trigger & evidence:** the prototype's own utterance is on screen (its trigger is
  unchanged and not ours to touch) **AND** the user has, on **≥3 evenings**, dropped
  the backlight by hand after sunset. **Honest downgrade from the drafted [live]:**
  the engine carries **`has_backlight`, a bool, and no brightness value anywhere** —
  `has_backlight()` is a bare `read_dir("/sys/class/backlight")` existence check
  (`collectors/system.rs:214–218`, surfaced at `state.rs:250–253` so that brightness
  controls are offered only where they would do something). Nothing reads the
  *level*, so the correction cannot be counted today. The unblock is the smallest in
  the batch: **one more read inside the same `read_dir`** — `brightness` over
  `max_brightness` as a percent, on the collector's existing poll, **no new
  wakeup** — which makes this **[cheap], in our own tree**, the same shape as unit
  3's six. One discipline is binding and is the reason the evidence is not simply
  "the level changed": **Golem's own dimming must never count.** The shipped
  `system.battery_dim` OPTION (§4.29) sets 40 % itself, and an engine that counted
  that would learn its own behaviour and offer it back — the identical trap A17
  avoids by counting only the user's own DND toggles, and A39 avoids below. **Three
  instances now; P8 should consider naming it a doctrine.**
- **Sentence:** **none.** It rides *"The sun is set, do you want to turn on eye
  protection?"* unchanged. This is the entire point of the action.
- **Verb(s):** **[and dim the screen]** — steps the backlight to the user's **own
  observed evening median** via `brightnessctl`, a command the engine's affordance
  layer already runs (`mind/affordance.rs:55`); the prototype's **[turn on]** is
  untouched, and either pill may be clicked alone. The structural cost is real and
  is named exactly rather than waved at: the module already nests **two** pills
  ([turn on] and the gear) with a documented gap between them, but the morph's width
  math hardcodes **one** inner label (`options.rs:2114–2121`) and
  `sunset_nested_rects()` returns a **2-tuple** (`options.rs:1804`) — so a third
  pill is a width sum, a rects tuple, one `PillId` and one hit-test arm, in a module
  that already does multi-pill nesting. **Narrow-display ruling, made here so P8 can
  check it:** where the message plus three pills would exceed the module's available
  width, the second verb is **dropped, never truncated** — a half-visible verb is
  worse than no verb, and the prototype must read the same on a 2013 Air's panel as
  on a desk monitor.
- **Refusal:** the prototype's right-click already means *"not now"* for the whole
  utterance and is unchanged. Refusing **only** the dim is a real gesture — taking
  [turn on] and leaving [and dim the screen] — and it is counted: **three such
  evenings retire the second pill** and the prototype returns to one verb, silently.
- **Gear:** no new gear box — the controls join the prototype's existing panel,
  which already carries an *"Automatically at sunset"* toggle (`sunset.rs:239`):
  (a) **the evening level** (default: the user's own median); (b) **bring it back up
  in the morning** — which is where the absorbed **U0194** (the morning brightness
  nobody brings back down) lives, and it is the one control in this block a user
  will actually go looking for; (c) dim automatically with the warmth; (d) stop
  offering the dim.
- **Ladder:** assisted = the second pill, clicked. Automatic = *"dim with the warmth
  every evening"*, which is the rung the prototype's own auto-toggle already
  defines — A38 does not invent a ladder, it extends one that is live.
- **Privacy note:** a u8 count and an 8-bit median evening level — **≈2 B**, and
  **no lifecycle row of its own**, because it has no utterance of its own to track.
  It is the smallest at-rest footprint in the batch by an order of magnitude, and
  the reason is structural: growth on an existing action inherits that action's
  bookkeeping.
- **Fires:** **literally zero new sentences, forever.** It does not enter the day's
  budget, it does not join a queue, it does not have a cluster rank — it changes an
  utterance that was going to happen anyway. Hunt #1 called it the safest action in
  the batch, and the block does nothing to spend that.

---

### A39 — the desk ready
*(V39 U0197 T0204 S0434 H0818) · time-of-day*

- **Type:** habit
- **Trigger & evidence:** a recurring **morning class SET** — *which* applications,
  never in which order — plus a **first-focus hour histogram**, stable across **≥3
  mornings**. **[live]** on the focus stream and the daylight/clock layer the engine
  already has. **Set-not-order is a privacy decision, not a simplification:** an
  ordered per-morning log is a diary of a person's waking routine, it would be read
  as one the first time anyone looked at the notebook, and the offer does not need
  it — "these six apps, most mornings, around here" is the entire premise. No dates
  are kept, and no minute: a 24-bucket hour histogram cannot say whether you were
  late on Tuesday.
- **Sentence:** "This is the set you open most mornings, do you want the desk
  ready?"
- **Verb(s):** **[have the desk ready]** — launches the members that are **not
  already running** through the launcher's own seam
  (`launch::launch(exec, needs_terminal, terminal)`, `main.rs:4303`) and
  **activates rather than duplicates** anything that is, which is the dock's
  existing macOS-model behaviour and not a special case written for this action
  (`main.rs:4289–4301`); then places each window by class through the fork's
  **verified runtime rule channel** (`hl.window_rule` over `eval()`,
  `hypr.rs:1109/1147–1152`) and moves it to its workspace with the dispatch the
  daemon already uses (`hl.dsp.window.move`, `hypr.rs:1575`). Two constraints carry
  over and are not optional. **First, the rules live in
  `~/.config/golem/rules/windows` and are re-asserted by the daemon**, because a
  `hyprctl reload` wipes runtime settings (unit 3's A31 finding) — a desk that
  un-arranges itself on the next reload is worse than one that was never arranged.
  **Second — the find of this unit — the verb must launch WITHOUT touching the
  ranking.** The launch path increments the launcher's usage counter on both
  branches (`main.rs:4292` on activate, `main.rs:4306` on launch), and `usage.json`
  is the one sort key the dock ranks by; a Golem-run morning would therefore teach
  the launcher that the user clicks six apps every day that they never clicked,
  re-ordering their own dock around Golem's behaviour. One bool on the launch path
  fixes it, and that bool is why this action is **[cheap]-pending rather than
  live**.
- **Refusal:** not now = silent **for a fortnight**, and then only if the set is
  still the same set (a changed routine is a new observation, not a retry of an old
  one). Two refusals retire the action: someone who opens their apps by hand is
  performing the start of their day, and there is a real chance the ritual is the
  point.
- **Gear:** (a) **which apps are in the set** — the observed list, each one
  removable (absorbs **U0001** browser-first, **U0013** the morning webapp set,
  **U0014** email first, **U0027** chat after login, **U0036** music first,
  **U0079** terminal first: six habits that differ only in *which* app, so they are
  rows in this list, not six actions); (b) **where each one goes** — the workspace
  per app, which is **U0175**'s home (rebuilding the layout by hand after every
  reboot) and the reason the verb places as well as launches; (c) **run it at
  login**, the ladder's automatic rung; (d) **don't touch what's already open**
  (default on); (e) forget my mornings. **Seven absorbed habits spent as five
  controls** — the batch's largest absorption, and it is a list and a map rather
  than a paragraph of promises.
- **Ladder:** assisted = **[have the desk ready]**, this morning, one click.
  Automatic = **at login**, from the gear or after repeated yeses — the textbook
  shape of Constitution IV's ladder, and the one action in the batch where the
  automatic rung is obviously the destination.
- **Privacy note:** per class an 8 B hash and a u8 morning count, ring of 16 =
  **≈150 B**; one 24-bucket u8 first-focus histogram = **24 B**; plus the **≈32 B**
  lifecycle row — **≈206 B**. The draft's superlative was re-added for the batched
  audit and failed: this is **not** the largest store in the batch (A02's is
  ≈700 B, A21's ≈550 B), and all thirty-four privacy notes sum to **≈3.7–3.8 KB**
  — the qualitative claim survives the recount, the superlative did not. **No
  dates, no order, no session log**: what is on disk is a set, a count and a shape
  of hour. The application *names* are read live from the world when the sentence
  and the gear list are built (name-at-offer-time), so the hashes on disk are not a
  list of your programs.
- **Fires:** **one sentence, ever.** It is the **MORNING cluster's rank 1** — ahead
  of A34, then A13/A14, the ranking its own first member cites — so the draft's *"no
  rival for that mouth"* claim was corrected here: it has rivals, and one mouth per
  cluster means a first-week whose A34 or A13/A14 unlocks cross at the same time
  staggers them. It is a habit unlock, so it waits for a morning when the day's
  budget has room and no expiring moment has taken the hour. Honest: days to a
  fortnight after the third morning.

---

### A40 — close up
*(V40 U0203 T0210 S0451 H0853) · time-of-day*

- **Type:** habit
- **Trigger & evidence:** **the user has already begun leaving** — the **first two
  closes** of the work-class set inside a recurring end-of-session window, on **≥3
  days**. **It must never speak at an hour**, and the block states the reason
  plainly because it is the difference between a companion and a manager: an action
  that fires at 18:00 is a clock telling you to go home, while an action that fires
  after you have closed two things is holding the door. The hour histogram exists
  only to recognise *this* closing as the end-of-day one, never to start the
  conversation. Feasibility, corrected in a useful direction: the daemon **already
  subscribes to `closewindow`** — it is in the dock's `RELEVANT` event list
  (`hypr.rs:35–45`) and is handled for the stage's bookkeeping (`hypr.rs:824–829`) —
  but the engine's own collector does not parse it into a signal (unit 3's finding
  about `parse_event`). So the event is **already arriving in this process** and
  needs an arm, not a subscription: **[cheap]**, our own tree, no new wakeups.
- **Sentence:** "You have started closing up, do you want the rest of it closed?" —
  present tense, describing what is already happening, never predicting.
- **Verb(s):** **[close up]** — **polite close requests only.** Each remaining
  member of the set gets the compositor's **close dispatcher** through the channel
  the daemon already owns (`hypr::dispatch`, `hypr.rs:69`) — **exactly what clicking
  the X does** — and **never a signal**, so every application's own save prompt
  still stands between the user and a lost document. This is hunt #1's repair of
  R05's data-loss hazard and it lives in the verb line, not in a footnote. The one
  name to verify before this ships is the **fork's Lua spelling of the close
  dispatcher**: the legacy `hyprctl` form is rejected by Golem's fork (A29's
  finding), so the Lua dispatch is the only road, and the channel that carries it is
  already proven. Stopping playback rides `playerctl`, which the daemon already
  shells out to (`main.rs:2789`) — that is **U0068**'s home, the music going off as
  the closing act.
- **Refusal:** not now = **silent for the rest of this evening**, and back of the
  queue for the evening cluster, so tomorrow's closing offers whatever has not been
  answered instead. Three refusals retire it. It is never re-offered inside the same
  closing — asking twice while someone is leaving is the exact texture of nagging.
- **Gear:** (a) **which apps are in the work set** — each removable (**U0184**, the
  habit of closing every window before shutdown, is this list); (b) **also stop the
  music** (**U0068**, default on); (c) **never close a call or anything sharing the
  screen** (default on, and not really optional — it is **U0035**'s home, the call
  app left running, and it leans on the two signals the shipped engine already has,
  the call detection behind §4.14's DND and the screencast state behind the amber
  pill); (d) **hold back the ones I check last** — email waits until the end and
  asks, which is where **U0034** (the last email check) lives; (e) stop offering.
- **Ladder:** assisted = this evening's **[close up]**. Automatic = *"close up when
  I start closing"*, and the rung is deliberately conservative: **it never closes the
  first window**. It follows the user's own first two closes and only then finishes
  the set — an automatic rung that could initiate the closing would be a machine
  deciding your day is over, which is not a rung, it is a different product.
- **Privacy note:** per class an 8 B hash and a u8 count, ring of 16 = **≈150 B**;
  a 24-bucket u8 closing-hour histogram = **24 B**; plus the **≈32 B** lifecycle
  row — **≈206 B**. No per-evening log and no durations: the histogram says *when
  closings tend to happen*, never how long anyone worked, which is F4 doctrine 2's
  line (no stopwatch over a person's day) drawn on the other end of it.
- **Fires:** **one sentence, ever**, and it is the **EVENING cluster's rank 4** —
  behind the sunset prototype (with A38 riding it), A11 and A20 — so honestly it
  waits **weeks** after its third qualifying day, because the evening mouth is the
  busiest in the batch. That is the queue working: the offer costs nothing while it
  waits, and its evidence was an aggregate before it ever spoke.

---

*Unit 4 of 4 complete — **the register is CLOSED at 34 of 34**. Final, after the
hunt #2 audit and P9: this note carries the corrected totals, because the
BATCH-WIDE TOTALS below the original note were written before hunt #2 §7–§10
re-tagged and recounted the register. **(1) Three [new] verbs, final — and both
members changed:** the set is **A29 (the `zwlr_output_manager` actuator), A34 (the
fprintd journal collector), A37 (the browser's own preference write)**. A02 left
the column when hunt #2 found the clipboard store already exists
(`clipboard-history.json`, `clipboard.rs:225`, `save_clip_history()` `:1573`) —
what it needs is permanence, a pinned flag, **[cheap]** — and A34 entered it when
its [bridge] tag was shown to name a socket it never touches. The number survived
three by accident, wrong in its members twice; this is the set that survives the
audit. **(2) Two actions dormant on the idle-manager absence: A26 and A33** —
settled by hunt #2 §8.1: idle SENSING is not missing (under `ext-idle-notify-v1`
the compositor is the source), what is missing is anything that ACTS on idle, so
both stay dormant and are **flagged as kills in waiting** if batch 1 ships before
an idle manager does. **(3) The batch ships ZERO [bridge]** — A34's was a
mislabelled [new]; F3's zero was never a regression. **(4) At-rest footprint,
re-added: 33 lifecycle rows at ≈32 B ≈ 1.06 KB** (A38 has none of its own), the
heaviest per-action store is **A02 at ≈700 B** with A39/A40's ≈206 B **fourth,
not first**, and the whole register sums to **≈3.7–3.8 KB** — *a few kilobytes of
counters, hashes, medians and histograms* survives the recount. **(5) The two
ratified system laws stand with one clarification for the record: the day's
budget is a debt, not a gate** — expiring moments overrun it and tighten the next
day. And the batch's honest headline, recounted block by block in P9: **10 of 34
can speak on today's engine; 24 cannot** (hunt #2 fixed 13→11 by removing A01 and
A07; P9 then removed A19, whose own block says no annotator or screenshots dir
ships on a stock Golem). Next: batch 2, phase P0.*

