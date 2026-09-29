# Changes — the OPTIONS ledger

The queue of what OPTIONS owes. **The number line is one line:** #1–#61
live in the preinstall archive and DockMenu's `FINDINGS.md`, #62–#67 are
Installing's (`../Installer/installing/changes.md`); this file continues
at **#68**.

## How to use this file

- A finding's raw experience goes where it happened — a GRIND session
  note, a machine's file, a VM screenshot. The **change it implies**
  lands here: what / why / where (file:location) / size (small · medium ·
  needs-Max). Status rides the header tag. Newest number first.
- Waverunner-side fixes ride the launcher → Golem lock → seed pipeline
  (#41). A fix is not real on a machine until the seed carries it.
- An entry moves below the line when it is applied **and verified** in
  method §4's vocabulary — sensed → surfaced → triggered → effect
  observed, with a screenshot. "The test is green" does not move an
  entry.

### A note on #68–#82 — numbered 2026-09-12, found earlier

This ledger was created on the day the program directory was stood up,
and the entries it opens with were **not discovered that day**. Each was
already written down as a known-open item in [UXRules.md](UXRules.md),
[modules.md](modules.md), [catalog.md](catalog.md), a GRIND session note,
or the engine's own source comments — on the dates each entry cites. They
simply never had numbers, so they could not be queued or closed.
Numbering is bookkeeping, not a discovery claim, and the numbers are
cheap to withdraw before anything cites them.

The exceptions are **#79–#82**, which *are* new: they fall out of reading
the [constitution](constitution.md) against the code, and pillars 4 and 5
had no findings at all before 2026-09-12.

---

## Queued

### 84. The cava pill recorded the MICROPHONE — `pw-record --target <sink>` silently falls back to the default source — [FOUND + FIXED on metal 2026-09-12 · the first thing in Golem to touch a live audio input, and it got it wrong]
**What happened.** The spectrum capture was spawned as
`pw-record --raw --target <sink-name> -`, which reads correctly and is
wrong. For a **capture** stream PipeWire does not interpret a sink target
as "that sink's monitor" — it ignores it and connects to the default
**source**. On the dev box the live link graph read:
```
alsa_input…HiFi__Mic1__source  ->  pw-record   [active]
```
The daemon was holding the built-in microphone open, from the moment Max
restarted it to test the pill until the capture was killed — a few
minutes. It is the exact line method §6 exists to draw, crossed by the
first feature that ever went near an audio input.

**Why it was not caught earlier.** The shape of the failure is silent in
both directions. The pill still appeared (it keys off `playing`, not off
the capture), the capture still produced bytes, and the bytes were
*silence* — because the mic was quiet — which looked exactly like the
expected "nothing audible is playing". Two independent wrong things
presenting as one right one. The manual capture test done before writing
the code had the same flaw and returned the same innocent-looking
silence.

**What actually contained the damage:** nothing was stored and nothing
could leave. The samples go into a 1024-frame ring, become seven bar
heights, and are overwritten ~30×/s; `spectrum.rs` lives in the daemon
precisely so audio never enters `ContextState`, is never serialised, and
is never published to a subscriber; and `options-engine` has no network
dependency by construction. The architecture limited a mistake it did not
prevent — which is the argument for "can't beats doesn't", not against it.

**The fix, verified live:**
- `-P '{ stream.capture.sink=true … }'` — the property that makes a
  capture stream attach to a sink's monitor. Confirmed: the link became
  `bluez_output…  ->  pw-record`, and the captured audio went from 2
  distinct byte values (digital silence) to 257 (real signal).
- `node.name=golem-cava` + a human `media.name`, so the stream is
  identifiable in any volume mixer instead of an anonymous `pw-record`.
  A user wondering what is listening can see the answer without asking.
- **A self-check that outranks the property.** After the first read, the
  worker walks the live link graph and requires *every* node feeding
  `golem-cava` to have `media.class == Audio/Sink`. A microphone is
  `Audio/Source` and fails outright. **Unverifiable counts as failure** —
  if `pw-dump` cannot be run or parsed, we cannot prove we are listening
  to the speakers, and the only safe answer to "am I holding the
  microphone?" is to assume yes and let go. It kills the capture rather
  than degrading into it.

**Owed and not done:** the guard has not been seen firing. It is written
so that the property failing means the capture dies, but nobody has
forced that path — the honest state is "the fix is proven, the backstop
is not". Forcing it (spawn without the property, confirm the guard kills
it) is one session.

### 83. The Brain is a FOCUS sensor, not a WORLD sensor — `ContextState` holds no collections at all — [FIXED in source 2026-09-12 · verified live on the dev box · Max: "we don't even know the user is playing a video on chrome on ws1 and music on spotify on ws5, and have a video paused on ws8. that is basic."]
**FIXED the same day.** `ContextState` gained three inventories —
`windows: Vec<WindowInfo>`, `playing: Vec<Playing>`, `outputs:
Vec<AudioSink>` — and `media: Option<MediaState>` was deleted outright so
nothing can keep pretending there is only one player. The compositor
collector now calls `j/clients`; the audio collector reads the output
streams and the sink inventory out of the `pw-dump` it was already
running; the media collector reports every MPRIS player instead of
`pick_best`, keeps Playing/Paused/Stopped instead of a bool, and asks
D-Bus for each player's **pid**. The two halves are merged by pid in
`engine::merge_playing` — MPRIS's words with PipeWire's routing — and
`ContextState::window_of` / `workspace_of` resolve a player to its window
and workspace.

**Verified live on the dev box, the same session that produced the
finding:**
```
♪ OpenTune - Pixel 8 Pro     [Paused]  @ no window → default
♪ OpenTune - Google Pixel 8  [Paused]  @ no window → default
♪ ffplay — Audio Stream      [Playing] @ no window → …HiFi__Speaker__sink
  outputs: HDMI/DP 3 · HDMI/DP 2 · HDMI/DP 1 · *Speaker · Easy Effects Sink
  windows(2): foot#2752 ws1 · foot#27656 ws2
```
Three sources where the engine used to report one; the previously
invisible `ffplay` is correctly the only thing Playing, with its sink
named; the phone players are correctly paused and window-less. The window
inventory carries pid and workspace, which is the join. (`ffplay` reports
no window because it runs `-nodisp` — the right answer, not a failed
lookup.) 100 engine tests green, clippy clean.

**Left open, honestly:** a *windowed* player has not yet been observed
end-to-end on metal — the pid→window→workspace join is proven by unit
test (`three_players_on_three_workspaces_are_three_entries`) and by the
inventory being live, but nothing windowed happened to be playing during
the session. Also noted: a PipeWire stream can be `running` while
producing silence (the dev box's `ffplay` is playing `anullsrc`), so
"Playing" means *the stream is live*, not *you can hear it* — an OPTION
that says "something is playing" must not treat the two as identical.

The original finding follows.

Every field on `ContextState` is either **the focused thing** or **a global
scalar**. `window: ActiveWindow` (singular), `media: Option<MediaState>`
(one player), `audio: AudioState` (the default sink's volume). There is
not one list anywhere in the struct. The compositor collector only ever
queries `j/activewindow` — **it has never called `j/clients`**, so the
engine has never looked at the set of windows.
- **the concrete failure, on the dev box 2026-09-12:** an `ffplay` stream
  (pid 1520) was playing to the Speaker sink, and the engine could not
  see it at all — no MPRIS player, and non-MPRIS audio is invisible.
  Meanwhile MPRIS held two kdeconnect players (Max's *phone*) and
  `pick_best` would have reported one of them, arbitrarily, as "what is
  playing". Not merely blind: **wrong**.
- **this is why the 76 deleted offers were a per-app toolbar.** It was
  not a failure of taste, it was the data shape: if the only visible
  thing is the focused window, every writable trigger is about the
  focused window. "A browser is focused → find in page" is not a lazy
  trigger, it is the ONLY shape of trigger the sensor permits. Pillar 3
  cannot be built on a sensor that reports one resource.
- **what Max's example needs, per player:** which window · which
  workspace · what state · which output. Zero of the four exist today.
- **three of the four are already fetched and discarded:**
  - `pw-dump` runs **every 2s** in the audio collector and is scanned
    ONLY for mic capture streams; every `Stream/Output/Audio` in the same
    dump is ignored. Each carries `application.process.id` (→ the window,
    since `ActiveWindow.pid` already exists) and `target.object` (→ the
    sink it is routed to). Verified live on the dev box.
  - MPRIS already enumerates every player into `candidates`, then
    `pick_best` keeps one and drops the rest.
  - `j/clients` is already used by the daemon (`focus_exact_class`,
    `workspace_windows`); the engine simply never asks.
  The genuinely new piece is the **sink inventory** (the dev box has 5:
  3 HDMI/DP, Speaker, EasyEffects) and the **PID→window join**.
- **states, too:** MPRIS distinguishes Playing / Paused / Stopped and the
  collector collapses it to `is_playing: bool`, so "a video paused on
  ws8" is not expressible even for the one player that survives.
- **where:** `crates/options-engine/src/state.rs` (the shape),
  `collectors/hyprland.rs` (add the client inventory),
  `collectors/media.rs` (`reconcile`/`pick_best`),
  `collectors/audio.rs` (the dump is already in hand).
- **size:** needs-Max to approve the `ContextState` shape, then medium.
  **This outranks every OPTION on the curated list** — no OPTION worth
  building can be written against a sensor that sees one window.

### 82. 67 of 76 offers are structurally exempt from pillar 4 — the scaffolding kind is used twice — [FOUND 2026-09-12 · the inventory census]
Counting every affordance in the tree: **57 `Control` (never fades), 10
`Warning` (never suppressed), 7 `Info` (fades gently), 2 `Action`** — and
`Action` is the scaffolding kind dynamic difficulty is really for. It is
used for `behavior.focus_churn` and `session.failure_streak`, and nowhere
else.
- **the measured effect, with #79 folded in:** base skill is a constant
  `0.5` and only friction moves it, so pillar 4's entire live dynamic
  range today is two offers moving between ×0.70 and ×1.00 and seven
  moving between ×0.85 and ×1.00. **Real in code, very nearly inert in
  effect.**
- **this may be correct rather than broken — it is a Max call.**
  `Control` is documented as *"the heart of the right action at the right
  moment: the button you were about to reach for"*, and OPTIONS being
  almost entirely Controls is a coherent reading of what OPTIONS *is*. If
  that is the answer, then dynamic difficulty mostly lives in **ACTIONS**,
  and the constitution should say so instead of leaving pillar 4 reading
  as an OPTIONS-wide law it cannot be.
- **if it is not the answer,** then a good number of those 57 were
  labelled `Control` because `Action` would have made them fade, which is
  method §2's "choosing the kind is a design act" being skipped — and the
  audit is one pass over the list asking, per offer, whether an expert
  genuinely wants it unchanged.
- **where:** [inventory.md](inventory.md) has the full census;
  `crates/options-engine/src/mind/decide.rs`.
- **size:** needs-Max (one decision), then either a doc change or a
  medium audit pass.

### 81. `Affordance.reason` was designed for diegetic phrasing and the surface never reads it — [FOUND 2026-09-12 · pillar 5]
Every affordance carries a `reason: &'static str`, documented in
`affordance.rs` as *"why it was surfaced — for debugging and for
**diegetic phrasing**"*. The engine fills it in **77 places**. The daemon
reads it in **zero**: the tooltip shows the offer's *title*, and nothing
on the bar ever says why it is there.
- **why this is a pillar-5 finding and not a nice-to-have:** pillar 5 is
  not only about where information sits, it is about the information
  belonging to the thing it is about. `reason` is the one field that
  carries that belonging from the Mind to the surface, and it is being
  thrown away at the boundary. The diegetic intent was designed in and
  then dropped in the last ten pixels.
- **also the cheapest honesty win available:** pillar 2 says an offer
  must be able to name the signal that produced it. Today it can, in the
  engine, and never to the user.
- **do not simply print it.** A reason rendered as a debug string under a
  glyph is a HUD caption, which is pillar 5 pointing backwards. The
  question is what it means for the *object* to say it.
- **where:** `~/launcher/crates/daemon/src/options.rs`
  (`push_options_tooltip`, ~2005) against
  `crates/options-engine/src/mind/affordance.rs`.
- **size:** needs-Max (a design call), then small.

### 80. The pill band is a nameable object — the standing debt against pillars 1 and 5 — [OPEN DESIGN QUESTION · raised 2026-09-12]
Pillar 1 says the environment is the assistant; pillar 5 says the
information is integrated into the environment. A strip of glyph circles
standing for arbitrary affordances is a HUD with rounded corners: it is a
*place you look to be helped*, which is the exact object both pillars
exist to abolish.
- **it was the right engineering call and is still a debt.** Catalog §3
  chose the topbar for good reasons — pills already exist, animate,
  hit-test and dispatch, and the design note at `options.rs:249`
  explicitly reserved that seam for the Brain. The cost is that every new
  offer since has had somewhere obvious to go, so nothing has had to earn
  a place in the world.
- **the register that already works:** the clock metamorphosing into the
  date. The object holding the state shows the state. That is diegetic,
  it shipped, and it is well liked — it is the proof the harder path is
  achievable, not theoretical.
- **not a demand to delete the bar.** The bar is how OPTIONS is reachable
  "de manera directa"; the definition asks for both direct and indirect
  access. The question is which offers belong in the world and which
  legitimately belong on a bar — and right now that question has never
  been asked, because there was only ever one answer available.
- **size:** needs-Max. This is the program's largest design question and
  the frontier PLAN.md leads with.

### 79. Pillar 4 is half-built — friction is live, demonstrated competence is never learned — [FOUND 2026-09-12 · `brain.rs:44`]
`calibrate()` and `effective_skill()` are real, tested and good: Action
scaffolding fades ×(1−0.6·skill), Info ×(1−0.3·skill), Control and
Warning never fade, and observed friction (focus churn, failed shell
commands, editor diagnostics, hesitation) lowers effective skill so the
help comes *back* when the user struggles.
- **but the base is a constant.** `daemon_tuning()` hands the Mind
  `skill: 0.5` and nothing ever moves it. So the system calibrates to
  your **last few seconds** and never to your **history** — while the
  pillar says *según tu desempeño*.
- **what that costs, concretely:** a user who has committed from the bar
  four hundred times still gets the same scaffolding weight as one who
  arrived yesterday, and a genuine beginner gets no more than an expert
  having a bad minute. The fading axis exists; the thing it is supposed
  to fade *along* does not.
- **the shape of the fix is constrained by method §6** — gestures, not
  content; aggregates, not diaries. Demonstrated competence is a counter
  per context, not a log. "You have used this offer N times" is already
  the right kind of fact; the ACTIONS habit detectors (≥3 demonstrations)
  are the nearest precedent for how to store it.
- **the notebook comes with it:** learning a persistent fact about the
  user is exactly what the ACTIONS constitution §V says must be
  inspectable and erasable. Competence-learning cannot ship without it.
- **where:** `~/launcher/crates/daemon/src/brain.rs:40–46`
  (`daemon_tuning`), `crates/options-engine/src/mind/decide.rs:265–282`
  (`effective_skill`).
- **size:** needs-Max to scope (it is the first persistent user model in
  Golem), then medium.

### 78. The 45 slices have been held to DoD 1–5 and never audited against 6–12 — [STATED by absence · catalog §4, modules.md]
Population B was built against *sensed → pill → action performs*, which
is DoD lines 1–5. The seven conduct lines — frictionless, repeatable,
still, on tempo, reversible, exclusive, one motion — arrived later
(2026-09-04, out of the UX-law work) and no slice has been walked through
them.
- **we already know the audit will not come back empty:** #68 is one of
  its findings, noticed by looking at the row rather than by the row
  failing on somebody.
- **the cheap half:** line 9 (on tempo — a grep for a rate or hold
  constant) and line 11 (exclusive) are close to mechanical. Lines 7, 8,
  10 and 12 need a session in the chair.
- **and the test above the twelve:** the constitution's acceptance test.
  A slice that passes all twelve and still leaves the user feeling
  *directed* has failed, and only a chair can tell you that.
- **where:** `crates/options-engine/src/mind/decide.rs` +
  `crates/daemon/src/options.rs`, one slice at a time.
- **size:** medium, and it is a *pass*, not a fix — its output is more
  numbered entries.

### 77. The clock's minute tick re-flows the bell by a pixel or two — [TOLERATED · stated 2026-09-04 · UXRules §2]
The same class of change as #68, far below the scale that costs a target,
and deliberately accepted.
- **the trigger to revisit:** if the clock ever takes a wider format.
  Recorded so that day is a lookup rather than a rediscovery.
- **size:** none today.

### 76. Tempo and stillness have never been watched on slow metal — [STANDING · corrected 2026-09-12]
*(This entry originally claimed no OPTION had ever been seen outside the
golem-vm. That was wrong and is corrected here: the dev box runs it
daily, the ASUS has it installed, and `settle.rs` exists **because** of
what Max watched on a 2013 MacBook Air. The real gap is narrower and
worth keeping.)*

What the VM proved: all 45 slices, sensed → pill → action, with
screenshots, on a virtio GPU on a fast host. What real machines have
given us: daily hours on an i9 with Vulkan, an installed ASUS on the GL
fallback, and the Air session that produced the appear-dwell.

**What nobody has ever seen** is the conduct laws under load. §3's tempo
is a *rate*, and a rate reads differently at 20fps; §1's Leader is a
different promise when the re-layout is visible frame by frame; pill
hit-testing under frame-throttle is the #40/#42 bug class exactly.
- **closes when** Installing's stage 1 lands a desktop on a 5400rpm
  Haswell and this program gets a session in that chair.
- **size:** no source change owed. A standing asterisk on the tempo and
  stillness claims specifically — not on the slices.

### 75. One Material's scope at the bar/body boundary is undecided — [OPEN DECISION · stated 2026-09-04 · UXRules §3]
The bar's own conceal grace in fullscreen and the launcher's page slide
were left on their own timings on purpose: both belong to the *surface*
rather than to an OPTION. Whether One Material governs the whole body or
only the OPTIONS bar was flagged and never decided.
- **why it needs an answer:** the audit that produced §3 found six
  modules agreeing by coincidence. An unscoped rule decays the same way —
  the next person to touch the launcher's slide has no way to know
  whether they are inside the law.
- **size:** needs-Max (one sentence in UXRules §3, then nothing or a
  small change).

### 74. Entry and exit are one symmetric ease; the design language asks for spring-in / decay-out — [OPEN DECISION · stated 2026-09-04 · UXRules §3]
Not a defect — a decision nobody has made. The UX/UI guidelines (§3
Animation & micro-physics) call for a spring with slight overshoot on
entry and a heavier decay on collapse. §3 **permits** the asymmetry; it
requires only that there be *one* of it, shared.
- **the risk of leaving it open:** an asymmetry will eventually arrive
  module by module, and a per-module asymmetry is exactly what §3
  forbids. Deciding once is cheap; discovering it twice is not.
- **where:** `~/launcher/crates/daemon/src/animation.rs`.
- **size:** needs-Max (a design call), then small.

### 73. The sticky pair has no ground of its own over bright fullscreen content — [STATED 2026-09-04 · GRIND session note]
§4's sticky control and its `[ ]` doorway are drawn over whatever the
fullscreen window is showing. Over bright content they lose contrast, and
the one affordance the rule exists to guarantee becomes hard to see.
- **the trade §4 accepted** was *one moment of chrome against a journey
  every time*. A pill that cannot be seen collects the cost of the chrome
  without delivering the guarantee — and "security" is one of the three
  feelings the acceptance test names.
- **the constraint:** §4's stated break is that where a fullscreen exists
  so nothing overlays it, the pill must be absent **entirely** — so the
  fix is a ground, never a heavier pill that is sometimes legible.
- **size:** small.

### 72. Nothing on the bar shows which window mode is ACTIVE — [STATED 2026-09-04 · GRIND session note]
The four modes are exclusive and each is reachable and escapable (§5 is
landed), but the bar never says which one is currently true.
- **why this is a §5 defect, not a feature request:** the rule's own
  requirement is *"the state shown matches what is on screen"*, and
  pressing the lit control is how you return to the base state. With
  nothing lit, the escape gesture is unteachable — the user must remember
  what they did, which is the opposite of *astuto*.
- **where:** the window-mode pills,
  `~/launcher/crates/daemon/src/options.rs`.
- **size:** small-to-medium; how it *reads* is a Max call.

### 71. window-pills is sensed and shown through the Brain but not decided or wired — [STATED 2026-08-30 · modules.md]
The collector perceives the active window and the pill is driven from
`ContextState.window` over the `brain.rs` bridge — two of the five build
lines. Still open: **Decided** (no Mind provider, so the window cluster
is never something the Brain *proposes*, only something it feeds) and
**Wired** (the raw context snapshot rather than the `OptionSet`).
- **why it matters beyond tidiness:** until the cluster arrives as ranked
  affordances it cannot be capped, de-cluttered, damped **or calibrated
  by skill** — it is permanently exempt from pillars 3 and 4 for an
  implementation reason.
- **keep** the `hyprctl` poll as the compositor-dark degrade path — the
  named fallback method §1 explicitly allows.
- **size:** medium.

### 70. Four modules still run a second brain — clipboard, notifications, dictionary, intellihide — [STATED 2026-08-30 · modules.md]
Each was built before `options-engine` existed and does its own sensing.
DoD line 4 is unmet for all four, and pillar 2 names the cost: two
pictures of the world that drift silently, and a Mind that cannot rank,
damp, cap or fade an offer it does not know about.
- **not cosmetic:** the notifications surface in particular already has a
  collector in the engine feeding `ContextState`, so the duplicate
  plumbing is live **today, on the normal path**, not as a fallback.
- **the pattern to copy:** battery v2 — the first module through the
  Spine, sensing only via the Brain.
- **where:** `~/launcher/crates/daemon/src/` (the four surfaces);
  providers in `crates/options-engine/src/mind/decide.rs`.
- **size:** needs-Max to sequence — four modules, one at a time, each
  re-verified live.

### 69. The Leader stops at the bar — box-internal lists never got it — [STATED 2026-09-04 · UXRules §1]
§1 landed at the pill level for the two groups that reflow: the window
cluster and the Mind's control row. The **notification cards and the
clipboard rows** are the same law one level down and are not done.
- **the failure, concretely:** dismiss a notification, the list closes
  up, and the next dismissal lands on a card that walked under the
  pointer. Repeated dismissal is exactly the "act N times" case §1 exists
  for, and it is the most repeated act on the bar.
- **the identity clause applies:** in a list that can re-rank, the leader
  is held by *which row it is*, never by which slot it sat in.
- **where:** the notification and clipboard box renderers in
  `~/launcher/crates/daemon/src/`.
- **size:** medium.

### 68. The Mind's ranked control row re-flows under the pointer — the Still Bar was never applied to it — [STATED 2026-09-04 · UXRules §2]
The row is **left-anchored**, so an offer arriving or withdrawing shifts
every control beside it — spontaneously, while the user is reaching for
one. This is the exact friction §2 was written to kill, in the one place
on the bar where things appear and disappear *on their own*, which makes
it the worst instance rather than a leftover.
- **why §1 does not cover it:** §1 pins on the *click*. This fires before
  any click, so nothing is pinned and there is nothing to hold.
- **the remedy is already named:** hold the ranking for the duration of
  the visit and apply it on leave — the same shape as the clock's
  deferred collapse, which is landed and works.
- **the exemption to keep:** urgency outranks stillness (§2's stated
  break); a Warning arrives when it arrives. `settle.rs` already encodes
  the same exception on the other axis.
- **where:** `~/launcher/crates/daemon/src/options.rs` (the dynamic
  OPTION pill band), against the deferred-collapse precedent in the
  clock.
- **size:** medium.

---

## Applied

*(nothing yet — this ledger opens 2026-09-12)*
